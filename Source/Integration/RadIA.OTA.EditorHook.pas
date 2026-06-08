unit RadIA.OTA.EditorHook;

interface

uses
  System.Classes, System.SysUtils, Vcl.Menus, Vcl.Dialogs, Vcl.Forms, ToolsAPI;

type
  { Manager to create and handle RadIA IDE contextual actions }
  TRadIAEditorHook = class(TComponent)
  private
    FOldActiveFormChange: TNotifyEvent;
    FInstalled: Boolean;
    
    procedure ActiveFormChange(Sender: TObject);
    procedure HookPopupMenu(AForm: TCustomForm);
    procedure UnhookPopupMenu(AForm: TCustomForm);
    function FindEditorPopupMenu(AParent: TComponent): TPopupMenu;
    procedure EditorMenuPopup(Sender: TObject);
    procedure InjectMenuIntoPopupMenu(APopupMenu: TPopupMenu);
    procedure RemoveMenuFromPopupMenu(APopupMenu: TPopupMenu);

    procedure OnExplainExecute(Sender: TObject);
    procedure OnOptimizeExecute(Sender: TObject);
    procedure OnTestsExecute(Sender: TObject);
    procedure OnBugsExecute(Sender: TObject);
    procedure OnDocExecute(Sender: TObject);
    procedure OnReviewExecute(Sender: TObject);
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
  System.Generics.Collections,
  RadIA.OTA.Helper, RadIA.OTA.ContextParser, RadIA.OTA.MessageViewHook, RadIA.Core.Types,
  RadIA.Core.Mediator, RadIA.OTA.DockableForm, RadIA.Core.Logger;

var
  // Global dictionary to track original OnPopup events for intercepted menus
  FInterceptedMenus: TDictionary<TPopupMenu, TNotifyEvent> = nil;

{ TRadIAEditorHook }

constructor TRadIAEditorHook.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOldActiveFormChange := nil;
  FInstalled := False;
end;

destructor TRadIAEditorHook.Destroy;
begin
  Uninstall;
  inherited Destroy;
end;

procedure TRadIAEditorHook.Install;
begin
  if FInstalled then
    Exit;

  TLogger.Log('Installing editor local menu hooks via VCL injection', 'EditorHook');
  
  if not Assigned(FInterceptedMenus) then
    FInterceptedMenus := TDictionary<TPopupMenu, TNotifyEvent>.Create;

  FOldActiveFormChange := Screen.OnActiveFormChange;
  Screen.OnActiveFormChange := ActiveFormChange;
  FInstalled := True;
  
  if Assigned(Screen) and Assigned(Screen.ActiveForm) then
    HookPopupMenu(Screen.ActiveForm);
end;

procedure TRadIAEditorHook.Uninstall;
var
  I: Integer;
  LMenu: TPopupMenu;
  LOldOnPopup: TNotifyEvent;
begin
  if not FInstalled then
    Exit;

  TLogger.Log('Uninstalling editor local menu hooks', 'EditorHook');
  if Assigned(Screen) then
    Screen.OnActiveFormChange := FOldActiveFormChange;
  
  FInstalled := False;
    
  if Assigned(Screen) then
  begin
    for I := 0 to Screen.FormCount - 1 do
      UnhookPopupMenu(Screen.Forms[I]);
  end;

  if Assigned(FInterceptedMenus) then
  begin
    // Restore all original OnPopup handlers
    for LMenu in FInterceptedMenus.Keys do
    begin
      LOldOnPopup := FInterceptedMenus.Items[LMenu];
      LMenu.OnPopup := LOldOnPopup;
      RemoveMenuFromPopupMenu(LMenu);
    end;
    FInterceptedMenus.Clear;
    FreeAndNil(FInterceptedMenus);
  end;
end;

procedure TRadIAEditorHook.ActiveFormChange(Sender: TObject);
var
  I: Integer;
begin
  if Assigned(Screen) then
  begin
    for I := 0 to Screen.FormCount - 1 do
      HookPopupMenu(Screen.Forms[I]);
  end;
    
  if Assigned(FOldActiveFormChange) then
    FOldActiveFormChange(Sender);
end;

function TRadIAEditorHook.FindEditorPopupMenu(AParent: TComponent): TPopupMenu;
var
  LComp: TComponent;
begin
  Result := nil;
  if Assigned(AParent) then
  begin
    LComp := AParent.FindComponent('EditorLocalMenu');
    if Assigned(LComp) and (LComp is TPopupMenu) then
      Result := TPopupMenu(LComp);
  end;
end;

procedure TRadIAEditorHook.HookPopupMenu(AForm: TCustomForm);
var
  LPopupMenu: TPopupMenu;
begin
  if not Assigned(AForm) then
    Exit;

  LPopupMenu := FindEditorPopupMenu(AForm);
  if not Assigned(LPopupMenu) then
    Exit;

  if Assigned(FInterceptedMenus) and not FInterceptedMenus.ContainsKey(LPopupMenu) then
  begin
    TLogger.Log(Format('Hooking OnPopup of EditorLocalMenu for %s (%s)', [AForm.Name, AForm.ClassName]), 'EditorHook');
    FInterceptedMenus.Add(LPopupMenu, LPopupMenu.OnPopup);
    LPopupMenu.OnPopup := EditorMenuPopup;
  end;
end;

procedure TRadIAEditorHook.UnhookPopupMenu(AForm: TCustomForm);
var
  LPopupMenu: TPopupMenu;
  LOldOnPopup: TNotifyEvent;
begin
  if not Assigned(AForm) then
    Exit;

  LPopupMenu := FindEditorPopupMenu(AForm);
  if Assigned(LPopupMenu) and Assigned(FInterceptedMenus) and FInterceptedMenus.TryGetValue(LPopupMenu, LOldOnPopup) then
  begin
    TLogger.Log(Format('Unhooking OnPopup of EditorLocalMenu for %s (%s)', [AForm.Name, AForm.ClassName]), 'EditorHook');
    LPopupMenu.OnPopup := LOldOnPopup;
    FInterceptedMenus.Remove(LPopupMenu);
    RemoveMenuFromPopupMenu(LPopupMenu);
  end;
end;

procedure TRadIAEditorHook.EditorMenuPopup(Sender: TObject);
var
  LPopupMenu: TPopupMenu;
  LOldOnPopup: TNotifyEvent;
begin
  if Sender is TPopupMenu then
  begin
    LPopupMenu := TPopupMenu(Sender);
    InjectMenuIntoPopupMenu(LPopupMenu);
    
    if Assigned(FInterceptedMenus) and FInterceptedMenus.TryGetValue(LPopupMenu, LOldOnPopup) and Assigned(LOldOnPopup) then
      LOldOnPopup(Sender);
  end;
end;

procedure TRadIAEditorHook.InjectMenuIntoPopupMenu(APopupMenu: TPopupMenu);
var
  LRootItem: TMenuItem;
  LSubItem: TMenuItem;
begin
  if not Assigned(APopupMenu) then
    Exit;

  // Prevent duplicate menus
  if Assigned(APopupMenu.Items.Find('mnuRadIARoot')) then
    Exit;

  TLogger.Log('Injecting RadIA menu items into EditorLocalMenu', 'EditorHook');

  // Root Submenu Item
  LRootItem := TMenuItem.Create(APopupMenu);
  LRootItem.Name := 'mnuRadIARoot';
  LRootItem.Caption := 'RadIA';

  // Action Submenu Items
  LSubItem := TMenuItem.Create(APopupMenu);
  LSubItem.Caption := 'Explain Selected Code';
  LSubItem.OnClick := OnExplainExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(APopupMenu);
  LSubItem.Caption := 'Optimize/Refactor Code';
  LSubItem.OnClick := OnOptimizeExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(APopupMenu);
  LSubItem.Caption := 'Generate Unit Tests (DUnitX)';
  LSubItem.OnClick := OnTestsExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(APopupMenu);
  LSubItem.Caption := 'Locate Bugs/Memory Leaks';
  LSubItem.OnClick := OnBugsExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(APopupMenu);
  LSubItem.Caption := 'Document Method (XML)';
  LSubItem.OnClick := OnDocExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(APopupMenu);
  LSubItem.Caption := 'Review Active Unit (Leaks/SOLID)';
  LSubItem.OnClick := OnReviewExecute;
  LRootItem.Add(LSubItem);

  // Separator visual
  LSubItem := TMenuItem.Create(APopupMenu);
  LSubItem.Caption := '-';
  LSubItem.Name := 'mnuRadIASeparator';
  APopupMenu.Items.Add(LSubItem);

  // Add RadIA menu to the VCL PopupMenu
  APopupMenu.Items.Add(LRootItem);
end;

procedure TRadIAEditorHook.RemoveMenuFromPopupMenu(APopupMenu: TPopupMenu);
var
  LItem: TMenuItem;
begin
  if not Assigned(APopupMenu) then
    Exit;

  LItem := APopupMenu.Items.Find('mnuRadIARoot');
  if Assigned(LItem) then
    APopupMenu.Items.Remove(LItem);

  LItem := APopupMenu.Items.Find('mnuRadIASeparator');
  if Assigned(LItem) then
    APopupMenu.Items.Remove(LItem);
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
    TLogger.Log(Format('SendCommandToChat failed: no active text selection for command %s', [ACommand]), 'EditorHook');
    ShowMessage('Please select a block of code in the editor first.');
    Exit;
  end;

  TLogger.Log(Format('SendCommandToChat: Command=%s, SelectionLength=%d', [ACommand, Length(LSelectedText)]), 'EditorHook');
  ShowRadIAChat;

  LPrompt := Format('%s %s'#13#10'```pascal'#13#10'%s'#13#10'```', [ACommand, APromptPrefix, LSelectedText]);
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
    TLogger.Log('OnOptimizeExecute failed: no active text selection', 'EditorHook');
    ShowMessage('Please select a block of code to optimize first.');
    Exit;
  end;

  TLogger.Log(Format('OnOptimizeExecute: SelectionLength=%d', [Length(LSelectedText)]), 'EditorHook');
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
    TLogger.Log('OnDocExecute failed: no active text selection', 'EditorHook');
    ShowMessage('Please select a method block of code to document.');
    Exit;
  end;

  TLogger.Log(Format('OnDocExecute: SelectionLength=%d', [Length(LSelectedText)]), 'EditorHook');
  LPrompt := Format('/doc'#13#10'```pascal'#13#10'%s'#13#10'```', [LSelectedText]);
  TRadIAMediator.Instance.RequestPrompt(LPrompt, True);
end;

procedure TRadIAEditorHook.OnReviewExecute(Sender: TObject);
var
  LActiveCode: string;
  LPrompt: string;
begin
  if not TRadIAOTAHelper.GetActiveEditorText(LActiveCode, False) then
  begin
    TLogger.Log('OnReviewExecute failed: no active code', 'EditorHook');
    ShowMessage('No active code file open in the editor.');
    Exit;
  end;

  TLogger.Log(Format('OnReviewExecute: CodeLength=%d', [Length(LActiveCode)]), 'EditorHook');
  ShowRadIAChat;

  LPrompt := Format('/review'#13#10'```pascal'#13#10'%s'#13#10'```', [LActiveCode]);
  TRadIAMediator.Instance.RequestPrompt(LPrompt, True);
end;

procedure TRadIAEditorHook.OnFixErrorExecute(Sender: TObject);
var
  LErrorMsg, LFileName, LSourceCode, LPrompt: string;
  LLine: Integer;
begin
  if not TRadIAMessageViewHook.GetLastCompilerError(LErrorMsg, LFileName, LLine) then
  begin
    TLogger.Log('OnFixErrorExecute failed: no compiler error found in Messages View', 'EditorHook');
    ShowMessage('No compiler errors found in the Messages View.');
    Exit;
  end;
  
  TLogger.Log(Format('OnFixErrorExecute: Compiler Error found. File=%s, Line=%d, Msg=%s', [LFileName, LLine, LErrorMsg]), 'EditorHook');
  
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

initialization
  // Ensure the FInterceptedMenus dictionary is nil at startup
  FInterceptedMenus := nil;

finalization
  if Assigned(FInterceptedMenus) then
  begin
    FInterceptedMenus.Clear;
    FreeAndNil(FInterceptedMenus);
  end;

end.
