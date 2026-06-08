unit RadIA.Tests.Sessions;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Sessions, RadIA.Core.Interfaces;

type
  [TestFixture]
  TTestRadIASessions = class
  private
    FManager: TRadIASessionManager;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestCreateSession;
    [Test]
    procedure TestRenameSession;
    [Test]
    procedure TestDeleteSession;
    [Test]
    procedure TestHistoryLoadSave;
    [Test]
    procedure TestUpdateSessionActivity;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, RadIA.Core.Service, RadIA.Core.Types;

{ TTestRadIASessions }

procedure TTestRadIASessions.Setup;
var
  LSessionsDir: string;
begin
  LSessionsDir := TPath.Combine(TPath.GetHomePath, 'RadIA\sessions');
  if TDirectory.Exists(LSessionsDir) then
    TDirectory.Delete(LSessionsDir, True);

  FManager := TRadIASessionManager.Create;
end;

procedure TTestRadIASessions.TearDown;
var
  LSessionsDir: string;
begin
  FManager.Free;
  FManager := nil;
  
  LSessionsDir := TPath.Combine(TPath.GetHomePath, 'RadIA\sessions');
  if TDirectory.Exists(LSessionsDir) then
    TDirectory.Delete(LSessionsDir, True);
end;

procedure TTestRadIASessions.TestCreateSession;
var
  LSession: TSessionInfo;
begin
  Assert.AreEqual(0, FManager.Sessions.Count);
  
  LSession := FManager.CreateSession('Test Session');
  
  Assert.AreEqual(1, FManager.Sessions.Count);
  Assert.AreEqual('Test Session', FManager.Sessions[0].Name);
  Assert.IsFalse(LSession.Id.IsEmpty);
  Assert.IsTrue(TFile.Exists(TPath.Combine(TPath.Combine(TPath.GetHomePath, 'RadIA\sessions'), 'sessions_index.json')));
end;

procedure TTestRadIASessions.TestRenameSession;
var
  LSession: TSessionInfo;
begin
  LSession := FManager.CreateSession('Old Name');
  FManager.RenameSession(LSession.Id, 'New Name');
  
  Assert.AreEqual('New Name', FManager.Sessions[0].Name);
  
  // Reload index to check persistence
  FManager.Free;
  FManager := TRadIASessionManager.Create;
  
  Assert.AreEqual('New Name', FManager.Sessions[0].Name);
end;

procedure TTestRadIASessions.TestDeleteSession;
var
  LSession: TSessionInfo;
  LFilePath: string;
begin
  LSession := FManager.CreateSession('Session to delete');
  LFilePath := FManager.GetSessionFilePath(LSession.Id);
  
  // Write fake file to see if it is deleted
  TFile.WriteAllText(LFilePath, '[]');
  Assert.IsTrue(TFile.Exists(LFilePath));
  
  FManager.DeleteSession(LSession.Id);
  
  Assert.AreEqual(0, FManager.Sessions.Count);
  Assert.IsFalse(TFile.Exists(LFilePath));
end;

procedure TTestRadIASessions.TestHistoryLoadSave;
var
  LSession: TSessionInfo;
  LHistoryIn, LHistoryOut: TArray<IChatMessage>;
begin
  LSession := FManager.CreateSession('History Session');
  
  LHistoryIn := [
    TRadIAService.CreateMessage(mrUser, 'Hello AI', 'Gemini', 'gemini-1.5-flash'),
    TRadIAService.CreateMessage(mrAssistant, 'Hello Developer!', 'Gemini', 'gemini-1.5-flash')
  ];
  
  FManager.SaveSessionHistory(LSession.Id, LHistoryIn);
  
  LHistoryOut := FManager.LoadSessionHistory(LSession.Id);
  
  Assert.AreEqual(2, Length(LHistoryOut));
  Assert.AreEqual(TAIMessageRole.mrUser, LHistoryOut[0].Role);
  Assert.AreEqual('Hello AI', LHistoryOut[0].Content);
  Assert.AreEqual('Gemini', LHistoryOut[0].Provider);
  Assert.AreEqual('gemini-1.5-flash', LHistoryOut[0].Model);
  
  Assert.AreEqual(TAIMessageRole.mrAssistant, LHistoryOut[1].Role);
  Assert.AreEqual('Hello Developer!', LHistoryOut[1].Content);
  Assert.AreEqual('Gemini', LHistoryOut[1].Provider);
  Assert.AreEqual('gemini-1.5-flash', LHistoryOut[1].Model);
end;

procedure TTestRadIASessions.TestUpdateSessionActivity;
var
  LSess1, LSess2: TSessionInfo;
begin
  LSess1 := FManager.CreateSession('First Session');
  Sleep(100); // Small delay to guarantee different times
  LSess2 := FManager.CreateSession('Second Session');
  
  // Recent first: LSess2 is at index 0, LSess1 is at index 1
  Assert.AreEqual(LSess2.Id, FManager.Sessions[0].Id);
  Assert.AreEqual(LSess1.Id, FManager.Sessions[1].Id);
  
  // Touch LSess1 to make it active
  FManager.UpdateSessionActivity(LSess1.Id);
  
  // Now LSess1 should be at index 0
  Assert.AreEqual(LSess1.Id, FManager.Sessions[0].Id);
  Assert.AreEqual(LSess2.Id, FManager.Sessions[1].Id);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIASessions);

end.
