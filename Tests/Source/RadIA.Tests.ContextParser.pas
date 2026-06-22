unit RadIA.Tests.ContextParser;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestContextParser = class
  public
    [Test]
    procedure TestSingleLineSlashComment;
    [Test]
    procedure TestBraceComment;
    [Test]
    procedure TestParenComment;
    [Test]
    procedure TestMultilineComment;
    [Test]
    procedure TestCursorAnywhereInsideMethod;
    [Test]
    procedure TestMethodWithoutCommentFails;
    [Test]
    procedure TestMethodWithExistingCodeFails;
    [Test]
    procedure TestInsertionPositionBelowComment;
    [Test]
    procedure TestGetClassContextAtLine;
    [Test]
    procedure TestGetInterfaceSection;
  end;

implementation

uses
  System.SysUtils, RadIA.OTA.ContextParser;

function BuildUnit(const ABody: string): string;
begin
  Result :=
    'unit SampleUnit;' + sLineBreak +
    sLineBreak +
    'interface' + sLineBreak +
    sLineBreak +
    'implementation' + sLineBreak +
    sLineBreak +
    'procedure DoWork;' + sLineBreak +
    'begin' + sLineBreak +
    ABody + sLineBreak +
    'end;' + sLineBreak +
    sLineBreak +
    'end.';
end;

procedure TTestContextParser.TestSingleLineSlashComment;
var
  LContext: TMethodExampleContext;
  LError: string;
begin
  Assert.IsTrue(TRadIAContextParser.TryGetMethodExampleContext(
    BuildUnit('  // load customer data'), 9, LContext, LError), LError);
  Assert.AreEqual('load customer data', LContext.CommentText);
end;

procedure TTestContextParser.TestBraceComment;
var
  LContext: TMethodExampleContext;
  LError: string;
begin
  Assert.IsTrue(TRadIAContextParser.TryGetMethodExampleContext(
    BuildUnit('  { load customer data }'), 9, LContext, LError), LError);
  Assert.AreEqual('load customer data', LContext.CommentText);
end;

procedure TTestContextParser.TestParenComment;
var
  LContext: TMethodExampleContext;
  LError: string;
begin
  Assert.IsTrue(TRadIAContextParser.TryGetMethodExampleContext(
    BuildUnit('  (* load customer data *)'), 9, LContext, LError), LError);
  Assert.AreEqual('load customer data', LContext.CommentText);
end;

procedure TTestContextParser.TestMultilineComment;
var
  LContext: TMethodExampleContext;
  LError: string;
  LSource: string;
begin
  LSource := BuildUnit(
    '  {' + sLineBreak +
    '    load customer data' + sLineBreak +
    '    and cache the result' + sLineBreak +
    '  }');

  Assert.IsTrue(TRadIAContextParser.TryGetMethodExampleContext(LSource, 10, LContext, LError), LError);
  Assert.Contains(LContext.CommentText, 'load customer data');
  Assert.Contains(LContext.CommentText, 'and cache the result');
end;

procedure TTestContextParser.TestCursorAnywhereInsideMethod;
var
  LContext: TMethodExampleContext;
  LError: string;
begin
  Assert.IsTrue(TRadIAContextParser.TryGetMethodExampleContext(
    BuildUnit('  // load customer data'), 10, LContext, LError), LError);
  Assert.AreEqual('load customer data', LContext.CommentText);
end;

procedure TTestContextParser.TestMethodWithoutCommentFails;
var
  LContext: TMethodExampleContext;
  LError: string;
begin
  Assert.IsFalse(TRadIAContextParser.TryGetMethodExampleContext(
    BuildUnit(''), 9, LContext, LError));
  Assert.IsFalse(LError.IsEmpty);
end;

procedure TTestContextParser.TestMethodWithExistingCodeFails;
var
  LContext: TMethodExampleContext;
  LError: string;
begin
  Assert.IsFalse(TRadIAContextParser.TryGetMethodExampleContext(
    BuildUnit('  // load customer data' + sLineBreak + '  Result := True;'), 9, LContext, LError));
  Assert.Contains(LError, 'empty');
end;

procedure TTestContextParser.TestInsertionPositionBelowComment;
var
  LContext: TMethodExampleContext;
  LError: string;
begin
  Assert.IsTrue(TRadIAContextParser.TryGetMethodExampleContext(
    BuildUnit('  // load customer data'), 9, LContext, LError), LError);
  Assert.AreEqual(10, LContext.InsertionLine);
  Assert.AreEqual(1, LContext.InsertionColumn);
  Assert.AreEqual('  ', LContext.BodyIndent);
end;

procedure TTestContextParser.TestGetClassContextAtLine;
var
  LResult: string;
begin
  LResult := TRadIAContextParser.GetClassContextAtLine(
    'unit Test;' + #13#10 +
    'interface' + #13#10 +
    'type' + #13#10 +
    '  TMyClass = class' + #13#10 +
    '  end;' + #13#10 +
    'implementation' + #13#10 +
    'end.',
    4
  );
  Assert.IsTrue(True);
end;

procedure TTestContextParser.TestGetInterfaceSection;
var
  LResult: string;
begin
  LResult := TRadIAContextParser.GetInterfaceSection(
    'unit Test;' + #13#10 +
    'interface' + #13#10 +
    'uses Classes;' + #13#10 +
    'implementation' + #13#10 +
    'end.'
  );
  Assert.IsTrue(True);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestContextParser);

end.
