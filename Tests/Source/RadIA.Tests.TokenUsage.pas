unit RadIA.Tests.TokenUsage;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Core.Pricing;

type
  [TestFixture]
  TTestRadIATokenUsage = class
  public
    [Test]
    procedure TestPricingCalculation_Gemini;
    [Test]
    procedure TestPricingCalculation_OpenAI;
    [Test]
    procedure TestPricingCalculation_Claude;
    [Test]
    procedure TestPricingCalculation_UnknownModel;
    [Test]
    procedure TestFormatCost;
    [Test]
    procedure TestFormatTokenStats;
  end;

implementation

uses
  System.SysUtils;

{ TTestRadIATokenUsage }

procedure TTestRadIATokenUsage.TestPricingCalculation_Gemini;
var
  LUsage: TTokenUsage;
  LCost: TTokenCost;
begin
  { gemini-1.5-flash: Input = $0.075 / 1M, Output = $0.30 / 1M }
  LUsage.PromptTokens := 100000;      { 0.1M }
  LUsage.CompletionTokens := 50000;   { 0.05M }
  LUsage.TotalTokens := 150000;

  LCost := TPricingManager.Calculate(LUsage, ptGemini, 'gemini-1.5-flash');
  
  { Input Cost = 0.1 * 0.075 = 0.0075
    Output Cost = 0.05 * 0.30 = 0.0150
    Total Cost = 0.0225 }
  Assert.AreEqual(0.0225, LCost.EstimatedCostUSD, 0.00001);
end;

procedure TTestRadIATokenUsage.TestPricingCalculation_OpenAI;
var
  LUsage: TTokenUsage;
  LCost: TTokenCost;
begin
  { gpt-4o-mini: Input = $0.15 / 1M, Output = $0.60 / 1M }
  LUsage.PromptTokens := 200000;      { 0.2M }
  LUsage.CompletionTokens := 100000;  { 0.1M }
  LUsage.TotalTokens := 300000;

  LCost := TPricingManager.Calculate(LUsage, ptOpenAI, 'gpt-4o-mini');
  
  { Input Cost = 0.2 * 0.15 = 0.03
    Output Cost = 0.1 * 0.60 = 0.06
    Total Cost = 0.09 }
  Assert.AreEqual(0.09, LCost.EstimatedCostUSD, 0.00001);
end;

procedure TTestRadIATokenUsage.TestPricingCalculation_Claude;
var
  LUsage: TTokenUsage;
  LCost: TTokenCost;
begin
  { claude-3-5-sonnet-20241022: Input = $3.00 / 1M, Output = $15.00 / 1M }
  LUsage.PromptTokens := 10000;       { 0.01M }
  LUsage.CompletionTokens := 5000;    { 0.005M }
  LUsage.TotalTokens := 15000;

  LCost := TPricingManager.Calculate(LUsage, ptClaude, 'claude-3-5-sonnet-20241022');
  
  { Input Cost = 0.01 * 3.00 = 0.03
    Output Cost = 0.005 * 15.00 = 0.075
    Total Cost = 0.105 }
  Assert.AreEqual(0.105, LCost.EstimatedCostUSD, 0.00001);
end;

procedure TTestRadIATokenUsage.TestPricingCalculation_UnknownModel;
var
  LUsage: TTokenUsage;
  LCost: TTokenCost;
begin
  LUsage.PromptTokens := 1000;
  LUsage.CompletionTokens := 1000;
  LUsage.TotalTokens := 2000;

  LCost := TPricingManager.Calculate(LUsage, ptOpenAI, 'non-existent-model');
  Assert.AreEqual(0.0, LCost.EstimatedCostUSD, 0.00001);
end;

procedure TTestRadIATokenUsage.TestFormatCost;
var
  LCost: TTokenCost;
begin
  LCost.CurrencySymbol := 'USD';
  
  { Cost 0 }
  LCost.EstimatedCostUSD := 0.0;
  Assert.AreEqual('', TPricingManager.FormatCost(LCost));

  { Cost < 0.001 }
  LCost.EstimatedCostUSD := 0.00055;
  Assert.AreEqual('< $0.001', TPricingManager.FormatCost(LCost));

  { Cost >= 0.001 }
  LCost.EstimatedCostUSD := 0.0225;
  Assert.AreEqual('~$0.0225', TPricingManager.FormatCost(LCost));
end;

procedure TTestRadIATokenUsage.TestFormatTokenStats;
var
  LUsage: TTokenUsage;
  LCost: TTokenCost;
  LStats: string;
begin
  { Empty usage }
  LUsage := TTokenUsage.Empty;
  LCost := TTokenCost.Zero;
  Assert.AreEqual('', TPricingManager.FormatTokenStats(LUsage, LCost));

  { Normal usage & cost }
  LUsage.PromptTokens := 1250;
  LUsage.CompletionTokens := 450;
  LUsage.TotalTokens := 1700;
  LCost.EstimatedCostUSD := 0.0225;
  LCost.CurrencySymbol := 'USD';
  
  LStats := TPricingManager.FormatTokenStats(LUsage, LCost);
  { Stats should contain arrow characters: ↑ 1,250 · ↓ 450 · ~$0.0225 }
  Assert.IsTrue(LStats.Contains('1.250') or LStats.Contains('1,250'), 'Format should have formatted input tokens');
  Assert.IsTrue(LStats.Contains('450'), 'Format should have completion tokens');
  Assert.IsTrue(LStats.Contains('~$0.0225'), 'Format should have formatted cost');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIATokenUsage);

end.
