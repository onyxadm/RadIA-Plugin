unit RadIA.OTA.EditorHook;

interface

uses
  System.Classes, System.SysUtils, Vcl.Menus, Vcl.Dialogs, ToolsAPI;

type
  { Manager to create and handle RadIA IDE contextual actions }
  TRadIAEditorHook = class(TComponent)
  private
    FBindingIndex: Integer;

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

type
  { Class that implements IOTALocalMenu to build the editor context menu }
  TRadIALocalMenu = class(TInterfacedObject, IOTALocalMenu)
  private
    FCaption: string;
    FName: string;
    FParent: string;
    FPosition: Integer;
    FExecuteProc: TProc;
  public
    constructor Create(const ACaption, AName, AParent: string; APosition: Integer; AExecuteProc: TProc);
    { IOTALocalMenu }
    function GetCaption: string;
    function GetChecked: Boolean;
    function GetEnabled: Boolean;
    function GetHelpContext: THelpContext;
    function GetName: string;
    function GetParent: string;
    function GetPosition: Integer;
    function GetVerb: string;
    procedure Execute(const Context: IOTAGetSelText);
  end;

  { Class that implements IOTAKeyboardBinding to register the context menus }
  TRadIAKeyboardBinding = class(TInterfacedObject, IOTAKeyboardBinding)
  private
    FEditorHook: TRadIAEditorHook;
  public
    constructor Create(AEditorHook: TRadIAEditorHook);
    { IOTAKeyboardBinding }
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
  end;

{ TRadIALocalMenu }

constructor TRadIALocalMenu.Create(const ACaption, AName, AParent: string; APosition: Integer; AExecuteProc: TProc);
begin
  inherited Create;
  FCaption := ACaption;
  FName := AName;
  FParent := AParent;
  FPosition := APosition;
  FExecuteProc := AExecuteProc;
end;

function TRadIALocalMenu.GetCaption: string;
begin
  Result := FCaption;
end;

function TRadIALocalMenu.GetChecked: Boolean;
begin
  Result := False;
end;

function TRadIALocalMenu.GetEnabled: Boolean;
begin
  Result := True;
end;

function TRadIALocalMenu.GetHelpContext: THelpContext;
begin
  Result := 0;
end;

function TRadIALocalMenu.GetName: string;
begin
  Result := FName;
end;

function TRadIALocalMenu.GetParent: string;
begin
  Result := FParent;
end;

function TRadIALocalMenu.GetPosition: Integer;
begin
  Result := FPosition;
end;

function TRadIALocalMenu.GetVerb: string;
begin
  Result := FCaption;
end;

procedure TRadIALocalMenu.Execute(const Context: IOTAGetSelText);
begin
  if Assigned(FExecuteProc) then
    FExecuteProc();
end;

{ TRadIAKeyboardBinding }

constructor TRadIAKeyboardBinding.Create(AEditorHook: TRadIAEditorHook);
begin
  inherited Create;
  FEditorHook := AEditorHook;
end;

function TRadIAKeyboardBinding.GetBindingType: TBindingType;
begin
  Result := btPartial;
end;

function TRadIAKeyboardBinding.GetDisplayName: string;
begin
  Result := 'RadIA Context Menu Binding';
end;

function TRadIAKeyboardBinding.GetName: string;
begin
  Result := 'RadIA.KeyboardBinding';
end;

procedure TRadIAKeyboardBinding.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  // Register the root context menu item (Submenu)
  BindingServices.RegisterLocalMenu('RadIA', TRadIALocalMenu.Create('RadIA', 'mnuRadIARoot', '', 0, nil));

  // Register child submenus pointing Parent to 'mnuRadIARoot'
  BindingServices.RegisterLocalMenu('RadIA', TRadIALocalMenu.Create('Explain Selected Code', 'mnuRadIAExplain', 'mnuRadIARoot', 10,
    procedure
    begin
      FEditorHook.OnExplainExecute(nil);
    end));

  BindingServices.RegisterLocalMenu('RadIA', TRadIALocalMenu.Create('Optimize/Refactor Code', 'mnuRadIAOptimize', 'mnuRadIARoot', 20,
    procedure
    begin
      FEditorHook.OnOptimizeExecute(nil);
    end));

  BindingServices.RegisterLocalMenu('RadIA', TRadIALocalMenu.Create('Generate Unit Tests (DUnitX)', 'mnuRadIATests', 'mnuRadIARoot', 30,
    procedure
    begin
      FEditorHook.OnTestsExecute(nil);
    end));

  BindingServices.RegisterLocalMenu('RadIA', TRadIALocalMenu.Create('Locate Bugs/Memory Leaks', 'mnuRadIABugs', 'mnuRadIARoot', 40,
    procedure
    begin
      FEditorHook.OnBugsExecute(nil);
    end));

  BindingServices.RegisterLocalMenu('RadIA', TRadIALocalMenu.Create('Document Method (XML)', 'mnuRadIADoc', 'mnuRadIARoot', 50,
    procedure
    begin
      FEditorHook.OnDocExecute(nil);
    end));

  BindingServices.RegisterLocalMenu('RadIA', TRadIALocalMenu.Create('Review Active Unit (Leaks/SOLID)', 'mnuRadIAReview', 'mnuRadIARoot', 60,
    procedure
    begin
      FEditorHook.OnReviewExecute(nil);
    end));
end;

{ TRadIAEditorHook }

constructor TRadIAEditorHook.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBindingIndex := 0;
end;

destructor TRadIAEditorHook.Destroy;
begin
  Uninstall;
  inherited Destroy;
end;

procedure TRadIAEditorHook.Install;
var
  LKeyboardServices: IOTAKeyboardServices;
  LBinding: IOTAKeyboardBinding;
begin
  TLogger.Log('Installing editor local menu hooks via KeyboardBinding', 'EditorHook');
  if Supports(BorlandIDEServices, IOTAKeyboardServices, LKeyboardServices) then
  begin
    LBinding := TRadIAKeyboardBinding.Create(Self);
    FBindingIndex := LKeyboardServices.AddKeyboardBinding(LBinding);
    TLogger.Log(Format('KeyboardBinding registered with index %d', [FBindingIndex]), 'EditorHook');
  end;
end;

procedure TRadIAEditorHook.Uninstall;
var
  LKeyboardServices: IOTAKeyboardServices;
begin
  if FBindingIndex > 0 then
  begin
    TLogger.Log(Format('Uninstalling editor local menu hooks (index %d)', [FBindingIndex]), 'EditorHook');
    if Supports(BorlandIDEServices, IOTAKeyboardServices, LKeyboardServices) then
    begin
      LKeyboardServices.RemoveKeyboardBinding(FBindingIndex);
    end;
    FBindingIndex := 0;
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
