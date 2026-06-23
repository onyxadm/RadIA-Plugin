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
    [Test]
    procedure TestMessageRoleToString;
    [Test]
    procedure TestStringToMessageRoleException;
  end;

implementation

uses
  System.SysUtils, RadIA.Core.TokenUsage, RadIA.Core.Types;

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

procedure TTestRadIATokenUsage.TestMessageRoleToString;
begin
  Assert.AreEqual('user', MessageRoleToString(mrUser));
  Assert.AreEqual('assistant', MessageRoleToString(mrAssistant));
  Assert.AreEqual('system', MessageRoleToString(mrSystem));
  Assert.AreEqual(mrUser, StringToMessageRole('user'));
  Assert.AreEqual(mrAssistant, StringToMessageRole('assistant'));
  Assert.AreEqual(mrSystem, StringToMessageRole('system'));
end;

procedure TTestRadIATokenUsage.TestStringToMessageRoleException;
begin
  Assert.WillRaise(
    procedure
    begin
      StringToMessageRole('invalid_role');
    end,
    EConvertError
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIATokenUsage);

end.
