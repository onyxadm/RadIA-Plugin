unit RadIA.UI.ConfigForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, RadIA.UI.ConfigFrame, ToolsAPI;

type
  TFormAIConfig = class(TForm)
  published
    pnlSidebar: TPanel;
    tvCategories: TTreeView;
    splSidebar: TSplitter;
    pnlFooter: TPanel;
    btnSave: TButton;
    btnCancel: TButton;
    procedure tvCategoriesChange(Sender: TObject; Node: TTreeNode);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  protected
    procedure CreateWnd; override;
  private
    FFrameConfig: TFrameAIConfig;
    procedure UpdateVCLColors(const AThemeName: string);
  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadConfig;
  end;

implementation

{$R *.dfm}

uses
  RadIA.UI.Resources, Vcl.Themes;

constructor TFormAIConfig.Create(AOwner: TComponent);
var
  LThemingServices: IOTAIDEThemingServices;
  LActiveTheme: string;
  LNodeGeneral, LNodeProviders: TTreeNode;
  LUseIDETheme: Boolean;
begin
  inherited Create(AOwner);
  
  FFrameConfig := TFrameAIConfig.Create(Self);
  FFrameConfig.Parent := Self;
  FFrameConfig.Align := alClient;
  FFrameConfig.Visible := True;

  LActiveTheme := 'light';
  LUseIDETheme := False;
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LThemingServices.ApplyTheme(Self);
      LActiveTheme := LThemingServices.ActiveTheme;
      LUseIDETheme := True;
    end;
  end;

  tvCategories.OnChange := tvCategoriesChange;
  
  LNodeGeneral := tvCategories.Items.Add(nil, 'General / Logs');
  tvCategories.Items.Add(nil, 'System Prompt');
  tvCategories.Items.Add(nil, 'Templates');
  LNodeProviders := tvCategories.Items.Add(nil, 'AI Providers');
  
  tvCategories.Items.AddChild(LNodeProviders, 'Gemini');
  tvCategories.Items.AddChild(LNodeProviders, 'OpenAI');
  tvCategories.Items.AddChild(LNodeProviders, 'Claude');
  tvCategories.Items.AddChild(LNodeProviders, 'DeepSeek');
  tvCategories.Items.AddChild(LNodeProviders, 'Groq');
  tvCategories.Items.AddChild(LNodeProviders, 'Ollama');
  
  tvCategories.FullExpand;
  tvCategories.Selected := LNodeGeneral;

  if not LUseIDETheme then
    UpdateVCLColors(LActiveTheme);
end;

procedure TFormAIConfig.CreateWnd;
var
  LThemingServices: IOTAIDEThemingServices;
  LActiveTheme: string;
begin
  inherited CreateWnd;
  
  LActiveTheme := 'light';
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LActiveTheme := LThemingServices.ActiveTheme;
    end;
  end;
  
  if SameText(LActiveTheme, 'dark') then
  begin
    TUIHelper.ApplyDarkTitleBar(Self, True);
  end;
end;

procedure TFormAIConfig.LoadConfig;
begin
  FFrameConfig.LoadConfig;
end;

procedure TFormAIConfig.btnSaveClick(Sender: TObject);
begin
  FFrameConfig.btnSaveClick(Sender);
  if Self.ModalResult = mrOk then
    ShowMessage('Settings saved successfully.');
end;

procedure TFormAIConfig.btnCancelClick(Sender: TObject);
begin
  FFrameConfig.btnCancelClick(Sender);
end;

procedure TFormAIConfig.tvCategoriesChange(Sender: TObject; Node: TTreeNode);
begin
  if Node = nil then Exit;
  FFrameConfig.tvCategoriesChange(Sender, Node);
end;

procedure TFormAIConfig.UpdateVCLColors(const AThemeName: string);
var
  LIsDark: Boolean;
  LBgColor, LTextColor, LInputBgColor: TColor;
begin
  LIsDark := SameText(AThemeName, 'dark') or AThemeName.ToLower.Contains('dark');
  
  if LIsDark then
  begin
    LBgColor := $00252526;
    LTextColor := $00D4D4D4;
    LInputBgColor := $001E1E1E;
  end
  else
  begin
    LBgColor := clBtnFace;
    LTextColor := clWindowText;
    LInputBgColor := clWindow;
  end;

  Self.StyleElements := Self.StyleElements - [seClient, seBorder];
  Self.Color := LBgColor;
  pnlFooter.StyleElements := pnlFooter.StyleElements - [seClient, seBorder];
  pnlFooter.Color := LBgColor;
  pnlFooter.ParentBackground := False;
  pnlSidebar.StyleElements := pnlSidebar.StyleElements - [seClient, seBorder];
  pnlSidebar.Color := LBgColor;
  pnlSidebar.ParentBackground := False;

  tvCategories.StyleElements := tvCategories.StyleElements - [seClient, seBorder];
  tvCategories.Color := LInputBgColor;
  tvCategories.Font.Color := LTextColor;
end;

end.
