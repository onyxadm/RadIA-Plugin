unit RadIA.Tests.TokenUsage;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestRadIATokenUsage = class
  public
    [Test]
    procedure TestEmptyTokenUsage;
    [Test]
    procedure TestFormatTokenStats;
  end;

implementation

uses
  System.SysUtils, RadIA.Core.TokenUsage;

{ TTestRadIATokenUsage }

procedure TTestRadIATokenUsage.TestEmptyTokenUsage;
var
  LUsage: TTokenUsage;
begin
  LUsage := TTokenUsage.Empty;
  Assert.IsTrue(LUsage.IsEmpty);
  Assert.AreEqual('', LUsage.FormatStats);
end;

procedure TTestRadIATokenUsage.TestFormatTokenStats;
var
  LUsage: TTokenUsage;
  LStats: string;
begin
  LUsage.PromptTokens := 1250;
  LUsage.CompletionTokens := 450;
  LUsage.TotalTokens := 1700;

  LStats := LUsage.FormatStats;
  { Stats should contain arrow characters: ↑ 1,250 · ↓ 450 }
  Assert.IsFalse(LUsage.IsEmpty);
  Assert.IsTrue(LStats.Contains('1.250') or LStats.Contains('1,250'), 'Format should have formatted input tokens');
  Assert.IsTrue(LStats.Contains('450'), 'Format should have completion tokens');
  Assert.IsFalse(LStats.Contains('$'), 'Format should not contain cost in USD');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIATokenUsage);

end.
