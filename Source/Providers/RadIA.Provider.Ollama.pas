unit RadIA.Provider.Ollama;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAOllamaProvider = class(TRadIAProviderBase)
  private
    function BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const AStream: Boolean; const ATemperature: Double; const AMaxTokens: Integer): string;
    function ParseResponseBody(const AResponseJson: string; out AUsage: TTokenUsage): string;
  public
    constructor Create(const AConfig: IAIConfig); override;
    
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback; const ATemperature: Double; const AMaxTokens: Integer); override;
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TStreamChunkCallback; const ATemperature: Double; const AMaxTokens: Integer); override;
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
    procedure ProcessStreamBuffer(var ABuffer: string; const ACallback: TStreamChunkCallback);
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

function TRadIAOllamaProvider.BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>;
  const AStream: Boolean; const ATemperature: Double; const AMaxTokens: Integer): string;
var
  LRootObj: TJSONObject;
  LMessagesArr: TJSONArray;
  LMsgObj: TJSONObject;
  LMsg: IChatMessage;
  LOptionsObj: TJSONObject;
begin
  LRootObj := TJSONObject.Create;
  try
    LRootObj.AddPair('model', GetActiveModel);
    LRootObj.AddPair('stream', TJSONBool.Create(AStream));

    LOptionsObj := TJSONObject.Create;
    if ATemperature >= 0.0 then
      LOptionsObj.AddPair('temperature', TJSONNumber.Create(ATemperature));
    if AMaxTokens > 0 then
      LOptionsObj.AddPair('num_predict', TJSONNumber.Create(AMaxTokens));

    if LOptionsObj.Count > 0 then
      LRootObj.AddPair('options', LOptionsObj)
    else
      LOptionsObj.Free;
    
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
        Result := LMsgObj.GetValue<string>('content', '');
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
  const ACallback: TCompletionCallback; const ATemperature: Double; const AMaxTokens: Integer);
var
  LUrl, LRequestBody: string;
  LTaskProc: TProc;
begin
  LUrl := FConfig.OllamaBaseUrl + '/api/chat';

  try
    LRequestBody := BuildRequestBody(APrompt, AHistory, False, ATemperature, AMaxTokens);
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
               begin
                 try
                   LResponseText := DoPostRequest(LUrl, nil, LRequestBody);
                   LResponseText := ParseResponseBody(LResponseText, LUsage);
                   
                   TThread.Queue(nil,
                     procedure
                     begin
                       ACallback(LResponseText, '', False, LUsage);
                     end);
                 except
                   on E: Exception do
                   begin
                     TThread.Queue(nil,
                       procedure
                       begin
                         ACallback('', E.Message, False, TTokenUsage.Empty);
                       end);
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
                 LName: string;
                 LModelsList: TList<string>;
                 LModelsArray: TArray<string>;
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
                               LName := LModelObj.GetValue<string>('name', '');
                               if not LName.IsEmpty then
                                 LModelsList.Add(LName);
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

procedure TRadIAOllamaProvider.ProcessStreamBuffer(var ABuffer: string; const ACallback: TStreamChunkCallback);
var
  LLine: string;
  LJson: TJSONObject;
  LMsgObj: TJSONObject;
  LContent: string;
  LDone: Boolean;
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
    if LLine.IsEmpty then
      Continue;

    try
      LJson := TJSONObject.ParseJSONValue(LLine) as TJSONObject;
      if Assigned(LJson) then
      begin
        try
          LContent := '';
          LMsgObj := LJson.GetValue('message') as TJSONObject;
          if Assigned(LMsgObj) then
          begin
            LContent := LMsgObj.GetValue<string>('content', '');
          end;

          LDone := LJson.GetValue<Boolean>('done', False);

          if not LContent.IsEmpty then
          begin
            ACallback(LContent, False, '');
          end;

          if LDone then
          begin
            ACallback('', True, '');
            
            ABuffer := ABuffer.Substring(LLastProcessedPos);
            Exit;
          end;
        finally
          LJson.Free;
        end;
      end;
    except
      { Ignore parse errors }
    end;
  end;

  if LLastProcessedPos > 0 then
  begin
    ABuffer := ABuffer.Substring(LLastProcessedPos);
  end;
end;

procedure TRadIAOllamaProvider.SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
  const ACallback: TStreamChunkCallback; const ATemperature: Double; const AMaxTokens: Integer);
var
  LUrl, LRequestBody: string;
  LTaskProc: TProc;
begin
  LUrl := FConfig.OllamaBaseUrl + '/api/chat';

  try
    LRequestBody := BuildRequestBody(APrompt, AHistory, True, ATemperature, AMaxTokens);
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
    begin
      LBufferText := '';
      try
        DoPostRequestStream(LUrl, nil, LRequestBody,
          procedure(ABytes: TBytes)
          begin
            LBufferText := LBufferText + TEncoding.UTF8.GetString(ABytes);
            ProcessStreamBuffer(LBufferText, ACallback);
          end);

        TThread.Queue(nil,
          procedure
          begin
            ACallback('', True, '');
          end);
      except
        on E: Exception do
        begin
          TThread.Queue(nil,
            procedure
            begin
              ACallback('', True, E.Message);
            end);
        end;
      end;
    end;

  TTask.Run(LTaskProc);
end;

end.
