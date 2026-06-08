unit RadIA.OTA.DockableForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Win.Registry, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, DockForm, ToolsAPI,
  RadIA.UI.ChatFrame;

type
  TFormRadIADockable = class(TDockableForm)
  private
    FChatFrame: TFrameAIChat;
    procedure ApplyIDETheme;
    procedure LoadWindowSize;
    procedure SaveVisibilityState(const AVisible: Boolean);
  protected
    procedure DoShow; override;
    procedure DoHide; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

procedure ShowRadIAChat;
procedure RegisterDockableForm;
procedure UnregisterDockableForm;

var
  FormRadIADockable: TFormRadIADockable = nil;

implementation

uses
  DeskUtil, RadIA.Core.Config, RadIA.UI.Resources;

procedure ShowRadIAChat;
begin
  if not Assigned(FormRadIADockable) then
  begin
    FormRadIADockable := TFormRadIADockable.Create(nil);
  end;
  
  ShowDockableForm(FormRadIADockable);
end;

procedure RegisterDockableForm;
begin
  if @RegisterFieldAddress <> nil then
    RegisterFieldAddress('FormRadIADockable', @FormRadIADockable);
  RegisterDesktopFormClass(TFormRadIADockable, 'FormRadIADockable', 'FormRadIADockable');
end;

procedure UnregisterDockableForm;
begin
  if @UnRegisterFieldAddress <> nil then
    UnRegisterFieldAddress(@FormRadIADockable);
  if Assigned(FormRadIADockable) then
    FreeAndNil(FormRadIADockable);
end;

{ TFormRadIADockable }

constructor TFormRadIADockable.Create(AOwner: TComponent);
var
  LThemingServices: IOTAIDEThemingServices;
begin
  FormRadIADockable := Self;
  inherited Create(AOwner);
  Caption := 'RadIA Chat';
  Name := 'FormRadIADockable';
  DeskSection := 'FormRadIADockable';
  AutoSave := True;
  SaveStateNecessary := True;
  
  { Default dimensions for the first run or when floating }
  Width := 990;
  Height := 650;
  LoadWindowSize;
  
  FChatFrame := TFrameAIChat.Create(Self);
  FChatFrame.Parent := Self;
  FChatFrame.Align := alClient;
  
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LThemingServices.ApplyTheme(Self);
    end;
  end;
  
  ApplyIDETheme;
end;

procedure TFormRadIADockable.LoadWindowSize;
var
  LReg: TRegistry;
  LRegPath: string;
  LPositionLoaded: Boolean;
begin
  LPositionLoaded := False;
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    LRegPath := TRadIAConfig.GetRegistryPath;
    if LReg.OpenKeyReadOnly(LRegPath) then
    begin
      if LReg.ValueExists('WindowWidth') then
        Width := LReg.ReadInteger('WindowWidth');
      if LReg.ValueExists('WindowHeight') then
        Height := LReg.ReadInteger('WindowHeight');
      if LReg.ValueExists('WindowLeft') and LReg.ValueExists('WindowTop') then
      begin
        Left := LReg.ReadInteger('WindowLeft');
        Top := LReg.ReadInteger('WindowTop');
        LPositionLoaded := True;
      end;
      LReg.CloseKey;
    end;
  finally
    LReg.Free;
  end;

  if LPositionLoaded then
    Position := poDesigned
  else
    Position := poScreenCenter;
end;

destructor TFormRadIADockable.Destroy;
var
  LReg: TRegistry;
  LRegPath: string;
begin
  if Floating then
  begin
    LReg := TRegistry.Create;
    try
      LReg.RootKey := HKEY_CURRENT_USER;
      LRegPath := TRadIAConfig.GetRegistryPath;
      if LReg.OpenKey(LRegPath, True) then
      begin
        LReg.WriteInteger('WindowWidth', Width);
        LReg.WriteInteger('WindowHeight', Height);
        LReg.WriteInteger('WindowLeft', Left);
        LReg.WriteInteger('WindowTop', Top);
        LReg.CloseKey;
      end;
    finally
      LReg.Free;
    end;
  end;

  if FormRadIADockable = Self then
    FormRadIADockable := nil;
  inherited Destroy;
end;

procedure TFormRadIADockable.SaveVisibilityState(const AVisible: Boolean);
var
  LReg: TRegistry;
  LRegPath: string;
begin
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    LRegPath := TRadIAConfig.GetRegistryPath;
    if LReg.OpenKey(LRegPath, True) then
    begin
      LReg.WriteBool('WindowVisible', AVisible);
      LReg.CloseKey;
    end;
  finally
    LReg.Free;
  end;
end;

procedure TFormRadIADockable.DoShow;
var
  LThemingServices: IOTAIDEThemingServices;
begin
  inherited DoShow;
  SaveVisibilityState(True);
  
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LThemingServices.ApplyTheme(Self);
      LThemingServices.ApplyTheme(FChatFrame);
    end;
  end;
  
  ApplyIDETheme;
end;

procedure TFormRadIADockable.DoHide;
begin
  inherited DoHide;
  SaveVisibilityState(False);
end;

procedure TFormRadIADockable.ApplyIDETheme;
var
  LThemingServices: IOTAIDEThemingServices;
  LActiveTheme: string;
begin
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LActiveTheme := LThemingServices.ActiveTheme;
      if IsThemeDark(LActiveTheme) then
        FChatFrame.SetTheme('dark')
      else
        FChatFrame.SetTheme('light');
    end;
  end;
end;

initialization
  RegisterDockableForm;

finalization
  UnregisterDockableForm;

end.
