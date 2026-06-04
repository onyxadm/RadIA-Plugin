unit RadIA.OTA.Register;

interface

uses
  System.SysUtils, System.Classes, ToolsAPI, Vcl.ExtCtrls;

type
  { Wizard implementing IOTAWizard to register RadIA into Delphi IDE }
  TRadIAWizard = class(TInterfacedObject, IOTAWizard)
  private
    FEditorHook: TObject;
    FTimer: TTimer;
    procedure RegisterMenus;
    procedure UnregisterMenus;
    procedure OnRequestDiff(const AOriginalCode: string);
    procedure OnTimerEvent(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    
    { IOTANotifier implementation }
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
    
    { IOTAWizard implementation }
    function GetName: string;
    function GetIDString: string;
    function GetState: TWizardState;
    procedure Execute;
  end;

procedure Register;

implementation

uses
  Vcl.Menus, Vcl.Controls, Vcl.Forms, Vcl.Graphics, RadIA.OTA.EditorHook, RadIA.UI.DiffForm, 
  RadIA.UI.ConfigFrame, RadIA.OTA.Helper, RadIA.Core.Types, RadIA.Core.Mediator, RadIA.Core.Config, RadIA.OTA.DockableForm;

var
  GWizardIndex: Integer = -1;
  GAboutBoxIndex: Integer = -1;
  LAboutServices: IOTAAboutBoxServices;

procedure LogDebug(const AMsg: string);
var
  LFolder: string;
  LFile: string;
  LStream: TFileStream;
  LWriter: TStreamWriter;
  LText: string;
begin
  try
    LFolder := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) + 'RadIA';
    ForceDirectories(LFolder);
    LFile := LFolder + '\log.txt';
    
    if FileExists(LFile) then
      LStream := TFileStream.Create(LFile, fmOpenWrite or fmShareDenyNone)
    else
      LStream := TFileStream.Create(LFile, fmCreate or fmShareDenyNone);
      
    try
      LStream.Seek(0, soEnd);
      LWriter := TStreamWriter.Create(LStream, TEncoding.UTF8);
      try
        LText := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' - ' + AMsg;
        LWriter.WriteLine(LText);
      finally
        LWriter.Free;
      end;
    finally
      LStream.Free;
    end;
  except
    // Silently capture any file access exception to prevent IDE crash on plugin start
  end;
end;

procedure RegisterSplashAndAbout;
var
  LBitmap: TBitmap;
begin
  LBitmap := TBitmap.Create;
  try
    LBitmap.PixelFormat := pf24bit;
    LBitmap.Width := 24;
    LBitmap.Height := 24;
    
    // Fundo azul escuro (#0F172A -> BGR $002A170F)
    LBitmap.Canvas.Brush.Color := $002A170F;
    LBitmap.Canvas.FillRect(Rect(0, 0, 24, 24));
    
    // Cabeça do robô cinza claro (#D1D5DB -> BGR $00DBD5D1)
    LBitmap.Canvas.Pen.Color := $00DBD5D1;
    LBitmap.Canvas.Brush.Color := $00DBD5D1;
    LBitmap.Canvas.RoundRect(4, 6, 20, 18, 4, 4);
    
    // Antena
    LBitmap.Canvas.Pen.Color := $00DBD5D1;
    LBitmap.Canvas.MoveTo(12, 6);
    LBitmap.Canvas.LineTo(12, 3);
    LBitmap.Canvas.Brush.Color := $00CC7A00; // Azul RadIA (#007ACC -> BGR $00CC7A00)
    LBitmap.Canvas.Ellipse(10, 1, 14, 5);
    
    // Olhos azuis brilhantes (#3B82F6 -> BGR $00F6823B)
    LBitmap.Canvas.Brush.Color := $00F6823B;
    LBitmap.Canvas.Pen.Color := $00F6823B;
    LBitmap.Canvas.Ellipse(7, 10, 10, 13);
    LBitmap.Canvas.Ellipse(14, 10, 17, 13);
    
    // Boca
    LBitmap.Canvas.Pen.Color := $009CA3AF;
    LBitmap.Canvas.MoveTo(9, 15);
    LBitmap.Canvas.LineTo(15, 15);

    { 1. Registrar na Splash Screen se disponível }
    if Assigned(SplashScreenServices) then
    begin
      SplashScreenServices.AddPluginBitmap(
        'RadIA AI Assistant',
        LBitmap.Handle,
        False,
        'Open Source (BYOK)'
      );
    end;

    { 2. Registrar no About Box se disponível }
    if Supports(BorlandIDEServices, IOTAAboutBoxServices, LAboutServices) then
    begin
      GAboutBoxIndex := LAboutServices.AddPluginInfo(
        'RadIA AI Assistant',
        'RadIA - AI Assistant for Delphi IDE' + sLineBreak +
        'Provides sidebar chat, code refactoring, context parsing, and smart diff.' + sLineBreak +
        'Copyright (c) 2026 RadIA Open Source Project',
        LBitmap.Handle,
        False,
        'Apache 2.0 License',
        'v0.0.1'
      );
    end;
  finally
    LBitmap.Free;
  end;
end;

procedure Register;
var
  LOTAInstance: IOTAWizard;
  LWizardServices: IOTAWizardServices;
  LOTAServices: IOTAServices;
begin
  LogDebug('Register called');
  if not Assigned(BorlandIDEServices) then
  begin
    LogDebug('Error: BorlandIDEServices is nil');
    Exit;
  end;

  if Supports(BorlandIDEServices, IOTAServices, LOTAServices) then
  begin
    TRadIAConfig.SetBaseRegistryPath(LOTAServices.GetBaseRegistryKey + '\RadIA');
  end;

  if Supports(BorlandIDEServices, IOTAWizardServices, LWizardServices) then
  begin
    LogDebug('IOTAWizardServices supported');
    try
      LOTAInstance := TRadIAWizard.Create;
      GWizardIndex := LWizardServices.AddWizard(LOTAInstance);
      LogDebug(Format('Wizard added successfully with index: %d', [GWizardIndex]));
    except
      on E: Exception do
        LogDebug('Exception during Wizard creation: ' + E.Message);
    end;
  end
  else
  begin
    LogDebug('Error: IOTAWizardServices NOT supported');
  end;
  RegisterSplashAndAbout;
end;

{ TRadIAWizard }

constructor TRadIAWizard.Create;
var
  LThemingServices: IOTAIDEThemingServices;
begin
  LogDebug('TRadIAWizard.Create called');
  inherited Create;
  
  { Register custom forms in IDE Theming Services }
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    LThemingServices.RegisterFormClass(TFormAIDiff);
    LThemingServices.RegisterFormClass(TFormAIConfig);
    LThemingServices.RegisterFormClass(TFormRadIADockable);
  end;
  
  FEditorHook := TRadIAEditorHook.Create(nil);
  RegisterMenus;
  
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 1000;
  FTimer.OnTimer := OnTimerEvent;
  FTimer.Enabled := True;
  
  TRadIAMediator.Instance.RegisterDiffHandler(OnRequestDiff);
end;

destructor TRadIAWizard.Destroy;
begin
  TRadIAMediator.Instance.UnregisterDiffHandler;
  if Assigned(FTimer) then
  begin
    FTimer.Enabled := False;
    FTimer.Free;
  end;
  UnregisterMenus;
  FEditorHook.Free;
  inherited Destroy;
end;

procedure TRadIAWizard.AfterSave;
begin
end;

procedure TRadIAWizard.BeforeSave;
begin
end;

procedure TRadIAWizard.Destroyed;
begin
end;

procedure TRadIAWizard.Modified;
begin
end;

function TRadIAWizard.GetIDString: string;
begin
  Result := 'RadIA.Wizard.Main';
end;

function TRadIAWizard.GetName: string;
begin
  Result := 'RadIA';
end;

function TRadIAWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

procedure TRadIAWizard.Execute;
begin
  // Handled on menu and context clicks, nothing to execute on start
end;

procedure TRadIAWizard.OnRequestDiff(const AOriginalCode: string);
var
  LForm: TFormAIDiff;
  LActiveFile: string;
  LEditBuffer: IOTAEditBuffer;
begin
  LForm := TFormAIDiff.Create(nil);
  try
    LEditBuffer := TRadIAOTAHelper.GetCurrentEditBuffer;
    if Assigned(LEditBuffer) then
      LActiveFile := LEditBuffer.FileName
    else
      LActiveFile := 'ActiveUnit.pas';
      
    LForm.InitializeDiff(ExtractFileName(LActiveFile), AOriginalCode);
    if LForm.ShowModal = mrOk then
    begin
      TRadIAOTAHelper.ReplaceActiveEditorText(LForm.SuggestedCode);
    end;
  finally
    LForm.Free;
  end;
end;

function FindToolsMenu(const AMainMenu: TMainMenu): TMenuItem;
var
  I: Integer;
  LCaption: string;
begin
  Result := nil;
  if not Assigned(AMainMenu) then
    Exit;

  // 1. Busca pelo nome do componente (independe de tradução)
  for I := 0 to AMainMenu.Items.Count - 1 do
  begin
    if SameText(AMainMenu.Items[I].Name, 'ToolsMenu') or 
       SameText(AMainMenu.Items[I].Name, 'Tools') then
    begin
      Result := AMainMenu.Items[I];
      Exit;
    end;
  end;

  // 2. Fallbacks de Caption usando buscas exatas limpas de atalhos (&)
  for I := 0 to AMainMenu.Items.Count - 1 do
  begin
    LCaption := StringReplace(AMainMenu.Items[I].Caption, '&', '', [rfReplaceAll]);
    if SameText(LCaption, 'Tools') or 
       SameText(LCaption, 'Ferramentas') or 
       SameText(LCaption, 'ToolsMenu') then
    begin
      Result := AMainMenu.Items[I];
      Exit;
    end;
  end;

  // 3. Fallback clássico da Open Tools API
  Result := AMainMenu.Items.Find('Tools');
end;

procedure TRadIAWizard.RegisterMenus;
var
  LNTAServices: INTAServices;
  LToolsMenu: TMenuItem;
  LPopupMenu: TComponent;
  I: Integer;
  LToolsAlreadyPopulated: Boolean;
  LContextAlreadyPopulated: Boolean;
  LHook: TRadIAEditorHook;
begin
  LogDebug('RegisterMenus called');
  LToolsAlreadyPopulated := False;
  LContextAlreadyPopulated := False;
  LHook := TRadIAEditorHook(FEditorHook);

  if Supports(BorlandIDEServices, INTAServices, LNTAServices) then
  begin
    LogDebug('INTAServices supported');
    
    { Register tools actions }
    LToolsMenu := FindToolsMenu(LNTAServices.MainMenu);
    if Assigned(LToolsMenu) then
    begin
      for I := 0 to LToolsMenu.Count - 1 do
      begin
        if (LToolsMenu.Items[I].Action = LHook.ShowChatAction) or 
           (LToolsMenu.Items[I].Action = LHook.FixErrorAction) then
        begin
          LToolsAlreadyPopulated := True;
          Break;
        end;
      end;

      if not LToolsAlreadyPopulated then
      begin
        LogDebug('Tools/Ferramentas menu found');
        LHook.PopulateToolsMenu(LToolsMenu);
        LogDebug('Tools menu populated');
      end;
    end
    else
    begin
      LogDebug('Error: Tools/Ferramentas menu NOT found');
    end;
    
    { Register editor context menu }
    LPopupMenu := Application.FindComponent('EditorContextMenu');
    if (LPopupMenu <> nil) and (LPopupMenu is TPopupMenu) then
    begin
      for I := 0 to TPopupMenu(LPopupMenu).Items.Count - 1 do
      begin
        if SameText(TPopupMenu(LPopupMenu).Items[I].Caption, '🤖 RadIA') then
        begin
          LContextAlreadyPopulated := True;
          Break;
        end;
      end;

      if not LContextAlreadyPopulated then
      begin
        LogDebug('EditorContextMenu found');
        LHook.PopulateContextMenu(TPopupMenu(LPopupMenu));
        LogDebug('Editor context menu populated');
      end;
    end
    else
    begin
      LogDebug('Warning: EditorContextMenu NOT found');
    end;
  end
  else
  begin
    LogDebug('Error: INTAServices NOT supported');
  end;
end;

procedure TRadIAWizard.OnTimerEvent(Sender: TObject);
var
  LNTAServices: INTAServices;
  LToolsMenu: TMenuItem;
  LPopupMenu: TComponent;
  LToolsPopulated, LContextPopulated: Boolean;
  I: Integer;
  LHook: TRadIAEditorHook;
begin
  LToolsPopulated := False;
  LContextPopulated := False;
  LHook := TRadIAEditorHook(FEditorHook);

  if Supports(BorlandIDEServices, INTAServices, LNTAServices) then
  begin
    // 1. Verificar e popular o menu Tools
    LToolsMenu := FindToolsMenu(LNTAServices.MainMenu);
    if Assigned(LToolsMenu) then
    begin
      for I := 0 to LToolsMenu.Count - 1 do
      begin
        if (LToolsMenu.Items[I].Action = LHook.ShowChatAction) or 
           (LToolsMenu.Items[I].Action = LHook.FixErrorAction) then
        begin
          LToolsPopulated := True;
          Break;
        end;
      end;

      if not LToolsPopulated then
      begin
        LogDebug('Tools menu not populated or reset. Populating now...');
        LHook.PopulateToolsMenu(LToolsMenu);
        LToolsPopulated := True;
        LogDebug('Tools menu populated successfully');
      end;
    end;
    
    // 2. Verificar e popular o menu de contexto do Editor
    LPopupMenu := Application.FindComponent('EditorContextMenu');
    if (LPopupMenu <> nil) and (LPopupMenu is TPopupMenu) then
    begin
      for I := 0 to TPopupMenu(LPopupMenu).Items.Count - 1 do
      begin
        if SameText(TPopupMenu(LPopupMenu).Items[I].Caption, '🤖 RadIA') then
        begin
          LContextPopulated := True;
          Break;
        end;
      end;

      if not LContextPopulated then
      begin
        LogDebug('EditorContextMenu not populated. Populating now...');
        LHook.PopulateContextMenu(TPopupMenu(LPopupMenu));
        LContextPopulated := True;
        LogDebug('EditorContextMenu populated successfully');
      end;
    end;
  end;

  // Desliga o timer assim que ambos estiverem populados
  if LToolsPopulated and LContextPopulated then
  begin
    LogDebug('Both menus populated. Disabling timer.');
    FTimer.Enabled := False;
  end;
end;

procedure TRadIAWizard.UnregisterMenus;
var
  LNTAServices: INTAServices;
  LToolsMenu: TMenuItem;
  LPopupMenu: TComponent;
  I: Integer;
  LHook: TRadIAEditorHook;
begin
  LogDebug('UnregisterMenus called');
  if not Assigned(FEditorHook) then
    Exit;
    
  LHook := TRadIAEditorHook(FEditorHook);
  if Supports(BorlandIDEServices, INTAServices, LNTAServices) then
  begin
    LToolsMenu := FindToolsMenu(LNTAServices.MainMenu);
    if Assigned(LToolsMenu) then
    begin
      for I := LToolsMenu.Count - 1 downto 0 do
      begin
        if (LToolsMenu.Items[I].Action = LHook.ShowChatAction) or
           (LToolsMenu.Items[I].Action = LHook.FixErrorAction) then
        begin
          LToolsMenu.Items[I].Free;
        end;
      end;
    end;
    
    { Unregister editor context menu }
    LPopupMenu := Application.FindComponent('EditorContextMenu');
    if (LPopupMenu <> nil) and (LPopupMenu is TPopupMenu) then
    begin
      for I := TPopupMenu(LPopupMenu).Items.Count - 1 downto 0 do
      begin
        if SameText(TPopupMenu(LPopupMenu).Items[I].Caption, '🤖 RadIA') then
        begin
          TPopupMenu(LPopupMenu).Items[I].Free;
        end;
      end;
    end;
  end;
end;

initialization

finalization
  if (GWizardIndex <> -1) and Assigned(BorlandIDEServices) then
  begin
    // Unload the wizard if the BPL is uninstalled
    (BorlandIDEServices as IOTAWizardServices).RemoveWizard(GWizardIndex);
  end;

  if (GAboutBoxIndex <> -1) and Assigned(BorlandIDEServices) then
  begin
    if Supports(BorlandIDEServices, IOTAAboutBoxServices, LAboutServices) then
    begin
      LAboutServices.RemovePluginInfo(GAboutBoxIndex);
    end;
  end;

end.
