unit RadIA.Provider.Base;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, System.Threading,
  RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.TokenUsage;

type
  { Custom stream that intercepts HTTP write calls to process SSE chunks in real time }
  TStreamingTargetStream = class(TStream)
  private
    FOnWrite: TProc<TBytes>;
  public
    constructor Create(const AOnWrite: TProc<TBytes>);
    function Write(const Buffer; Count: Longint): Longint; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  { Base class for AI Providers implementing IIAProvider }
  TRadIAProviderBase = class(TInterfacedObject, IIAProvider)
  protected
    FConfig: IAIConfig;
    FProviderType: TAIProviderType;

    function GetApiKey: string;
    function GetActiveModel: string;
    function DoPostRequest(const AUrl: string; const AHeaders: TNetHeaders;
      const ARequestBody: string): string;
    function DoPostRequestStream(const AUrl: string; const AHeaders: TNetHeaders;
      const ARequestBody: string; const AOnWrite: TProc<TBytes>): Boolean;
    function DoGetRequest(const AUrl: string; const AHeaders: TNetHeaders): string;

    { OpenAI-compatible helpers (shared by OpenAI, DeepSeek, Groq providers) }
    function BuildOpenAICompatibleRequestBody(const APrompt: string;
      const AHistory: TArray<IChatMessage>; const AStream: Boolean): string;
    function ParseOpenAICompatibleResponse(const AResponseJson: string;
      out AUsage: TTokenUsage): string;
    procedure ProcessOpenAICompatibleStreamBuffer(var ABuffer: string;
      const ACallback: TStreamChunkCallback);

    { Hook for providers that support model discovery via /models endpoint.
      Subclasses must return the base URL (without path) and optionally
      override FilterModelId to apply provider-specific filtering. }
    function GetModelsDiscoveryUrl: string; virtual;
    function FilterModelId(const AId: string): Boolean; virtual;
  public
    constructor Create(const AConfig: IAIConfig); virtual;

    { IIAProvider implementation }
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TCompletionCallback); virtual; abstract;
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TStreamChunkCallback); virtual;
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); virtual;
    function GetAvailableModels: TArray<string>; virtual; abstract;
    function GetName: string; virtual; abstract;
    function GetProviderType: TAIProviderType;
  end;

implementation

uses
  System.JSON, System.Generics.Collections;

constructor TRadIAProviderBase.Create(const AConfig: IAIConfig);
begin
  inherited Create;
  FConfig := AConfig;
end;

function TRadIAProviderBase.GetApiKey: string;
begin
  Result := FConfig.GetApiKey(FProviderType);
end;

function TRadIAProviderBase.GetActiveModel: string;
begin
  Result := FConfig.GetActiveModel(FProviderType);
end;

function TRadIAProviderBase.GetProviderType: TAIProviderType;
begin
  Result := FProviderType;
end;

function TRadIAProviderBase.DoGetRequest(const AUrl: string; const AHeaders: TNetHeaders): string;
var
  LHTTPClient: THTTPClient;
  LResponse: IHTTPResponse;
begin
  LHTTPClient := THTTPClient.Create;
  try
    LHTTPClient.ConnectionTimeout := 10000;
    LHTTPClient.SendTimeout := 10000;
    LHTTPClient.ResponseTimeout := 60000;
    LHTTPClient.AcceptCharSet := 'utf-8';

    LResponse := LHTTPClient.Get(AUrl, nil, AHeaders);

    if LResponse.StatusCode <> 200 then
      raise ENetHTTPClientException.CreateFmt('HTTP error %d: %s. Response: %s',
        [LResponse.StatusCode, LResponse.StatusText, LResponse.ContentAsString(TEncoding.UTF8)]);

    Result := LResponse.ContentAsString(TEncoding.UTF8);
  finally
    LHTTPClient.Free;
  end;
end;

function TRadIAProviderBase.DoPostRequest(const AUrl: string; const AHeaders: TNetHeaders;
  const ARequestBody: string): string;
var
  LHTTPClient: THTTPClient;
  LSourceStream: TStringStream;
  LResponse: IHTTPResponse;
begin
  LHTTPClient := THTTPClient.Create;
  LSourceStream := TStringStream.Create(ARequestBody, TEncoding.UTF8);
  try
    LHTTPClient.ConnectionTimeout := 10000;
    LHTTPClient.SendTimeout := 10000;
    LHTTPClient.ResponseTimeout := 60000;
    LHTTPClient.ContentType := 'application/json';
    LHTTPClient.AcceptCharSet := 'utf-8';

    LResponse := LHTTPClient.Post(AUrl, LSourceStream, nil, AHeaders);

    if LResponse.StatusCode <> 200 then
      raise ENetHTTPClientException.CreateFmt('HTTP error %d: %s. Response: %s',
        [LResponse.StatusCode, LResponse.StatusText, LResponse.ContentAsString(TEncoding.UTF8)]);

    Result := LResponse.ContentAsString(TEncoding.UTF8);
  finally
    LSourceStream.Free;
    LHTTPClient.Free;
  end;
end;

function TRadIAProviderBase.DoPostRequestStream(const AUrl: string; const AHeaders: TNetHeaders;
  const ARequestBody: string; const AOnWrite: TProc<TBytes>): Boolean;
var
  LHTTPClient: THTTPClient;
  LSourceStream: TStringStream;
  LTargetStream: TStreamingTargetStream;
  LResponse: IHTTPResponse;
begin
  Result := False;
  LHTTPClient := THTTPClient.Create;
  LSourceStream := TStringStream.Create(ARequestBody, TEncoding.UTF8);
  LTargetStream := TStreamingTargetStream.Create(AOnWrite);
  try
    LHTTPClient.ConnectionTimeout := 10000;
    LHTTPClient.SendTimeout := 10000;
    LHTTPClient.ResponseTimeout := 60000;
    LHTTPClient.ContentType := 'application/json';
    LHTTPClient.AcceptCharSet := 'utf-8';

    LResponse := LHTTPClient.Post(AUrl, LSourceStream, LTargetStream, AHeaders);

    if LResponse.StatusCode <> 200 then
      raise ENetHTTPClientException.CreateFmt('HTTP error %d: %s. Response: %s',
        [LResponse.StatusCode, LResponse.StatusText, LResponse.ContentAsString(TEncoding.UTF8)]);

    Result := True;
  finally
    LTargetStream.Free;
    LSourceStream.Free;
    LHTTPClient.Free;
  end;
end;

procedure TRadIAProviderBase.SendPromptStreamAsync(const APrompt: string;
  const AHistory: TArray<IChatMessage>; const ACallback: TStreamChunkCallback);
begin
  { Default fallback simulating streaming }
  SendPromptAsync(APrompt, AHistory,
    procedure(const AResponse: string; const AError: string; AFromCache: Boolean; const AUsage: TTokenUsage)
    begin
      TThread.Queue(nil,
        procedure
        begin
          ACallback(AResponse, True, AError);
        end);
    end);
end;

{ --- OpenAI-Compatible Shared Helpers --- }

function TRadIAProviderBase.BuildOpenAICompatibleRequestBody(const APrompt: string;
  const AHistory: TArray<IChatMessage>; const AStream: Boolean): string;
var
  LRootObj: TJSONObject;
  LMessagesArr: TJSONArray;
  LMsgObj: TJSONObject;
  LMsg: IChatMessage;
begin
  LRootObj := TJSONObject.Create;
  try
    LRootObj.AddPair('model', GetActiveModel);
    if AStream then
      LRootObj.AddPair('stream', TJSONBool.Create(True));

    LMessagesArr := TJSONArray.Create;
    LRootObj.AddPair('messages', LMessagesArr);

    { Add history messages }
    for LMsg in AHistory do
    begin
      LMsgObj := TJSONObject.Create;
      LMessagesArr.AddElement(LMsgObj);
      LMsgObj.AddPair('role', MessageRoleToString(LMsg.Role));
      LMsgObj.AddPair('content', LMsg.Content);
    end;

    { Add current user prompt }
    LMsgObj := TJSONObject.Create;
    LMessagesArr.AddElement(LMsgObj);
    LMsgObj.AddPair('role', 'user');
    LMsgObj.AddPair('content', APrompt);

    Result := LRootObj.ToJSON;
  finally
    LRootObj.Free;
  end;
end;

function TRadIAProviderBase.ParseOpenAICompatibleResponse(const AResponseJson: string;
  out AUsage: TTokenUsage): string;
var
  LJsonObj: TJSONObject;
  LChoices: TJSONArray;
  LChoice: TJSONObject;
  LMessage: TJSONObject;
  LUsageNode: TJSONObject;
begin
  Result := '';
  AUsage := TTokenUsage.Empty;

  LJsonObj := TJSONObject.ParseJSONValue(AResponseJson) as TJSONObject;
  if not Assigned(LJsonObj) then
    Exit;

  try
    { Extract text from choices[0].message.content }
    LChoices := LJsonObj.GetValue('choices') as TJSONArray;
    if Assigned(LChoices) and (LChoices.Count > 0) then
    begin
      LChoice := LChoices.Items[0] as TJSONObject;
      LMessage := LChoice.GetValue('message') as TJSONObject;
      if Assigned(LMessage) then
        Result := LMessage.GetValue<string>('content', '');
    end;

    { Check for API error node }
    if Result.IsEmpty and Assigned(LJsonObj.GetValue('error')) then
      raise Exception.Create(LJsonObj.GetValue('error').ToString);

    { Extract token usage }
    LUsageNode := LJsonObj.GetValue('usage') as TJSONObject;
    if Assigned(LUsageNode) then
    begin
      AUsage.PromptTokens     := LUsageNode.GetValue<Integer>('prompt_tokens', 0);
      AUsage.CompletionTokens := LUsageNode.GetValue<Integer>('completion_tokens', 0);
      AUsage.TotalTokens      := LUsageNode.GetValue<Integer>('total_tokens', 0);
    end;
  finally
    LJsonObj.Free;
  end;
end;

procedure TRadIAProviderBase.ProcessOpenAICompatibleStreamBuffer(var ABuffer: string;
  const ACallback: TStreamChunkCallback);
var
  LLine: string;
  LJsonLine: string;
  LJson: TJSONObject;
  LChoices: TJSONArray;
  LChoice: TJSONObject;
  LDelta: TJSONObject;
  LContent: string;
  LIdx: Integer;
  LStartPos: Integer;
  LPtr: PChar;
  LLen: Integer;
  LLastProcessedPos: Integer;
begin
  LLen := ABuffer.Length;
  if LLen = 0 then
    Exit;

  LPtr := PChar(ABuffer);
  LStartPos := 0;
  LLastProcessedPos := 0;

  while LStartPos < LLen do
  begin
    LIdx := LStartPos;
    while (LIdx < LLen) and (LPtr[LIdx] <> #10) do
      Inc(LIdx);

    if LIdx >= LLen then
      Break;

    LLine := ABuffer.Substring(LStartPos, LIdx - LStartPos);
    LStartPos := LIdx + 1;
    LLastProcessedPos := LStartPos;

    LLine := Trim(LLine);
    if LLine.StartsWith('data:') then
    begin
      LJsonLine := Trim(LLine.Substring(5));
      if LJsonLine = '[DONE]' then
      begin
        TThread.Queue(nil,
          procedure
          begin
            ACallback('', True, '');
          end);

        ABuffer := ABuffer.Substring(LLastProcessedPos);
        Exit;
      end;

      try
        LJson := TJSONObject.ParseJSONValue(LJsonLine) as TJSONObject;
        if Assigned(LJson) then
        begin
          try
            LChoices := LJson.GetValue('choices') as TJSONArray;
            if Assigned(LChoices) and (LChoices.Count > 0) then
            begin
              LChoice := LChoices.Items[0] as TJSONObject;
              LDelta := LChoice.GetValue('delta') as TJSONObject;
              if Assigned(LDelta) then
              begin
                LContent := LDelta.GetValue<string>('content', '');
                if not LContent.IsEmpty then
                TThread.Queue(nil,
                  procedure
                  begin
                    ACallback(LContent, False, '');
                  end);
              end;
            end;
          finally
            LJson.Free;
          end;
        end;
      except
        { Ignore JSON parse errors in stream chunks }
      end;
    end;
  end;

  if LLastProcessedPos > 0 then
    ABuffer := ABuffer.Substring(LLastProcessedPos);
end;

{ --- Model Discovery Hook (for OpenAI-compatible /models endpoints) --- }

function TRadIAProviderBase.GetModelsDiscoveryUrl: string;
begin
  Result := '';
end;

function TRadIAProviderBase.FilterModelId(const AId: string): Boolean;
begin
  Result := not AId.IsEmpty;
end;

procedure TRadIAProviderBase.FetchAvailableModelsAsync(
  const ACallback: TProc<TArray<string>, string>);
var
  LUrl: string;
  LApiKey: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
begin
  LUrl := GetModelsDiscoveryUrl;

  { Providers that do not supply a discovery URL fall back to static list }
  if LUrl.IsEmpty then
  begin
    TThread.Queue(nil,
      procedure
      begin
        ACallback(GetAvailableModels, '');
      end);
    Exit;
  end;

  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    TThread.Queue(nil,
      procedure
      begin
        ACallback(GetAvailableModels,
          Format('API Key is missing for %s. Using fallback models.', [GetName]));
      end);
    Exit;
  end;

  SetLength(LHeaders, 1);
  LHeaders[0] := TNetHeader.Create('Authorization', 'Bearer ' + LApiKey);

  LTaskProc :=
    procedure
    var
      LResponseText: string;
      LJson: TJSONObject;
      LDataArr: TJSONArray;
      LVal: TJSONValue;
      LModelObj: TJSONObject;
      LId: string;
      LModelsList: TList<string>;
      LModelsArray: TArray<string>;
    begin
      LModelsList := TList<string>.Create;
      try
        try
          LResponseText := DoGetRequest(LUrl, LHeaders);
          LJson := TJSONObject.ParseJSONValue(LResponseText) as TJSONObject;
          if Assigned(LJson) then
          begin
            try
              LDataArr := LJson.GetValue('data') as TJSONArray;
              if Assigned(LDataArr) then
              begin
                for LVal in LDataArr do
                begin
                  if LVal is TJSONObject then
                  begin
                    LModelObj := LVal as TJSONObject;
                    LId := LModelObj.GetValue<string>('id', '');
                    if FilterModelId(LId) then
                      LModelsList.Add(LId);
                  end;
                end;
              end;
            finally
              LJson.Free;
            end;
          end;

          LModelsList.Sort;

          if LModelsList.Count = 0 then
            LModelsArray := GetAvailableModels
          else
            LModelsArray := LModelsList.ToArray;

          TThread.Queue(nil,
            procedure
            begin
              ACallback(LModelsArray, '');
            end);
        except
          on E: Exception do
          begin
            LModelsArray := GetAvailableModels;
            TThread.Queue(nil,
              procedure
              begin
                ACallback(LModelsArray, E.Message);
              end);
          end;
        end;
      finally
        LModelsList.Free;
      end;
    end;

  TTask.Run(LTaskProc);
end;

{ TStreamingTargetStream }

constructor TStreamingTargetStream.Create(const AOnWrite: TProc<TBytes>);
begin
  inherited Create;
  FOnWrite := AOnWrite;
end;

function TStreamingTargetStream.Write(const Buffer; Count: Integer): Longint;
var
  LBytes: TBytes;
begin
  Result := Count;
  if (Count > 0) and Assigned(FOnWrite) then
  begin
    SetLength(LBytes, Count);
    Move(Buffer, LBytes[0], Count);
    FOnWrite(LBytes);
  end;
end;

function TStreamingTargetStream.Read(var Buffer; Count: Integer): Longint;
begin
  Result := 0;
end;

function TStreamingTargetStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := 0;
end;

end.
