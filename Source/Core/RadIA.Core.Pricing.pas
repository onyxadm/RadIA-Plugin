unit RadIA.Core.Pricing;

interface

uses
  RadIA.Core.Types,
  RadIA.Core.TokenUsage;

type
  { Pricing entry per million tokens }
  TPricingEntry = record
    Provider: TAIProviderType;
    Model: string;
    InputPricePerMillion: Double;   { USD per 1M input tokens  }
    OutputPricePerMillion: Double;  { USD per 1M output tokens }
  end;

  { Computes estimated cost for a TTokenUsage based on built-in pricing table.
    Prices are approximate and may differ from actual billing.
    Source: public pricing pages as of mid-2025. }
  TPricingManager = class
  private
    class function FindEntry(const AProvider: TAIProviderType; const AModel: string;
      out AEntry: TPricingEntry): Boolean; static;
  public
    { Calculate estimated cost for a given usage, provider and model }
    class function Calculate(const AUsage: TTokenUsage; const AProvider: TAIProviderType;
      const AModel: string): TTokenCost; static;

    { Format cost as a human-readable string: "~$0.0012 USD" or "< $0.001 USD" }
    class function FormatCost(const ACost: TTokenCost): string; static;

    { Format a compact stats line: "↑ 1,234 · ↓ 567 · ~$0.0012" }
    class function FormatTokenStats(const AUsage: TTokenUsage; const ACost: TTokenCost): string; static;
  end;

implementation

uses
  System.SysUtils;

{ Approximate prices (USD per 1M tokens) — updated mid-2025 }
const
  PRICING_TABLE: array[0..14] of TPricingEntry = (
    { Google Gemini }
    (Provider: ptGemini; Model: 'gemini-1.5-flash';     InputPricePerMillion: 0.075;  OutputPricePerMillion: 0.30),
    (Provider: ptGemini; Model: 'gemini-1.5-pro';       InputPricePerMillion: 1.25;   OutputPricePerMillion: 5.00),
    (Provider: ptGemini; Model: 'gemini-2.0-flash-exp'; InputPricePerMillion: 0.075;  OutputPricePerMillion: 0.30),
    { OpenAI }
    (Provider: ptOpenAI; Model: 'gpt-4o';               InputPricePerMillion: 2.50;   OutputPricePerMillion: 10.00),
    (Provider: ptOpenAI; Model: 'gpt-4o-mini';          InputPricePerMillion: 0.15;   OutputPricePerMillion: 0.60),
    (Provider: ptOpenAI; Model: 'gpt-4-turbo';          InputPricePerMillion: 10.00;  OutputPricePerMillion: 30.00),
    (Provider: ptOpenAI; Model: 'gpt-3.5-turbo';        InputPricePerMillion: 0.50;   OutputPricePerMillion: 1.50),
    { Anthropic Claude }
    (Provider: ptClaude; Model: 'claude-3-5-sonnet-20241022'; InputPricePerMillion: 3.00;  OutputPricePerMillion: 15.00),
    (Provider: ptClaude; Model: 'claude-3-5-haiku-20241022';  InputPricePerMillion: 0.80;  OutputPricePerMillion: 4.00),
    (Provider: ptClaude; Model: 'claude-3-opus-20240229';     InputPricePerMillion: 15.00; OutputPricePerMillion: 75.00),
    { DeepSeek }
    (Provider: ptDeepSeek; Model: 'deepseek-chat';      InputPricePerMillion: 0.14;   OutputPricePerMillion: 0.28),
    (Provider: ptDeepSeek; Model: 'deepseek-reasoning'; InputPricePerMillion: 0.55;   OutputPricePerMillion: 2.19),
    { Groq }
    (Provider: ptGroq; Model: 'llama-3.3-70b-versatile'; InputPricePerMillion: 0.59;  OutputPricePerMillion: 0.79),
    (Provider: ptGroq; Model: 'mixtral-8x7b-32768';      InputPricePerMillion: 0.24;  OutputPricePerMillion: 0.24),
    (Provider: ptGroq; Model: 'gemma2-9b-it';            InputPricePerMillion: 0.20;  OutputPricePerMillion: 0.20)
  );

{ TPricingManager }



class function TPricingManager.FindEntry(const AProvider: TAIProviderType; const AModel: string;
  out AEntry: TPricingEntry): Boolean;
var
  LEntry: TPricingEntry;
begin
  for LEntry in PRICING_TABLE do
  begin
    if (LEntry.Provider = AProvider) and SameText(LEntry.Model, AModel) then
    begin
      AEntry := LEntry;
      Exit(True);
    end;
  end;
  Result := False;
end;

class function TPricingManager.Calculate(const AUsage: TTokenUsage; const AProvider: TAIProviderType;
  const AModel: string): TTokenCost;
var
  LEntry: TPricingEntry;
  LInputCost, LOutputCost: Double;
begin
  Result := TTokenCost.Zero;

  if AUsage.IsEmpty then
    Exit;

  if not FindEntry(AProvider, AModel, LEntry) then
    Exit; { Unknown model — no cost estimate }

  { Cost = (tokens / 1_000_000) * price_per_million }
  LInputCost  := (AUsage.PromptTokens     / 1000000.0) * LEntry.InputPricePerMillion;
  LOutputCost := (AUsage.CompletionTokens / 1000000.0) * LEntry.OutputPricePerMillion;
  Result.EstimatedCostUSD := LInputCost + LOutputCost;
end;

class function TPricingManager.FormatCost(const ACost: TTokenCost): string;
var
  LSettings: TFormatSettings;
begin
  if ACost.EstimatedCostUSD = 0 then
    Result := ''
  else if ACost.EstimatedCostUSD < 0.001 then
    Result := '< $0.001'
  else
  begin
    LSettings := TFormatSettings.Invariant;
    Result := Format('~$%.4f', [ACost.EstimatedCostUSD], LSettings);
  end;
end;

class function TPricingManager.FormatTokenStats(const AUsage: TTokenUsage; const ACost: TTokenCost): string;
var
  LCostStr: string;
  LSettings: TFormatSettings;
begin
  if AUsage.IsEmpty then
  begin
    Result := '';
    Exit;
  end;

  LSettings := TFormatSettings.Invariant;
  LCostStr := FormatCost(ACost);
  if LCostStr.IsEmpty then
    Result := Format('%s %s · %s %s',
      [#$2191, FormatFloat('#,##0', AUsage.PromptTokens, LSettings),
       #$2193, FormatFloat('#,##0', AUsage.CompletionTokens, LSettings)], LSettings)
  else
    Result := Format('%s %s · %s %s · %s',
      [#$2191, FormatFloat('#,##0', AUsage.PromptTokens, LSettings),
       #$2193, FormatFloat('#,##0', AUsage.CompletionTokens, LSettings),
       LCostStr], LSettings);
end;

end.
