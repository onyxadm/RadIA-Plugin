unit RadIA.UI.ConfigFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config, ToolsAPI,
  RadIA.Core.PromptTemplates;

type
  TFrameAIConfig = class(TFrame)
  published
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
    procedure lstTemplatesClick(Sender: TObject);
    procedure btnNewTemplateClick(Sender: TObject);
    procedure btnDeleteTemplateClick(Sender: TObject);
    procedure btnSaveTemplateClick(Sender: TObject);
    procedure btnRestoreDefaultsClick(Sender: TObject);
  private
    FConfig: IAIConfig;
    FTemplateManager: TPromptTemplateManager;
    FOnClose: TNotifyEvent;
    
    FEdtTemperatures: array[TAIProviderType] of TEdit;
    FEdtMaxTokens: array[TAIProviderType] of TEdit;
    FEdtTimeouts: array[TAIProviderType] of TEdit;
    FChkSmartConfig: TCheckBox;
    
    tsGeneral: TTabSheet;
    chkLogEnabled: TCheckBox;
    lblLogPath: TLabel;
    edtLogPath: TEdit;
    btnBrowseLogPath: TButton;
    lblLogMaxSize: TLabel;
    edtLogMaxSize: TEdit;
    
    grpQuota: TGroupBox;
    chkQuotaEnabled: TCheckBox;
    lblQuotaLimit: TLabel;
    edtQuotaLimit: TEdit;
    lblQuotaUsed: TLabel;
    btnResetQuota: TButton;
    
    procedure btnBrowseLogPathClick(Sender: TObject);
    procedure btnResetQuotaClick(Sender: TObject);
    
    procedure CreateProviderAdvancedControls(ATabSheet: TTabSheet; AProvider: TAIProviderType);
    procedure PopulateTemplatesList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure LoadConfig;
    procedure UpdateVCLColors(const AThemeName: string);
    procedure tvCategoriesChange(Sender: TObject; Node: TTreeNode);
    procedure SelectCategoryByName(const ACategoryName: string);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.JSON, RadIA.UI.Resources, System.UITypes, Vcl.FileCtrl, RadIA.Core.Logger, Vcl.Themes;

type
  TTabSheetColorHack = class(TTabSheet);
  TWinControlHack = class(TWinControl);

constructor TFrameAIConfig.Create(AOwner: TComponent);
var
  LThemingServices: IOTAIDEThemingServices;
  LActiveTheme: string;
  LUseIDETheme: Boolean;
begin
  inherited Create(AOwner);
  FConfig := TRadIAConfig.Create;
  FTemplateManager := TPromptTemplateManager.Create;
  FTemplateManager.Load;

  { Create advanced settings groupbox for each provider tab }
  CreateProviderAdvancedControls(tsGemini, ptGemini);
  CreateProviderAdvancedControls(tsOpenAI, ptOpenAI);
  CreateProviderAdvancedControls(tsClaude, ptClaude);
  CreateProviderAdvancedControls(tsDeepSeek, ptDeepSeek);
  CreateProviderAdvancedControls(tsGroq, ptGroq);
  CreateProviderAdvancedControls(tsOllama, ptOllama);

  { Create General/Logs Tab and controls programmatically }
  tsGeneral := TTabSheet.Create(Self);
  tsGeneral.PageControl := pgcSettings;
  tsGeneral.Caption := 'General / Logs';
  tsGeneral.TabVisible := False;

  FChkSmartConfig := TCheckBox.Create(Self);
  FChkSmartConfig.Parent := tsGeneral;
  FChkSmartConfig.Left := 16;
  FChkSmartConfig.Top := 16;
  FChkSmartConfig.Width := 300;
  FChkSmartConfig.Height := 23;
  FChkSmartConfig.Caption := 'Auto (Smart Parameters)';

  chkLogEnabled := TCheckBox.Create(Self);
  chkLogEnabled.Parent := tsGeneral;
  chkLogEnabled.Left := 16;
  chkLogEnabled.Top := 48;
  chkLogEnabled.Width := 200;
  chkLogEnabled.Caption := 'Enable logging';

  lblLogPath := TLabel.Create(Self);
  lblLogPath.Parent := tsGeneral;
  lblLogPath.Left := 16;
  lblLogPath.Top := 80;
  lblLogPath.Caption := 'Log Folder Path:';

  edtLogPath := TEdit.Create(Self);
  edtLogPath.Parent := tsGeneral;
  edtLogPath.Left := 16;
  edtLogPath.Top := 98;
  edtLogPath.Width := 320;

  btnBrowseLogPath := TButton.Create(Self);
  btnBrowseLogPath.Parent := tsGeneral;
  btnBrowseLogPath.Left := 342;
  btnBrowseLogPath.Top := 96;
  btnBrowseLogPath.Width := 30;
  btnBrowseLogPath.Height := 23;
  btnBrowseLogPath.Caption := '...';
  btnBrowseLogPath.OnClick := btnBrowseLogPathClick;

  lblLogMaxSize := TLabel.Create(Self);
  lblLogMaxSize.Parent := tsGeneral;
  lblLogMaxSize.Left := 16;
  lblLogMaxSize.Top := 136;
  lblLogMaxSize.Caption := 'Max Log File Size (KB):';

  edtLogMaxSize := TEdit.Create(Self);
  edtLogMaxSize.Parent := tsGeneral;
  edtLogMaxSize.Left := 16;
  edtLogMaxSize.Top := 154;
  edtLogMaxSize.Width := 100;
  edtLogMaxSize.NumbersOnly := True;

  grpQuota := TGroupBox.Create(Self);
  grpQuota.Parent := tsGeneral;
  grpQuota.Left := 16;
  grpQuota.Top := 192;
  grpQuota.Width := 356;
  grpQuota.Height := 140;
  grpQuota.Caption := ' Local Token Quota ';

  chkQuotaEnabled := TCheckBox.Create(Self);
  chkQuotaEnabled.Parent := grpQuota;
  chkQuotaEnabled.Left := 16;
  chkQuotaEnabled.Top := 24;
  chkQuotaEnabled.Width := 200;
  chkQuotaEnabled.Caption := 'Enable local token quota';

  lblQuotaLimit := TLabel.Create(Self);
  lblQuotaLimit.Parent := grpQuota;
  lblQuotaLimit.Left := 16;
  lblQuotaLimit.Top := 54;
  lblQuotaLimit.Caption := 'Monthly Token Limit:';

  edtQuotaLimit := TEdit.Create(Self);
  edtQuotaLimit.Parent := grpQuota;
  edtQuotaLimit.Left := 16;
  edtQuotaLimit.Top := 72;
  edtQuotaLimit.Width := 150;
  edtQuotaLimit.NumbersOnly := True;

  lblQuotaUsed := TLabel.Create(Self);
  lblQuotaUsed.Parent := grpQuota;
  lblQuotaUsed.Left := 16;
  lblQuotaUsed.Top := 110;
  lblQuotaUsed.Caption := 'Monthly Used Tokens: 0';

  btnResetQuota := TButton.Create(Self);
  btnResetQuota.Parent := grpQuota;
  btnResetQuota.Left := 240;
  btnResetQuota.Top := 68;
  btnResetQuota.Width := 100;
  btnResetQuota.Height := 25;
  btnResetQuota.Caption := 'Reset Usage';
  btnResetQuota.OnClick := btnResetQuotaClick;

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

  if not LUseIDETheme then
    UpdateVCLColors(LActiveTheme);
  LoadConfig;
end;

destructor TFrameAIConfig.Destroy;
begin
  FTemplateManager.Free;
  inherited Destroy;
end;

procedure TFrameAIConfig.CreateProviderAdvancedControls(ATabSheet: TTabSheet; AProvider: TAIProviderType);
var
  LGroupBox: TGroupBox;
  LLabel: TLabel;
begin
  LGroupBox := TGroupBox.Create(Self);
  LGroupBox.Parent := ATabSheet;
  LGroupBox.Align := alBottom;
  LGroupBox.Height := 90;
  LGroupBox.Caption := ' Advanced Settings ';
  LGroupBox.Margins.Left := 8;
  LGroupBox.Margins.Right := 8;
  LGroupBox.Margins.Bottom := 8;
  LGroupBox.AlignWithMargins := True;

  // Temperature
  LLabel := TLabel.Create(Self);
  LLabel.Parent := LGroupBox;
  LLabel.Left := 16;
  LLabel.Top := 24;
  LLabel.Caption := 'Temperature (0.0 - 1.0):';

  FEdtTemperatures[AProvider] := TEdit.Create(Self);
  FEdtTemperatures[AProvider].Parent := LGroupBox;
  FEdtTemperatures[AProvider].Left := 16;
  FEdtTemperatures[AProvider].Top := 42;
  FEdtTemperatures[AProvider].Width := 100;

  // Max Tokens
  LLabel := TLabel.Create(Self);
  LLabel.Parent := LGroupBox;
  LLabel.Left := 140;
  LLabel.Top := 24;
  LLabel.Caption := 'Max Output Tokens:';

  FEdtMaxTokens[AProvider] := TEdit.Create(Self);
  FEdtMaxTokens[AProvider].Parent := LGroupBox;
  FEdtMaxTokens[AProvider].Left := 140;
  FEdtMaxTokens[AProvider].Top := 42;
  FEdtMaxTokens[AProvider].Width := 100;
  FEdtMaxTokens[AProvider].NumbersOnly := True;

  // Timeout
  LLabel := TLabel.Create(Self);
  LLabel.Parent := LGroupBox;
  LLabel.Left := 264;
  LLabel.Top := 24;
  LLabel.Caption := 'Timeout (seconds):';

  FEdtTimeouts[AProvider] := TEdit.Create(Self);
  FEdtTimeouts[AProvider].Parent := LGroupBox;
  FEdtTimeouts[AProvider].Left := 264;
  FEdtTimeouts[AProvider].Top := 42;
  FEdtTimeouts[AProvider].Width := 100;
  FEdtTimeouts[AProvider].NumbersOnly := True;
end;

procedure TFrameAIConfig.UpdateVCLColors(const AThemeName: string);
var
  LIsDark: Boolean;
  LBgColor, LTextColor, LInputBgColor: TColor;
  I: Integer;
  LProvider: TAIProviderType;
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
  TWinControlHack(Self).Color := LBgColor;
  pgcSettings.StyleElements := pgcSettings.StyleElements - [seClient, seBorder];
  TWinControlHack(pgcSettings).Color := LBgColor;

  TWinControlHack(Self).ParentBackground := False;
  TWinControlHack(pgcSettings).ParentBackground := False;
  for I := 0 to pgcSettings.PageCount - 1 do
  begin
    pgcSettings.Pages[I].StyleElements := pgcSettings.Pages[I].StyleElements - [seClient, seBorder];
    TTabSheetColorHack(pgcSettings.Pages[I]).ParentBackground := False;
    TTabSheetColorHack(pgcSettings.Pages[I]).Color := LBgColor;
  end;

  // Memo do System Prompt
  memSystemPrompt.StyleElements := memSystemPrompt.StyleElements - [seClient, seBorder];
  memSystemPrompt.Color := LInputBgColor;
  memSystemPrompt.Font.Color := LTextColor;

  // Inputs
  edtGeminiKey.StyleElements := edtGeminiKey.StyleElements - [seClient, seBorder];
  edtGeminiKey.Color := LInputBgColor;
  edtGeminiKey.Font.Color := LTextColor;
  
  edtOpenAIKey.StyleElements := edtOpenAIKey.StyleElements - [seClient, seBorder];
  edtOpenAIKey.Color := LInputBgColor;
  edtOpenAIKey.Font.Color := LTextColor;
  edtOpenAICustomUrl.StyleElements := edtOpenAICustomUrl.StyleElements - [seClient, seBorder];
  edtOpenAICustomUrl.Color := LInputBgColor;
  edtOpenAICustomUrl.Font.Color := LTextColor;
  
  edtClaudeKey.StyleElements := edtClaudeKey.StyleElements - [seClient, seBorder];
  edtClaudeKey.Color := LInputBgColor;
  edtClaudeKey.Font.Color := LTextColor;
  
  edtDeepSeekKey.StyleElements := edtDeepSeekKey.StyleElements - [seClient, seBorder];
  edtDeepSeekKey.Color := LInputBgColor;
  edtDeepSeekKey.Font.Color := LTextColor;
  
  edtGroqKey.StyleElements := edtGroqKey.StyleElements - [seClient, seBorder];
  edtGroqKey.Color := LInputBgColor;
  edtGroqKey.Font.Color := LTextColor;
  
  edtOllamaUrl.StyleElements := edtOllamaUrl.StyleElements - [seClient, seBorder];
  edtOllamaUrl.Color := LInputBgColor;
  edtOllamaUrl.Font.Color := LTextColor;

  // Labels
  lblGeminiKey.StyleElements := lblGeminiKey.StyleElements - [seClient, seBorder];
  lblGeminiKey.Font.Color := LTextColor;
  lblOpenAIKey.StyleElements := lblOpenAIKey.StyleElements - [seClient, seBorder];
  lblOpenAIKey.Font.Color := LTextColor;
  lblOpenAICustomUrl.StyleElements := lblOpenAICustomUrl.StyleElements - [seClient, seBorder];
  lblOpenAICustomUrl.Font.Color := LTextColor;
  lblClaudeKey.StyleElements := lblClaudeKey.StyleElements - [seClient, seBorder];
  lblClaudeKey.Font.Color := LTextColor;
  lblDeepSeekKey.StyleElements := lblDeepSeekKey.StyleElements - [seClient, seBorder];
  lblDeepSeekKey.Font.Color := LTextColor;
  lblGroqKey.StyleElements := lblGroqKey.StyleElements - [seClient, seBorder];
  lblGroqKey.Font.Color := LTextColor;
  lblOllamaUrl.StyleElements := lblOllamaUrl.StyleElements - [seClient, seBorder];
  lblOllamaUrl.Font.Color := LTextColor;

  // Aba de Templates
  pnlTemplatesLeft.StyleElements := pnlTemplatesLeft.StyleElements - [seClient, seBorder];
  pnlTemplatesLeft.Color := LBgColor;
  pnlTemplatesLeft.ParentBackground := False;
  pnlTemplatesLeftButtons.StyleElements := pnlTemplatesLeftButtons.StyleElements - [seClient, seBorder];
  pnlTemplatesLeftButtons.Color := LBgColor;
  pnlTemplatesLeftButtons.ParentBackground := False;
  pnlTemplatesClient.StyleElements := pnlTemplatesClient.StyleElements - [seClient, seBorder];
  pnlTemplatesClient.Color := LBgColor;
  pnlTemplatesClient.ParentBackground := False;
  
  lstTemplates.StyleElements := lstTemplates.StyleElements - [seClient, seBorder];
  lstTemplates.Color := LInputBgColor;
  lstTemplates.Font.Color := LTextColor;
  edtTemplateName.StyleElements := edtTemplateName.StyleElements - [seClient, seBorder];
  edtTemplateName.Color := LInputBgColor;
  edtTemplateName.Font.Color := LTextColor;
  edtTemplateDesc.StyleElements := edtTemplateDesc.StyleElements - [seClient, seBorder];
  edtTemplateDesc.Color := LInputBgColor;
  edtTemplateDesc.Font.Color := LTextColor;
  memTemplateBody.StyleElements := memTemplateBody.StyleElements - [seClient, seBorder];
  memTemplateBody.Color := LInputBgColor;
  memTemplateBody.Font.Color := LTextColor;
  
  lblTemplateName.StyleElements := lblTemplateName.StyleElements - [seClient, seBorder];
  lblTemplateName.Font.Color := LTextColor;
  lblTemplateDesc.StyleElements := lblTemplateDesc.StyleElements - [seClient, seBorder];
  lblTemplateDesc.Font.Color := LTextColor;
  lblTemplateBody.StyleElements := lblTemplateBody.StyleElements - [seClient, seBorder];
  lblTemplateBody.Font.Color := LTextColor;

  { Paint Advanced Controls }
  for LProvider := Low(TAIProviderType) to High(TAIProviderType) do
  begin
    if Assigned(FEdtTemperatures[LProvider]) then
    begin
      FEdtTemperatures[LProvider].StyleElements := FEdtTemperatures[LProvider].StyleElements - [seClient, seBorder];
      FEdtTemperatures[LProvider].Color := LInputBgColor;
      FEdtTemperatures[LProvider].Font.Color := LTextColor;
    end;
    if Assigned(FEdtMaxTokens[LProvider]) then
    begin
      FEdtMaxTokens[LProvider].StyleElements := FEdtMaxTokens[LProvider].StyleElements - [seClient, seBorder];
      FEdtMaxTokens[LProvider].Color := LInputBgColor;
      FEdtMaxTokens[LProvider].Font.Color := LTextColor;
    end;
    if Assigned(FEdtTimeouts[LProvider]) then
    begin
      FEdtTimeouts[LProvider].StyleElements := FEdtTimeouts[LProvider].StyleElements - [seClient, seBorder];
      FEdtTimeouts[LProvider].Color := LInputBgColor;
      FEdtTimeouts[LProvider].Font.Color := LTextColor;
    end;
  end;

  if Assigned(FChkSmartConfig) then
  begin
    FChkSmartConfig.StyleElements := FChkSmartConfig.StyleElements - [seClient, seBorder];
    FChkSmartConfig.Font.Color := LTextColor;
  end;

  if Assigned(tsGeneral) then
  begin
    tsGeneral.StyleElements := tsGeneral.StyleElements - [seClient, seBorder];
    TTabSheetColorHack(tsGeneral).ParentBackground := False;
    TTabSheetColorHack(tsGeneral).Color := LBgColor;
  end;
  if Assigned(chkLogEnabled) then
  begin
    chkLogEnabled.StyleElements := chkLogEnabled.StyleElements - [seClient, seBorder];
    chkLogEnabled.Font.Color := LTextColor;
  end;
  if Assigned(lblLogPath) then
  begin
    lblLogPath.StyleElements := lblLogPath.StyleElements - [seClient, seBorder];
    lblLogPath.Font.Color := LTextColor;
  end;
  if Assigned(edtLogPath) then
  begin
    edtLogPath.StyleElements := edtLogPath.StyleElements - [seClient, seBorder];
    edtLogPath.Color := LInputBgColor;
    edtLogPath.Font.Color := LTextColor;
  end;
  if Assigned(edtLogMaxSize) then
  begin
    edtLogMaxSize.StyleElements := edtLogMaxSize.StyleElements - [seClient, seBorder];
    edtLogMaxSize.Color := LInputBgColor;
    edtLogMaxSize.Font.Color := LTextColor;
  end;
  
  if Assigned(grpQuota) then
  begin
    grpQuota.StyleElements := grpQuota.StyleElements - [seClient, seBorder];
    grpQuota.Font.Color := LTextColor;
    chkQuotaEnabled.StyleElements := chkQuotaEnabled.StyleElements - [seClient, seBorder];
    chkQuotaEnabled.Font.Color := LTextColor;
    lblQuotaLimit.StyleElements := lblQuotaLimit.StyleElements - [seClient, seBorder];
    lblQuotaLimit.Font.Color := LTextColor;
    edtQuotaLimit.StyleElements := edtQuotaLimit.StyleElements - [seClient, seBorder];
    edtQuotaLimit.Color := LInputBgColor;
    edtQuotaLimit.Font.Color := LTextColor;
    lblQuotaUsed.StyleElements := lblQuotaUsed.StyleElements - [seClient, seBorder];
    lblQuotaUsed.Font.Color := LTextColor;
  end;
end;

procedure TFrameAIConfig.LoadConfig;
var
  LProvider: TAIProviderType;
  LFormatSettings: TFormatSettings;
begin
  LFormatSettings := TFormatSettings.Invariant;
  
  edtGeminiKey.Text := FConfig.GetApiKey(ptGemini);
  edtOpenAIKey.Text := FConfig.GetApiKey(ptOpenAI);
  edtOpenAICustomUrl.Text := FConfig.OpenAICustomBaseUrl;
  edtClaudeKey.Text := FConfig.GetApiKey(ptClaude);
  edtDeepSeekKey.Text := FConfig.GetApiKey(ptDeepSeek);
  edtGroqKey.Text := FConfig.GetApiKey(ptGroq);
  memSystemPrompt.Text := FConfig.SystemPrompt;
  edtOllamaUrl.Text := FConfig.OllamaBaseUrl;

  if Assigned(FChkSmartConfig) then
    FChkSmartConfig.Checked := FConfig.SmartConfigEnabled;

  for LProvider := Low(TAIProviderType) to High(TAIProviderType) do
  begin
    if Assigned(FEdtTemperatures[LProvider]) then
      FEdtTemperatures[LProvider].Text := FormatFloat('0.0', FConfig.GetTemperature(LProvider), LFormatSettings);
    if Assigned(FEdtMaxTokens[LProvider]) then
      FEdtMaxTokens[LProvider].Text := IntToStr(FConfig.GetMaxTokens(LProvider));
    if Assigned(FEdtTimeouts[LProvider]) then
      FEdtTimeouts[LProvider].Text := IntToStr(FConfig.GetTimeout(LProvider));
  end;

  if Assigned(chkLogEnabled) then
    chkLogEnabled.Checked := FConfig.LogEnabled;
  if Assigned(edtLogPath) then
    edtLogPath.Text := FConfig.LogPath;
  if Assigned(edtLogMaxSize) then
    edtLogMaxSize.Text := IntToStr(FConfig.LogMaxSizeKB);

  if Assigned(chkQuotaEnabled) then
    chkQuotaEnabled.Checked := FConfig.QuotaEnabled;
  if Assigned(edtQuotaLimit) then
    edtQuotaLimit.Text := FConfig.QuotaLimit.ToString;
  if Assigned(lblQuotaUsed) then
    lblQuotaUsed.Caption := Format('Monthly Used Tokens: %s', [FormatFloat('#,##0', FConfig.QuotaUsed, LFormatSettings)]);

  PopulateTemplatesList;
  if lstTemplates.Count > 0 then
  begin
    lstTemplates.ItemIndex := 0;
    lstTemplatesClick(nil);
  end;
end;

procedure TFrameAIConfig.btnSaveClick(Sender: TObject);
var
  LForm: TCustomForm;
  LOllamaUrl: string;
  LOpenAIUrl: string;
  LProvider: TAIProviderType;
  LFormatSettings: TFormatSettings;
  LTemp: Double;
begin
  LOllamaUrl := Trim(edtOllamaUrl.Text);
  LOpenAIUrl := Trim(edtOpenAICustomUrl.Text);
  LFormatSettings := TFormatSettings.Invariant;

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

  if Assigned(FChkSmartConfig) then
    FConfig.SmartConfigEnabled := FChkSmartConfig.Checked;

  for LProvider := Low(TAIProviderType) to High(TAIProviderType) do
  begin
    if Assigned(FEdtTemperatures[LProvider]) then
    begin
      if TryStrToFloat(FEdtTemperatures[LProvider].Text, LTemp, LFormatSettings) then
      begin
        if (LTemp >= 0.0) and (LTemp <= 2.0) then
          FConfig.SetTemperature(LProvider, LTemp);
      end;
    end;
    if Assigned(FEdtMaxTokens[LProvider]) then
      FConfig.SetMaxTokens(LProvider, StrToIntDef(FEdtMaxTokens[LProvider].Text, 2048));
    if Assigned(FEdtTimeouts[LProvider]) then
      FConfig.SetTimeout(LProvider, StrToIntDef(FEdtTimeouts[LProvider].Text, 60));
  end;

  if Assigned(chkLogEnabled) then
    FConfig.LogEnabled := chkLogEnabled.Checked;
  if Assigned(edtLogPath) then
    FConfig.LogPath := Trim(edtLogPath.Text);
  if Assigned(edtLogMaxSize) then
    FConfig.LogMaxSizeKB := StrToIntDef(edtLogMaxSize.Text, 1024);

  if Assigned(chkQuotaEnabled) then
    FConfig.QuotaEnabled := chkQuotaEnabled.Checked;
  if Assigned(edtQuotaLimit) then
    FConfig.QuotaLimit := StrToInt64Def(edtQuotaLimit.Text, 1000000);

  FConfig.Save;

  { Save templates too }
  FTemplateManager.Save;

  if Sender <> nil then
    ShowMessage('Settings saved successfully.');

  LForm := GetParentForm(Self);
  if LForm <> nil then
    LForm.ModalResult := mrOk;
end;

procedure TFrameAIConfig.btnCancelClick(Sender: TObject);
var
  LForm: TCustomForm;
begin
  LoadConfig;
  LForm := GetParentForm(Self);
  if LForm <> nil then
    LForm.ModalResult := mrCancel;
end;

procedure TFrameAIConfig.PopulateTemplatesList;
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

procedure TFrameAIConfig.lstTemplatesClick(Sender: TObject);
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

procedure TFrameAIConfig.btnNewTemplateClick(Sender: TObject);
begin
  lstTemplates.ItemIndex := -1;
  edtTemplateName.Text := '';
  edtTemplateDesc.Text := '';
  memTemplateBody.Text := '';
  edtTemplateName.SetFocus;
end;

procedure TFrameAIConfig.btnDeleteTemplateClick(Sender: TObject);
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

procedure TFrameAIConfig.btnSaveTemplateClick(Sender: TObject);
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

procedure TFrameAIConfig.btnRestoreDefaultsClick(Sender: TObject);
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

procedure TFrameAIConfig.btnBrowseLogPathClick(Sender: TObject);
var
  LFolder: string;
begin
  if Vcl.FileCtrl.SelectDirectory('Select Log Folder', '', LFolder, [sdNewUI, sdNewFolder]) then
    edtLogPath.Text := LFolder;
end;

procedure TFrameAIConfig.btnResetQuotaClick(Sender: TObject);
begin
  if MessageDlg('Are you sure you want to reset the monthly token usage counter to zero?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FConfig.QuotaUsed := 0;
    FConfig.QuotaCycleStart := Now;
    FConfig.Save;
    
    lblQuotaUsed.Caption := 'Monthly Used Tokens: 0';
    ShowMessage('Token usage counter reset successfully.');
  end;
end;

procedure TFrameAIConfig.tvCategoriesChange(Sender: TObject; Node: TTreeNode);
begin
  if Node <> nil then
    SelectCategoryByName(Node.Text);
end;

procedure TFrameAIConfig.SelectCategoryByName(const ACategoryName: string);
begin
  if SameText(ACategoryName, 'General / Logs') then
    pgcSettings.ActivePage := tsGeneral
  else if SameText(ACategoryName, 'System Prompt') then
    pgcSettings.ActivePage := tsSystemPrompt
  else if SameText(ACategoryName, 'Templates') then
    pgcSettings.ActivePage := tsTemplates
  else if SameText(ACategoryName, 'Gemini') then
    pgcSettings.ActivePage := tsGemini
  else if SameText(ACategoryName, 'OpenAI') then
    pgcSettings.ActivePage := tsOpenAI
  else if SameText(ACategoryName, 'Claude') then
    pgcSettings.ActivePage := tsClaude
  else if SameText(ACategoryName, 'DeepSeek') then
    pgcSettings.ActivePage := tsDeepSeek
  else if SameText(ACategoryName, 'Groq') then
    pgcSettings.ActivePage := tsGroq
  else if SameText(ACategoryName, 'Ollama') then
    pgcSettings.ActivePage := tsOllama;
end;

end.
