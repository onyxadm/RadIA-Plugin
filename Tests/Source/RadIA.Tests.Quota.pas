unit RadIA.Tests.Quota;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces, RadIA.Core.Config, RadIA.Core.Service;

type
  [TestFixture]
  TTestRadIAQuota = class
  private
    FConfig: IRadIAConfig;
    FService: TRadIAService;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestQuotaIncrement;
    [Test]
    procedure TestQuotaCycleReset;
    [Test]
    procedure TestQuotaBlocking;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.DateUtils, System.SyncObjs,
  RadIA.Core.TokenUsage, RadIA.Core.Types, RadIA.Core.SettingsStorage;

{ TTestRadIAQuota }

procedure TTestRadIAQuota.Setup;
begin
  TRadIAConfig.SetBaseRegistryPath('Software\TestRadIAQuota');
  TRadIAConfig.SetStorage(TRadIAMemorySettingsStorage.Create);
  FConfig := TRadIAConfig.Create;
  FConfig.QuotaEnabled := False;
  FConfig.QuotaLimit := 1000;
  FConfig.QuotaUsed := 0;
  FConfig.QuotaCycleStart := Now;
  FConfig.Save;

  FService := TRadIAService.Create(FConfig);
end;

procedure TTestRadIAQuota.TearDown;
begin
  FService.Free;
  FService := nil;
  FConfig := nil;
  TRadIAConfig.SetStorage(nil);
  TRadIAConfig.SetBaseRegistryPath('');
end;

procedure TTestRadIAQuota.TestQuotaIncrement;
var
  LUsage: TTokenUsage;
begin
  FConfig.QuotaEnabled := True;
  FConfig.QuotaUsed := 0;
  FConfig.QuotaLimit := 1000;
  FConfig.Save;

  LUsage.PromptTokens := 100;
  LUsage.CompletionTokens := 150;
  LUsage.TotalTokens := 250;

  FConfig.AddToQuotaUsage(LUsage);

  Assert.AreEqual(Int64(250), FConfig.QuotaUsed);
end;

procedure TTestRadIAQuota.TestQuotaCycleReset;
var
  LPrevMonth: TDateTime;
begin
  FConfig.QuotaEnabled := True;
  FConfig.QuotaLimit := 1000;
  FConfig.QuotaUsed := 500;

  // Set start of cycle to 2 months ago to force reset
  LPrevMonth := IncMonth(Now, -2);
  FConfig.QuotaCycleStart := LPrevMonth;
  FConfig.Save;

  // Reloading config should check and trigger the reset cycle
  FConfig.Load;

  Assert.AreEqual(Int64(0), FConfig.QuotaUsed);
  Assert.AreNotEqual(LPrevMonth, FConfig.QuotaCycleStart);
end;

procedure TTestRadIAQuota.TestQuotaBlocking;
var
  LDoneEvent: TSimpleEvent;
  LErrorMsg: string;
  LHistory: TArray<IRadIAChatMessage>;
begin
  FConfig.QuotaEnabled := True;
  FConfig.SetActiveProvider('Gemini');
  FConfig.SetProviderAuthType('Gemini', 'api_key');
  FConfig.SetApiKey('Gemini', 'test-api-key');
  FConfig.QuotaLimit := 100;
  FConfig.QuotaUsed := 100; // Limit reached
  FConfig.Save;

  LHistory := [];
  LDoneEvent := TSimpleEvent.Create;
  try
    LErrorMsg := '';

    // 1. Test SendPrompt (Blocking)
    FService.SendPrompt('Hello AI', LHistory,
      procedure(const AResponse: string; const AError: string; AFromCache: Boolean; const AUsage: TTokenUsage)
      begin
        LErrorMsg := AError;
        LDoneEvent.SetEvent;
      end);

    LDoneEvent.WaitFor(5000);
    Assert.Contains(LErrorMsg, 'Local monthly token quota exceeded');

    LDoneEvent.ResetEvent;
    LErrorMsg := '';

    // 2. Test SendPromptStream (Blocking)
    FService.SendPromptStream('Hello AI', LHistory,
      procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
      begin
        if AIsDone then
        begin
          LErrorMsg := AError;
          LDoneEvent.SetEvent;
        end;
      end);

    LDoneEvent.WaitFor(5000);
    Assert.Contains(LErrorMsg, 'Local monthly token quota exceeded');
  finally
    LDoneEvent.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAQuota);

end.
