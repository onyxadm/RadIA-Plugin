unit RadIA.OTA.EditorHook;

interface

uses
  System.Classes, System.SysUtils, Vcl.ActnList, Vcl.Menus, Vcl.Dialogs, ToolsAPI;

type
  { Manager to create and handle RadIA IDE contextual actions }
  TRadIAEditorHook = class(TComponent)
  private
    FActionList: TActionList;
    procedure AddAction(const AName, ACaption, ACategory: string; AExecute: TNotifyEvent);
    procedure ActionUpdate(Sender: TObject);

    procedure OnExplainExecute(Sender: TObject);
    procedure OnOptimizeExecute(Sender: TObject);
    procedure OnTestsExecute(Sender: TObject);
    procedure OnBugsExecute(Sender: TObject);
    procedure OnDocExecute(Sender: TObject);
    procedure OnFixErrorExecute(Sender: TObject);
    procedure OnShowChatExecute(Sender: TObject);

    procedure SendCommandToChat(const ACommand: string; const APromptPrefix: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure Install;
    procedure Uninstall;
    procedure PopulateToolsMenu(const AMenuItem: TMenuItem);
  end;

implementation

uses
  RadIA.OTA.Helper, RadIA.OTA.ContextParser, RadIA.OTA.MessageViewHook, RadIA.Core.Types,
  RadIA.Core.Mediator, RadIA.OTA.DockableForm;

{ TRadIAEditorHook }

constructor TRadIAEditorHook.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActionList := nil;
end;

destructor TRadIAEditorHook.Destroy;
begin
  Uninstall;
  inherited Destroy;
end;

procedure TRadIAEditorHook.AddAction(const AName, ACaption, ACategory: string; AExecute: TNotifyEvent);
var
  LAct: TAction;
begin
  LAct := TAction.Create(FActionList);
  LAct.Name := AName;
  LAct.Caption := ACaption;
  LAct.Category := ACategory;
  LAct.ActionList := FActionList;
  LAct.OnExecute := AExecute;
  LAct.OnUpdate := ActionUpdate;
end;

procedure TRadIAEditorHook.ActionUpdate(Sender: TObject);
begin
  if Sender is TAction then
    TAction(Sender).Enabled := True;
end;

procedure TRadIAEditorHook.Install;
var
  LEditorLocalMenu: INTAEditorLocalMenu;
begin
  if Supports(BorlandIDEServices, INTAEditorLocalMenu, LEditorLocalMenu) then
  begin
    FActionList := TActionList.Create(Self);
    FActionList.Name := 'RadIAEditorActionList';

    // 1. Action Pai (Submenu)
    AddAction(
      'actRadIARoot',
      'RadIA',
      'RadIA',
      nil
    );

    // 2. Actions Filhas (Subitens)
    AddAction(
      'actRadIAExplain',
      'Explain Selected Code',
      'RadIA.Code',
      OnExplainExecute
    );

    AddAction(
      'actRadIAOptimize',
      'Optimize/Refactor Code',
      'RadIA.Code',
      OnOptimizeExecute
    );

    AddAction(
      'actRadIATests',
      'Generate Unit Tests (DUnitX)',
      'RadIA.Code',
      OnTestsExecute
    );

    AddAction(
      'actRadIABugs',
      'Locate Bugs/Memory Leaks',
      'RadIA.Code',
      OnBugsExecute
    );

    AddAction(
      'actRadIADoc',
      'Document Method (XML)',
      'RadIA.Code',
      OnDocExecute
    );

    LEditorLocalMenu.RegisterActionList(
      FActionList,
      cEdMenuCatBase
    );
  end;
end;

procedure TRadIAEditorHook.Uninstall;
var
  LEditorLocalMenu: INTAEditorLocalMenu;
begin
  if Assigned(FActionList) then
  begin
    if Supports(BorlandIDEServices, INTAEditorLocalMenu, LEditorLocalMenu) then
      LEditorLocalMenu.UnregisterActionList(cEdMenuCatBase);
    FreeAndNil(FActionList);
  end;
end;

procedure TRadIAEditorHook.PopulateToolsMenu(const AMenuItem: TMenuItem);
var
  LItem: TMenuItem;
begin
  if not Assigned(AMenuItem) then
    Exit;
    
  LItem := TMenuItem.Create(AMenuItem);
  LItem.Caption := 'RadIA Chat Panel';
  LItem.OnClick := OnShowChatExecute;
  AMenuItem.Add(LItem);
  
  LItem := TMenuItem.Create(AMenuItem);
  LItem.Caption := 'Fix Last Compiler Error';
  LItem.OnClick := OnFixErrorExecute;
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
  TRadIAMediator.Instance.RequestPrompt(LPrompt, True);
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

  TRadIAMediator.Instance.RequestDiff(LSelectedText);
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
  TRadIAMediator.Instance.RequestPrompt(LPrompt, True);
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

  TRadIAMediator.Instance.RequestPrompt(LPrompt, True);
end;

end.
