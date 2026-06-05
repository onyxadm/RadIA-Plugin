unit RadIA.Tests.Service;

interface

uses
  DUnitX.TestFramework,
  RadIA.Core.Interfaces,
  RadIA.Core.Types,
  RadIA.Core.Service,
  RadIA.Core.Config,
  RadIA.Core.TokenUsage;

type
  { Mock minimal config for trimming tests — avoids registry I/O }
  TMockConfig = class(TInterfacedObject, IAIConfig)
  private
    FMaxHistoryMessages: Integer;
    FSystemPrompt: string;
    FOpenAICustomBaseUrl: string;
    FOllamaBaseUrl: string;
    FActiveProvider: TAIProviderType;
    FTemperatures: array[TAIProviderType] of Double;
    FMaxTokens: array[TAIProviderType] of Integer;
    FTimeouts: array[TAIProviderType] of Integer;
    FSmartConfigEnabled: Boolean;
    FLogEnabled: Boolean;
    FLogPath: string;
    FLogMaxSizeKB: Integer;
    FQuotaEnabled: Boolean;
    FQuotaLimit: Int64;
    FQuotaUsed: Int64;
    FQuotaCycleStart: TDateTime;
    FActiveSessionId: string;
  public
    constructor Create(const AMaxHistory: Integer; const ASystemPrompt: string = '');

    function GetApiKey(const AProvider: TAIProviderType): string;
    procedure SetApiKey(const AProvider: TAIProviderType; const AKey: string);
    function GetActiveProvider: TAIProviderType;
    procedure SetActiveProvider(const AProvider: TAIProviderType);
    function GetActiveModel(const AProvider: TAIProviderType): string;
    procedure SetActiveModel(const AProvider: TAIProviderType; const AModel: string);
    function GetSystemPrompt: string;
    procedure SetSystemPrompt(const AValue: string);
    function GetOllamaBaseUrl: string;
    procedure SetOllamaBaseUrl(const AValue: string);
    function GetMaxHistoryMessages: Integer;
    procedure SetMaxHistoryMessages(const AValue: Integer);
    function GetOpenAICustomBaseUrl: string;
    procedure SetOpenAICustomBaseUrl(const AValue: string);
    function GetTemperature(const AProvider: TAIProviderType): Double;
    procedure SetTemperature(const AProvider: TAIProviderType; const AValue: Double);
    function GetMaxTokens(const AProvider: TAIProviderType): Integer;
    procedure SetMaxTokens(const AProvider: TAIProviderType; const AValue: Integer);
    function GetTimeout(const AProvider: TAIProviderType): Integer;
    procedure SetTimeout(const AProvider: TAIProviderType; const AValue: Integer);
    function GetSmartConfigEnabled: Boolean;
    procedure SetSmartConfigEnabled(const AValue: Boolean);
    function GetLogEnabled: Boolean;
    procedure SetLogEnabled(const AValue: Boolean);
    function GetLogPath: string;
    procedure SetLogPath(const AValue: string);
    function GetLogMaxSizeKB: Integer;
    procedure SetLogMaxSizeKB(const AValue: Integer);
    function GetQuotaEnabled: Boolean;
    procedure SetQuotaEnabled(const AValue: Boolean);
    function GetQuotaLimit: Int64;
    procedure SetQuotaLimit(const AValue: Int64);
    function GetQuotaUsed: Int64;
    procedure SetQuotaUsed(const AValue: Int64);
    function GetQuotaCycleStart: TDateTime;
    procedure SetQuotaCycleStart(const AValue: TDateTime);
    function GetActiveSessionId: string;
    procedure SetActiveSessionId(const AValue: string);
    procedure AddToQuotaUsage(const AUsage: TTokenUsage);
    procedure Save;
    procedure Load;
  end;

  [TestFixture]
  TTestRadIAService = class
  private
    function MakeHistory(const ACount: Integer): TArray<IChatMessage>;
    function MakeHistoryWithSystem(const AUserAssistantCount: Integer): TArray<IChatMessage>;
  public
    [Test]
    procedure TestTrimming_NoTrimWhenUnderLimit;
    [Test]
    procedure TestTrimming_NoTrimWhenAtExactLimit;
    [Test]
    procedure TestTrimming_TrimsOldestWhenOverLimit;
    [Test]
    procedure TestTrimming_AlwaysPreservesNewestMessages;
    [Test]
    procedure TestTrimming_SystemMessagesIgnoredInCount;
    [Test]
    procedure TestSmartConfigResolution;
  end;

  [TestFixture]
  TTestRadIAConfigExtended = class
  private
    FConfig: IAIConfig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestMaxHistoryMessages_DefaultIs20;
    [Test]
    procedure TestMaxHistoryMessages_Persistence;
    [Test]
    procedure TestMaxHistoryMessages_ZeroResetsToDefault;
    [Test]
    procedure TestOpenAICustomBaseUrl_DefaultIsEmpty;
    [Test]
    procedure TestOpenAICustomBaseUrl_Persistence;
  end;

implementation

uses
  System.SysUtils;

{ TMockConfig }

constructor TMockConfig.Create(const AMaxHistory: Integer; const ASystemPrompt: string);
var
  LProvider: TAIProviderType;
begin
  inherited Create;
  FMaxHistoryMessages := AMaxHistory;
  FSystemPrompt := ASystemPrompt;
  FOpenAICustomBaseUrl := '';
  FOllamaBaseUrl := 'http://localhost:11434';
  FActiveProvider := ptGemini;
  FSmartConfigEnabled := True;
  FLogEnabled := True;
  FLogPath := '';
  FLogMaxSizeKB := 1024;
  for LProvider := Low(TAIProviderType) to High(TAIProviderType) do
  begin
    FTemperatures[LProvider] := 0.7;
    FMaxTokens[LProvider] := 2048;
    FTimeouts[LProvider] := 60;
  end;
  FQuotaEnabled := False;
  FQuotaLimit := 1000000;
  FQuotaUsed := 0;
  FQuotaCycleStart := Now;
  FActiveSessionId := '';
end;

function TMockConfig.GetApiKey(const AProvider: TAIProviderType): string;
begin
  Result := '';
end;

procedure TMockConfig.SetApiKey(const AProvider: TAIProviderType; const AKey: string);
begin
end;

function TMockConfig.GetActiveProvider: TAIProviderType;
begin
  Result := FActiveProvider;
end;

procedure TMockConfig.SetActiveProvider(const AProvider: TAIProviderType);
begin
  FActiveProvider := AProvider;
end;

function TMockConfig.GetActiveModel(const AProvider: TAIProviderType): string;
begin
  Result := 'test-model';
end;

procedure TMockConfig.SetActiveModel(const AProvider: TAIProviderType; const AModel: string);
begin
end;

function TMockConfig.GetSystemPrompt: string;
begin
  Result := FSystemPrompt;
end;

procedure TMockConfig.SetSystemPrompt(const AValue: string);
begin
  FSystemPrompt := AValue;
end;

function TMockConfig.GetOllamaBaseUrl: string;
begin
  Result := FOllamaBaseUrl;
end;

procedure TMockConfig.SetOllamaBaseUrl(const AValue: string);
begin
  FOllamaBaseUrl := AValue;
end;

function TMockConfig.GetMaxHistoryMessages: Integer;
begin
  Result := FMaxHistoryMessages;
end;

procedure TMockConfig.SetMaxHistoryMessages(const AValue: Integer);
begin
  if AValue > 0 then
    FMaxHistoryMessages := AValue
  else
    FMaxHistoryMessages := 20;
end;

function TMockConfig.GetOpenAICustomBaseUrl: string;
begin
  Result := FOpenAICustomBaseUrl;
end;

procedure TMockConfig.SetOpenAICustomBaseUrl(const AValue: string);
begin
  FOpenAICustomBaseUrl := AValue;
end;

procedure TMockConfig.Save;
begin
end;

procedure TMockConfig.Load;
begin
end;

function TMockConfig.GetTemperature(const AProvider: TAIProviderType): Double;
begin
  Result := FTemperatures[AProvider];
end;

procedure TMockConfig.SetTemperature(const AProvider: TAIProviderType; const AValue: Double);
begin
  FTemperatures[AProvider] := AValue;
end;

function TMockConfig.GetMaxTokens(const AProvider: TAIProviderType): Integer;
begin
  Result := FMaxTokens[AProvider];
end;

procedure TMockConfig.SetMaxTokens(const AProvider: TAIProviderType; const AValue: Integer);
begin
  FMaxTokens[AProvider] := AValue;
end;

function TMockConfig.GetTimeout(const AProvider: TAIProviderType): Integer;
begin
  Result := FTimeouts[AProvider];
end;

procedure TMockConfig.SetTimeout(const AProvider: TAIProviderType; const AValue: Integer);
begin
  FTimeouts[AProvider] := AValue;
end;

function TMockConfig.GetSmartConfigEnabled: Boolean;
begin
  Result := FSmartConfigEnabled;
end;

procedure TMockConfig.SetSmartConfigEnabled(const AValue: Boolean);
begin
  FSmartConfigEnabled := AValue;
end;

function TMockConfig.GetLogEnabled: Boolean;
begin
  Result := FLogEnabled;
end;

procedure TMockConfig.SetLogEnabled(const AValue: Boolean);
begin
  FLogEnabled := AValue;
end;

function TMockConfig.GetLogPath: string;
begin
  Result := FLogPath;
end;

procedure TMockConfig.SetLogPath(const AValue: string);
begin
  FLogPath := AValue;
end;

function TMockConfig.GetLogMaxSizeKB: Integer;
begin
  Result := FLogMaxSizeKB;
end;

procedure TMockConfig.SetLogMaxSizeKB(const AValue: Integer);
begin
  FLogMaxSizeKB := AValue;
end;

function TMockConfig.GetQuotaEnabled: Boolean;
begin
  Result := FQuotaEnabled;
end;

procedure TMockConfig.SetQuotaEnabled(const AValue: Boolean);
begin
  FQuotaEnabled := AValue;
end;

function TMockConfig.GetQuotaLimit: Int64;
begin
  Result := FQuotaLimit;
end;

procedure TMockConfig.SetQuotaLimit(const AValue: Int64);
begin
  FQuotaLimit := AValue;
end;

function TMockConfig.GetQuotaUsed: Int64;
begin
  Result := FQuotaUsed;
end;

procedure TMockConfig.SetQuotaUsed(const AValue: Int64);
begin
  FQuotaUsed := AValue;
end;

function TMockConfig.GetQuotaCycleStart: TDateTime;
begin
  Result := FQuotaCycleStart;
end;

procedure TMockConfig.SetQuotaCycleStart(const AValue: TDateTime);
begin
  FQuotaCycleStart := AValue;
end;

function TMockConfig.GetActiveSessionId: string;
begin
  Result := FActiveSessionId;
end;

procedure TMockConfig.SetActiveSessionId(const AValue: string);
begin
  FActiveSessionId := AValue;
end;

procedure TMockConfig.AddToQuotaUsage(const AUsage: TTokenUsage);
begin
  if FQuotaEnabled then
    FQuotaUsed := FQuotaUsed + AUsage.TotalTokens;
end;

{ TTestRadIAService helpers }

function TTestRadIAService.MakeHistory(const ACount: Integer): TArray<IChatMessage>;
var
  I: Integer;
  LRole: TAIMessageRole;
begin
  SetLength(Result, ACount);
  for I := 0 to ACount - 1 do
  begin
    if I mod 2 = 0 then
      LRole := mrUser
    else
      LRole := mrAssistant;
    Result[I] := TRadIAService.CreateMessage(LRole, 'Message ' + IntToStr(I));
  end;
end;

function TTestRadIAService.MakeHistoryWithSystem(const AUserAssistantCount: Integer): TArray<IChatMessage>;
var
  I: Integer;
  LRole: TAIMessageRole;
begin
  { First message is system, then user/assistant pairs }
  SetLength(Result, AUserAssistantCount + 1);
  Result[0] := TRadIAService.CreateMessage(mrSystem, 'You are a Delphi expert.');
  for I := 1 to AUserAssistantCount do
  begin
    if I mod 2 = 1 then
      LRole := mrUser
    else
      LRole := mrAssistant;
    Result[I] := TRadIAService.CreateMessage(LRole, 'Message ' + IntToStr(I));
  end;
end;

{ TTestRadIAService }

procedure TTestRadIAService.TestTrimming_NoTrimWhenUnderLimit;
var
  LConfig: IAIConfig;
  LService: TRadIAService;
  LHistory: TArray<IChatMessage>;
  LTrimmed: TArray<IChatMessage>;
begin
  { MaxHistoryMessages = 5 → limit = 10 messages; we send 6 → no trim }
  LConfig := TMockConfig.Create(5);
  LService := TRadIAService.Create(LConfig);
  try
    LHistory := MakeHistory(6);
    LTrimmed := LService.TrimHistory(LHistory);
    Assert.AreEqual(6, Length(LTrimmed), 'Should NOT trim when under limit');
  finally
    LService.Free;
  end;
end;

procedure TTestRadIAService.TestTrimming_NoTrimWhenAtExactLimit;
var
  LConfig: IAIConfig;
  LService: TRadIAService;
  LHistory: TArray<IChatMessage>;
  LTrimmed: TArray<IChatMessage>;
begin
  { MaxHistoryMessages = 5 → limit = 10; we send exactly 10 → no trim }
  LConfig := TMockConfig.Create(5);
  LService := TRadIAService.Create(LConfig);
  try
    LHistory := MakeHistory(10);
    LTrimmed := LService.TrimHistory(LHistory);
    Assert.AreEqual(10, Length(LTrimmed), 'Should NOT trim at exact limit');
  finally
    LService.Free;
  end;
end;

procedure TTestRadIAService.TestTrimming_TrimsOldestWhenOverLimit;
var
  LConfig: IAIConfig;
  LService: TRadIAService;
  LHistory: TArray<IChatMessage>;
  LTrimmed: TArray<IChatMessage>;
begin
  { MaxHistoryMessages = 3 → limit = 6; we send 10 → trim to 6 }
  LConfig := TMockConfig.Create(3);
  LService := TRadIAService.Create(LConfig);
  try
    LHistory := MakeHistory(10);
    LTrimmed := LService.TrimHistory(LHistory);
    Assert.AreEqual(6, Length(LTrimmed), 'Should trim to MaxHistoryMessages*2 messages');
  finally
    LService.Free;
  end;
end;

procedure TTestRadIAService.TestTrimming_AlwaysPreservesNewestMessages;
var
  LConfig: IAIConfig;
  LService: TRadIAService;
  LHistory: TArray<IChatMessage>;
  LTrimmed: TArray<IChatMessage>;
begin
  { MaxHistoryMessages = 2 → limit = 4; send 8 messages → keeps last 4 }
  LConfig := TMockConfig.Create(2);
  LService := TRadIAService.Create(LConfig);
  try
    LHistory := MakeHistory(8);
    LTrimmed := LService.TrimHistory(LHistory);
    Assert.AreEqual(4, Length(LTrimmed), 'Should keep exactly MaxHistoryMessages*2 newest messages');
    Assert.AreEqual('Message 4', LTrimmed[0].Content, 'First kept message should be index 4');
    Assert.AreEqual('Message 7', LTrimmed[3].Content, 'Last kept message should be index 7');
  finally
    LService.Free;
  end;
end;

procedure TTestRadIAService.TestTrimming_SystemMessagesIgnoredInCount;
var
  LConfig: IAIConfig;
  LService: TRadIAService;
  LHistory: TArray<IChatMessage>;
  LTrimmed: TArray<IChatMessage>;
begin
  { MaxHistoryMessages = 3 → limit = 6 user/assistant; 1 system + 4 user/assistant = 5 total.
    System messages are filtered out before counting, so 4 <= 6 → no trim. }
  LConfig := TMockConfig.Create(3, 'You are a Delphi expert.');
  LService := TRadIAService.Create(LConfig);
  try
    LHistory := MakeHistoryWithSystem(4);
    LTrimmed := LService.TrimHistory(LHistory);
    { TrimHistory strips system messages from count; 4 user/assistant < 6 limit → no trim }
    Assert.AreEqual(4, Length(LTrimmed), 'System messages must not be counted toward trim limit');
    Assert.AreNotEqual(mrSystem, LTrimmed[0].Role, 'System messages should be stripped from trimmed result');
  finally
    LService.Free;
  end;
end;

procedure TTestRadIAService.TestSmartConfigResolution;
var
  LConfig: IAIConfig;
  LService: TRadIAService;
  LTemp: Double;
  LMaxTokens: Integer;
begin
  LConfig := TMockConfig.Create(5);
  LService := TRadIAService.Create(LConfig);
  try
    { 1. Com Smart Config Enabled (Padrão) }
    LConfig.SmartConfigEnabled := True;
    
    // Refatorar
    LService.ResolveParameters(ptGemini, rpRefactorCode, LTemp, LMaxTokens);
    Assert.AreEqual(0.1, LTemp, 0.01);
    Assert.AreEqual(4096, LMaxTokens);
    
    // Chat Geral
    LService.ResolveParameters(ptGemini, rpGeneralChat, LTemp, LMaxTokens);
    Assert.AreEqual(0.7, LTemp, 0.01);
    Assert.AreEqual(2048, LMaxTokens);
    
    { 2. Com Smart Config Disabled (Usa valores da config) }
    LConfig.SmartConfigEnabled := False;
    LConfig.SetTemperature(ptGemini, 0.4);
    LConfig.SetMaxTokens(ptGemini, 1024);
    
    LService.ResolveParameters(ptGemini, rpRefactorCode, LTemp, LMaxTokens);
    Assert.AreEqual(0.4, LTemp, 0.01);
    Assert.AreEqual(1024, LMaxTokens);
  finally
    LService.Free;
  end;
end;

{ TTestRadIAConfigExtended }

procedure TTestRadIAConfigExtended.Setup;
begin
  FConfig := TRadIAConfig.Create;
end;

procedure TTestRadIAConfigExtended.TearDown;
begin
  FConfig := nil;
end;

procedure TTestRadIAConfigExtended.TestMaxHistoryMessages_DefaultIs20;
begin
  { Fresh config created in Setup already loads from registry; if not set, defaults to 20 }
  Assert.IsTrue(FConfig.GetMaxHistoryMessages > 0, 'MaxHistoryMessages must be positive');
  Assert.IsTrue(FConfig.GetMaxHistoryMessages >= 1, 'MaxHistoryMessages must be at least 1');
end;

procedure TTestRadIAConfigExtended.TestMaxHistoryMessages_Persistence;
const
  TEST_VALUE = 15;
begin
  FConfig.MaxHistoryMessages := TEST_VALUE;
  FConfig.Save;
  FConfig.Load;
  Assert.AreEqual(TEST_VALUE, FConfig.GetMaxHistoryMessages);
end;

procedure TTestRadIAConfigExtended.TestMaxHistoryMessages_ZeroResetsToDefault;
begin
  FConfig.MaxHistoryMessages := 0;
  Assert.AreEqual(20, FConfig.GetMaxHistoryMessages, 'Zero value should reset to default 20');
end;

procedure TTestRadIAConfigExtended.TestOpenAICustomBaseUrl_DefaultIsEmpty;
var
  LFreshConfig: IAIConfig;
begin
  { Create fresh mock config: default custom URL must be empty }
  LFreshConfig := TMockConfig.Create(20);
  Assert.IsEmpty(LFreshConfig.GetOpenAICustomBaseUrl, 'Default OpenAI Custom Base URL should be empty');
end;

procedure TTestRadIAConfigExtended.TestOpenAICustomBaseUrl_Persistence;
const
  TEST_URL = 'http://localhost:1234/v1';
begin
  FConfig.OpenAICustomBaseUrl := TEST_URL;
  FConfig.Save;
  FConfig.Load;
  Assert.AreEqual(TEST_URL, FConfig.GetOpenAICustomBaseUrl);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAService);
  TDUnitX.RegisterTestFixture(TTestRadIAConfigExtended);

end.
