unit RadIA.Provider.Gemini;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAGeminiProvider = class(TRadIAProviderBase)
  private
    function BuildRequestBody(const APrompt: string; const AHistory: TArray<IRadIAChatMessage>;
      const ATemperature: Double; const AMaxTokens: Integer): string;
    function ParseResponseBody(const AResponseJson: string; out AUsage: TTokenUsage): string;
  public
    constructor Create(const AConfig: IRadIAConfig); override;

    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IRadIAChatMessage>;
      const ACallback: TCompletionCallback; const ATemperature: Double; const AMaxTokens: Integer); override;
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IRadIAChatMessage>;
      const ACallback: TStreamChunkCallback; const ATemperature: Double; const AMaxTokens: Integer); override;
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
    procedure ProcessStreamBuffer(var ABuffer: string; const ACallback: TStreamChunkCallback);
  end;

implementation

uses
  System.JSON, System.Threading, System.Generics.Collections, System.Net.URLClient, System.NetEncoding,
  System.SyncObjs, System.Math, RadIA.Core.Logger, RadIA.Core.ProviderRegistry;

{ TRadIAGeminiProvider }

constructor TRadIAGeminiProvider.Create(const AConfig: IRadIAConfig);
begin
  inherited Create(AConfig);
  FProviderId := 'Gemini';
end;

function TRadIAGeminiProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_GEMINI_15_FLASH, MODEL_GEMINI_15_PRO);
end;

function TRadIAGeminiProvider.GetName: string;
begin
  Result := 'Google Gemini';
end;

function TRadIAGeminiProvider.BuildRequestBody(const APrompt: string; const AHistory: TArray<IRadIAChatMessage>;
  const ATemperature: Double; const AMaxTokens: Integer): string;
var
  LRootObj: TJSONObject;
  LContentsArr: TJSONArray;
  LContentObj: TJSONObject;
  LPartsArr: TJSONArray;
  LPartObj: TJSONObject;
  LMsg: IRadIAChatMessage;
  LRoleStr: string;
  LSystemPrompt: string;
  LSystemObj: TJSONObject;
  LSystemPartsArr: TJSONArray;
  LSystemPartObj: TJSONObject;
  LGenConfigObj: TJSONObject;
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

    { Add Generation Config }
    LGenConfigObj := TJSONObject.Create;
    if ATemperature >= 0.0 then
      LGenConfigObj.AddPair('temperature', TJSONNumber.Create(ATemperature));
    if AMaxTokens > 0 then
      LGenConfigObj.AddPair('maxOutputTokens', TJSONNumber.Create(AMaxTokens));

    if LGenConfigObj.Count > 0 then
      LRootObj.AddPair('generationConfig', LGenConfigObj)
    else
      LGenConfigObj.Free;

    Result := LRootObj.ToJSON;
  finally
    LRootObj.Free;
  end;
end;

function TRadIAGeminiProvider.ParseResponseBody(const AResponseJson: string; out AUsage: TTokenUsage): string;
var
  LJsonObj: TJSONObject;
  LCandidates: TJSONArray;
  LCandidate: TJSONObject;
  LContent: TJSONObject;
  LParts: TJSONArray;
  LPart: TJSONObject;
  LUsageNode: TJSONObject;
begin
  Result := '';
  AUsage := TTokenUsage.Empty;

  LJsonObj := TJSONObject.ParseJSONValue(AResponseJson) as TJSONObject;
  if not Assigned(LJsonObj) then
    Exit;

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
          if Assigned(LPart) then
            Result := LPart.GetValue<string>('text', '');
        end;
      end;
    end;

    if Result.IsEmpty and Assigned(LJsonObj.GetValue('error')) then
      raise Exception.Create(LJsonObj.GetValue('error').ToString);

    LUsageNode := LJsonObj.GetValue('usageMetadata') as TJSONObject;
    if Assigned(LUsageNode) then
    begin
      AUsage.PromptTokens     := LUsageNode.GetValue<Integer>('promptTokenCount', 0);
      AUsage.CompletionTokens := LUsageNode.GetValue<Integer>('candidatesTokenCount', 0);
      AUsage.TotalTokens      := LUsageNode.GetValue<Integer>('totalTokenCount', 0);
    end;
  finally
    LJsonObj.Free;
  end;
end;

procedure TRadIAGeminiProvider.SendPromptAsync(const APrompt: string; const AHistory: TArray<IRadIAChatMessage>;
  const ACallback: TCompletionCallback; const ATemperature: Double; const AMaxTokens: Integer);
var
  LUrl, LApiKey, LModel, LRequestBody: string;
begin
  LApiKey := GetApiKey;
  LModel := GetActiveModel;

  if LApiKey.IsEmpty then
  begin
    ACallback('', 'API Key is missing for Google Gemini. Please check settings.', False, TTokenUsage.Empty);
    Exit;
  end;

  LUrl := Format('https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s',
    [LModel, TNetEncoding.URL.Encode(LApiKey)]);

  try
    LRequestBody := BuildRequestBody(APrompt, AHistory, ATemperature, AMaxTokens);
  except
    on E: Exception do
    begin
      ACallback('', 'Error building request JSON: ' + E.Message, False, TTokenUsage.Empty);
      Exit;
    end;
  end;

  ExecuteRequestAsync(LUrl, nil, LRequestBody,
    function(const AResponseJson: string; out AUsage: TTokenUsage): string
    begin
      Result := ParseResponseBody(AResponseJson, AUsage);
    end, ACallback);
end;

procedure TRadIAGeminiProvider.FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>);
var
  LApiKey: string;
  LUrl: string;
  LTaskProc: TProc;
  LProviderRef: IRadIAProvider;
begin
  LProviderRef := Self;
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    if not GIsShuttingDown then
    begin
      TThread.Queue(nil,
        procedure
        begin
          ACallback(GetAvailableModels, 'API Key is missing for Google Gemini. Using fallback models.');
        end);
    end;
    Exit;
  end;

  LUrl := Format('https://generativelanguage.googleapis.com/v1beta/models?key=%s', [TNetEncoding.URL.Encode(LApiKey)]);

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
                 LErrorMsg: string;
               begin
                 try
                   System.Math.SetExceptionMask(System.Math.exAllArithmeticExceptions);
                   LProviderRef.GetProviderId;
                   LModelsList := TList<string>.Create;
                   try
                     try
                       LResponseText := DoGetRequest(LUrl, nil, 5000); // Timeout rápido de 5 segundos para busca de modelos
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
                                 begin
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
                                     if LName.StartsWith('models/') then
                                       LName := LName.Substring(7);
                                     LModelsList.Add(LName);
                                   end;
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

                       if not GIsShuttingDown then
                       begin
                         TThread.Queue(nil,
                           TThreadProcedure(
                             procedure
                             begin
                               ACallback(LModelsArray, '');
                             end
                           )
                         );
                       end;
                     except
                       on E: Exception do
                       begin
                         LErrorMsg := E.ClassName + ': ' + E.Message;
                         LModelsArray := GetAvailableModels;
                         if not GIsShuttingDown then
                         begin
                           TThread.Queue(nil,
                             TThreadProcedure(
                               procedure
                               begin
                                 ACallback(LModelsArray, LErrorMsg);
                               end
                             )
                           );
                         end;
                       end;
                     end;
                   finally
                     LModelsList.Free;
                   end;
                 finally
                   TInterlocked.Decrement(GActiveThreadCount);
                 end;
               end;

  TInterlocked.Increment(GActiveThreadCount);
  TTask.Run(LTaskProc);
end;

procedure TRadIAGeminiProvider.ProcessStreamBuffer(var ABuffer: string; const ACallback: TStreamChunkCallback);
// Parses the Gemini streaming response format: a JSON array of objects.
// Logs every step for diagnostics. Remove TLogger calls after issue is resolved.
var
  LOpenBrackets: Integer;
  I: Integer;
  LInString: Boolean;
  LCandidateStr: string;
  LJson: TJSONObject;
  LCandidates: TJSONArray;
  LCandidate: TJSONObject;
  LContent: TJSONObject;
  LParts: TJSONArray;
  LPart: TJSONObject;
  LText: string;
  LPtr: PChar;
  LLen: Integer;
  LObjectCount: Integer;
begin
  LObjectCount := 0;
  TLogger.Log(Format('PSB: Entry BufferLen=%d First30=|%s|', [ABuffer.Length, ABuffer.Substring(0, Min(30, ABuffer.Length))]), 'Provider');

  while True do
  begin
    ABuffer := ABuffer.TrimLeft(['[', ',', #13, #10, ' ', ']']);
    if ABuffer.IsEmpty or not ABuffer.StartsWith('{') then
    begin
      TLogger.Log(Format('PSB: Break. Empty=%s StartBrace=%s Objs=%d ResidualLen=%d', [
        BoolToStr(ABuffer.IsEmpty, True), BoolToStr(ABuffer.StartsWith('{'), True),
        LObjectCount, ABuffer.Length]), 'Provider');
      Break;
    end;

    LOpenBrackets := 0;
    LInString := False;
    LLen := ABuffer.Length;
    LPtr := PChar(ABuffer);
    I := 0;

    while I < LLen do
    begin
      if LInString then
      begin
        if LPtr[I] = '\' then
          Inc(I)
        else if LPtr[I] = '"' then
          LInString := False;
      end
      else
      begin
        case LPtr[I] of
          '"': LInString := True;
          '{': Inc(LOpenBrackets);
          '}':
          begin
            Dec(LOpenBrackets);
            if LOpenBrackets = 0 then
            begin
              LCandidateStr := ABuffer.Substring(0, I + 1);
              ABuffer := ABuffer.Substring(I + 1);
              Inc(LObjectCount);

              TLogger.Log(Format('PSB: Obj#%d Found ObjLen=%d', [LObjectCount, LCandidateStr.Length]), 'Provider');

              try
                LJson := TJSONObject.ParseJSONValue(LCandidateStr) as TJSONObject;
                if Assigned(LJson) then
                begin
                  try
                    if Assigned(LJson.GetValue('error')) then
                    begin
                      LText := '';
                      if LJson.GetValue('error') is TJSONObject then
                        LText := TJSONObject(LJson.GetValue('error')).GetValue<string>('message', '');
                      if LText.IsEmpty then
                        LText := LJson.GetValue('error').ToString;
                      TLogger.Log('PSB: API error=' + LText, 'Provider');
                      ACallback('', True, LText);
                      Exit;
                    end;

                    LText := '';
                    LCandidates := LJson.GetValue('candidates') as TJSONArray;
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
                          if Assigned(LPart) then
                            LText := LPart.GetValue<string>('text', '');
                        end;
                      end;
                    end;

                    TLogger.Log(Format('PSB: Obj#%d TextLen=%d', [LObjectCount, LText.Length]), 'Provider');
                    if not LText.IsEmpty then
                      ACallback(LText, False, '');
                  finally
                    LJson.Free;
                  end;
                end
                else
                  TLogger.Log(Format('PSB: Obj#%d ParseJSONValue=nil', [LObjectCount]), 'Provider');
              except
                on E: Exception do
                  TLogger.Log(Format('PSB: Obj#%d Exception=%s', [LObjectCount, E.Message]), 'Provider');
              end;
              Break;
            end;
          end;
        end;
      end;
      Inc(I);
    end;

    if I >= LLen then
    begin
      TLogger.Log(Format('PSB: Incomplete obj, waiting. BufferLen=%d', [ABuffer.Length]), 'Provider');
      Break;
    end;
  end;
  TLogger.Log(Format('PSB: Exit Objs=%d ResidualLen=%d', [LObjectCount, ABuffer.Length]), 'Provider');
end;

procedure TRadIAGeminiProvider.SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IRadIAChatMessage>;
  const ACallback: TStreamChunkCallback; const ATemperature: Double; const AMaxTokens: Integer);
var
  LUrl, LApiKey, LModel, LRequestBody: string;
begin
  LApiKey := GetApiKey;
  LModel := GetActiveModel;

  if LApiKey.IsEmpty then
  begin
    ACallback('', True, 'API Key is missing for Google Gemini. Please check settings.');
    Exit;
  end;

  LUrl := Format('https://generativelanguage.googleapis.com/v1beta/models/%s:streamGenerateContent?key=%s',
    [LModel, TNetEncoding.URL.Encode(LApiKey)]);

  try
    LRequestBody := BuildRequestBody(APrompt, AHistory, ATemperature, AMaxTokens);
  except
    on E: Exception do
    begin
      ACallback('', True, 'Error building request JSON: ' + E.Message);
      Exit;
    end;
  end;

  ExecuteRequestStreamAsync(LUrl, nil, LRequestBody,
    function(const ABuffer: string): string
    var
      LTemp: string;
    begin
      LTemp := ABuffer;
      ProcessStreamBuffer(LTemp, ACallback);
      Result := LTemp;
    end, ACallback);
end;

initialization
  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create(
      'Gemini',
      'Google Gemini',
      'https://generativelanguage.googleapis.com',
      True, // HasApiKey
      False, // HasCustomUrl
      [MODEL_GEMINI_15_FLASH, MODEL_GEMINI_15_PRO],
      function(const ACfg: IRadIAConfig): IRadIAProvider
      begin
        Result := TRadIAGeminiProvider.Create(ACfg);
      end
    )
  );

end.
