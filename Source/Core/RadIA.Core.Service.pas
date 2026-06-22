unit RadIA.Core.Service;

interface

uses  RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Cache;

type
  { Orchestrator service to manage active provider instantiation }
  TRadIAService = class(TInterfacedObject, IRadIAService)
  private
    FConfig: IRadIAConfig;
    FCacheManager: TRadIACacheManager;
    FActiveProvider: IRadIAProvider;

    function BuildEffectiveHistory(const ASystemPrompt: string;
      const ATrimmedHistory: TArray<IRadIAChatMessage>): TArray<IRadIAChatMessage>;
    function SerializeHistoryToJson(const AHistory: TArray<IRadIAChatMessage>): string;
    function ComputePromptHash(const APrompt: string;
      const ATrimmedHistory: TArray<IRadIAChatMessage>; const ASystemPrompt: string): string;
    function IsLocalQuotaLimitReached: Boolean;
  public
    constructor Create(const AConfig: IRadIAConfig);
    destructor Destroy; override;

    function GetEffectiveSystemPrompt: string;

    procedure ResolveParameters(const AProviderName: string; const AProfile: TAIRequestProfile;
      out ATemperature: Double; out AMaxTokens: Integer);

    function CreateActiveProvider: IRadIAProvider;
    function TrimHistory(const AHistory: TArray<IRadIAChatMessage>): TArray<IRadIAChatMessage>;
    procedure SendPrompt(const APrompt: string; const AHistory: TArray<IRadIAChatMessage>;
      const ACallback: TCompletionCallback; const AProfile: TAIRequestProfile = rpGeneralChat);
    procedure SendPromptStream(const APrompt: string; const AHistory: TArray<IRadIAChatMessage>;
      const ACallback: TStreamChunkCallback; const AProfile: TAIRequestProfile = rpGeneralChat);
    procedure CancelCurrentRequest;
    procedure ClearCache;
  end;

implementation

uses  System.JSON, System.Threading, System.Math, RadIA.Core.Container, RadIA.Core.ProjectContext,
  RadIA.Core.ProviderRegistry, RadIA.Core.Logger, System.SyncObjs, System.SysUtils,
      System.Classes, RadIA.Core.TokenUsage,
      RadIA.Core.ChatMessage;

procedure LogService(const AMsg: string);
begin
  TLogger.Log(AMsg, 'Service');
end;


{ TRadIAService }

constructor TRadIAService.Create(const AConfig: IRadIAConfig);
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

function TRadIAService.TrimHistory(const AHistory: TArray<IRadIAChatMessage>): TArray<IRadIAChatMessage>;
var
  LMaxMessages: Integer;
  LMaxPairs: Integer;
  LStartIndex: Integer;
  LCount: Integer;
  LNonSystemHistory: TArray<IRadIAChatMessage>;
  LMsg: IRadIAChatMessage;
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

function TRadIAService.CreateActiveProvider: IRadIAProvider;
var
  LProviderName: string;
begin
  LProviderName := FConfig.GetActiveProvider;
  if FConfig.IsWebLoginProvider(LProviderName) then
    Result := TProviderRegistry.CreateProvider('WebViewBridge', FConfig)
  else
    Result := TProviderRegistry.CreateProvider(LProviderName, FConfig);
end;

function TRadIAService.GetEffectiveSystemPrompt: string;
var
  LSystemPrompt: string;
  LProjectFolder: string;
  LProjectContext: string;
  LDelphiVersionPrompt: string;
  LConcisePrompt: string;
  LAdapter: IRadIAIDEAdapter;
  LDelphiVersionName: string;
  LPreferredLanguage: string;
begin
  LSystemPrompt := FConfig.SystemPrompt;

  if FConfig.ConciseResponses then
  begin
    LConcisePrompt := 'Default response style: be concise. Prefer short bullet lists, avoid long explanations, ' +
                      'and include only the minimum context needed to act safely. Preserve code formatting exactly.';
    if LSystemPrompt.IsEmpty then
      LSystemPrompt := LConcisePrompt
    else
      LSystemPrompt := LSystemPrompt + sLineBreak + sLineBreak + LConcisePrompt;
  end;

  LDelphiVersionName := 'Delphi';
  LPreferredLanguage := '';
  LProjectFolder := '';

  if TRadIAContainer.TryResolve<IRadIAIDEAdapter>(LAdapter) then
  begin
    LDelphiVersionName := LAdapter.GetDelphiVersionName;
    LPreferredLanguage := LAdapter.GetPreferredLanguageInstruction;
    LProjectFolder := LAdapter.GetActiveProjectFolder;
  end;

  if FConfig.InjectDelphiVersion then
  begin
    LDelphiVersionPrompt := 'The user is writing code using Embarcadero ' + LDelphiVersionName + '. ' +
                            'Make sure any code, syntax, keywords, and RTL components you generate are ' +
                                'fully compatible and compile ' +
                            'in this version. Avoid newer language features that are not supported in ' +
                                '' + LDelphiVersionName + '. ';
    if not LPreferredLanguage.IsEmpty then
      LDelphiVersionPrompt := LDelphiVersionPrompt + LPreferredLanguage;

    if LSystemPrompt.IsEmpty then
      LSystemPrompt := LDelphiVersionPrompt
    else
      LSystemPrompt := LSystemPrompt + sLineBreak + sLineBreak + LDelphiVersionPrompt;
  end;

  if not LProjectFolder.IsEmpty then
  begin
    if TProjectContextLoader.LoadContext(LProjectFolder, LProjectContext) and not LProjectContext.IsEmpty then
    begin
      LSystemPrompt := LProjectContext + sLineBreak + sLineBreak + LSystemPrompt;
    end;
  end;
  Result := LSystemPrompt;
end;

function TRadIAService.BuildEffectiveHistory(const ASystemPrompt: string;
  const ATrimmedHistory: TArray<IRadIAChatMessage>): TArray<IRadIAChatMessage>;
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

function TRadIAService.SerializeHistoryToJson(const AHistory: TArray<IRadIAChatMessage>): string;
var
  LHistoryJson: TJSONArray;
  LMsg: IRadIAChatMessage;
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
  const ATrimmedHistory: TArray<IRadIAChatMessage>; const ASystemPrompt: string): string;
var
  LProviderName: string;
  LModelName: string;
  LHistoryStr: string;
begin
  LProviderName := FConfig.GetActiveProvider;
  LModelName    := FConfig.GetActiveModel(LProviderName);
  LHistoryStr   := SerializeHistoryToJson(ATrimmedHistory);
  Result := TRadIACacheManager.GenerateHash(LProviderName, LModelName, ASystemPrompt, APrompt, LHistoryStr);
end;

function TRadIAService.IsLocalQuotaLimitReached: Boolean;
var
  LActiveProvider: string;
begin
  LActiveProvider := FConfig.GetActiveProvider;

  Result := FConfig.QuotaEnabled and
    (not FConfig.IsWebLoginProvider(LActiveProvider)) and
    (FConfig.QuotaUsed >= FConfig.QuotaLimit);
end;

procedure TRadIAService.SendPrompt(const APrompt: string; const AHistory: TArray<IRadIAChatMessage>;
  const ACallback: TCompletionCallback; const AProfile: TAIRequestProfile);
begin
  if IsLocalQuotaLimitReached then
  begin
    ACallback('', 'Local monthly token quota exceeded.', False, TTokenUsage.Empty);
    Exit;
  end;

  TInterlocked.Increment(GActiveThreadCount);
  TTask.Run(
    procedure
    var
      LProvider: IRadIAProvider;
      LHash: string;
      LCachedResponse: string;
      LSystemPrompt: string;
      LHistory: TArray<IRadIAChatMessage>;
      LTrimmedHistory: TArray<IRadIAChatMessage>;
      LTemperature: Double;
      LMaxTokens: Integer;
    begin
      try
        System.Math.SetExceptionMask(System.Math.exAllArithmeticExceptions);
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
            TThread.Queue(nil,
              procedure
              begin
                ACallback(LCachedResponse, '', True, TTokenUsage.Empty);
              end);
            Exit;
          end;

          { Build effective history with system instructions }
          LHistory := BuildEffectiveHistory(LSystemPrompt, LTrimmedHistory);

          { Resolve parameters based on config and profile }
          ResolveParameters(LProvider.GetProviderId, AProfile, LTemperature, LMaxTokens);

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
              TThread.Queue(nil,
                procedure
                begin
                  ACallback(AResponse, AError, False, AUsage);
                end);
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
            var LErrMsg := 'Failed to initialize AI Provider: ' + E.Message;
            TThread.Queue(nil,
              procedure
              begin
                ACallback('', LErrMsg, False, TTokenUsage.Empty);
              end);
          end;
        end;
      finally
        TInterlocked.Decrement(GActiveThreadCount);
      end;
    end);
end;

procedure TRadIAService.SendPromptStream(const APrompt: string; const AHistory: TArray<IRadIAChatMessage>;
  const ACallback: TStreamChunkCallback; const AProfile: TAIRequestProfile);
begin
  if IsLocalQuotaLimitReached then
  begin
    ACallback('', True, 'Local monthly token quota exceeded.');
    Exit;
  end;

  TInterlocked.Increment(GActiveThreadCount);
  TTask.Run(
    procedure
    var
      LProvider: IRadIAProvider;
      LSystemPrompt: string;
      LHistory: TArray<IRadIAChatMessage>;
      LTrimmedHistory: TArray<IRadIAChatMessage>;
      LHash: string;
      LCachedResponse: string;
      LAccumulator: string;
      LTemperature: Double;
      LMaxTokens: Integer;
    begin
      try
        System.Math.SetExceptionMask(System.Math.exAllArithmeticExceptions);
        try
          LProvider       := CreateActiveProvider;
          TMonitor.Enter(Self);
          try
            FActiveProvider := LProvider;
          finally
            TMonitor.Exit(Self);
          end;

          LogService('SendPromptStream: ActiveProvider=' + FConfig.GetActiveProvider +
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

            LogService('SendPromptStream: Cache hit for hash ' + LHash + '. Response ' +
                'length: ' + IntToStr(Length(LCachedResponse)));
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
          ResolveParameters(LProvider.GetProviderId, AProfile, LTemperature, LMaxTokens);
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
                  FCacheManager.Put(LHash, LAccumulator);
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

              TThread.Queue(nil,
                procedure
                begin
                  ACallback(AChunk, AIsDone, AError);
                end);
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
            var LErrMsg := 'Failed to initialize AI Provider: ' + E.Message;
            TThread.Queue(nil,
              procedure
              begin
                ACallback('', True, LErrMsg);
              end);
          end;
        end;
      finally
        TInterlocked.Decrement(GActiveThreadCount);
      end;
    end);
end;

procedure TRadIAService.CancelCurrentRequest;
var
  LProvider: IRadIAProvider;
begin
  TMonitor.Enter(Self);
  try
    LProvider := FActiveProvider;
  finally
    TMonitor.Exit(Self);
  end;

  if Assigned(LProvider) then
  begin
    LogService('CancelCurrentRequest: Cancelling active provider request.');
    LProvider.CancelCurrentRequest;
  end
  else
    LogService('CancelCurrentRequest: No active provider request to cancel.');
end;

procedure TRadIAService.ResolveParameters(const AProviderName: string; const AProfile: TAIRequestProfile;
  out ATemperature: Double; out AMaxTokens: Integer);
begin
  if FConfig.SmartConfigEnabled then
  begin
    case AProfile of
      rpRefactorCode:
      begin
        ATemperature := 0.1;
        AMaxTokens := 16384;
      end;
      rpFindBugs:
      begin
        ATemperature := 0.1;
        AMaxTokens := 8192;
      end;
      rpGenerateTests:
      begin
        ATemperature := 0.2;
        AMaxTokens := 16384;
      end;
      rpExplainCode:
      begin
        ATemperature := 0.3;
        AMaxTokens := 8192;
      end;
      rpOptimizeSQL:
      begin
        ATemperature := 0.1;
        AMaxTokens := 8192;
      end;
      rpScanWarnings:
      begin
        ATemperature := 0.2;
        AMaxTokens := 8192;
      end;
    else
      ATemperature := 0.7;
      AMaxTokens := 8192;
    end;
  end
  else
  begin
    ATemperature := FConfig.GetTemperature(AProviderName);
    AMaxTokens := FConfig.GetMaxTokens(AProviderName);
    if AMaxTokens <= 0 then
      AMaxTokens := 8192;
  end;
end;

procedure TRadIAService.ClearCache;
begin
  if Assigned(FCacheManager) then
    FCacheManager.Clear;
end;

end.
