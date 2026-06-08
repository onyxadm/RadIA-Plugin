unit RadIA.Tests.PromptHistory;

interface

uses
  DUnitX.TestFramework,
  RadIA.Core.PromptHistory;

type
  [TestFixture]
  TTestPromptHistoryManager = class
  private
    FManager: TPromptHistoryManager;
    FTempFile: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestAdd_StoresPrompt;
    [Test]
    procedure TestAdd_IgnoresEmptyPrompt;
    [Test]
    procedure TestAdd_IgnoresDuplicateConsecutive;
    [Test]
    procedure TestNavigate_Up_ReturnsLastPrompt;
    [Test]
    procedure TestNavigate_Up_MultipleTimesGoesBackward;
    [Test]
    procedure TestNavigate_Down_AfterUp_ReturnsNext;
    [Test]
    procedure TestNavigate_Down_AtBottom_ReturnsEmpty;
    [Test]
    procedure TestNavigate_Down_WithoutUp_ReturnsEmpty;
    [Test]
    procedure TestLimit_Max50_DiscardsOldest;
    [Test]
    procedure TestReset_CursorAfterAdd;
    [Test]
    procedure TestPersistence_SaveAndLoad;
    [Test]
    procedure TestPersistence_LoadNonExistentFile_NoError;
    [Test]
    procedure TestNavigate_EmptyHistory_ReturnsEmpty;
  end;

implementation

uses
  System.SysUtils, System.IOUtils;

{ TTestPromptHistoryManager }

procedure TTestPromptHistoryManager.Setup;
begin
  FManager := TPromptHistoryManager.Create;
  FTempFile := TPath.Combine(TPath.GetTempPath, 'radia_test_prompt_history.json');
  { Clean up any leftover file from previous test run }
  if TFile.Exists(FTempFile) then
    TFile.Delete(FTempFile);
end;

procedure TTestPromptHistoryManager.TearDown;
begin
  FManager.Free;
  if TFile.Exists(FTempFile) then
    TFile.Delete(FTempFile);
end;

procedure TTestPromptHistoryManager.TestAdd_StoresPrompt;
begin
  FManager.Add('First prompt');
  Assert.AreEqual(1, FManager.Count);
  Assert.AreEqual('First prompt', FManager.GetItem(0));
end;

procedure TTestPromptHistoryManager.TestAdd_IgnoresEmptyPrompt;
begin
  FManager.Add('');
  Assert.AreEqual(0, FManager.Count, 'Empty prompt must not be stored');
end;

procedure TTestPromptHistoryManager.TestAdd_IgnoresDuplicateConsecutive;
begin
  FManager.Add('Same prompt');
  FManager.Add('Same prompt');
  Assert.AreEqual(1, FManager.Count, 'Duplicate consecutive prompt must not be duplicated');
end;

procedure TTestPromptHistoryManager.TestNavigate_EmptyHistory_ReturnsEmpty;
begin
  Assert.IsEmpty(FManager.NavigateUp, 'NavigateUp on empty history must return empty');
  Assert.IsEmpty(FManager.NavigateDown, 'NavigateDown on empty history must return empty');
end;

procedure TTestPromptHistoryManager.TestNavigate_Up_ReturnsLastPrompt;
begin
  FManager.Add('First');
  FManager.Add('Second');
  FManager.Add('Third');

  Assert.AreEqual('Third', FManager.NavigateUp, 'First ↑ must return the most recent prompt');
end;

procedure TTestPromptHistoryManager.TestNavigate_Up_MultipleTimesGoesBackward;
begin
  FManager.Add('First');
  FManager.Add('Second');
  FManager.Add('Third');

  FManager.NavigateUp; { Third }
  Assert.AreEqual('Second', FManager.NavigateUp, 'Second ↑ must return previous prompt');
  Assert.AreEqual('First', FManager.NavigateUp, 'Third ↑ must reach oldest prompt');
  Assert.AreEqual('First', FManager.NavigateUp, 'Additional ↑ at oldest must stay at oldest');
end;

procedure TTestPromptHistoryManager.TestNavigate_Down_AfterUp_ReturnsNext;
begin
  FManager.Add('First');
  FManager.Add('Second');
  FManager.Add('Third');

  FManager.NavigateUp; { Third }
  FManager.NavigateUp; { Second }
  Assert.AreEqual('Third', FManager.NavigateDown, '↓ after two ↑ must move forward to Third');
end;

procedure TTestPromptHistoryManager.TestNavigate_Down_AtBottom_ReturnsEmpty;
begin
  FManager.Add('First');
  FManager.Add('Second');

  FManager.NavigateUp; { Second }
  FManager.NavigateDown; { back to empty = past newest }
  Assert.IsEmpty(FManager.NavigateDown, 'Extra ↓ at the newest entry must return empty string');
end;

procedure TTestPromptHistoryManager.TestNavigate_Down_WithoutUp_ReturnsEmpty;
begin
  FManager.Add('Prompt A');
  Assert.IsEmpty(FManager.NavigateDown, '↓ without prior ↑ must return empty');
end;

procedure TTestPromptHistoryManager.TestLimit_Max50_DiscardsOldest;
var
  LManager: TPromptHistoryManager;
  I: Integer;
begin
  LManager := TPromptHistoryManager.Create(5);
  try
    for I := 1 to 7 do
      LManager.Add('Prompt ' + IntToStr(I));

    Assert.AreEqual(5, LManager.Count, 'History must respect max size limit');
    Assert.AreEqual('Prompt 3', LManager.GetItem(0), 'Oldest entries must be discarded first (FIFO)');
    Assert.AreEqual('Prompt 7', LManager.GetItem(4), 'Newest entry must be at the end');
  finally
    LManager.Free;
  end;
end;

procedure TTestPromptHistoryManager.TestReset_CursorAfterAdd;
begin
  FManager.Add('First');
  FManager.Add('Second');
  FManager.NavigateUp; { Second }
  FManager.NavigateUp; { First }

  { Adding a new prompt must reset cursor to "past end" }
  FManager.Add('Third');
  Assert.AreEqual('Third', FManager.NavigateUp,
    'After Add, cursor must reset so ↑ returns the newly added prompt');
end;

procedure TTestPromptHistoryManager.TestPersistence_SaveAndLoad;
var
  LManager2: TPromptHistoryManager;
begin
  FManager.Add('Saved prompt 1');
  FManager.Add('Saved prompt 2');
  FManager.Add('Saved prompt 3');
  FManager.SaveToFile(FTempFile);

  LManager2 := TPromptHistoryManager.Create;
  try
    LManager2.LoadFromFile(FTempFile);
    Assert.AreEqual(3, LManager2.Count, 'Loaded history must have same count as saved');
    Assert.AreEqual('Saved prompt 1', LManager2.GetItem(0));
    Assert.AreEqual('Saved prompt 3', LManager2.GetItem(2));
  finally
    LManager2.Free;
  end;
end;

procedure TTestPromptHistoryManager.TestPersistence_LoadNonExistentFile_NoError;
begin
  Assert.WillNotRaiseAny(
    procedure
    begin
      FManager.LoadFromFile('C:\NonExistent\Path\file.json');
    end,
    'LoadFromFile must not raise any exception when file does not exist');
  Assert.AreEqual(0, FManager.Count, 'Count must be 0 after loading non-existent file');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPromptHistoryManager);

end.
