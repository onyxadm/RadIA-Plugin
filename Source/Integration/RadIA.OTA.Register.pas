unit RadIA.OTA.Register;

interface

uses
  System.SysUtils, System.Classes, ToolsAPI;

type
  { Wizard implementing IOTAWizard to register RadIA into Delphi IDE }
  TRadIAWizard = class(TInterfacedObject, IOTAWizard)
  private
    FEditorHook: TObject;
    procedure RegisterMenus;
    procedure UnregisterMenus;
    procedure OnRequestDiff(const AOriginalCode: string);
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
  Vcl.Menus, Vcl.Controls, Vcl.Forms, Vcl.Graphics, RadIA.OTA.EditorHook, RadIA.UI.DiffForm, RadIA.OTA.Helper, RadIA.Core.Types, RadIA.Core.Mediator;

var
  GWizardIndex: Integer = -1;
  GAboutBoxIndex: Integer = -1;
  LAboutServices: IOTAAboutBoxServices;

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
begin
  if Supports(BorlandIDEServices, IOTAWizardServices, LWizardServices) then
  begin
    LOTAInstance := TRadIAWizard.Create;
    GWizardIndex := LWizardServices.AddWizard(LOTAInstance);
  end;
  RegisterSplashAndAbout;
end;

{ TRadIAWizard }

constructor TRadIAWizard.Create;
begin
  inherited Create;
  FEditorHook := TRadIAEditorHook.Create(nil);
  RegisterMenus;
  TRadIAMediator.Instance.RegisterDiffHandler(OnRequestDiff);
end;

destructor TRadIAWizard.Destroy;
begin
  TRadIAMediator.Instance.UnregisterDiffHandler;
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
  Result := 'RadIA.DelphiAIPlugin.Wizard';
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

procedure TRadIAWizard.RegisterMenus;
var
  LNTAServices: INTAServices;
  LToolsMenu: TMenuItem;
  LPopupMenu: TComponent;
begin
  if Supports(BorlandIDEServices, INTAServices, LNTAServices) then
  begin
    { Register tools actions }
    LToolsMenu := LNTAServices.MainMenu.Items.Find('Tools');
    if Assigned(LToolsMenu) then
    begin
      TRadIAEditorHook(FEditorHook).PopulateToolsMenu(LToolsMenu);
    end;
    
    { Register editor context menu }
    LPopupMenu := Application.FindComponent('EditorContextMenu');
    if (LPopupMenu <> nil) and (LPopupMenu is TPopupMenu) then
    begin
      TRadIAEditorHook(FEditorHook).PopulateContextMenu(TPopupMenu(LPopupMenu));
    end;
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
  if not Assigned(FEditorHook) then
    Exit;
    
  LHook := TRadIAEditorHook(FEditorHook);
  if Supports(BorlandIDEServices, INTAServices, LNTAServices) then
  begin
    LToolsMenu := LNTAServices.MainMenu.Items.Find('Tools');
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
