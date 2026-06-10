unit RadIA.Tests.InlineCompletion;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestInlineCompletion = class
  public
    [Test]
    procedure TestWindowContextIncludesCursorMarkerAndNearbyLines;
    [Test]
    procedure TestFullFileContextKeepsWholeSource;
    [Test]
    procedure TestResponseCleanerRemovesMarkdownFence;
    [Test]
    procedure TestResponseCleanerRejectsFullUnitScaffold;
    [Test]
    procedure TestResponseCleanerRestoresEscapedLineBreaks;
    [Test]
    procedure TestShortcutParserHandlesAltEnter;
  end;

implementation

uses
  System.SysUtils, RadIA.Core.Types, RadIA.Core.InlineCompletion,
  RadIA.OTA.InlineCompletion;

procedure TTestInlineCompletion.TestWindowContextIncludesCursorMarkerAndNearbyLines;
var
  LContext: TInlineCompletionContext;
  LSource: string;
begin
  LSource :=
    'line1' + sLineBreak +
    'line2' + sLineBreak +
    'line3' + sLineBreak +
    'line4';

  LContext := TInlineCompletionContextBuilder.BuildContext(
    LSource,
    'Unit1.pas',
    3,
    6,
    icmWindow,
    1,
    0);

  Assert.IsFalse(LContext.Text.Contains('line1'));
  Assert.IsTrue(LContext.Text.Contains('line2'));
  Assert.IsTrue(LContext.Text.Contains('line3' + CInlineCompletionCursorMarker));
  Assert.IsFalse(LContext.Text.Contains('line4'));
end;

procedure TTestInlineCompletion.TestFullFileContextKeepsWholeSource;
var
  LContext: TInlineCompletionContext;
begin
  LContext := TInlineCompletionContextBuilder.BuildContext(
    'abc' + sLineBreak + 'def',
    'Unit1.pas',
    1,
    2,
    icmFullFile,
    0,
    0);

  Assert.IsTrue(LContext.Text.Contains('a' + CInlineCompletionCursorMarker + 'bc'));
  Assert.IsTrue(LContext.Text.Contains('def'));
end;

procedure TTestInlineCompletion.TestResponseCleanerRemovesMarkdownFence;
var
  LClean: string;
begin
  LClean := TInlineCompletionResponseCleaner.Clean(
    '```pascal' + sLineBreak +
    'Result := True;' + sLineBreak +
    '```');

  Assert.AreEqual('Result := True;', LClean);
end;

procedure TTestInlineCompletion.TestResponseCleanerRejectsFullUnitScaffold;
var
  LClean: string;
begin
  LClean := TInlineCompletionResponseCleaner.Clean(
    'unit Unit1;interface uses System.SysUtils;');

  Assert.AreEqual('', LClean);
end;

procedure TTestInlineCompletion.TestResponseCleanerRestoresEscapedLineBreaks;
var
  LClean: string;
begin
  LClean := TInlineCompletionResponseCleaner.Clean(
    'private\n  FName: string;\npublic');

  Assert.AreEqual(
    'private' + sLineBreak +
    '  FName: string;' + sLineBreak +
    'public',
    LClean);
end;

procedure TTestInlineCompletion.TestShortcutParserHandlesAltEnter;
begin
  Assert.IsTrue(InlineCompletionShortcutFromText('Alt+Enter') <> 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestInlineCompletion);

end.
