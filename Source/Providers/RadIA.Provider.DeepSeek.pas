unit RadIA.Provider.DeepSeek;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIADeepSeekProvider = class(TRadIAProviderBase)
  private
    function BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>; const AStream: Boolean = False): string;
    function ParseResponseBody(const AResponseJson: string; out AUsage: TTokenUsage): string;
    procedure ProcessStreamBuffer(var ABuffer: string; const ACallback: TStreamChunkCallback);
  public
    constructor Create(const AConfig: IAIConfig); override;
    
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback); override;
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TStreamChunkCallback); override;
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading, System.Generics.Collections;

{ TRadIADeepSeekProvider }

constructor TRadIADeepSeekProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderType := ptDeepSeek;
end;

function TRadIADeepSeekProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_DEEPSEEK_CHAT, MODEL_DEEPSEEK_REASONING);
end;

function TRadIADeepSeekProvider.GetName: string;
begin
  Result := 'DeepSeek';
end;

function TRadIADeepSeekProvider.BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>; const AStream: Boolean): string;
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
    
    { Add History }
    for LMsg in AHistory do
    begin
      LMsgObj := TJSONObject.Create;
      LMessagesArr.AddElement(LMsgObj);
      LMsgObj.AddPair('role', MessageRoleToString(LMsg.Role));
      LMsgObj.AddPair('content', LMsg.Content);
    end;
    
    { Add Current Prompt }
    LMsgObj := TJSONObject.Create;
    LMessagesArr.AddElement(LMsgObj);
    LMsgObj.AddPair('role', 'user');
    LMsgObj.AddPair('content', APrompt);
    
    Result := LRootObj.ToJSON;
  finally
    LRootObj.Free;
  end;
end;

function TRadIADeepSeekProvider.ParseResponseBody(const AResponseJson: string; out AUsage: TTokenUsage): string;
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
    LChoices := LJsonObj.GetValue('choices') as TJSONArray;
    if Assigned(LChoices) and (LChoices.Count > 0) then
    begin
      LChoice := LChoices.Items[0] as TJSONObject;
      LMessage := LChoice.GetValue('message') as TJSONObject;
      if Assigned(LMessage) then
        Result := LMessage.GetValue('content').Value;
    end;

    if Result.IsEmpty and Assigned(LJsonObj.GetValue('error')) then
      raise Exception.Create(LJsonObj.GetValue('error').ToString);

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

procedure TRadIADeepSeekProvider.SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
  const ACallback: TCompletionCallback);
var
  LUrl, LApiKey, LRequestBody: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', 'API Key is missing for DeepSeek. Please check settings.', False, TTokenUsage.Empty);
    Exit;
  end;

  LUrl := 'https://api.deepseek.com/chat/completions';

  SetLength(LHeaders, 1);
  LHeaders[0] := TNetHeader.Create('Authorization', 'Bearer ' + LApiKey);

  try
    LRequestBody := BuildRequestBody(APrompt, AHistory);
  except
    on E: Exception do
    begin
      ACallback('', 'Error building request JSON: ' + E.Message, False, TTokenUsage.Empty);
      Exit;
    end;
  end;

  LTaskProc :=
    procedure
    var
      LResponseText: string;
      LUsage: TTokenUsage;
      LQueueProc: TThreadProcedure;
    begin
      try
        LResponseText := DoPostRequest(LUrl, LHeaders, LRequestBody);
        LResponseText := ParseResponseBody(LResponseText, LUsage);

        LQueueProc :=
          procedure
          begin
            ACallback(LResponseText, '', False, LUsage);
          end;
        TThread.Queue(nil, LQueueProc);
      except
        on E: Exception do
        begin
          LQueueProc :=
            procedure
            begin
              ACallback('', E.Message, False, TTokenUsage.Empty);
            end;
          TThread.Queue(nil, LQueueProc);
        end;
      end;
    end;

  TTask.Run(LTaskProc);
end;

procedure TRadIADeepSeekProvider.FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>);
var
  LApiKey: string;
  LUrl: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    TThread.Queue(nil,
      procedure
      begin
        ACallback(GetAvailableModels, 'API Key is missing for DeepSeek. Using fallback models.');
      end);
    Exit;
  end;

  LUrl := 'https://api.deepseek.com/models';
  
  SetLength(LHeaders, 1);
  LHeaders[0] := TNetHeader.Create('Authorization', 'Bearer ' + LApiKey);

  LTaskProc := procedure
               var
                 LResponseText: string;
                 LJson: TJSONObject;
                 LDataArr: TJSONArray;
                 LVal: TJSONValue;
                 LModelObj: TJSONObject;
                 LId: string;
                 LModelsList: TList<string>;
                 LModelsArray: TArray<string>;
                 LQueueProc: TThreadProcedure;
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
                               LId := LModelObj.GetValue('id').Value;
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
                       
                     LQueueProc := procedure
                                   begin
                                     ACallback(LModelsArray, '');
                                   end;
                     TThread.Queue(nil, LQueueProc);
                   except
                     on E: Exception do
                     begin
                       LModelsArray := GetAvailableModels;
                       LQueueProc := procedure
                                     begin
                                       ACallback(LModelsArray, E.Message);
                                     end;
                       TThread.Queue(nil, LQueueProc);
                     end;
                   end;
                 finally
                   LModelsList.Free;
                 end;
               end;

  TTask.Run(LTaskProc);
end;

procedure TRadIADeepSeekProvider.ProcessStreamBuffer(var ABuffer: string; const ACallback: TStreamChunkCallback);
var
  LLine: string;
  LJsonLine: string;
  LJson: TJSONObject;
  LChoices: TJSONArray;
  LChoice: TJSONObject;
  LDelta: TJSONObject;
  LContent: string;
  LQueueProc: TThreadProcedure;
  LIdx: Integer;
begin
  while True do
  begin
    LIdx := ABuffer.IndexOf(#10);
    if LIdx = -1 then
      Break;
      
    LLine := ABuffer.Substring(0, LIdx);
    ABuffer := ABuffer.Substring(LIdx + 1);
    
    LLine := Trim(LLine);
    if LLine.StartsWith('data:') then
    begin
      LJsonLine := Trim(LLine.Substring(5));
      if LJsonLine = '[DONE]' then
      begin
        LQueueProc := procedure
                      begin
                        ACallback('', True, '');
                      end;
        TThread.Queue(nil, LQueueProc);
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
              if Assigned(LDelta) and Assigned(LDelta.GetValue('content')) then
              begin
                LContent := LDelta.GetValue('content').Value;
                LQueueProc := procedure
                              begin
                                ACallback(LContent, False, '');
                              end;
                TThread.Queue(nil, LQueueProc);
              end;
            end;
          finally
            LJson.Free;
          end;
        end;
      except
        { Ignore JSON parse errors }
      end;
    end;
  end;
end;

procedure TRadIADeepSeekProvider.SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
  const ACallback: TStreamChunkCallback);
var
  LUrl, LApiKey, LRequestBody: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', True, 'API Key is missing for DeepSeek. Please check settings.');
    Exit;
  end;

  LUrl := 'https://api.deepseek.com/chat/completions';

  SetLength(LHeaders, 1);
  LHeaders[0] := TNetHeader.Create('Authorization', 'Bearer ' + LApiKey);

  try
    LRequestBody := BuildRequestBody(APrompt, AHistory, True);
  except
    on E: Exception do
    begin
      ACallback('', True, 'Error building request JSON: ' + E.Message);
      Exit;
    end;
  end;

  LTaskProc :=
    procedure
    var
      LBufferText: string;
      LQueueProc: TThreadProcedure;
    begin
      LBufferText := '';
      try
        DoPostRequestStream(LUrl, LHeaders, LRequestBody,
          procedure(ABytes: TBytes)
          begin
            LBufferText := LBufferText + TEncoding.UTF8.GetString(ABytes);
            ProcessStreamBuffer(LBufferText, ACallback);
          end);
      except
        on E: Exception do
        begin
          LQueueProc := procedure
                        begin
                          ACallback('', True, E.Message);
                        end;
          TThread.Queue(nil, LQueueProc);
        end;
      end;
    end;

  TTask.Run(LTaskProc);
end;

end.
