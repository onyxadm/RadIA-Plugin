unit RadIA.Tests.InlineCompletion;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces, RadIA.Core.RequestOrchestrator;

type
  TMockInlineOrchestrator = class(TInterfacedObject, IAIRequestOrchestrator)
  public
    LastRequest: TAIRequest;
    ResponseText: string;
    ErrorText: string;
    ExecuteAsyncCalled: Boolean;
    procedure ExecuteAsync(const ARequest: TAIRequest; const ACallback: TAIRequestCallback);
    procedure ExecuteStreamAsync(const ARequest: TAIRequest; const ACallback: TStreamChunkCallback);
    procedure CancelCurrentRequest;
  end;

  [TestFixture]
  TTestInlineCompletion = class
  public
    [Test]
    procedure TestWindowContextIncludesCursorMarkerAndNearbyLines;
    [Test]
    procedure TestFullFileContextKeepsWholeSource;
    [Test]
    procedure TestPromptUsesDelphiMarkerAndDeclarationRule;
    [Test]
    procedure TestResponseCleanerRemovesMarkdownFence;
    [Test]
    procedure TestResponseCleanerRejectsFullUnitScaffold;
    [Test]
    procedure TestResponseCleanerRejectsLabeledMarkdownUnitScaffold;
    [Test]
    procedure TestResponseCleanerRestoresEscapedLineBreaks;
    [Test]
    procedure TestInlineServiceUsesOrchestratorRequest;
    [Test]
    procedure TestShortcutParserHandlesAltEnter;
  end;

implementation

uses
  System.SysUtils, RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Core.InlineCompletion,
  RadIA.Core.InlineCompletionService, RadIA.OTA.InlineCompletion;

{ TMockInlineOrchestrator }

procedure TMockInlineOrchestrator.ExecuteAsync(const ARequest: TAIRequest;
  const ACallback: TAIRequestCallback);
begin
  ExecuteAsyncCalled := True;
  LastRequest := ARequest;
  ACallback(ResponseText, ErrorText, TTokenUsage.Empty);
end;

procedure TMockInlineOrchestrator.ExecuteStreamAsync(const ARequest: TAIRequest;
  const ACallback: TStreamChunkCallback);
begin
end;

procedure TMockInlineOrchestrator.CancelCurrentRequest;
begin
end;

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

procedure TTestInlineCompletion.TestPromptUsesDelphiMarkerAndDeclarationRule;
var
  LContext: TInlineCompletionContext;
  LPrompt: string;
begin
  LContext := TInlineCompletionContextBuilder.BuildContext(
    'type' + sLineBreak +
    '  TCustomer = class' + sLineBreak +
    '  private' + sLineBreak +
    '  end;',
    'Unit1.pas',
    3,
    10,
    icmWindow,
    3,
    1);

  LPrompt := TInlineCompletionContextBuilder.BuildPrompt(LContext);

  Assert.IsTrue(LPrompt.Contains(CInlineCompletionCursorMarker));
  Assert.IsTrue(LPrompt.Contains('return only declarations'));
  Assert.IsTrue(LPrompt.Contains('never return implementation code containing begin'));
  Assert.IsTrue(LPrompt.Contains('Focus only on the immediate code around the marker'));
  Assert.IsTrue(LPrompt.Contains('Inside a method body, suggest executable statements only'));
  Assert.IsTrue(LPrompt.Contains('not Free Pascal-only syntax'));
  Assert.IsTrue(LPrompt.Contains('The user is writing code using Embarcadero'));
  Assert.IsTrue(LPrompt.Contains('Only suggest code compatible with'));
  Assert.IsTrue(LPrompt.Contains('Please reply in'));
  Assert.IsTrue(LPrompt.Contains('Delphi code containing the marker'));
  Assert.IsTrue(LPrompt.Contains('Example inside a method body'));
  Assert.IsFalse(LPrompt.Contains('Code before marker:'));
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

procedure TTestInlineCompletion.TestResponseCleanerRejectsLabeledMarkdownUnitScaffold;
var
  LClean: string;
begin
  LClean := TInlineCompletionResponseCleaner.Clean(
    'Delphi ```pascal unit Unit1;interfaceuses System.SysUtils;type TForm1 = class end;```');

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

procedure TTestInlineCompletion.TestInlineServiceUsesOrchestratorRequest;
var
  LMock: TMockInlineOrchestrator;
  LService: TInlineCompletionService;
  LSuggestion: string;
  LError: string;
begin
  LMock := TMockInlineOrchestrator.Create;
  LMock.ResponseText :=
    '```pascal' + sLineBreak +
    'Result := True;' + sLineBreak +
    '```';
  LService := TInlineCompletionService.Create(nil, LMock);
  try
    LService.RequestCompletion('prompt',
      procedure(const ASuggestion: string; const AError: string)
      begin
        LSuggestion := ASuggestion;
        LError := AError;
      end);

    Assert.IsTrue(LMock.ExecuteAsyncCalled);
    Assert.AreEqual('prompt', LMock.LastRequest.Prompt);
    Assert.AreEqual(ruInlineCompletion, LMock.LastRequest.UseCase);
    Assert.AreEqual(rpInlineCompletion, LMock.LastRequest.Profile);
    Assert.AreEqual(rmComplete, LMock.LastRequest.ResponseMode);
    Assert.AreEqual('Result := True;', LSuggestion);
    Assert.AreEqual('', LError);
  finally
    LService.Free;
  end;
end;

procedure TTestInlineCompletion.TestShortcutParserHandlesAltEnter;
begin
  Assert.IsTrue(InlineCompletionShortcutFromText('Alt+Enter') <> 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestInlineCompletion);

end.
