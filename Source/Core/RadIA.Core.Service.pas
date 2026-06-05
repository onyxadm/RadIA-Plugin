unit RadIA.Core.Service;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Cache, RadIA.Core.TokenUsage;

type
  { Simple concrete class implementing IChatMessage }
  TRadIAChatMessage = class(TInterfacedObject, IChatMessage)
  private
    FRole: TAIMessageRole;
    FContent: string;
    FProvider: string;
    FModel: string;

    function GetRole: TAIMessageRole;
    function GetContent: string;
    procedure SetContent(const AValue: string);
    function GetProvider: string;
    procedure SetProvider(const AValue: string);
    function GetModel: string;
    procedure SetModel(const AValue: string);
  public
    constructor Create(const ARole: TAIMessageRole; const AContent: string;
      const AProvider: string = ''; const AModel: string = '');

    property Role: TAIMessageRole read GetRole;
    property Content: string read GetContent write SetContent;
    property Provider: string read GetProvider write SetProvider;
    property Model: string read GetModel write SetModel;
  end;

  { Orchestrator service to manage active provider instantiation }
  TRadIAService = class
  private
    FConfig: IAIConfig;
    FCacheManager: TRadIACacheManager;
    FActiveProvider: IIAProvider;

    function GetEffectiveSystemPrompt: string;
    function BuildEffectiveHistory(const ASystemPrompt: string;
      const ATrimmedHistory: TArray<IChatMessage>): TArray<IChatMessage>;
    function SerializeHistoryToJson(const AHistory: TArray<IChatMessage>): string;
    function ComputePromptHash(const APrompt: string;
      const ATrimmedHistory: TArray<IChatMessage>; const ASystemPrompt: string): string;
  public
    constructor Create(const AConfig: IAIConfig);
    destructor Destroy; override;

    procedure ResolveParameters(const AProvider: TAIProviderType; const AProfile: TAIRequestProfile;
      out ATemperature: Double; out AMaxTokens: Integer);

    function CreateActiveProvider: IIAProvider;
    function TrimHistory(const AHistory: TArray<IChatMessage>): TArray<IChatMessage>;
    procedure SendPrompt(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TCompletionCallback; const AProfile: TAIRequestProfile = rpGeneralChat);
    procedure SendPromptStream(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TStreamChunkCallback; const AProfile: TAIRequestProfile = rpGeneralChat);
    procedure CancelCurrentRequest;
    procedure ClearCache;

    class function CreateMessage(const ARole: TAIMessageRole; const AContent: string;
      const AProvider: string = ''; const AModel: string = ''): IChatMessage;
  end;

implementation

uses
  System.IOUtils, System.JSON, RadIA.OTA.Helper, RadIA.Core.ProjectContext,
  RadIA.Provider.Gemini, RadIA.Provider.OpenAI, RadIA.Provider.Claude, RadIA.Provider.Ollama,
  RadIA.Provider.DeepSeek, RadIA.Provider.Groq, RadIA.Core.Logger;

procedure LogService(const AMsg: string);
begin
  TLogger.Log(AMsg, 'Service');
end;


{ TRadIAChatMessage }

constructor TRadIAChatMessage.Create(const ARole: TAIMessageRole; const AContent: string;
  const AProvider: string; const AModel: string);
begin
  inherited Create;
  FRole := ARole;
  FContent := AContent;
  FProvider := AProvider;
  FModel := AModel;
end;

function TRadIAChatMessage.GetContent: string;
begin
  Result := FContent;
end;

function TRadIAChatMessage.GetRole: TAIMessageRole;
begin
  Result := FRole;
end;

procedure TRadIAChatMessage.SetContent(const AValue: string);
begin
  FContent := AValue;
end;

function TRadIAChatMessage.GetProvider: string;
begin
  Result := FProvider;
end;

procedure TRadIAChatMessage.SetProvider(const AValue: string);
begin
  FProvider := AValue;
end;

function TRadIAChatMessage.GetModel: string;
begin
  Result := FModel;
end;

procedure TRadIAChatMessage.SetModel(const AValue: string);
begin
  FModel := AValue;
end;

{ TRadIAService }

constructor TRadIAService.Create(const AConfig: IAIConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FCacheManager := TRadIACacheManager.Create;
end;

destructor TRadIAService.Destroy;
begin
  FCacheManager.Free;
  inherited Destroy;
end;

function TRadIAService.TrimHistory(const AHistory: TArray<IChatMessage>): TArray<IChatMessage>;
var
  LMaxMessages: Integer;
  LMaxPairs: Integer;
  LStartIndex: Integer;
  LCount: Integer;
  LNonSystemHistory: TArray<IChatMessage>;
  LMsg: IChatMessage;
  I: Integer;
begin
  LMaxMessages := FConfig.GetMaxHistoryMessages;

  { Separate system messages (handled externally) from user/assistant pairs }
  SetLength(LNonSystemHistory, 0);
  for LMsg in AHistory do
  begin
    if LMsg.Role <> mrSystem then
    begin
      SetLength(LNonSystemHistory, Length(LNonSystemHistory) + 1);
      LNonSystemHistory[High(LNonSystemHistory)] := LMsg;
    end;
  end;

  { LMaxMessages pairs = LMaxMessages * 2 messages (user + assistant) }
  LMaxPairs := LMaxMessages * 2;
  LCount := Length(LNonSystemHistory);

  if LCount <= LMaxPairs then
  begin
    Result := LNonSystemHistory;
    Exit;
  end;

  { Keep only the most recent LMaxPairs messages }
  LStartIndex := LCount - LMaxPairs;
  SetLength(Result, LMaxPairs);
  for I := 0 to LMaxPairs - 1 do
    Result[I] := LNonSystemHistory[LStartIndex + I];
end;

function TRadIAService.CreateActiveProvider: IIAProvider;
var
  LProviderType: TAIProviderType;
begin
  LProviderType := FConfig.GetActiveProvider;
  case LProviderType of
    ptGemini:   Result := TRadIAGeminiProvider.Create(FConfig);
    ptOpenAI:   Result := TRadIAOpenAIProvider.Create(FConfig);
    ptClaude:   Result := TRadIAClaudeProvider.Create(FConfig);
    ptOllama:   Result := TRadIAOllamaProvider.Create(FConfig);
    ptDeepSeek: Result := TRadIADeepSeekProvider.Create(FConfig);
    ptGroq:     Result := TRadIAGroqProvider.Create(FConfig);
  else
    raise Exception.Create('Invalid active provider type selected.');
  end;
end;

function TRadIAService.GetEffectiveSystemPrompt: string;
var
  LSystemPrompt: string;
  LProjectFolder: string;
  LProjectContext: string;
begin
  LSystemPrompt := FConfig.SystemPrompt;
  LProjectFolder := TRadIAOTAHelper.GetActiveProjectFolder;
  if not LProjectFolder.IsEmpty then
  begin
    if TProjectContextLoader.LoadContext(LProjectFolder, LProjectContext) and not LProjectContext.IsEmpty then
    begin
      if LSystemPrompt.IsEmpty then
        LSystemPrompt := LProjectContext
      else
        LSystemPrompt := LProjectContext + sLineBreak + sLineBreak + LSystemPrompt;
    end;
  end;
  Result := LSystemPrompt;
end;

function TRadIAService.BuildEffectiveHistory(const ASystemPrompt: string;
  const ATrimmedHistory: TArray<IChatMessage>): TArray<IChatMessage>;
var
  I: Integer;
begin
  if not ASystemPrompt.IsEmpty then
  begin
    SetLength(Result, Length(ATrimmedHistory) + 1);
    Result[0] := TRadIAChatMessage.Create(mrSystem, ASystemPrompt);
    for I := 0 to High(ATrimmedHistory) do
      Result[I + 1] := ATrimmedHistory[I];
  end
  else
    Result := ATrimmedHistory;
end;

function TRadIAService.SerializeHistoryToJson(const AHistory: TArray<IChatMessage>): string;
var
  LHistoryJson: TJSONArray;
  LMsg: IChatMessage;
  LMsgObj: TJSONObject;
begin
  LHistoryJson := TJSONArray.Create;
  try
    for LMsg in AHistory do
    begin
      LMsgObj := TJSONObject.Create;
      LMsgObj.AddPair('role', MessageRoleToString(LMsg.Role));
      LMsgObj.AddPair('content', LMsg.Content);
      LHistoryJson.AddElement(LMsgObj);
    end;
    Result := LHistoryJson.ToJSON;
  finally
    LHistoryJson.Free;
  end;
end;

function TRadIAService.ComputePromptHash(const APrompt: string;
  const ATrimmedHistory: TArray<IChatMessage>; const ASystemPrompt: string): string;
var
  LProviderName: string;
  LModelName: string;
  LHistoryStr: string;
begin
  LProviderName := ProviderTypeToString(FConfig.GetActiveProvider);
  LModelName    := FConfig.GetActiveModel(FConfig.GetActiveProvider);
  LHistoryStr   := SerializeHistoryToJson(ATrimmedHistory);
  Result := TRadIACacheManager.GenerateHash(LProviderName, LModelName, ASystemPrompt, APrompt, LHistoryStr);
end;

procedure TRadIAService.SendPrompt(const APrompt: string; const AHistory: TArray<IChatMessage>;
  const ACallback: TCompletionCallback; const AProfile: TAIRequestProfile);
var
  LProvider: IIAProvider;
  LHash: string;
  LCachedResponse: string;
  LSystemPrompt: string;
  LHistory: TArray<IChatMessage>;
  LTrimmedHistory: TArray<IChatMessage>;
  LTemperature: Double;
  LMaxTokens: Integer;
begin
  if FConfig.QuotaEnabled and (FConfig.QuotaUsed >= FConfig.QuotaLimit) then
  begin
    ACallback('', 'Cota mensal de tokens excedida (limite local atingido).', False, TTokenUsage.Empty);
    Exit;
  end;

  try
    LProvider := CreateActiveProvider;
    TMonitor.Enter(Self);
    try
      FActiveProvider := LProvider;
    finally
      TMonitor.Exit(Self);
    end;

    LSystemPrompt    := GetEffectiveSystemPrompt;
    LTrimmedHistory  := TrimHistory(AHistory);
    LHash            := ComputePromptHash(APrompt, LTrimmedHistory, LSystemPrompt);

    { Query Cache }
    if FCacheManager.Get(LHash, LCachedResponse) then
    begin
      TMonitor.Enter(Self);
      try
        if FActiveProvider = LProvider then
          FActiveProvider := nil;
      finally
        TMonitor.Exit(Self);
      end;
      ACallback(LCachedResponse, '', True, TTokenUsage.Empty);
      Exit;
    end;

    { Build effective history with system instructions }
    LHistory := BuildEffectiveHistory(LSystemPrompt, LTrimmedHistory);

    { Resolve parameters based on config and profile }
    ResolveParameters(LProvider.GetProviderType, AProfile, LTemperature, LMaxTokens);

    { Perform the actual async prompt request }
    LProvider.SendPromptAsync(APrompt, LHistory,
      procedure(const AResponse: string; const AError: string; AFromCache: Boolean; const AUsage: TTokenUsage)
      begin
        TMonitor.Enter(Self);
        try
          if FActiveProvider = LProvider then
            FActiveProvider := nil;
        finally
          TMonitor.Exit(Self);
        end;

        if AError.IsEmpty and not AResponse.IsEmpty then
          FCacheManager.Put(LHash, AResponse);
        ACallback(AResponse, AError, False, AUsage);
      end, LTemperature, LMaxTokens);
  except
    on E: Exception do
    begin
      TMonitor.Enter(Self);
      try
        FActiveProvider := nil;
      finally
        TMonitor.Exit(Self);
      end;
      ACallback('', 'Failed to initialize AI Provider: ' + E.Message, False, TTokenUsage.Empty);
    end;
  end;
end;

procedure TRadIAService.SendPromptStream(const APrompt: string; const AHistory: TArray<IChatMessage>;
  const ACallback: TStreamChunkCallback; const AProfile: TAIRequestProfile);
var
  LProvider: IIAProvider;
  LSystemPrompt: string;
  LHistory: TArray<IChatMessage>;
  LTrimmedHistory: TArray<IChatMessage>;
  LHash: string;
  LCachedResponse: string;
  LAccumulator: string;
  LTemperature: Double;
  LMaxTokens: Integer;
begin
  if FConfig.QuotaEnabled and (FConfig.QuotaUsed >= FConfig.QuotaLimit) then
  begin
    TThread.Queue(nil,
      procedure
      begin
        ACallback('', True, 'Cota mensal de tokens excedida (limite local atingido).');
      end);
    Exit;
  end;

  try
    LProvider       := CreateActiveProvider;
    TMonitor.Enter(Self);
    try
      FActiveProvider := LProvider;
    finally
      TMonitor.Exit(Self);
    end;

    LogService('SendPromptStream: ActiveProvider=' + ProviderTypeToString(FConfig.GetActiveProvider) +
      ' Model=' + FConfig.GetActiveModel(FConfig.GetActiveProvider) +
      ' SmartConfig=' + BoolToStr(FConfig.SmartConfigEnabled, True));
    LSystemPrompt   := GetEffectiveSystemPrompt;
    LTrimmedHistory := TrimHistory(AHistory);
    LHash           := ComputePromptHash(APrompt, LTrimmedHistory, LSystemPrompt);

    { R2 FIX: Check cache before streaming }
    if FCacheManager.Get(LHash, LCachedResponse) then
    begin
      TMonitor.Enter(Self);
      try
        if FActiveProvider = LProvider then
          FActiveProvider := nil;
      finally
        TMonitor.Exit(Self);
      end;

      LogService('SendPromptStream: Cache hit for hash ' + LHash + '. Response length: ' + IntToStr(Length(LCachedResponse)));
      TThread.Queue(nil,
        procedure
        begin
          ACallback(LCachedResponse, True, '');
        end);
      Exit;
    end;

    LogService('SendPromptStream: Cache miss for hash ' + LHash + '. Initiating request...');
    LHistory     := BuildEffectiveHistory(LSystemPrompt, LTrimmedHistory);
    LAccumulator := '';

    { Resolve parameters based on config and profile }
    ResolveParameters(LProvider.GetProviderType, AProfile, LTemperature, LMaxTokens);
    LogService(Format('SendPromptStream: Params resolved: Temp=%0.2f MaxTokens=%d', [LTemperature, LMaxTokens]));

    { R2 FIX: Wrap callback to accumulate chunks and persist to cache on completion }
    LProvider.SendPromptStreamAsync(APrompt, LHistory,
      procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
      begin
        LogService(Format('SendPromptStream Callback: ChunkLen=%d IsDone=%s Error="%s"', 
          [Length(AChunk), BoolToStr(AIsDone, True), AError]));
        if AError.IsEmpty then
        begin
          if not AChunk.IsEmpty then
            LAccumulator := LAccumulator + AChunk;
          if AIsDone and not LAccumulator.IsEmpty then
          begin
            LogService('SendPromptStream: Caching response of length ' + IntToStr(Length(LAccumulator)));
            FCacheManager.Put(LHash, LAccumulator);
          end;
        end;

        if AIsDone or (not AError.IsEmpty) then
        begin
          TMonitor.Enter(Self);
          try
            if FActiveProvider = LProvider then
              FActiveProvider := nil;
          finally
            TMonitor.Exit(Self);
          end;
        end;

        ACallback(AChunk, AIsDone, AError);
      end, LTemperature, LMaxTokens);
  except
    on E: Exception do
    begin
      TMonitor.Enter(Self);
      try
        FActiveProvider := nil;
      finally
        TMonitor.Exit(Self);
      end;
      LogService('SendPromptStream: Exception in initialization: ' + E.Message);
      ACallback('', True, 'Failed to initialize AI Provider: ' + E.Message);
    end;
  end;
end;

procedure TRadIAService.CancelCurrentRequest;
var
  LProvider: IIAProvider;
begin
  TMonitor.Enter(Self);
  try
    LProvider := FActiveProvider;
  finally
    TMonitor.Exit(Self);
  end;

  if LProvider <> nil then
  begin
    LogService('CancelCurrentRequest: Cancelling active provider request.');
    LProvider.CancelCurrentRequest;
  end
  else
    LogService('CancelCurrentRequest: No active provider request to cancel.');
end;

procedure TRadIAService.ResolveParameters(const AProvider: TAIProviderType; const AProfile: TAIRequestProfile;
  out ATemperature: Double; out AMaxTokens: Integer);
begin
  if FConfig.SmartConfigEnabled then
  begin
    case AProfile of
      rpRefactorCode:
      begin
        ATemperature := 0.1;
        AMaxTokens := 4096;
      end;
      rpFindBugs:
      begin
        ATemperature := 0.1;
        AMaxTokens := 2048;
      end;
      rpGenerateTests:
      begin
        ATemperature := 0.2;
        AMaxTokens := 4096;
      end;
      rpExplainCode:
      begin
        ATemperature := 0.3;
        AMaxTokens := 2048;
      end;
    else
      ATemperature := 0.7;
      AMaxTokens := 2048;
    end;
  end
  else
  begin
    ATemperature := FConfig.GetTemperature(AProvider);
    AMaxTokens := FConfig.GetMaxTokens(AProvider);
  end;
end;

procedure TRadIAService.ClearCache;
begin
  if Assigned(FCacheManager) then
    FCacheManager.Clear;
end;

class function TRadIAService.CreateMessage(const ARole: TAIMessageRole; const AContent: string;
  const AProvider: string; const AModel: string): IChatMessage;
begin
  Result := TRadIAChatMessage.Create(ARole, AContent, AProvider, AModel);
end;

end.
