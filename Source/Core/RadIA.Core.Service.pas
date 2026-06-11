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

    function BuildEffectiveHistory(const ASystemPrompt: string;
      const ATrimmedHistory: TArray<IChatMessage>): TArray<IChatMessage>;
    function SerializeHistoryToJson(const AHistory: TArray<IChatMessage>): string;
    function ComputePromptHash(const APrompt: string;
      const ATrimmedHistory: TArray<IChatMessage>; const ASystemPrompt: string): string;
    function IsWebLoginProvider(const AProviderName: string): Boolean;
    function ShouldUseWebLoginForRequest(const AProviderName: string): Boolean;
    function CreateRequestProvider: IIAProvider;
    function IsLocalQuotaLimitReached: Boolean;
  public
    constructor Create(const AConfig: IAIConfig);
    destructor Destroy; override;

    function GetEffectiveSystemPrompt: string;

    procedure ResolveParameters(const AProviderName: string; const AProfile: TAIRequestProfile;
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
  System.IOUtils, System.JSON, System.Threading, System.Math, RadIA.OTA.Helper, RadIA.Core.ProjectContext,
  RadIA.Provider.Gemini, RadIA.Provider.OpenAI, RadIA.Provider.Claude, RadIA.Provider.Ollama,
  RadIA.Provider.DeepSeek, RadIA.Provider.Groq, RadIA.Provider.OpenRouter, RadIA.Provider.LMStudio,
  RadIA.Provider.WebViewBridge, RadIA.Provider.AzureOpenAI, RadIA.Provider.Qwen, RadIA.Provider.Mistral,
  RadIA.Provider.Bedrock,
  RadIA.Core.ProviderRegistry, RadIA.Core.Logger, System.SyncObjs;

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
  LProviderName: string;
begin
  LProviderName := FConfig.GetActiveProvider;
  if IsWebLoginProvider(LProviderName) then
    Result := TProviderRegistry.CreateProvider('WebViewBridge', FConfig)
  else
    Result := TProviderRegistry.CreateProvider(LProviderName, FConfig);
end;

function TRadIAService.CreateRequestProvider: IIAProvider;
var
  LProviderName: string;
begin
  LProviderName := FConfig.GetActiveProvider;
  if ShouldUseWebLoginForRequest(LProviderName) then
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
begin
  LSystemPrompt := FConfig.SystemPrompt;
  
  if FConfig.InjectDelphiVersion then
  begin
    LDelphiVersionPrompt := 'The user is writing code using Embarcadero ' + TRadIAOTAHelper.GetDelphiVersionName + '. ' +
                            'Make sure any code, syntax, keywords, and RTL components you generate are fully compatible and compile ' +
                            'in this version. Avoid newer language features that are not supported in ' + TRadIAOTAHelper.GetDelphiVersionName + '. ' +
                            TRadIAOTAHelper.GetPreferredLanguageInstruction;
    
    if LSystemPrompt.IsEmpty then
      LSystemPrompt := LDelphiVersionPrompt
    else
      LSystemPrompt := LSystemPrompt + sLineBreak + sLineBreak + LDelphiVersionPrompt;
  end;

  LProjectFolder := TRadIAOTAHelper.GetActiveProjectFolder;
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
  LProviderName := FConfig.GetActiveProvider;
  LModelName    := FConfig.GetActiveModel(LProviderName);
  LHistoryStr   := SerializeHistoryToJson(ATrimmedHistory);
  Result := TRadIACacheManager.GenerateHash(LProviderName, LModelName, ASystemPrompt, APrompt, LHistoryStr);
end;

function TRadIAService.IsWebLoginProvider(const AProviderName: string): Boolean;
begin
  if SameText(AProviderName, 'WebViewBridge') then
    Exit(True);

  Result := SameText(FConfig.GetProviderAuthType(AProviderName), 'web_login');
end;

function TRadIAService.ShouldUseWebLoginForRequest(const AProviderName: string): Boolean;
begin
  Result := IsWebLoginProvider(AProviderName) or
    ((SameText(AProviderName, 'Gemini') or SameText(AProviderName, 'OpenAI')) and
     FConfig.GetApiKey(AProviderName).Trim.IsEmpty);
end;

function TRadIAService.IsLocalQuotaLimitReached: Boolean;
var
  LActiveProvider: string;
begin
  LActiveProvider := FConfig.GetActiveProvider;

  Result := FConfig.QuotaEnabled and
    (not ShouldUseWebLoginForRequest(LActiveProvider)) and
    (FConfig.QuotaUsed >= FConfig.QuotaLimit);
end;

procedure TRadIAService.SendPrompt(const APrompt: string; const AHistory: TArray<IChatMessage>;
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
      LProvider: IIAProvider;
      LHash: string;
      LCachedResponse: string;
      LSystemPrompt: string;
      LHistory: TArray<IChatMessage>;
      LTrimmedHistory: TArray<IChatMessage>;
      LTemperature: Double;
      LMaxTokens: Integer;
    begin
      try
        System.Math.SetExceptionMask(System.Math.exAllArithmeticExceptions);
        try
          LProvider := CreateRequestProvider;
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

procedure TRadIAService.SendPromptStream(const APrompt: string; const AHistory: TArray<IChatMessage>;
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
      try
        System.Math.SetExceptionMask(System.Math.exAllArithmeticExceptions);
        try
          LProvider       := CreateRequestProvider;
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

class function TRadIAService.CreateMessage(const ARole: TAIMessageRole; const AContent: string;
  const AProvider: string; const AModel: string): IChatMessage;
begin
  Result := TRadIAChatMessage.Create(ARole, AContent, AProvider, AModel);
end;

end.
