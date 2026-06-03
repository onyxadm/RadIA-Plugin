unit RadIA.UI.ConfigFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config, ToolsAPI,
  RadIA.Core.PromptTemplates;

type
  TFormAIConfig = class(TForm)
    pgcSettings: TPageControl;
    tsGemini: TTabSheet;
    tsOpenAI: TTabSheet;
    tsClaude: TTabSheet;
    tsDeepSeek: TTabSheet;
    tsGroq: TTabSheet;
    tsOllama: TTabSheet;
    tsSystemPrompt: TTabSheet;
    lblGeminiKey: TLabel;
    edtGeminiKey: TEdit;
    lblOpenAIKey: TLabel;
    edtOpenAIKey: TEdit;
    lblOpenAICustomUrl: TLabel;
    edtOpenAICustomUrl: TEdit;
    lblClaudeKey: TLabel;
    edtClaudeKey: TEdit;
    lblOllamaUrl: TLabel;
    edtOllamaUrl: TEdit;
    lblDeepSeekKey: TLabel;
    edtDeepSeekKey: TEdit;
    lblGroqKey: TLabel;
    edtGroqKey: TEdit;
    memSystemPrompt: TMemo;
    pnlFooter: TPanel;
    btnSave: TButton;
    btnCancel: TButton;
    tsTemplates: TTabSheet;
    pnlTemplatesLeft: TPanel;
    lstTemplates: TListBox;
    pnlTemplatesLeftButtons: TPanel;
    btnNewTemplate: TButton;
    btnDeleteTemplate: TButton;
    pnlTemplatesClient: TPanel;
    lblTemplateName: TLabel;
    lblTemplateDesc: TLabel;
    lblTemplateBody: TLabel;
    edtTemplateName: TEdit;
    edtTemplateDesc: TEdit;
    memTemplateBody: TMemo;
    btnSaveTemplate: TButton;
    btnRestoreDefaults: TButton;
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure lstTemplatesClick(Sender: TObject);
    procedure btnNewTemplateClick(Sender: TObject);
    procedure btnDeleteTemplateClick(Sender: TObject);
    procedure btnSaveTemplateClick(Sender: TObject);
    procedure btnRestoreDefaultsClick(Sender: TObject);
  protected
    procedure CreateWnd; override;
  private
    FConfig: IAIConfig;
    FTemplateManager: TPromptTemplateManager;
    FOnClose: TNotifyEvent;
    procedure UpdateVCLColors(const AThemeName: string);
    procedure PopulateTemplatesList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadConfig;
    
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.JSON, RadIA.UI.Resources, System.UITypes;

type
  TTabSheetColorHack = class(TTabSheet);

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

constructor TFormAIConfig.Create(AOwner: TComponent);
var
  LThemingServices: IOTAIDEThemingServices;
  LActiveTheme: string;
begin
  inherited Create(AOwner);
  FConfig := TRadIAConfig.Create;
  FTemplateManager := TPromptTemplateManager.Create;
  FTemplateManager.Load;

  LActiveTheme := 'light';
  { Apply IDE theme so this form matches the current Delphi skin }
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LThemingServices.ApplyTheme(Self);
      LActiveTheme := LThemingServices.ActiveTheme;
    end;
  end;

  if not (Assigned(LThemingServices) and LThemingServices.IDEThemingEnabled) then
  begin
    UpdateVCLColors(LActiveTheme);
  end;
  LoadConfig;
end;

destructor TFormAIConfig.Destroy;
begin
  FTemplateManager.Free;
  inherited Destroy;
end;

procedure TFormAIConfig.UpdateVCLColors(const AThemeName: string);
var
  LIsDark: Boolean;
  LBgColor, LTextColor, LInputBgColor: TColor;
  I: Integer;
begin
  LIsDark := SameText(AThemeName, 'dark');
  
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

  Self.Color := LBgColor;
  pnlFooter.Color := LBgColor;
  pnlFooter.ParentBackground := False;

  { Apply theme to all tabs in the PageControl to avoid default white backgrounds }
  for I := 0 to pgcSettings.PageCount - 1 do
  begin
    TTabSheetColorHack(pgcSettings.Pages[I]).ParentBackground := False;
    TTabSheetColorHack(pgcSettings.Pages[I]).Color := LBgColor;
  end;

  // Memo do System Prompt
  memSystemPrompt.Color := LInputBgColor;
  memSystemPrompt.Font.Color := LTextColor;

  // Inputs
  edtGeminiKey.Color := LInputBgColor;
  edtGeminiKey.Font.Color := LTextColor;
  
  edtOpenAIKey.Color := LInputBgColor;
  edtOpenAIKey.Font.Color := LTextColor;
  edtOpenAICustomUrl.Color := LInputBgColor;
  edtOpenAICustomUrl.Font.Color := LTextColor;
  
  edtClaudeKey.Color := LInputBgColor;
  edtClaudeKey.Font.Color := LTextColor;
  
  edtDeepSeekKey.Color := LInputBgColor;
  edtDeepSeekKey.Font.Color := LTextColor;
  
  edtGroqKey.Color := LInputBgColor;
  edtGroqKey.Font.Color := LTextColor;
  
  edtOllamaUrl.Color := LInputBgColor;
  edtOllamaUrl.Font.Color := LTextColor;

  // Labels
  lblGeminiKey.Font.Color := LTextColor;
  lblOpenAIKey.Font.Color := LTextColor;
  lblOpenAICustomUrl.Font.Color := LTextColor;
  lblClaudeKey.Font.Color := LTextColor;
  lblDeepSeekKey.Font.Color := LTextColor;
  lblGroqKey.Font.Color := LTextColor;
  lblOllamaUrl.Font.Color := LTextColor;

  // Aba de Templates
  pnlTemplatesLeft.Color := LBgColor;
  pnlTemplatesLeft.ParentBackground := False;
  pnlTemplatesLeftButtons.Color := LBgColor;
  pnlTemplatesLeftButtons.ParentBackground := False;
  pnlTemplatesClient.Color := LBgColor;
  pnlTemplatesClient.ParentBackground := False;
  
  lstTemplates.Color := LInputBgColor;
  lstTemplates.Font.Color := LTextColor;
  edtTemplateName.Color := LInputBgColor;
  edtTemplateName.Font.Color := LTextColor;
  edtTemplateDesc.Color := LInputBgColor;
  edtTemplateDesc.Font.Color := LTextColor;
  memTemplateBody.Color := LInputBgColor;
  memTemplateBody.Font.Color := LTextColor;
  
  lblTemplateName.Font.Color := LTextColor;
  lblTemplateDesc.Font.Color := LTextColor;
  lblTemplateBody.Font.Color := LTextColor;
end;

procedure TFormAIConfig.LoadConfig;
begin
  edtGeminiKey.Text := FConfig.GetApiKey(ptGemini);
  edtOpenAIKey.Text := FConfig.GetApiKey(ptOpenAI);
  edtOpenAICustomUrl.Text := FConfig.OpenAICustomBaseUrl;
  edtClaudeKey.Text := FConfig.GetApiKey(ptClaude);
  edtDeepSeekKey.Text := FConfig.GetApiKey(ptDeepSeek);
  edtGroqKey.Text := FConfig.GetApiKey(ptGroq);
  memSystemPrompt.Text := FConfig.SystemPrompt;
  edtOllamaUrl.Text := FConfig.OllamaBaseUrl;

  PopulateTemplatesList;
  if lstTemplates.Count > 0 then
  begin
    lstTemplates.ItemIndex := 0;
    lstTemplatesClick(nil);
  end;
end;

procedure TFormAIConfig.btnSaveClick(Sender: TObject);
var
  LForm: TCustomForm;
  LOllamaUrl: string;
  LOpenAIUrl: string;
begin
  LOllamaUrl := Trim(edtOllamaUrl.Text);
  LOpenAIUrl := Trim(edtOpenAICustomUrl.Text);

  if not LOllamaUrl.IsEmpty and not (LOllamaUrl.StartsWith('http://', True) or LOllamaUrl.StartsWith('https://', True)) then
  begin
    ShowMessage('Ollama URL must start with http:// or https://');
    Exit;
  end;

  if not LOpenAIUrl.IsEmpty and not (LOpenAIUrl.StartsWith('http://', True) or LOpenAIUrl.StartsWith('https://', True)) then
  begin
    ShowMessage('OpenAI Custom Base URL must start with http:// or https://');
    Exit;
  end;

  FConfig.SetApiKey(ptGemini, Trim(edtGeminiKey.Text));
  FConfig.SetApiKey(ptOpenAI, Trim(edtOpenAIKey.Text));
  FConfig.OpenAICustomBaseUrl := LOpenAIUrl;
  FConfig.SetApiKey(ptClaude, Trim(edtClaudeKey.Text));
  FConfig.SetApiKey(ptDeepSeek, Trim(edtDeepSeekKey.Text));
  FConfig.SetApiKey(ptGroq, Trim(edtGroqKey.Text));
  FConfig.SystemPrompt := memSystemPrompt.Text;
  FConfig.OllamaBaseUrl := LOllamaUrl;
  FConfig.Save;

  { Save templates too }
  FTemplateManager.Save;

  ShowMessage('Settings saved successfully.');

  LForm := GetParentForm(Self);
  if LForm <> nil then
    LForm.ModalResult := mrOk;
end;

procedure TFormAIConfig.btnCancelClick(Sender: TObject);
var
  LForm: TCustomForm;
begin
  LoadConfig;
  LForm := GetParentForm(Self);
  if LForm <> nil then
    LForm.ModalResult := mrCancel;
end;

procedure TFormAIConfig.PopulateTemplatesList;
var
  LTemplate: TPromptTemplate;
  LSelectedIndex: Integer;
begin
  LSelectedIndex := lstTemplates.ItemIndex;
  lstTemplates.Items.BeginUpdate;
  try
    lstTemplates.Items.Clear;
    for LTemplate in FTemplateManager.GetTemplates do
    begin
      lstTemplates.Items.Add(LTemplate.Name);
    end;
  finally
    lstTemplates.Items.EndUpdate;
  end;
  
  if (LSelectedIndex >= 0) and (LSelectedIndex < lstTemplates.Count) then
    lstTemplates.ItemIndex := LSelectedIndex
  else if lstTemplates.Count > 0 then
    lstTemplates.ItemIndex := 0
  else
    lstTemplates.ItemIndex := -1;
end;

procedure TFormAIConfig.lstTemplatesClick(Sender: TObject);
var
  LName: string;
  LTemplate: TPromptTemplate;
begin
  if lstTemplates.ItemIndex < 0 then
  begin
    edtTemplateName.Text := '';
    edtTemplateDesc.Text := '';
    memTemplateBody.Text := '';
    Exit;
  end;

  LName := lstTemplates.Items[lstTemplates.ItemIndex];
  if FTemplateManager.FindTemplate(LName, LTemplate) then
  begin
    edtTemplateName.Text := LTemplate.Name;
    edtTemplateDesc.Text := LTemplate.Description;
    memTemplateBody.Text := LTemplate.Template;
  end;
end;

procedure TFormAIConfig.btnNewTemplateClick(Sender: TObject);
begin
  lstTemplates.ItemIndex := -1;
  edtTemplateName.Text := '';
  edtTemplateDesc.Text := '';
  memTemplateBody.Text := '';
  edtTemplateName.SetFocus;
end;

procedure TFormAIConfig.btnDeleteTemplateClick(Sender: TObject);
var
  LName: string;
begin
  if lstTemplates.ItemIndex < 0 then
  begin
    ShowMessage('Please select a template to delete.');
    Exit;
  end;

  LName := lstTemplates.Items[lstTemplates.ItemIndex];
  if MessageDlg(Format('Are you sure you want to delete the template "%s"?', [LName]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FTemplateManager.DeleteTemplate(LName);
    PopulateTemplatesList;
    lstTemplatesClick(nil);
  end;
end;

procedure TFormAIConfig.btnSaveTemplateClick(Sender: TObject);
var
  LName, LDesc, LBody: string;
  LIndex: Integer;
begin
  LName := Trim(edtTemplateName.Text);
  LDesc := Trim(edtTemplateDesc.Text);
  LBody := memTemplateBody.Text;

  if LName.IsEmpty then
  begin
    ShowMessage('Template Name cannot be empty.');
    Exit;
  end;

  FTemplateManager.AddTemplate(LName, LDesc, LBody);
  PopulateTemplatesList;
  
  LIndex := lstTemplates.Items.IndexOf(LName);
  if LIndex >= 0 then
  begin
    lstTemplates.ItemIndex := LIndex;
    lstTemplatesClick(nil);
  end;
  
  ShowMessage('Template saved successfully.');
end;

procedure TFormAIConfig.btnRestoreDefaultsClick(Sender: TObject);
begin
  if MessageDlg('Are you sure you want to restore default templates? This will overwrite your changes.',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FTemplateManager.RestoreDefaultTemplates;
    PopulateTemplatesList;
    if lstTemplates.Count > 0 then
    begin
      lstTemplates.ItemIndex := 0;
      lstTemplatesClick(nil);
    end;
    ShowMessage('Default templates restored successfully.');
  end;
end;

end.
