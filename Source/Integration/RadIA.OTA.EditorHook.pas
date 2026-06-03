unit RadIA.OTA.EditorHook;

interface

uses
  System.SysUtils, System.Classes, Vcl.ActnList, Vcl.Menus, Vcl.Dialogs;

type
  { Manager to create and handle RadIA IDE contextual actions }
  TRadIAEditorHook = class
  private
    FActionList: TActionList;
    FExplainAction: TAction;
    FOptimizeAction: TAction;
    FTestsAction: TAction;
    FBugsAction: TAction;
    FDocAction: TAction;
    FFixErrorAction: TAction;
    FShowChatAction: TAction;
    
    procedure OnExplainExecute(Sender: TObject);
    procedure OnOptimizeExecute(Sender: TObject);
    procedure OnTestsExecute(Sender: TObject);
    procedure OnBugsExecute(Sender: TObject);
    procedure OnDocExecute(Sender: TObject);
    procedure OnFixErrorExecute(Sender: TObject);
    procedure OnShowChatExecute(Sender: TObject);
    
    procedure SendCommandToChat(const ACommand: string; const APromptPrefix: string);
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    
    procedure PopulateContextMenu(const AContextMenu: TPopupMenu);
    procedure PopulateToolsMenu(const AMenuItem: TMenuItem);
    
    property ActionList: TActionList read FActionList;
    property ExplainAction: TAction read FExplainAction;
    property OptimizeAction: TAction read FOptimizeAction;
    property TestsAction: TAction read FTestsAction;
    property BugsAction: TAction read FBugsAction;
    property DocAction: TAction read FDocAction;
    property FixErrorAction: TAction read FFixErrorAction;
    property ShowChatAction: TAction read FShowChatAction;
  end;

implementation

uses
  RadIA.OTA.Helper, RadIA.OTA.ContextParser, RadIA.OTA.MessageViewHook, RadIA.Core.Types,
  RadIA.OTA.DockableForm;

{ TRadIAEditorHook }

constructor TRadIAEditorHook.Create(AOwner: TComponent);
begin
  FActionList := TActionList.Create(AOwner);
  
  FExplainAction := TAction.Create(FActionList);
  FExplainAction.ActionList := FActionList;
  FExplainAction.Caption := 'RadIA: Explain Selected Code';
  FExplainAction.OnExecute := OnExplainExecute;
  
  FOptimizeAction := TAction.Create(FActionList);
  FOptimizeAction.ActionList := FActionList;
  FOptimizeAction.Caption := 'RadIA: Optimize/Refactor Code';
  FOptimizeAction.OnExecute := OnOptimizeExecute;
  
  FTestsAction := TAction.Create(FActionList);
  FTestsAction.ActionList := FActionList;
  FTestsAction.Caption := 'RadIA: Generate Unit Tests (DUnitX)';
  FTestsAction.OnExecute := OnTestsExecute;
  
  FBugsAction := TAction.Create(FActionList);
  FBugsAction.ActionList := FActionList;
  FBugsAction.Caption := 'RadIA: Locate Bugs/Memory Leaks';
  FBugsAction.OnExecute := OnBugsExecute;
  
  FDocAction := TAction.Create(FActionList);
  FDocAction.ActionList := FActionList;
  FDocAction.Caption := 'RadIA: Document Method (XML)';
  FDocAction.OnExecute := OnDocExecute;
  
  FFixErrorAction := TAction.Create(FActionList);
  FFixErrorAction.ActionList := FActionList;
  FFixErrorAction.Caption := 'RadIA: Fix Last Compiler Error';
  FFixErrorAction.OnExecute := OnFixErrorExecute;
  
  FShowChatAction := TAction.Create(FActionList);
  FShowChatAction.ActionList := FActionList;
  FShowChatAction.Caption := 'RadIA Chat Panel';
  FShowChatAction.OnExecute := OnShowChatExecute;
end;

destructor TRadIAEditorHook.Destroy;
begin
  FActionList.Free;
  inherited Destroy;
end;

procedure TRadIAEditorHook.PopulateContextMenu(const AContextMenu: TPopupMenu);
var
  LRadIASubMenu: TMenuItem;
  LItem: TMenuItem;
begin
  if not Assigned(AContextMenu) then
    Exit;
    
  LRadIASubMenu := TMenuItem.Create(AContextMenu);
  LRadIASubMenu.Caption := '🤖 RadIA';
  AContextMenu.Items.Add(LRadIASubMenu);
  
  LItem := TMenuItem.Create(LRadIASubMenu);
  LItem.Action := FExplainAction;
  LRadIASubMenu.Add(LItem);
  
  LItem := TMenuItem.Create(LRadIASubMenu);
  LItem.Action := FOptimizeAction;
  LRadIASubMenu.Add(LItem);
  
  LItem := TMenuItem.Create(LRadIASubMenu);
  LItem.Action := FTestsAction;
  LRadIASubMenu.Add(LItem);
  
  LItem := TMenuItem.Create(LRadIASubMenu);
  LItem.Action := FBugsAction;
  LRadIASubMenu.Add(LItem);
  
  LItem := TMenuItem.Create(LRadIASubMenu);
  LItem.Action := FDocAction;
  LRadIASubMenu.Add(LItem);
end;

procedure TRadIAEditorHook.PopulateToolsMenu(const AMenuItem: TMenuItem);
var
  LItem: TMenuItem;
begin
  if not Assigned(AMenuItem) then
    Exit;
    
  LItem := TMenuItem.Create(AMenuItem);
  LItem.Action := FShowChatAction;
  AMenuItem.Add(LItem);
  
  LItem := TMenuItem.Create(AMenuItem);
  LItem.Action := FFixErrorAction;
  AMenuItem.Add(LItem);
end;

procedure TRadIAEditorHook.SendCommandToChat(const ACommand: string; const APromptPrefix: string);
var
  LSelectedText: string;
  LPrompt: string;
begin
  if not TRadIAOTAHelper.GetActiveEditorText(LSelectedText, True) then
  begin
    ShowMessage('Please select a block of code in the editor first.');
    Exit;
  end;
  
  ShowRadIAChat;
  
  LPrompt := Format('%s'#13#10'```pascal'#13#10'%s'#13#10'```', [ACommand, LSelectedText]);
  if Assigned(GlobalOnRequestPrompt) then
  begin
    GlobalOnRequestPrompt(LPrompt, True);
  end;
end;

procedure TRadIAEditorHook.OnExplainExecute(Sender: TObject);
begin
  SendCommandToChat('/explain', 'Explain the following Delphi Pascal code block in detail:');
end;

procedure TRadIAEditorHook.OnShowChatExecute(Sender: TObject);
begin
  ShowRadIAChat;
end;

procedure TRadIAEditorHook.OnOptimizeExecute(Sender: TObject);
var
  LSelectedText: string;
begin
  if not TRadIAOTAHelper.GetActiveEditorText(LSelectedText, True) then
  begin
    ShowMessage('Please select a block of code to optimize first.');
    Exit;
  end;
  
  if Assigned(GlobalOnRequestDiff) then
  begin
    GlobalOnRequestDiff(LSelectedText);
  end;
end;

procedure TRadIAEditorHook.OnTestsExecute(Sender: TObject);
begin
  SendCommandToChat('/test', 'Write DUnitX unit tests for the following Delphi Pascal code:');
end;

procedure TRadIAEditorHook.OnBugsExecute(Sender: TObject);
begin
  SendCommandToChat('/bugs', 'Perform static analysis on the following code to locate potential bugs, exceptions, or memory leaks:');
end;

procedure TRadIAEditorHook.OnDocExecute(Sender: TObject);
var
  LSelectedText: string;
  LPrompt: string;
begin
  if not TRadIAOTAHelper.GetActiveEditorText(LSelectedText, True) then
  begin
    ShowMessage('Please select a method block of code to document.');
    Exit;
  end;
  
  LPrompt := Format('/doc'#13#10'```pascal'#13#10'%s'#13#10'```', [LSelectedText]);
  if Assigned(GlobalOnRequestPrompt) then
  begin
    GlobalOnRequestPrompt(LPrompt, True);
  end;
end;

procedure TRadIAEditorHook.OnFixErrorExecute(Sender: TObject);
var
  LErrorMsg, LFileName, LSourceCode, LPrompt: string;
  LLine: Integer;
begin
  if not TRadIAMessageViewHook.GetLastCompilerError(LErrorMsg, LFileName, LLine) then
  begin
    ShowMessage('No compiler errors found in the Messages View.');
    Exit;
  end;
  
  { Extract source code context if line is valid }
  LSourceCode := '';
  if (LLine > 0) and TRadIAOTAHelper.GetActiveEditorText(LSourceCode, False) then
  begin
    LSourceCode := 'Source Code Context around the error line:'#13#10'```pascal'#13#10 + 
                   TRadIAContextParser.GetClassContextAtLine(LSourceCode, LLine) + 
                   #13#10'```';
  end;
  
  LPrompt := Format('/fix'#13#10'Compiler Error: %s'#13#10'File: %s (Line %d)'#13#10#13#10'%s', 
    [LErrorMsg, ExtractFileName(LFileName), LLine, LSourceCode]);
    
  if Assigned(GlobalOnRequestPrompt) then
  begin
    GlobalOnRequestPrompt(LPrompt, True);
  end;
end;

end.
