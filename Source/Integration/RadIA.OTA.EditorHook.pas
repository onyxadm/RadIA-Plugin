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
    procedure InjectMenuIntoForm(AForm: TCustomForm);
    procedure RemoveMenuFromForm(AForm: TCustomForm);
    function FindEditorPopupMenu(AParent: TComponent): TPopupMenu;

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
  RadIA.OTA.Helper, RadIA.OTA.ContextParser, RadIA.OTA.MessageViewHook, RadIA.Core.Types,
  RadIA.Core.Mediator, RadIA.OTA.DockableForm, RadIA.Core.Logger;

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
var
  LActiveForm: TCustomForm;
begin
  if FInstalled then
    Exit;

  TLogger.Log('Installing editor local menu hooks via VCL injection', 'EditorHook');
  FOldActiveFormChange := Screen.OnActiveFormChange;
  Screen.OnActiveFormChange := ActiveFormChange;
  FInstalled := True;
  
  if Assigned(Screen) then
  begin
    LActiveForm := Screen.ActiveForm;
    if Assigned(LActiveForm) then
    begin
      TThread.ForceQueue(nil,
        procedure
        begin
          if FInstalled and Assigned(Screen) and (Screen.ActiveForm = LActiveForm) then
            InjectMenuIntoForm(LActiveForm);
        end);
    end;
  end;
end;

procedure TRadIAEditorHook.Uninstall;
var
  I: Integer;
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
      RemoveMenuFromForm(Screen.Forms[I]);
  end;
end;

procedure TRadIAEditorHook.ActiveFormChange(Sender: TObject);
var
  LActiveForm: TCustomForm;
begin
  if Assigned(Screen) then
  begin
    LActiveForm := Screen.ActiveForm;
    if Assigned(LActiveForm) and SameText(LActiveForm.ClassName, 'TEditWindow') then
    begin
      // Adia a injeção do menu para o próximo ciclo de mensagens, garantindo que
      // o formulário e suas subviews estejam completamente construídos e estáveis.
      TThread.ForceQueue(nil,
        procedure
        begin
          if FInstalled and Assigned(Screen) and (Screen.ActiveForm = LActiveForm) then
            InjectMenuIntoForm(LActiveForm);
        end);
    end;
  end;
    
  if Assigned(FOldActiveFormChange) then
    FOldActiveFormChange(Sender);
end;

function TRadIAEditorHook.FindEditorPopupMenu(AParent: TComponent): TPopupMenu;
var
  I: Integer;
  LComp: TComponent;
begin
  Result := nil;
  if not Assigned(AParent) then
    Exit;
    
  for I := 0 to AParent.ComponentCount - 1 do
  begin
    LComp := AParent.Components[I];
    if LComp is TPopupMenu then
    begin
      if SameText(LComp.Name, 'EditorLocalMenu') then
      begin
        Result := TPopupMenu(LComp);
        Exit;
      end;
    end;
    
    Result := FindEditorPopupMenu(LComp);
    if Assigned(Result) then
      Exit;
  end;
end;

procedure TRadIAEditorHook.InjectMenuIntoForm(AForm: TCustomForm);
var
  LPopupMenu: TPopupMenu;
  LRootItem: TMenuItem;
  LSubItem: TMenuItem;
begin
  if not Assigned(AForm) or not SameText(AForm.ClassName, 'TEditWindow') then
    Exit;

  LPopupMenu := FindEditorPopupMenu(AForm);
  if not Assigned(LPopupMenu) then
    Exit;

  // Evita duplicidade se o menu ja estiver injetado nesta janela de edicao
  if Assigned(LPopupMenu.Items.Find('mnuRadIARoot')) then
    Exit;

  TLogger.Log(Format('Injecting RadIA menu into local menu of editor: %s', [AForm.Name]), 'EditorHook');

  // Cria o item de submenu raiz
  LRootItem := TMenuItem.Create(LPopupMenu);
  LRootItem.Name := 'mnuRadIARoot';
  LRootItem.Caption := 'RadIA';

  // Cria e aninha os subitens de acao
  LSubItem := TMenuItem.Create(LPopupMenu);
  LSubItem.Caption := 'Explain Selected Code';
  LSubItem.OnClick := OnExplainExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(LPopupMenu);
  LSubItem.Caption := 'Optimize/Refactor Code';
  LSubItem.OnClick := OnOptimizeExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(LPopupMenu);
  LSubItem.Caption := 'Generate Unit Tests (DUnitX)';
  LSubItem.OnClick := OnTestsExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(LPopupMenu);
  LSubItem.Caption := 'Locate Bugs/Memory Leaks';
  LSubItem.OnClick := OnBugsExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(LPopupMenu);
  LSubItem.Caption := 'Document Method (XML)';
  LSubItem.OnClick := OnDocExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(LPopupMenu);
  LSubItem.Caption := 'Review Active Unit (Leaks/SOLID)';
  LSubItem.OnClick := OnReviewExecute;
  LRootItem.Add(LSubItem);

  // Adiciona um separador visual antes do item RadIA
  LSubItem := TMenuItem.Create(LPopupMenu);
  LSubItem.Caption := '-';
  LSubItem.Name := 'mnuRadIASeparator';
  LPopupMenu.Items.Add(LSubItem);

  // Adiciona o RadIA ao menu de contexto da IDE
  LPopupMenu.Items.Add(LRootItem);
end;

procedure TRadIAEditorHook.RemoveMenuFromForm(AForm: TCustomForm);
var
  LPopupMenu: TPopupMenu;
  LItem: TMenuItem;
begin
  if not Assigned(AForm) or not SameText(AForm.ClassName, 'TEditWindow') then
    Exit;

  LPopupMenu := FindEditorPopupMenu(AForm);
  if Assigned(LPopupMenu) then
  begin
    LItem := LPopupMenu.Items.Find('mnuRadIARoot');
    if Assigned(LItem) then
      LPopupMenu.Items.Remove(LItem);

    LItem := LPopupMenu.Items.Find('mnuRadIASeparator');
    if Assigned(LItem) then
      LPopupMenu.Items.Remove(LItem);
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

end.
