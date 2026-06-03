unit RadIA.Provider.OpenAI;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAOpenAIProvider = class(TRadIAProviderBase)
  private
    function BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>): string;
    function ParseResponseBody(const AResponseJson: string; out AUsage: TTokenUsage): string;
  public
    constructor Create(const AConfig: IAIConfig); override;
    
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback); override;
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading, System.Generics.Collections;

{ TRadIAOpenAIProvider }

constructor TRadIAOpenAIProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderType := ptOpenAI;
end;

function TRadIAOpenAIProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_OPENAI_GPT4O_MINI, MODEL_OPENAI_GPT4O);
end;

function TRadIAOpenAIProvider.GetName: string;
begin
  Result := 'OpenAI ChatGPT';
end;

function TRadIAOpenAIProvider.BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>): string;
var
  LRootObj: TJSONObject;
  LMessagesArr: TJSONArray;
  LMsgObj: TJSONObject;
  LMsg: IChatMessage;
begin
  LRootObj := TJSONObject.Create;
  try
    LRootObj.AddPair('model', GetActiveModel);
    
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

function TRadIAOpenAIProvider.ParseResponseBody(const AResponseJson: string; out AUsage: TTokenUsage): string;
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
        Result := LMessage.GetValue('content').Value;
    end;

    { Check for API error }
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

procedure TRadIAOpenAIProvider.SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
  const ACallback: TCompletionCallback);
var
  LUrl, LApiKey, LRequestBody: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', 'API Key is missing for OpenAI. Please check settings.', False, TTokenUsage.Empty);
    Exit;
  end;

  { Resolve base URL: use custom endpoint if configured }
  if not FConfig.GetOpenAICustomBaseUrl.IsEmpty then
    LUrl := FConfig.GetOpenAICustomBaseUrl.TrimRight(['/']) + '/chat/completions'
  else
    LUrl := 'https://api.openai.com/v1/chat/completions';

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

procedure TRadIAOpenAIProvider.FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>);
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
        ACallback(GetAvailableModels, 'API Key is missing for OpenAI. Using fallback models.');
      end);
    Exit;
  end;

  { Resolve base URL for models discovery }
  if not FConfig.GetOpenAICustomBaseUrl.IsEmpty then
    LUrl := FConfig.GetOpenAICustomBaseUrl.TrimRight(['/']) + '/models'
  else
    LUrl := 'https://api.openai.com/v1/models';
  
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
                               
                               { Filter: gpt-* or o1-* or o3-* (chat and reasoning models) }
                               if LId.StartsWith('gpt-') or LId.StartsWith('o1-') or LId.StartsWith('o3-') then
                               begin
                                 LModelsList.Add(LId);
                               end;
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

end.
