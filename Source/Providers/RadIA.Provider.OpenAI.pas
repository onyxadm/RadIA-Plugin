unit RadIA.Provider.OpenAI;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAOpenAIProvider = class(TRadIAProviderBase)
  private
    function BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>): string;
    function ParseResponseBody(const AResponseJson: string): string;
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

function TRadIAOpenAIProvider.ParseResponseBody(const AResponseJson: string): string;
var
  LJsonObj: TJSONObject;
  LChoices: TJSONArray;
  LChoice: TJSONObject;
  LMessage: TJSONObject;
begin
  Result := '';
  LJsonObj := TJSONObject.ParseJSONValue(AResponseJson) as TJSONObject;
  if Assigned(LJsonObj) then
  begin
    try
      LChoices := LJsonObj.GetValue('choices') as TJSONArray;
      if Assigned(LChoices) and (LChoices.Count > 0) then
      begin
        LChoice := LChoices.Items[0] as TJSONObject;
        LMessage := LChoice.GetValue('message') as TJSONObject;
        if Assigned(LMessage) then
        begin
          Result := LMessage.GetValue('content').Value;
        end;
      end;
      
      if Result.IsEmpty then
      begin
        if LJsonObj.GetValue('error') <> nil then
          raise Exception.Create(LJsonObj.GetValue('error').ToString);
      end;
    finally
      LJsonObj.Free;
    end;
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
    ACallback('', 'API Key is missing for OpenAI. Please check settings.', False);
    Exit;
  end;

  LUrl := 'https://api.openai.com/v1/chat/completions';
  
  SetLength(LHeaders, 1);
  LHeaders[0] := TNetHeader.Create('Authorization', 'Bearer ' + LApiKey);

  try
    LRequestBody := BuildRequestBody(APrompt, AHistory);
  except
    on E: Exception do
    begin
      ACallback('', 'Error building request JSON: ' + E.Message, False);
      Exit;
    end;
  end;

  LTaskProc := procedure
               var
                 LResponseText: string;
                 LQueueProc: TThreadProcedure;
               begin
                 try
                   LResponseText := DoPostRequest(LUrl, LHeaders, LRequestBody);
                   LResponseText := ParseResponseBody(LResponseText);
                   
                   LQueueProc := procedure
                                 begin
                                   ACallback(LResponseText, '', False);
                                 end;
                   TThread.Queue(nil, LQueueProc);
                 except
                   on E: Exception do
                   begin
                     LQueueProc := procedure
                                   begin
                                     ACallback('', E.Message, False);
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
