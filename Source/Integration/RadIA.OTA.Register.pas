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
  Vcl.Menus, Vcl.Controls, RadIA.OTA.EditorHook, RadIA.UI.DiffForm, RadIA.OTA.Helper, RadIA.Core.Types;

var
  GWizardIndex: Integer = -1;

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
end;

{ TRadIAWizard }

constructor TRadIAWizard.Create;
begin
  inherited Create;
  FEditorHook := TRadIAEditorHook.Create(nil);
  RegisterMenus;
  GlobalOnRequestDiff := OnRequestDiff;
end;

destructor TRadIAWizard.Destroy;
begin
  GlobalOnRequestDiff := nil;
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
begin
  if Supports(BorlandIDEServices, INTAServices, LNTAServices) then
  begin
    { Register tools actions }
    LToolsMenu := LNTAServices.MainMenu.Items.Find('Tools');
    if Assigned(LToolsMenu) then
    begin
      TRadIAEditorHook(FEditorHook).PopulateToolsMenu(LToolsMenu);
    end;
  end;
end;

procedure TRadIAWizard.UnregisterMenus;
begin
  // Menu items are freed automatically when their parent menu is freed,
  // but cleanup logic can be placed here if needed.
end;

initialization

finalization
  if (GWizardIndex <> -1) and Assigned(BorlandIDEServices) then
  begin
    // Unload the wizard if the BPL is uninstalled
    (BorlandIDEServices as IOTAWizardServices).RemoveWizard(GWizardIndex);
  end;

end.
