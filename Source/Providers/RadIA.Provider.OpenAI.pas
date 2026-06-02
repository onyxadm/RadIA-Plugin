unit RadIA.Provider.OpenAI;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Provider.Base;

type
  TRadIAOpenAIProvider = class(TRadIAProviderBase)
  private
    function BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>): string;
    function ParseResponseBody(const AResponseJson: string): string;
  public
    constructor Create(const AConfig: IAIConfig); override;
    
    { IIAProvider implementation }
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback) override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading;

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
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', 'API Key is missing for OpenAI. Please check settings.');
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
      ACallback('', 'Error building request JSON: ' + E.Message);
      Exit;
    end;
  end;

  TTask.Run(
    procedure
    var
      LResponseText: string;
    begin
      try
        LResponseText := DoPostRequest(LUrl, LHeaders, LRequestBody);
        LResponseText := ParseResponseBody(LResponseText);
        
        TThread.Queue(nil,
          procedure
          begin
            ACallback(LResponseText, '');
          end);
      except
        on E: Exception do
        begin
          TThread.Queue(nil,
            procedure
            begin
              ACallback('', E.Message);
            end);
        end;
      end;
    end);
end;

end.
