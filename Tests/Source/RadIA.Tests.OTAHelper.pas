unit RadIA.Tests.OTAHelper;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestOTAHelper = class
  public
    [Test]
    procedure TestHelperMethodsOutsideIDE;
  end;

implementation

uses
  RadIA.OTA.Helper;

{ TTestOTAHelper }

procedure TTestOTAHelper.TestHelperMethodsOutsideIDE;
var
  LText: string;
begin
  // When running tests, BorlandIDEServices is nil.
  // We can test that the methods fail gracefully without crashing.
  Assert.AreEqual('a'#13#10'b'#13#10'c', TRadIAOTAHelper.NormalizeLineBreaks('a'#10'b'#13'c'));
  
  Assert.IsFalse(TRadIAOTAHelper.GetActiveEditorText(LText, True));
  Assert.IsFalse(TRadIAOTAHelper.GetActiveEditorText(LText, False));
  
  Assert.IsFalse(TRadIAOTAHelper.ReplaceActiveEditorText('new text'));
  Assert.IsFalse(TRadIAOTAHelper.ReplaceActiveEditorText('new text', True));
  Assert.IsFalse(TRadIAOTAHelper.ReplaceActiveEditorText('new text', False, 'original text'));
  
  Assert.IsFalse(TRadIAOTAHelper.InsertTextAtCursor('text'));
  Assert.IsFalse(TRadIAOTAHelper.InsertTextAtLineColumn('text', 1, 1));
  
  Assert.AreEqual(0, TRadIAOTAHelper.GetCurrentCursorLine);
  Assert.AreEqual('', TRadIAOTAHelper.GetActiveUnitName);
  Assert.AreEqual('', TRadIAOTAHelper.GetActiveProjectName);
  Assert.AreEqual('', TRadIAOTAHelper.GetActiveProjectFolder);
  
  Assert.IsNull(TRadIAOTAHelper.GetCurrentEditBuffer);
  Assert.IsNull(TRadIAOTAHelper.GetCurrentEditView);
  
  Assert.IsFalse(TRadIAOTAHelper.OpenProjectInIDE('dummy.dproj'));
  
  Assert.IsNotEmpty(TRadIAOTAHelper.GetPreferredLanguageInstruction);
  Assert.IsNotEmpty(TRadIAOTAHelper.GetDelphiVersionName);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOTAHelper);

end.
