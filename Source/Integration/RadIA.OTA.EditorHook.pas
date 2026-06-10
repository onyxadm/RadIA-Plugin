unit RadIA.OTA.EditorHook;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, Vcl.Menus, Vcl.Dialogs, Vcl.Forms, Vcl.ExtCtrls, ToolsAPI;

type
  { Manager to create and handle RadIA IDE contextual actions }
  TRadIAEditorHook = class(TComponent)
  private
    FOldActiveFormChange: TNotifyEvent;
    FInstalled: Boolean;
    FIDENotifierIndex: Integer;
    FEditorNotifiers: TInterfaceList;
    {$IFNDEF TESTS}
    FTimer: TTimer;
    FHookPending: Boolean;
    FHookRequestedAt: UInt64;
    {$ENDIF}
    
    procedure ActiveFormChange(Sender: TObject);
    procedure QueueHookActiveEditor;
    {$IFNDEF TESTS}
    procedure HookEditorWindowsNow;
    {$ENDIF}
    procedure InstallEditorNotifiers;
    procedure RemoveEditorNotifiers;
    procedure TryAddSourceEditorNotifier(const ASourceEditor: IOTASourceEditor);
    {$IFNDEF TESTS}
    procedure HookPopupMenu(AForm: TCustomForm);
    {$ENDIF}
    procedure UnhookPopupMenu(AForm: TCustomForm);
    procedure HookControlPopupMenus(AControl: TControl);
    procedure UnhookControlPopupMenus(AControl: TControl);
    function FindEditorPopupMenu(AParent: TComponent): TPopupMenu;
    function IsEditorPopupMenu(APopupMenu: TPopupMenu): Boolean;
    procedure EditorMenuPopup(Sender: TObject);
    procedure InjectMenuIntoPopupMenu(APopupMenu: TPopupMenu);
    procedure RemoveMenuFromPopupMenu(APopupMenu: TPopupMenu);
    function FindMenuItemByName(const AItems: TMenuItem; const AName: string): TMenuItem;

    procedure OnExplainExecute(Sender: TObject);
    procedure OnOptimizeExecute(Sender: TObject);
    procedure OnTestsExecute(Sender: TObject);
    procedure OnBugsExecute(Sender: TObject);
    procedure OnDocExecute(Sender: TObject);
    procedure OnReviewExecute(Sender: TObject);
    procedure OnFixErrorExecute(Sender: TObject);
    procedure OnShowChatExecute(Sender: TObject);

    procedure SendCommandToChat(const ACommand: string; const APromptPrefix: string);
    {$IFNDEF TESTS}
    procedure RequestDelayedHook;
    procedure OnTimerEvent(Sender: TObject);
    {$ENDIF}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure Install;
    procedure Uninstall;
    procedure PopulateToolsMenu(const AMenuItem: TMenuItem);
    
    procedure HookMenuDirectly(APopupMenu: TPopupMenu);
    procedure UnhookMenuDirectly(APopupMenu: TPopupMenu);
  end;

implementation

uses
  System.Generics.Collections,
  Winapi.Windows,
  RadIA.OTA.Helper, RadIA.OTA.ContextParser, RadIA.OTA.MessageViewHook, RadIA.Core.Types,
  RadIA.Core.Mediator,
  {$IFNDEF TESTS}
  RadIA.OTA.DockableForm,
  {$ENDIF}
  RadIA.Core.Logger;

const
  CEditorHookDelayMs = 1200;

{$IFDEF TESTS}
procedure ShowRadIAChat;
begin
  // Stub for unit tests to avoid pulling VCL Forms/WebView2 components
end;
{$ENDIF}

var
  // Global dictionary to track original OnPopup events for intercepted menus
  FInterceptedMenus: TDictionary<TPopupMenu, TNotifyEvent> = nil;

threadvar
  GExecutingPopup: Boolean;

type
  TRadIAIDEEditorNotifier = class(TNotifierObject, IOTAIDENotifier)
  private
    FHook: TRadIAEditorHook;
  public
    constructor Create(AHook: TRadIAEditorHook);
    procedure FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var Cancel: Boolean);
    procedure BeforeCompile(const Project: IOTAProject; var Cancel: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean); overload;
  end;

  TRadIASourceEditorNotifier = class(TNotifierObject, IOTANotifier, IOTAEditorNotifier)
  private
    FHook: TRadIAEditorHook;
    FSourceEditor: IOTASourceEditor;
    FIndex: Integer;
    procedure RemoveNotifier;
  public
    constructor Create(AHook: TRadIAEditorHook; const ASourceEditor: IOTASourceEditor);
    destructor Destroy; override;
    procedure Destroyed;
    procedure ViewActivated(const View: IOTAEditView);
    procedure ViewNotification(const View: IOTAEditView; Operation: TOperation);
  end;

  TControlAccess = class(TControl);

{ TRadIAIDEEditorNotifier }

constructor TRadIAIDEEditorNotifier.Create(AHook: TRadIAEditorHook);
begin
  inherited Create;
  FHook := AHook;
end;

procedure TRadIAIDEEditorNotifier.AfterCompile(Succeeded: Boolean);
begin
end;

procedure TRadIAIDEEditorNotifier.BeforeCompile(const Project: IOTAProject; var Cancel: Boolean);
begin
  Cancel := False;
end;

procedure TRadIAIDEEditorNotifier.FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var Cancel: Boolean);
var
  LModuleServices: IOTAModuleServices;
  LModule: IOTAModule;
  LSourceEditor: IOTASourceEditor;
  I: Integer;
begin
  Cancel := False;
  if NotifyCode <> ofnFileOpened then
    Exit;

  if not SameText(ExtractFileExt(FileName), '.pas') then
    Exit;

  if not Assigned(FHook) then
    Exit;

  if Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) then
  begin
    LModule := LModuleServices.FindModule(FileName);
    if Assigned(LModule) then
    begin
      for I := 0 to LModule.GetModuleFileCount - 1 do
      begin
        if Supports(LModule.GetModuleFileEditor(I), IOTASourceEditor, LSourceEditor) then
          FHook.TryAddSourceEditorNotifier(LSourceEditor);
      end;
    end;
  end;

  FHook.QueueHookActiveEditor;
end;

{ TRadIASourceEditorNotifier }

constructor TRadIASourceEditorNotifier.Create(AHook: TRadIAEditorHook; const ASourceEditor: IOTASourceEditor);
begin
  inherited Create;
  FHook := AHook;
  FSourceEditor := ASourceEditor;
  FIndex := -1;
  if Assigned(FSourceEditor) then
    FIndex := FSourceEditor.AddNotifier(Self);
end;

destructor TRadIASourceEditorNotifier.Destroy;
begin
  RemoveNotifier;
  inherited Destroy;
end;

procedure TRadIASourceEditorNotifier.Destroyed;
begin
  RemoveNotifier;
end;

procedure TRadIASourceEditorNotifier.RemoveNotifier;
begin
  if Assigned(FSourceEditor) and (FIndex >= 0) then
  begin
    FSourceEditor.RemoveNotifier(FIndex);
    FIndex := -1;
    FSourceEditor := nil;
  end;
end;

procedure TRadIASourceEditorNotifier.ViewActivated(const View: IOTAEditView);
begin
  if Assigned(FHook) then
    FHook.QueueHookActiveEditor;
end;

procedure TRadIASourceEditorNotifier.ViewNotification(const View: IOTAEditView; Operation: TOperation);
begin
  if (Operation = opInsert) and Assigned(FHook) then
    FHook.QueueHookActiveEditor;
end;

{ TRadIAEditorHook }

constructor TRadIAEditorHook.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOldActiveFormChange := nil;
  FIDENotifierIndex := -1;
  FEditorNotifiers := TInterfaceList.Create;
  {$IFNDEF TESTS}
  FTimer := nil;
  FHookPending := False;
  FHookRequestedAt := 0;
  {$ENDIF}
  FInstalled := False;
end;

destructor TRadIAEditorHook.Destroy;
begin
  Uninstall;
  FEditorNotifiers.Free;
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
  InstallEditorNotifiers;

{$IFNDEF TESTS}
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 250;
  FTimer.OnTimer := OnTimerEvent;
  FTimer.Enabled := True;
{$ENDIF}

  FInstalled := True;
  QueueHookActiveEditor;
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

  {$IFNDEF TESTS}
  if Assigned(FTimer) then
  begin
    FTimer.Enabled := False;
    FreeAndNil(FTimer);
  end;
  {$ENDIF}

  if Assigned(Screen) and (not GIsShuttingDown) then
  begin
    try
      Screen.OnActiveFormChange := FOldActiveFormChange;
    except
      on E: Exception do
        TLogger.Log('Uninstall: Error restoring Screen.OnActiveFormChange: ' + E.Message, 'EditorHook');
    end;
  end;
  
  FInstalled := False;
  RemoveEditorNotifiers;
    
  if Assigned(Screen) and (not GIsShuttingDown) then
  begin
    for I := 0 to Screen.FormCount - 1 do
    begin
      try
        UnhookPopupMenu(Screen.Forms[I]);
      except
        on E: Exception do
          TLogger.Log('Uninstall: Error unhooking form menu: ' + E.Message, 'EditorHook');
      end;
    end;
  end;

  if Assigned(FInterceptedMenus) then
  begin
    try
      // Restore menus only outside shutdown because IDE-owned menus may already be destroyed.
      if not GIsShuttingDown then
      begin
        for LMenu in FInterceptedMenus.Keys do
        begin
          try
            LOldOnPopup := FInterceptedMenus.Items[LMenu];
            LMenu.OnPopup := LOldOnPopup;
            RemoveMenuFromPopupMenu(LMenu);
          except
            on E: Exception do
              TLogger.Log('Uninstall: Error restoring popup menu: ' + E.Message, 'EditorHook');
          end;
        end;
      end;
    finally
      FInterceptedMenus.Clear;
      FreeAndNil(FInterceptedMenus);
    end;
  end;
end;

procedure TRadIAEditorHook.ActiveFormChange(Sender: TObject);
var
  LActiveForm: TCustomForm;
begin
  if Assigned(FOldActiveFormChange) then
  begin
    try
      FOldActiveFormChange(Sender);
    except
      on E: Exception do
        TLogger.Log('ActiveFormChange: Error executing original OnActiveFormChange: ' + E.Message, 'EditorHook');
    end;
  end;

  try
    if Assigned(Screen) then
    begin
      LActiveForm := Screen.ActiveForm;
      if Assigned(LActiveForm) and SameText(LActiveForm.ClassName, 'TEditWindow') then
        QueueHookActiveEditor;
    end;
  except
    on E: Exception do
      TLogger.Log('ActiveFormChange: General error: ' + E.Message, 'EditorHook');
  end;
end;

procedure TRadIAEditorHook.QueueHookActiveEditor;
begin
  {$IFDEF TESTS}
  Exit;
  {$ELSE}
  TThread.Queue(nil,
    TThreadProcedure(
    procedure begin
      RequestDelayedHook;
    end));
  {$ENDIF}
end;

{$IFNDEF TESTS}
procedure TRadIAEditorHook.HookEditorWindowsNow;
var
  I: Integer;
begin
  if (not FInstalled) or GIsShuttingDown then
    Exit;

  if Assigned(Screen) and Assigned(Screen.ActiveForm) then
  begin
    try
      HookPopupMenu(Screen.ActiveForm);
    except
      on E: Exception do
        TLogger.Log('HookEditorWindowsNow: Error hooking active form: ' + E.Message, 'EditorHook');
    end;
  end;

  if Assigned(Screen) then
  begin
    for I := 0 to Screen.FormCount - 1 do
    begin
      if SameText(Screen.Forms[I].ClassName, 'TEditWindow') and
         Screen.Forms[I].HandleAllocated and Screen.Forms[I].Visible then
      begin
        try
          HookPopupMenu(Screen.Forms[I]);
        except
          on E: Exception do
            TLogger.Log('HookEditorWindowsNow: Error hooking editor window: ' + E.Message, 'EditorHook');
        end;
      end;
    end;
  end;
end;
{$ENDIF}

procedure TRadIAEditorHook.InstallEditorNotifiers;
var
  LOTAServices: IOTAServices;
  LModuleServices: IOTAModuleServices;
  LModule: IOTAModule;
  LSourceEditor: IOTASourceEditor;
  I: Integer;
  J: Integer;
begin
  {$IFDEF TESTS}
  Exit;
  {$ENDIF}

  if FIDENotifierIndex < 0 then
  begin
    if Supports(BorlandIDEServices, IOTAServices, LOTAServices) then
      FIDENotifierIndex := LOTAServices.AddNotifier(TRadIAIDEEditorNotifier.Create(Self));
  end;

  if Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) then
  begin
    for I := 0 to LModuleServices.ModuleCount - 1 do
    begin
      LModule := LModuleServices.Modules[I];
      if not Assigned(LModule) then
        Continue;

      for J := 0 to LModule.GetModuleFileCount - 1 do
      begin
        if Supports(LModule.GetModuleFileEditor(J), IOTASourceEditor, LSourceEditor) and
           SameText(ExtractFileExt(LSourceEditor.FileName), '.pas') then
        begin
          TryAddSourceEditorNotifier(LSourceEditor);
        end;
      end;
    end;
  end;
end;

procedure TRadIAEditorHook.RemoveEditorNotifiers;
var
  LOTAServices: IOTAServices;
begin
  {$IFDEF TESTS}
  Exit;
  {$ENDIF}

  FEditorNotifiers.Clear;

  if (FIDENotifierIndex >= 0) and Supports(BorlandIDEServices, IOTAServices, LOTAServices) then
  begin
    try
      LOTAServices.RemoveNotifier(FIDENotifierIndex);
    except
      on E: Exception do
        TLogger.Log('RemoveEditorNotifiers: Error removing IDE notifier: ' + E.Message, 'EditorHook');
    end;
    FIDENotifierIndex := -1;
  end;
end;

procedure TRadIAEditorHook.TryAddSourceEditorNotifier(const ASourceEditor: IOTASourceEditor);
var
  LNotifier: IOTAEditorNotifier;
begin
  {$IFDEF TESTS}
  Exit;
  {$ENDIF}

  if not Assigned(ASourceEditor) then
    Exit;

  try
    LNotifier := TRadIASourceEditorNotifier.Create(Self, ASourceEditor);
    FEditorNotifiers.Add(LNotifier);
  except
    on E: Exception do
      TLogger.Log('TryAddSourceEditorNotifier: Error adding source editor notifier: ' + E.Message, 'EditorHook');
  end;
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

function TRadIAEditorHook.IsEditorPopupMenu(APopupMenu: TPopupMenu): Boolean;
  function HasCaption(const AItem: TMenuItem; const ACaption: string): Boolean;
  var
    I: Integer;
    LCaption: string;
  begin
    Result := False;
    if not Assigned(AItem) then
      Exit;

    for I := 0 to AItem.Count - 1 do
    begin
      LCaption := StringReplace(AItem[I].Caption, '&', '', [rfReplaceAll]);
      if SameText(LCaption, ACaption) then
        Exit(True);

      if HasCaption(AItem[I], ACaption) then
        Exit(True);
    end;
  end;
begin
  Result := False;
  if not Assigned(APopupMenu) then
    Exit;

  if SameText(APopupMenu.Name, 'EditorLocalMenu') then
    Exit(True);

  Result :=
    HasCaption(APopupMenu.Items, 'Cut') or
    HasCaption(APopupMenu.Items, 'Copy') or
    HasCaption(APopupMenu.Items, 'Paste') or
    HasCaption(APopupMenu.Items, 'Select All') or
    HasCaption(APopupMenu.Items, 'Editor Options') or
    HasCaption(APopupMenu.Items, 'Read Only');
end;

{$IFNDEF TESTS}
procedure TRadIAEditorHook.HookPopupMenu(AForm: TCustomForm);
var
  LPopupMenu: TPopupMenu;
  I: Integer;
begin
  if not Assigned(AForm) then
    Exit;

  // Only hook editor windows to avoid side effects while other IDE forms are being created.
  if not SameText(AForm.ClassName, 'TEditWindow') then
    Exit;

  if (not AForm.HandleAllocated) or (not AForm.Visible) then
    Exit;

  LPopupMenu := FindEditorPopupMenu(AForm);
  if Assigned(LPopupMenu) then
    HookMenuDirectly(LPopupMenu);

  HookControlPopupMenus(AForm);

  for I := 0 to AForm.ComponentCount - 1 do
  begin
    if AForm.Components[I] is TPopupMenu then
      HookMenuDirectly(TPopupMenu(AForm.Components[I]));
  end;
end;
{$ENDIF}

procedure TRadIAEditorHook.UnhookPopupMenu(AForm: TCustomForm);
var
  LPopupMenu: TPopupMenu;
  I: Integer;
begin
  if not Assigned(AForm) then
    Exit;

  if not SameText(AForm.ClassName, 'TEditWindow') then
    Exit;

  if not AForm.HandleAllocated then
    Exit;

  LPopupMenu := FindEditorPopupMenu(AForm);
  if Assigned(LPopupMenu) then
    UnhookMenuDirectly(LPopupMenu);

  UnhookControlPopupMenus(AForm);

  for I := 0 to AForm.ComponentCount - 1 do
  begin
    if AForm.Components[I] is TPopupMenu then
      UnhookMenuDirectly(TPopupMenu(AForm.Components[I]));
  end;
end;

procedure TRadIAEditorHook.HookControlPopupMenus(AControl: TControl);
var
  I: Integer;
  LWinControl: TWinControl;
begin
  if not Assigned(AControl) then
    Exit;

  if Assigned(TControlAccess(AControl).PopupMenu) then
    HookMenuDirectly(TControlAccess(AControl).PopupMenu);

  if AControl is TWinControl then
  begin
    LWinControl := TWinControl(AControl);
    for I := 0 to LWinControl.ControlCount - 1 do
      HookControlPopupMenus(LWinControl.Controls[I]);
  end;
end;

procedure TRadIAEditorHook.UnhookControlPopupMenus(AControl: TControl);
var
  I: Integer;
  LWinControl: TWinControl;
begin
  if not Assigned(AControl) then
    Exit;

  if Assigned(TControlAccess(AControl).PopupMenu) then
    UnhookMenuDirectly(TControlAccess(AControl).PopupMenu);

  if AControl is TWinControl then
  begin
    LWinControl := TWinControl(AControl);
    for I := 0 to LWinControl.ControlCount - 1 do
      UnhookControlPopupMenus(LWinControl.Controls[I]);
  end;
end;

procedure TRadIAEditorHook.HookMenuDirectly(APopupMenu: TPopupMenu);
var
  LEventHook: TNotifyEvent;
  LEventCurrent: TNotifyEvent;
  LMethodHook: TMethod;
  LMethodCurrent: TMethod;
begin
  if not Assigned(APopupMenu) then
    Exit;

  if not Assigned(FInterceptedMenus) then
    Exit;

  LEventHook := EditorMenuPopup;
  LMethodHook := TMethod(LEventHook);
  LEventCurrent := APopupMenu.OnPopup;
  LMethodCurrent := TMethod(LEventCurrent);

  // Re-hook when another extension or the IDE replaces our popup handler.
  if (LMethodCurrent.Code <> LMethodHook.Code) or (LMethodCurrent.Data <> LMethodHook.Data) then
  begin
    if FInterceptedMenus.ContainsKey(APopupMenu) then
    begin
      TLogger.Log('Re-hooking OnPopup of EditorLocalMenu - hook was overridden', 'EditorHook');
      FInterceptedMenus.AddOrSetValue(APopupMenu, LEventCurrent);
    end
    else
    begin
      TLogger.Log('Hooking OnPopup of EditorLocalMenu', 'EditorHook');
      FInterceptedMenus.Add(APopupMenu, LEventCurrent);
    end;
    
    APopupMenu.OnPopup := LEventHook;
  end;
end;

procedure TRadIAEditorHook.UnhookMenuDirectly(APopupMenu: TPopupMenu);
var
  LOldOnPopup: TNotifyEvent;
begin
  if not Assigned(APopupMenu) then
    Exit;

  if Assigned(FInterceptedMenus) and FInterceptedMenus.TryGetValue(APopupMenu, LOldOnPopup) then
  begin
    TLogger.Log('Unhooking OnPopup of EditorLocalMenu', 'EditorHook');
    APopupMenu.OnPopup := LOldOnPopup;
    FInterceptedMenus.Remove(APopupMenu);
    RemoveMenuFromPopupMenu(APopupMenu);
  end;
end;

procedure TRadIAEditorHook.EditorMenuPopup(Sender: TObject);
var
  LPopupMenu: TPopupMenu;
  LOldOnPopup: TNotifyEvent;
begin
  // Circuit breaker to avoid mutual recursion with other third-party popup hooks.
  if GExecutingPopup then
    Exit;

  GExecutingPopup := True;
  try
    try
      if Sender is TPopupMenu then
      begin
        LPopupMenu := TPopupMenu(Sender);

        if Assigned(FInterceptedMenus) and FInterceptedMenus.TryGetValue(LPopupMenu, LOldOnPopup) and Assigned(LOldOnPopup) then
        begin
          try
            LOldOnPopup(Sender);
          except
            on E: Exception do
              TLogger.Log('EditorMenuPopup: Error executing original OnPopup: ' + E.Message, 'EditorHook');
          end;
        end;

        if IsEditorPopupMenu(LPopupMenu) then
        begin
          try
            InjectMenuIntoPopupMenu(LPopupMenu);
          except
            on E: Exception do
              TLogger.Log('EditorMenuPopup: Error injecting RadIA menu: ' + E.Message, 'EditorHook');
          end;
        end
        else
          TLogger.Log('EditorMenuPopup: Skipping non-editor popup menu: ' + LPopupMenu.Name, 'EditorHook');
      end;
    except
      on E: Exception do
        TLogger.Log('EditorMenuPopup: General error: ' + E.Message, 'EditorHook');
    end;
  finally
    GExecutingPopup := False;
  end;
end;

function TRadIAEditorHook.FindMenuItemByName(const AItems: TMenuItem; const AName: string): TMenuItem;
var
  I: Integer;
begin
  Result := nil;
  if not Assigned(AItems) then
    Exit;

  for I := 0 to AItems.Count - 1 do
  begin
    if SameText(AItems[I].Name, AName) then
      Exit(AItems[I]);

    Result := FindMenuItemByName(AItems[I], AName);
    if Assigned(Result) then
      Exit;
  end;
end;

procedure TRadIAEditorHook.InjectMenuIntoPopupMenu(APopupMenu: TPopupMenu);
var
  LRootItem: TMenuItem;
  LSubItem: TMenuItem;
  LComp: TComponent;
begin
  if not Assigned(APopupMenu) then
    Exit;

  // Nothing to do if the RadIA menu is already present.
  if Assigned(FindMenuItemByName(APopupMenu.Items, 'mnuRadIARoot')) then
    Exit;

  // Remove orphaned owner components to avoid duplicate component names in the IDE.

  LComp := APopupMenu.FindComponent('mnuRadIARoot');
  if Assigned(LComp) then
  begin
    try
      LComp.Free;
    except
      on E: Exception do
        TLogger.Log('InjectMenuIntoPopupMenu: Error freeing orphaned mnuRadIARoot: ' + E.Message, 'EditorHook');
    end;
  end;

  LComp := APopupMenu.FindComponent('mnuRadIASeparator');
  if Assigned(LComp) then
  begin
    try
      LComp.Free;
    except
      on E: Exception do
        TLogger.Log('InjectMenuIntoPopupMenu: Error freeing orphaned mnuRadIASeparator: ' + E.Message, 'EditorHook');
    end;
  end;

  TLogger.Log('Injecting RadIA menu items into EditorLocalMenu', 'EditorHook');

  // Root Submenu Item
  LRootItem := TMenuItem.Create(APopupMenu);
  LRootItem.Name := 'mnuRadIARoot';
  LRootItem.Caption := 'RadIA';

  // Action Submenu Items - Owner MUST be LRootItem so they are automatically freed when LRootItem is freed
  LSubItem := TMenuItem.Create(LRootItem);
  LSubItem.Caption := 'Explain Selected Code';
  LSubItem.OnClick := OnExplainExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(LRootItem);
  LSubItem.Caption := 'Optimize/Refactor Code';
  LSubItem.OnClick := OnOptimizeExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(LRootItem);
  LSubItem.Caption := 'Generate Unit Tests (DUnitX)';
  LSubItem.OnClick := OnTestsExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(LRootItem);
  LSubItem.Caption := 'Locate Bugs/Memory Leaks';
  LSubItem.OnClick := OnBugsExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(LRootItem);
  LSubItem.Caption := 'Document Method (XML)';
  LSubItem.OnClick := OnDocExecute;
  LRootItem.Add(LSubItem);

  LSubItem := TMenuItem.Create(LRootItem);
  LSubItem.Caption := 'Review Active Unit (Leaks/SOLID)';
  LSubItem.OnClick := OnReviewExecute;
  LRootItem.Add(LSubItem);

  // Separator visual
  LSubItem := TMenuItem.Create(APopupMenu);
  LSubItem.Caption := '-';
  LSubItem.Name := 'mnuRadIASeparator';

  // Keep RadIA visible as the first editor action group.
  APopupMenu.Items.Insert(0, LRootItem);
  APopupMenu.Items.Insert(1, LSubItem);
end;

procedure TRadIAEditorHook.RemoveMenuFromPopupMenu(APopupMenu: TPopupMenu);
var
  LItem: TMenuItem;
begin
  if not Assigned(APopupMenu) then
    Exit;

  LItem := FindMenuItemByName(APopupMenu.Items, 'mnuRadIARoot');
  if Assigned(LItem) then
    LItem.Free;

  LItem := FindMenuItemByName(APopupMenu.Items, 'mnuRadIASeparator');
  if Assigned(LItem) then
    LItem.Free;
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

{$IFNDEF TESTS}
procedure TRadIAEditorHook.RequestDelayedHook;
begin
  if (not FInstalled) or GIsShuttingDown then
    Exit;

  FHookPending := True;
  FHookRequestedAt := GetTickCount64;
end;

procedure TRadIAEditorHook.OnTimerEvent(Sender: TObject);
var
  LActiveForm: TCustomForm;
begin
  if (not FInstalled) or GIsShuttingDown then
    Exit;

  if not FHookPending then
  begin
    if Assigned(Screen) then
    begin
      LActiveForm := Screen.ActiveForm;
      if Assigned(LActiveForm) and SameText(LActiveForm.ClassName, 'TEditWindow') then
        RequestDelayedHook;
    end;
    Exit;
  end;

  if GetTickCount64 - FHookRequestedAt < CEditorHookDelayMs then
    Exit;

  FHookPending := False;
  HookEditorWindowsNow;
end;
{$ENDIF}

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
