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
  tvCategories.Items.AddChild(LNodeProviders, 'OpenRouter');
  // Added node for Inline Autocomplete feature
  tvCategories.Items.Add(nil, 'Inline Autocomplete');
  
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
  LColors: TRadIAThemeColors;
begin
  LColors := TRadIAThemeColors.GetColorsForTheme(AThemeName);

  Self.StyleElements := Self.StyleElements - [seClient, seBorder];
  Self.Color := LColors.BgBase;
  pnlFooter.StyleElements := pnlFooter.StyleElements - [seClient, seBorder];
  pnlFooter.Color := LColors.BgBase;
  pnlFooter.ParentBackground := False;
  pnlSidebar.StyleElements := pnlSidebar.StyleElements - [seClient, seBorder];
  pnlSidebar.Color := LColors.BgBase;
  pnlSidebar.ParentBackground := False;

  tvCategories.StyleElements := tvCategories.StyleElements - [seClient, seBorder];
  tvCategories.Color := LColors.InputBgColor;
  tvCategories.Font.Color := LColors.TextColor;
end;

end.
