unit RadIA.Core.TokenUsage;

interface

uses
  System.SysUtils;

type
  { Holds token counters returned from any AI provider response }
  TTokenUsage = record
    PromptTokens: Integer;
    CompletionTokens: Integer;
    TotalTokens: Integer;

    class function Empty: TTokenUsage; static;
    function IsEmpty: Boolean;
    function FormatStats: string;
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

function TTokenUsage.FormatStats: string;
var
  LSettings: TFormatSettings;
begin
  if IsEmpty then
  begin
    Result := '';
    Exit;
  end;

  LSettings := TFormatSettings.Invariant;
  Result := Format('%s %s · %s %s',
    [#$2191, FormatFloat('#,##0', PromptTokens, LSettings),
     #$2193, FormatFloat('#,##0', CompletionTokens, LSettings)], LSettings);
end;

end.
