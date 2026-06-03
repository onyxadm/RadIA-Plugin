unit RadIA.Provider.Gemini;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAGeminiProvider = class(TRadIAProviderBase)
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

{ TRadIAGeminiProvider }

constructor TRadIAGeminiProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderType := ptGemini;
end;

function TRadIAGeminiProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_GEMINI_15_FLASH, MODEL_GEMINI_15_PRO);
end;

function TRadIAGeminiProvider.GetName: string;
begin
  Result := 'Google Gemini';
end;

function TRadIAGeminiProvider.BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>): string;
var
  LRootObj: TJSONObject;
  LContentsArr: TJSONArray;
  LContentObj: TJSONObject;
  LPartsArr: TJSONArray;
  LPartObj: TJSONObject;
  LMsg: IChatMessage;
  LRoleStr: string;
  LSystemPrompt: string;
  LSystemObj: TJSONObject;
  LSystemPartsArr: TJSONArray;
  LSystemPartObj: TJSONObject;
begin
  LRootObj := TJSONObject.Create;
  try
    LContentsArr := TJSONArray.Create;
    LRootObj.AddPair('contents', LContentsArr);
    
    LSystemPrompt := '';

    { Add History }
    for LMsg in AHistory do
    begin
      if LMsg.Role = mrSystem then
      begin
        LSystemPrompt := LSystemPrompt + LMsg.Content + sLineBreak;
        Continue;
      end;

      LContentObj := TJSONObject.Create;
      LContentsArr.AddElement(LContentObj);
      
      { Gemini expects 'model' instead of 'assistant' }
      if LMsg.Role = mrAssistant then
        LRoleStr := 'model'
      else
        LRoleStr := 'user';
        
      LContentObj.AddPair('role', LRoleStr);
      
      LPartsArr := TJSONArray.Create;
      LContentObj.AddPair('parts', LPartsArr);
      
      LPartObj := TJSONObject.Create;
      LPartsArr.AddElement(LPartObj);
      LPartObj.AddPair('text', LMsg.Content);
    end;

    { Add Current Prompt }
    LContentObj := TJSONObject.Create;
    LContentsArr.AddElement(LContentObj);
    LContentObj.AddPair('role', 'user');
    
    LPartsArr := TJSONArray.Create;
    LContentObj.AddPair('parts', LPartsArr);
    
    LPartObj := TJSONObject.Create;
    LPartsArr.AddElement(LPartObj);
    LPartObj.AddPair('text', APrompt);

    { Add System Instruction if present }
    if not LSystemPrompt.IsEmpty then
    begin
      LSystemObj := TJSONObject.Create;
      LRootObj.AddPair('systemInstruction', LSystemObj);
      
      LSystemPartsArr := TJSONArray.Create;
      LSystemObj.AddPair('parts', LSystemPartsArr);
      
      LSystemPartObj := TJSONObject.Create;
      LSystemPartsArr.AddElement(LSystemPartObj);
      LSystemPartObj.AddPair('text', LSystemPrompt.Trim);
    end;

    Result := LRootObj.ToJSON;
  finally
    LRootObj.Free;
  end;
end;

function TRadIAGeminiProvider.ParseResponseBody(const AResponseJson: string): string;
var
  LJsonObj: TJSONObject;
  LCandidates: TJSONArray;
  LCandidate: TJSONObject;
  LContent: TJSONObject;
  LParts: TJSONArray;
  LPart: TJSONObject;
begin
  Result := '';
  LJsonObj := TJSONObject.ParseJSONValue(AResponseJson) as TJSONObject;
  if Assigned(LJsonObj) then
  begin
    try
      LCandidates := LJsonObj.GetValue('candidates') as TJSONArray;
      if Assigned(LCandidates) and (LCandidates.Count > 0) then
      begin
        LCandidate := LCandidates.Items[0] as TJSONObject;
        LContent := LCandidate.GetValue('content') as TJSONObject;
        if Assigned(LContent) then
        begin
          LParts := LContent.GetValue('parts') as TJSONArray;
          if Assigned(LParts) and (LParts.Count > 0) then
          begin
            LPart := LParts.Items[0] as TJSONObject;
            Result := LPart.GetValue('text').Value;
          end;
        end;
      end;
      
      if Result.IsEmpty then
      begin
        // Check if there was an API error in the response
        if LJsonObj.GetValue('error') <> nil then
          raise Exception.Create(LJsonObj.GetValue('error').ToString);
      end;
    finally
      LJsonObj.Free;
    end;
  end;
end;

procedure TRadIAGeminiProvider.SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
  const ACallback: TCompletionCallback);
var
  LUrl, LApiKey, LModel, LRequestBody: string;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  LModel := GetActiveModel;
  
  if LApiKey.IsEmpty then
  begin
    ACallback('', 'API Key is missing for Google Gemini. Please check settings.', False);
    Exit;
  end;

  LUrl := Format('https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s', 
    [LModel, LApiKey]);

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
                   LResponseText := DoPostRequest(LUrl, nil, LRequestBody);
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

procedure TRadIAGeminiProvider.FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>);
var
  LApiKey: string;
  LUrl: string;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    TThread.Queue(nil,
      procedure
      begin
        ACallback(GetAvailableModels, 'API Key is missing for Google Gemini. Using fallback models.');
      end);
    Exit;
  end;

  LUrl := Format('https://generativelanguage.googleapis.com/v1beta/models?key=%s', [LApiKey]);

  LTaskProc := procedure
               var
                 LResponseText: string;
                 LJson: TJSONObject;
                 LModelsArr: TJSONArray;
                 LVal: TJSONValue;
                 LModelObj: TJSONObject;
                 LName: string;
                 LMethodsArr: TJSONArray;
                 LMethodVal: TJSONValue;
                 LCanGenerate: Boolean;
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
                               LName := LModelObj.GetValue('name').Value;
                               
                               { Check if it supports generateContent }
                               LCanGenerate := False;
                               LMethodsArr := LModelObj.GetValue('supportedGenerationMethods') as TJSONArray;
                               if Assigned(LMethodsArr) then
                               begin
                                 for LMethodVal in LMethodsArr do
                                 begin
                                   if SameText(LMethodVal.Value, 'generateContent') then
                                   begin
                                     LCanGenerate := True;
                                     Break;
                                   end;
                                 end;
                               end;
                               
                               if LCanGenerate then
                               begin
                                 { Remove prefix 'models/' }
                                 if LName.StartsWith('models/') then
                                   LName := LName.Substring(7);
                                 LModelsList.Add(LName);
                               end;
                             end;
                           end;
                         end;
                       finally
                         LJson.Free;
                       end;
                     end;
                     
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
