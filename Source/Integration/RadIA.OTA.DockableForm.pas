unit RadIA.OTA.DockableForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, DockForm, ToolsAPI,
  RadIA.UI.ChatFrame;

type
  TFormRadIADockable = class(TDockableForm)
  private
    FChatFrame: TFrameAIChat;
    procedure ApplyIDETheme;
  protected
    procedure DoShow; override;
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
  DeskUtil;

procedure ShowRadIAChat;
begin
  if not Assigned(FormRadIADockable) then
  begin
    FormRadIADockable := TFormRadIADockable.Create(nil);
  end;
  
  if not FormRadIADockable.Visible then
  begin
    FormRadIADockable.Show;
  end;
  FormRadIADockable.BringToFront;
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
  inherited Create(AOwner);
  Caption := 'RadIA Chat';
  Name := 'FormRadIADockable';
  DeskSection := 'FormRadIADockable';
  AutoSave := True;
  SaveStateNecessary := True;
  
  { Default dimensions for the first run or when floating }
  Width := 990;
  Height := 650;
  Position := poScreenCenter;
  
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

destructor TFormRadIADockable.Destroy;
begin
  FormRadIADockable := nil;
  inherited Destroy;
end;

procedure TFormRadIADockable.DoShow;
var
  LThemingServices: IOTAIDEThemingServices;
begin
  inherited DoShow;
  
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
      if SameText(LActiveTheme, 'Dark') then
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
