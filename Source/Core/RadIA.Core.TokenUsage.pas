unit RadIA.Core.TokenUsage;

interface

type
  { Holds token counters returned from any AI provider response }
  TTokenUsage = record
    PromptTokens: Integer;
    CompletionTokens: Integer;
    TotalTokens: Integer;

    class function Empty: TTokenUsage; static;
    function IsEmpty: Boolean;
  end;

  { Calculated cost from a token usage + pricing table }
  TTokenCost = record
    EstimatedCostUSD: Double;
    CurrencySymbol: string;

    class function Zero: TTokenCost; static;
  end;

implementation

{ TTokenUsage }

class function TTokenUsage.Empty: TTokenUsage;
begin
  Result.PromptTokens := 0;
  Result.CompletionTokens := 0;
  Result.TotalTokens := 0;
end;

function TTokenUsage.IsEmpty: Boolean;
begin
  Result := (PromptTokens = 0) and (CompletionTokens = 0);
end;

{ TTokenCost }

class function TTokenCost.Zero: TTokenCost;
begin
  Result.EstimatedCostUSD := 0;
  Result.CurrencySymbol := 'USD';
end;

end.
