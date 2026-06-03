unit RadIA.Provider.Ollama;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAOllamaProvider = class(TRadIAProviderBase)
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

{ TRadIAOllamaProvider }

constructor TRadIAOllamaProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderType := ptOllama;
end;

function TRadIAOllamaProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create('llama3:latest', 'codellama:latest', 'mistral:latest', 'phi3:latest');
end;

function TRadIAOllamaProvider.GetName: string;
begin
  Result := 'Ollama Local/Network';
end;

function TRadIAOllamaProvider.BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>): string;
var
  LRootObj: TJSONObject;
  LMessagesArr: TJSONArray;
  LMsgObj: TJSONObject;
  LMsg: IChatMessage;
begin
  LRootObj := TJSONObject.Create;
  try
    LRootObj.AddPair('model', GetActiveModel);
    LRootObj.AddPair('stream', TJSONBool.Create(False));
    
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

function TRadIAOllamaProvider.ParseResponseBody(const AResponseJson: string; out AUsage: TTokenUsage): string;
var
  LJsonObj: TJSONObject;
  LMsgObj: TJSONObject;
begin
  Result := '';
  AUsage := TTokenUsage.Empty;
  
  LJsonObj := TJSONObject.ParseJSONValue(AResponseJson) as TJSONObject;
  if Assigned(LJsonObj) then
  begin
    try
      LMsgObj := LJsonObj.GetValue('message') as TJSONObject;
      if Assigned(LMsgObj) then
      begin
        Result := LMsgObj.GetValue('content').Value;
      end;
      
      if Result.IsEmpty then
      begin
        if LJsonObj.GetValue('error') <> nil then
          raise Exception.Create(LJsonObj.GetValue('error').ToString);
      end;

      { Extract token usage }
      AUsage.PromptTokens     := LJsonObj.GetValue<Integer>('prompt_eval_count', 0);
      AUsage.CompletionTokens := LJsonObj.GetValue<Integer>('eval_count', 0);
      AUsage.TotalTokens      := AUsage.PromptTokens + AUsage.CompletionTokens;
    finally
      LJsonObj.Free;
    end;
  end;
end;

procedure TRadIAOllamaProvider.SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
  const ACallback: TCompletionCallback);
var
  LUrl, LRequestBody: string;
  LTaskProc: TProc;
begin
  LUrl := FConfig.OllamaBaseUrl + '/api/chat';

  try
    LRequestBody := BuildRequestBody(APrompt, AHistory);
  except
    on E: Exception do
    begin
      ACallback('', 'Error building request JSON: ' + E.Message, False, TTokenUsage.Empty);
      Exit;
    end;
  end;

  LTaskProc := procedure
               var
                 LResponseText: string;
                 LUsage: TTokenUsage;
                 LQueueProc: TThreadProcedure;
               begin
                 try
                   LResponseText := DoPostRequest(LUrl, nil, LRequestBody);
                   LResponseText := ParseResponseBody(LResponseText, LUsage);
                   
                   LQueueProc := procedure
                                 begin
                                   ACallback(LResponseText, '', False, LUsage);
                                 end;
                   TThread.Queue(nil, LQueueProc);
                 except
                   on E: Exception do
                   begin
                     LQueueProc := procedure
                                   begin
                                     ACallback('', E.Message, False, TTokenUsage.Empty);
                                   end;
                     TThread.Queue(nil, LQueueProc);
                   end;
                 end;
               end;

  TTask.Run(LTaskProc);
end;

procedure TRadIAOllamaProvider.FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>);
var
  LUrl: string;
  LTaskProc: TProc;
begin
  LUrl := FConfig.OllamaBaseUrl + '/api/tags';

  LTaskProc := procedure
               var
                 LResponseText: string;
                 LJson: TJSONObject;
                 LModelsArr: TJSONArray;
                 LVal: TJSONValue;
                 LModelObj: TJSONObject;
                 LModelsList: TList<string>;
                 LModelsArray: TArray<string>;
                 LQueueProc: TThreadProcedure;
               begin
                 LModelsList := TList<string>.Create;
                 try
                   try
                     LResponseText := DoGetRequest(LUrl, nil);
                     LJson := TJSONObject.ParseJSONValue(LResponseText) as TJSONObject;
                     if Assigned(LJson) then
                     begin
                       try
                         LModelsArr := LJson.GetValue('models') as TJSONArray;
                         if Assigned(LModelsArr) then
                         begin
                           for LVal in LModelsArr do
                           begin
                             if LVal is TJSONObject then
                             begin
                                LModelObj := LVal as TJSONObject;
                                LModelsList.Add(LModelObj.GetValue('name').Value);
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
