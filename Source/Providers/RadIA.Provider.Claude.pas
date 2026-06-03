unit RadIA.Provider.Claude;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAClaudeProvider = class(TRadIAProviderBase)
  private
    function BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>): string;
    function ParseResponseBody(const AResponseJson: string): string;
  public
    constructor Create(const AConfig: IAIConfig); override;
    
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading;

{ TRadIAClaudeProvider }

constructor TRadIAClaudeProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderType := ptClaude;
end;

function TRadIAClaudeProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_CLAUDE_3_HAIKU, MODEL_CLAUDE_35_SONNET);
end;

function TRadIAClaudeProvider.GetName: string;
begin
  Result := 'Anthropic Claude';
end;

function TRadIAClaudeProvider.BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>): string;
var
  LRootObj: TJSONObject;
  LMessagesArr: TJSONArray;
  LMsgObj: TJSONObject;
  LMsg: IChatMessage;
  LSystemPrompt: string;
begin
  LRootObj := TJSONObject.Create;
  try
    LRootObj.AddPair('model', GetActiveModel);
    LRootObj.AddPair('max_tokens', TJSONNumber.Create(4096));
    
    LMessagesArr := TJSONArray.Create;
    LRootObj.AddPair('messages', LMessagesArr);
    
    LSystemPrompt := '';

    { Add History }
    for LMsg in AHistory do
    begin
      if LMsg.Role = mrSystem then
      begin
        LSystemPrompt := LSystemPrompt + LMsg.Content + sLineBreak;
        Continue;
      end;

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

    { Add System instruction if present }
    if not LSystemPrompt.IsEmpty then
    begin
      LRootObj.AddPair('system', LSystemPrompt.Trim);
    end;
    
    Result := LRootObj.ToJSON;
  finally
    LRootObj.Free;
  end;
end;

function TRadIAClaudeProvider.ParseResponseBody(const AResponseJson: string): string;
var
  LJsonObj: TJSONObject;
  LContentArr: TJSONArray;
  LContentObj: TJSONObject;
begin
  Result := '';
  LJsonObj := TJSONObject.ParseJSONValue(AResponseJson) as TJSONObject;
  if Assigned(LJsonObj) then
  begin
    try
      LContentArr := LJsonObj.GetValue('content') as TJSONArray;
      if Assigned(LContentArr) and (LContentArr.Count > 0) then
      begin
        LContentObj := LContentArr.Items[0] as TJSONObject;
        if Assigned(LContentObj) and (LContentObj.GetValue('text') <> nil) then
        begin
          Result := LContentObj.GetValue('text').Value;
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

procedure TRadIAClaudeProvider.SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
  const ACallback: TCompletionCallback);
var
  LUrl, LApiKey, LRequestBody: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', 'API Key is missing for Anthropic Claude. Please check settings.', False);
    Exit;
  end;

  LUrl := 'https://api.anthropic.com/v1/messages';
  
  SetLength(LHeaders, 2);
  LHeaders[0] := TNetHeader.Create('x-api-key', LApiKey);
  LHeaders[1] := TNetHeader.Create('anthropic-version', '2023-06-01');

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

end.
