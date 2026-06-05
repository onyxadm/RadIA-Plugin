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
    FHTTPClient: THTTPClient;
    FCancelled: Boolean;

    procedure HTTPClientReceiveData(const Sender: TObject;
      AContentLength, AReadCount: Int64; var AAbort: Boolean);

    function GetApiKey: string;
    function GetActiveModel: string;
    function DoPostRequest(const AUrl: string; const AHeaders: TNetHeaders;
      const ARequestBody: string): string;
    procedure DoPostRequestStream(const AUrl: string; const AHeaders: TNetHeaders;
      const ARequestBody: string; const AOnWrite: TProc<TBytes>);
    function DoGetRequest(const AUrl: string; const AHeaders: TNetHeaders): string;

    { OpenAI-compatible helpers (shared by OpenAI, DeepSeek, Groq providers) }
    function BuildOpenAICompatibleRequestBody(const APrompt: string;
      const AHistory: TArray<IChatMessage>; const AStream: Boolean;
      const ATemperature: Double; const AMaxTokens: Integer): string;
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
    destructor Destroy; override;

    { IIAProvider implementation }
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TCompletionCallback; const ATemperature: Double; const AMaxTokens: Integer); virtual; abstract;
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TStreamChunkCallback; const ATemperature: Double; const AMaxTokens: Integer); virtual;
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); virtual;
    function GetAvailableModels: TArray<string>; virtual; abstract;
    function GetName: string; virtual; abstract;
    function GetProviderType: TAIProviderType;
    procedure CancelCurrentRequest; virtual;
  end;

implementation

uses
  System.JSON, System.Generics.Collections, System.Math, RadIA.Core.Logger;

function MaskHeaders(const AHeaders: TNetHeaders): string;
var
  LHeader: TNetHeader;
  LList: TStringList;
begin
  LList := TStringList.Create;
  try
    for LHeader in AHeaders do
    begin
      if SameText(LHeader.Name, 'Authorization') or
         SameText(LHeader.Name, 'api-key') or
         SameText(LHeader.Name, 'x-api-key') or
         LHeader.Name.ToLower.Contains('key') or
         LHeader.Name.ToLower.Contains('token') then
      begin
        LList.Add(LHeader.Name + ': [MASKED]');
      end
      else
      begin
        LList.Add(LHeader.Name + ': ' + LHeader.Value);
      end;
    end;
    Result := LList.Text.Replace(#13#10, ', ').Trim([',', ' ']);
  finally
    LList.Free;
  end;
end;

constructor TRadIAProviderBase.Create(const AConfig: IAIConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FHTTPClient := THTTPClient.Create;
  FHTTPClient.OnReceiveData := HTTPClientReceiveData;
end;

destructor TRadIAProviderBase.Destroy;
begin
  FHTTPClient.Free;
  inherited Destroy;
end;

procedure TRadIAProviderBase.HTTPClientReceiveData(const Sender: TObject;
  AContentLength, AReadCount: Int64; var AAbort: Boolean);
begin
  if FCancelled then
  begin
    TLogger.Log('HTTPClientReceiveData: Aborting request because FCancelled is True', 'Provider');
    AAbort := True;
  end;
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

procedure TRadIAProviderBase.CancelCurrentRequest;
begin
  TLogger.Log('CancelCurrentRequest: Requesting cancellation (FCancelled := True)', 'Provider');
  FCancelled := True;
end;

function TRadIAProviderBase.DoGetRequest(const AUrl: string; const AHeaders: TNetHeaders): string;
var
  LResponse: IHTTPResponse;
  LTimeoutMs: Integer;
begin
  TLogger.Log(Format('DoGetRequest: URL=%s', [AUrl]), 'Provider');
  TLogger.Log(Format('DoGetRequest: Headers=[%s]', [MaskHeaders(AHeaders)]), 'Provider');
  
  FCancelled := False;
  LTimeoutMs := FConfig.GetTimeout(FProviderType) * 1000;
  if LTimeoutMs <= 0 then LTimeoutMs := 60000;

  FHTTPClient.ConnectionTimeout := LTimeoutMs;
  FHTTPClient.SendTimeout := LTimeoutMs;
  FHTTPClient.ResponseTimeout := LTimeoutMs;
  FHTTPClient.AcceptCharSet := 'utf-8';
  FHTTPClient.ProtocolVersion := THTTPProtocolVersion.HTTP_1_1;

  try
    LResponse := FHTTPClient.Get(AUrl, nil, AHeaders);
    TLogger.Log(Format('DoGetRequest: Response Status=%d %s', [LResponse.StatusCode, LResponse.StatusText]), 'Provider');
    
    if LResponse.StatusCode <> 200 then
    begin
      TLogger.Log(Format('DoGetRequest: Error Response content=%s', [LResponse.ContentAsString(TEncoding.UTF8)]), 'Provider');
      raise ENetHTTPClientException.CreateFmt('HTTP error %d: %s. Response: %s',
        [LResponse.StatusCode, LResponse.StatusText, LResponse.ContentAsString(TEncoding.UTF8)]);
    end;

    Result := LResponse.ContentAsString(TEncoding.UTF8);
    TLogger.Log(Format('DoGetRequest: Response length=%d', [Length(Result)]), 'Provider');
  except
    on E: Exception do
    begin
      TLogger.Log(Format('DoGetRequest: Exception occurred: %s', [E.Message]), 'Provider');
      raise;
    end;
  end;
end;

function TRadIAProviderBase.DoPostRequest(const AUrl: string; const AHeaders: TNetHeaders;
  const ARequestBody: string): string;
var
  LSourceStream: TStringStream;
  LResponse: IHTTPResponse;
  LTimeoutMs: Integer;
begin
  TLogger.Log(Format('DoPostRequest: URL=%s', [AUrl]), 'Provider');
  TLogger.Log(Format('DoPostRequest: Headers=[%s]', [MaskHeaders(AHeaders)]), 'Provider');
  TLogger.Log(Format('DoPostRequest: Body=%s', [ARequestBody]), 'Provider');

  FCancelled := False;
  LSourceStream := TStringStream.Create(ARequestBody, TEncoding.UTF8);
  try
    LTimeoutMs := FConfig.GetTimeout(FProviderType) * 1000;
    if LTimeoutMs <= 0 then LTimeoutMs := 60000;

    FHTTPClient.ConnectionTimeout := LTimeoutMs;
    FHTTPClient.SendTimeout := LTimeoutMs;
    FHTTPClient.ResponseTimeout := LTimeoutMs;
    FHTTPClient.ContentType := 'application/json';
    FHTTPClient.AcceptCharSet := 'utf-8';
    FHTTPClient.ProtocolVersion := THTTPProtocolVersion.HTTP_1_1;

    try
      LResponse := FHTTPClient.Post(AUrl, LSourceStream, nil, AHeaders);
      TLogger.Log(Format('DoPostRequest: Response Status=%d %s', [LResponse.StatusCode, LResponse.StatusText]), 'Provider');
      
      if LResponse.StatusCode <> 200 then
      begin
        TLogger.Log(Format('DoPostRequest: Error Response content=%s', [LResponse.ContentAsString(TEncoding.UTF8)]), 'Provider');
        raise ENetHTTPClientException.CreateFmt('HTTP error %d: %s. Response: %s',
          [LResponse.StatusCode, LResponse.StatusText, LResponse.ContentAsString(TEncoding.UTF8)]);
      end;

      Result := LResponse.ContentAsString(TEncoding.UTF8);
      TLogger.Log(Format('DoPostRequest: Response Body=%s', [Result]), 'Provider');
    except
      on E: Exception do
      begin
        TLogger.Log(Format('DoPostRequest: Exception occurred: %s', [E.Message]), 'Provider');
        raise;
      end;
    end;
  finally
    LSourceStream.Free;
  end;
end;

procedure TRadIAProviderBase.DoPostRequestStream(const AUrl: string; const AHeaders: TNetHeaders;
  const ARequestBody: string; const AOnWrite: TProc<TBytes>);
var
  LSourceStream: TStringStream;
  LTargetStream: TStreamingTargetStream;
  LResponse: IHTTPResponse;
  LTimeoutMs: Integer;
begin
  TLogger.Log(Format('DoPostRequestStream: URL=%s', [AUrl]), 'Provider');
  TLogger.Log(Format('DoPostRequestStream: Headers=[%s]', [MaskHeaders(AHeaders)]), 'Provider');
  TLogger.Log(Format('DoPostRequestStream: Body=%s', [ARequestBody]), 'Provider');

  FCancelled := False;
  LSourceStream := TStringStream.Create(ARequestBody, TEncoding.UTF8);
  LTargetStream := TStreamingTargetStream.Create(AOnWrite);
  try
    LTimeoutMs := FConfig.GetTimeout(FProviderType) * 1000;
    if LTimeoutMs <= 0 then LTimeoutMs := 60000;

    FHTTPClient.ConnectionTimeout := LTimeoutMs;
    FHTTPClient.SendTimeout := LTimeoutMs;
    FHTTPClient.ResponseTimeout := LTimeoutMs;
    FHTTPClient.ContentType := 'application/json';
    FHTTPClient.AcceptCharSet := 'utf-8';
    FHTTPClient.ProtocolVersion := THTTPProtocolVersion.HTTP_1_1;

    try
      LResponse := FHTTPClient.Post(AUrl, LSourceStream, LTargetStream, AHeaders);
      TLogger.Log(Format('DoPostRequestStream: Response Status=%d %s', [LResponse.StatusCode, LResponse.StatusText]), 'Provider');
      
      if LResponse.StatusCode <> 200 then
      begin
        TLogger.Log('DoPostRequestStream: Error occurred during streaming', 'Provider');
        raise ENetHTTPClientException.CreateFmt('HTTP error %d: %s.',
          [LResponse.StatusCode, LResponse.StatusText]);
      end;
    except
      on E: Exception do
      begin
        TLogger.Log(Format('DoPostRequestStream: Exception occurred: %s', [E.Message]), 'Provider');
        raise;
      end;
    end;
  finally
    LTargetStream.Free;
    LSourceStream.Free;
  end;
end;

procedure TRadIAProviderBase.SendPromptStreamAsync(const APrompt: string;
  const AHistory: TArray<IChatMessage>; const ACallback: TStreamChunkCallback;
  const ATemperature: Double; const AMaxTokens: Integer);
begin
  { Default fallback simulating streaming }
  SendPromptAsync(APrompt, AHistory,
    procedure(const AResponse: string; const AError: string; AFromCache: Boolean; const AUsage: TTokenUsage)
    var
      LResCopy: string;
      LErrCopy: string;
    begin
      LResCopy := AResponse;
      LErrCopy := AError;
      TThread.Queue(nil,
        TThreadProcedure(
          procedure
          begin
            ACallback(LResCopy, True, LErrCopy);
          end
        )
      );
    end, ATemperature, AMaxTokens);
end;

{ --- OpenAI-Compatible Shared Helpers --- }

function TRadIAProviderBase.BuildOpenAICompatibleRequestBody(const APrompt: string;
  const AHistory: TArray<IChatMessage>; const AStream: Boolean;
  const ATemperature: Double; const AMaxTokens: Integer): string;
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

    if ATemperature >= 0.0 then
      LRootObj.AddPair('temperature', TJSONNumber.Create(ATemperature));
    if AMaxTokens > 0 then
      LRootObj.AddPair('max_tokens', TJSONNumber.Create(AMaxTokens));

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
        ACallback('', True, '');

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
                  ACallback(LContent, False, '');
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
  LProviderRef: IIAProvider;
begin
  LProviderRef := Self;
  LUrl := GetModelsDiscoveryUrl;

  { Providers that do not supply a discovery URL fall back to static list }
  if LUrl.IsEmpty then
  begin
    TThread.Queue(nil,
      TThreadProcedure(
        procedure
        var
          LModels: TArray<string>;
        begin
          LModels := GetAvailableModels;
          ACallback(LModels, '');
        end
      )
    );
    Exit;
  end;

  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    TThread.Queue(nil,
      TThreadProcedure(
        procedure
        var
          LModels: TArray<string>;
          LMsg: string;
        begin
          LModels := GetAvailableModels;
          LMsg := Format('API Key is missing for %s. Using fallback models.', [GetName]);
          ACallback(LModels, LMsg);
        end
      )
    );
    Exit;
  end;

  SetLength(LHeaders, 1);
  LHeaders[0] := TNetHeader.Create('Authorization', 'Bearer ' + LApiKey);

  LTaskProc :=
    procedure
    var
      LResponseText: string;
      LJson: TJSONObject;
      LData: TJSONArray;
      LVal: TJSONValue;
      LId: string;
      LModelsList: TList<string>;
      LModelsArray: TArray<string>;
      LErrorMsg: string;
      I: Integer;
    begin
      LProviderRef.GetProviderType;
      LModelsList := TList<string>.Create;
      try
        try
          LResponseText := DoGetRequest(LUrl, LHeaders);
          LJson := TJSONObject.ParseJSONValue(LResponseText) as TJSONObject;
          if Assigned(LJson) then
          begin
            try
              LData := LJson.GetValue('data') as TJSONArray;
              if Assigned(LData) then
              begin
                for I := 0 to LData.Count - 1 do
                begin
                  LVal := LData.Items[I];
                  if LVal.TryGetValue<string>('id', LId) then
                  begin
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
            TThreadProcedure(
              procedure
              var
                LModelsCopy: TArray<string>;
              begin
                LModelsCopy := LModelsArray;
                ACallback(LModelsCopy, '');
              end
            )
          );
        except
          on E: Exception do
          begin
            LErrorMsg := E.ClassName + ': ' + E.Message;
            LModelsArray := GetAvailableModels;
            TThread.Queue(nil,
              TThreadProcedure(
                procedure
                var
                  LModelsCopy: TArray<string>;
                  LErrCopy: string;
                begin
                  LModelsCopy := LModelsArray;
                  LErrCopy := LErrorMsg;
                  ACallback(LModelsCopy, LErrCopy);
                end
              )
            );
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

function TStreamingTargetStream.Write(const Buffer; Count: Longint): Longint;
var
  LBytes: TBytes;
begin
  Result := Count;
  TLogger.Log(Format('TStreamingTargetStream.Write: Count = %d', [Count]), 'Provider');
  if (Count > 0) and Assigned(FOnWrite) then
  begin
    SetLength(LBytes, Count);
    Move(Buffer, LBytes[0], Count);
    FOnWrite(LBytes);
  end;
end;

function TStreamingTargetStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := 0;
end;

function TStreamingTargetStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := 0;
end;

end.
