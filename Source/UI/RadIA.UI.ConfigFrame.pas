unit RadIA.UI.ConfigFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, System.Generics.Collections, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config, ToolsAPI,
  RadIA.Core.PromptTemplates;

type
  TFrameAIConfig = class(TFrame)
  published
    pgcSettings: TPageControl;
    tsGemini: TTabSheet;
    pnlGemini: TPanel;
    tsOpenAI: TTabSheet;
    pnlOpenAI: TPanel;
    tsClaude: TTabSheet;
    pnlClaude: TPanel;
    tsDeepSeek: TTabSheet;
    pnlDeepSeek: TPanel;
    tsGroq: TTabSheet;
    pnlGroq: TPanel;
    tsOllama: TTabSheet;
    pnlOllama: TPanel;
    tsOpenRouter: TTabSheet;
    pnlOpenRouter: TPanel;
    tsSystemPrompt: TTabSheet;
    pnlSystemPrompt: TPanel;
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
    lblOpenRouterKey: TLabel;
    edtOpenRouterKey: TEdit;
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
    
    FEdtTemperatures: TDictionary<string, TEdit>;
    FEdtMaxTokens: TDictionary<string, TEdit>;
    FEdtTimeouts: TDictionary<string, TEdit>;
    FChkSmartConfig: TCheckBox;
    
    tsGeneral: TTabSheet;
    pnlGeneral: TPanel;
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

    tsAutocomplete: TTabSheet;
    pnlAutocomplete: TPanel;
    chkAutocompleteEnabled: TCheckBox;
    lblAutocompleteProvider: TLabel;
    cmbAutocompleteProvider: TComboBox;
    lblAutocompleteModel: TLabel;
    cmbAutocompleteModel: TComboBox;
    lblAutocompleteDelay: TLabel;
    edtAutocompleteDelay: TEdit;
    
    procedure btnBrowseLogPathClick(Sender: TObject);
    procedure btnResetQuotaClick(Sender: TObject);
    procedure chkAutocompleteEnabledClick(Sender: TObject);
    procedure cmbAutocompleteProviderChange(Sender: TObject);
    procedure UpdateAutocompleteModels;
    
    procedure CreateProviderAdvancedControls(ATabSheet: TTabSheet; const AProviderId: string);
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
  System.IOUtils, System.JSON, RadIA.UI.Resources, System.UITypes, Vcl.FileCtrl, RadIA.Core.Logger, Vcl.Themes,
  RadIA.Core.ProviderRegistry;

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
  FConfig := TRadIAConfig.GetInstance;
  FTemplateManager := TPromptTemplateManager.Create;
  FTemplateManager.Load;

  FEdtTemperatures := TDictionary<string, TEdit>.Create;
  FEdtMaxTokens := TDictionary<string, TEdit>.Create;
  FEdtTimeouts := TDictionary<string, TEdit>.Create;

  CreateProviderAdvancedControls(tsGemini, 'Gemini');
  CreateProviderAdvancedControls(tsOpenAI, 'OpenAI');
  CreateProviderAdvancedControls(tsClaude, 'Claude');
  CreateProviderAdvancedControls(tsDeepSeek, 'DeepSeek');
  CreateProviderAdvancedControls(tsGroq, 'Groq');
  CreateProviderAdvancedControls(tsOllama, 'Ollama');
  CreateProviderAdvancedControls(tsOpenRouter, 'OpenRouter');

  { Create General/Logs Tab and controls programmatically }
  tsGeneral := TTabSheet.Create(Self);
  tsGeneral.PageControl := pgcSettings;
  tsGeneral.Caption := 'General / Logs';
  tsGeneral.TabVisible := False;

  pnlGeneral := TPanel.Create(Self);
  pnlGeneral.Parent := tsGeneral;
  pnlGeneral.Align := alClient;
  pnlGeneral.BevelOuter := bvNone;
  pnlGeneral.ShowCaption := False;

  FChkSmartConfig := TCheckBox.Create(Self);
  FChkSmartConfig.Parent := pnlGeneral;
  FChkSmartConfig.Left := 16;
  FChkSmartConfig.Top := 16;
  FChkSmartConfig.Width := 300;
  FChkSmartConfig.Height := 23;
  FChkSmartConfig.Caption := 'Auto (Smart Parameters)';

  chkLogEnabled := TCheckBox.Create(Self);
  chkLogEnabled.Parent := pnlGeneral;
  chkLogEnabled.Left := 16;
  chkLogEnabled.Top := 48;
  chkLogEnabled.Width := 200;
  chkLogEnabled.Caption := 'Enable logging';

  lblLogPath := TLabel.Create(Self);
  lblLogPath.Parent := pnlGeneral;
  lblLogPath.Left := 16;
  lblLogPath.Top := 80;
  lblLogPath.Caption := 'Log Folder Path:';

  edtLogPath := TEdit.Create(Self);
  edtLogPath.Parent := pnlGeneral;
  edtLogPath.Left := 16;
  edtLogPath.Top := 98;
  edtLogPath.Width := 320;

  btnBrowseLogPath := TButton.Create(Self);
  btnBrowseLogPath.Parent := pnlGeneral;
  btnBrowseLogPath.Left := 342;
  btnBrowseLogPath.Top := 96;
  btnBrowseLogPath.Width := 30;
  btnBrowseLogPath.Height := 23;
  btnBrowseLogPath.Caption := '...';
  btnBrowseLogPath.OnClick := btnBrowseLogPathClick;

  lblLogMaxSize := TLabel.Create(Self);
  lblLogMaxSize.Parent := pnlGeneral;
  lblLogMaxSize.Left := 16;
  lblLogMaxSize.Top := 136;
  lblLogMaxSize.Caption := 'Max Log File Size (KB):';

  edtLogMaxSize := TEdit.Create(Self);
  edtLogMaxSize.Parent := pnlGeneral;
  edtLogMaxSize.Left := 16;
  edtLogMaxSize.Top := 154;
  edtLogMaxSize.Width := 100;
  edtLogMaxSize.NumbersOnly := True;

  grpQuota := TGroupBox.Create(Self);
  grpQuota.Parent := pnlGeneral;
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

  { Create Inline Autocomplete Tab and controls programmatically }
  tsAutocomplete := TTabSheet.Create(Self);
  tsAutocomplete.PageControl := pgcSettings;
  tsAutocomplete.Caption := 'Inline Autocomplete';
  tsAutocomplete.TabVisible := False;

  pnlAutocomplete := TPanel.Create(Self);
  pnlAutocomplete.Parent := tsAutocomplete;
  pnlAutocomplete.Align := alClient;
  pnlAutocomplete.BevelOuter := bvNone;
  pnlAutocomplete.ShowCaption := False;

  chkAutocompleteEnabled := TCheckBox.Create(Self);
  chkAutocompleteEnabled.Parent := pnlAutocomplete;
  chkAutocompleteEnabled.Left := 16;
  chkAutocompleteEnabled.Top := 16;
  chkAutocompleteEnabled.Width := 300;
  chkAutocompleteEnabled.Caption := 'Enable Inline Autocomplete (Ghost Text)';
  chkAutocompleteEnabled.OnClick := chkAutocompleteEnabledClick;

  lblAutocompleteProvider := TLabel.Create(Self);
  lblAutocompleteProvider.Parent := pnlAutocomplete;
  lblAutocompleteProvider.Left := 16;
  lblAutocompleteProvider.Top := 54;
  lblAutocompleteProvider.Caption := 'Dedicated AI Provider:';

  cmbAutocompleteProvider := TComboBox.Create(Self);
  cmbAutocompleteProvider.Parent := pnlAutocomplete;
  cmbAutocompleteProvider.Left := 16;
  cmbAutocompleteProvider.Top := 72;
  cmbAutocompleteProvider.Width := 200;
  cmbAutocompleteProvider.Style := csDropDownList;

  lblAutocompleteModel := TLabel.Create(Self);
  lblAutocompleteModel.Parent := pnlAutocomplete;
  lblAutocompleteModel.Left := 16;
  lblAutocompleteModel.Top := 112;
  lblAutocompleteModel.Caption := 'Dedicated AI Model:';

  cmbAutocompleteModel := TComboBox.Create(Self);
  cmbAutocompleteModel.Parent := pnlAutocomplete;
  cmbAutocompleteModel.Left := 16;
  cmbAutocompleteModel.Top := 130;
  cmbAutocompleteModel.Width := 320;
  cmbAutocompleteModel.Style := csDropDown;

  lblAutocompleteDelay := TLabel.Create(Self);
  lblAutocompleteDelay.Parent := pnlAutocomplete;
  lblAutocompleteDelay.Left := 16;
  lblAutocompleteDelay.Top := 170;
  lblAutocompleteDelay.Caption := 'Debounce Delay (ms):';

  edtAutocompleteDelay := TEdit.Create(Self);
  edtAutocompleteDelay.Parent := pnlAutocomplete;
  edtAutocompleteDelay.Left := 16;
  edtAutocompleteDelay.Top := 188;
  edtAutocompleteDelay.Width := 100;
  edtAutocompleteDelay.NumbersOnly := True;

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
  cmbAutocompleteProvider.OnChange := cmbAutocompleteProviderChange;
  LoadConfig;
end;

procedure TFrameAIConfig.chkAutocompleteEnabledClick(Sender: TObject);
begin
  FConfig.SetAutocompleteEnabled(chkAutocompleteEnabled.Checked);
  FConfig.Save;
end;

procedure TFrameAIConfig.cmbAutocompleteProviderChange(Sender: TObject);
begin
  UpdateAutocompleteModels;
  if cmbAutocompleteModel.Items.Count > 0 then
    cmbAutocompleteModel.ItemIndex := 0;
end;

procedure TFrameAIConfig.UpdateAutocompleteModels;
var
  LProviders: TArray<TProviderMetadata>;
  LMeta: TProviderMetadata;
  LModel: string;
begin
  if not Assigned(cmbAutocompleteProvider) or not Assigned(cmbAutocompleteModel) then
    Exit;
    
  cmbAutocompleteModel.Items.Clear;
  if cmbAutocompleteProvider.ItemIndex >= 0 then
  begin
    LProviders := TProviderRegistry.GetProviders;
    if cmbAutocompleteProvider.ItemIndex < Length(LProviders) then
    begin
      LMeta := LProviders[cmbAutocompleteProvider.ItemIndex];
      for LModel in LMeta.DefaultModels do
        cmbAutocompleteModel.Items.Add(LModel);
    end;
  end;
end;

destructor TFrameAIConfig.Destroy;
begin
  FTemplateManager.Free;
  FEdtTemperatures.Free;
  FEdtMaxTokens.Free;
  FEdtTimeouts.Free;
  inherited Destroy;
end;

procedure TFrameAIConfig.CreateProviderAdvancedControls(ATabSheet: TTabSheet; const AProviderId: string);
var
  LGroupBox: TGroupBox;
  LLabel: TLabel;
  LParent: TWinControl;
  I: Integer;
  LEdtTemp, LEdtMax, LEdtTime: TEdit;
begin
  LParent := ATabSheet;
  for I := 0 to ATabSheet.ControlCount - 1 do
  begin
    if ATabSheet.Controls[I] is TPanel then
    begin
      LParent := TWinControl(ATabSheet.Controls[I]);
      Break;
    end;
  end;

  LGroupBox := TGroupBox.Create(Self);
  LGroupBox.Parent := LParent;
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

  LEdtTemp := TEdit.Create(Self);
  LEdtTemp.Parent := LGroupBox;
  LEdtTemp.Left := 16;
  LEdtTemp.Top := 42;
  LEdtTemp.Width := 100;
  FEdtTemperatures.Add(AProviderId, LEdtTemp);

  // Max Tokens
  LLabel := TLabel.Create(Self);
  LLabel.Parent := LGroupBox;
  LLabel.Left := 140;
  LLabel.Top := 24;
  LLabel.Caption := 'Max Output Tokens:';

  LEdtMax := TEdit.Create(Self);
  LEdtMax.Parent := LGroupBox;
  LEdtMax.Left := 140;
  LEdtMax.Top := 42;
  LEdtMax.Width := 100;
  LEdtMax.NumbersOnly := True;
  FEdtMaxTokens.Add(AProviderId, LEdtMax);

  // Timeout
  LLabel := TLabel.Create(Self);
  LLabel.Parent := LGroupBox;
  LLabel.Left := 264;
  LLabel.Top := 24;
  LLabel.Caption := 'Timeout (seconds):';

  LEdtTime := TEdit.Create(Self);
  LEdtTime.Parent := LGroupBox;
  LEdtTime.Left := 264;
  LEdtTime.Top := 42;
  LEdtTime.Width := 100;
  LEdtTime.NumbersOnly := True;
  FEdtTimeouts.Add(AProviderId, LEdtTime);
end;

procedure TFrameAIConfig.UpdateVCLColors(const AThemeName: string);
var
  LColors: TRadIAThemeColors;
  I: Integer;
begin
  LColors := TRadIAThemeColors.GetColorsForTheme(AThemeName);

  Self.StyleElements := Self.StyleElements - [seClient, seBorder];
  TWinControlHack(Self).Color := LColors.BgBase;
  pgcSettings.StyleElements := pgcSettings.StyleElements - [seClient, seBorder];
  TWinControlHack(pgcSettings).Color := LColors.BgBase;

  TWinControlHack(Self).ParentBackground := False;
  TWinControlHack(pgcSettings).ParentBackground := False;
  for I := 0 to pgcSettings.PageCount - 1 do
  begin
    pgcSettings.Pages[I].StyleElements := pgcSettings.Pages[I].StyleElements - [seClient, seBorder];
    TTabSheetColorHack(pgcSettings.Pages[I]).ParentBackground := False;
    TTabSheetColorHack(pgcSettings.Pages[I]).Color := LColors.BgBase;
  end;

  pnlGemini.StyleElements := pnlGemini.StyleElements - [seClient, seBorder];
  pnlGemini.Color := LColors.BgBase;
  pnlGemini.ParentBackground := False;
  pnlOpenAI.StyleElements := pnlOpenAI.StyleElements - [seClient, seBorder];
  pnlOpenAI.Color := LColors.BgBase;
  pnlOpenAI.ParentBackground := False;
  pnlClaude.StyleElements := pnlClaude.StyleElements - [seClient, seBorder];
  pnlClaude.Color := LColors.BgBase;
  pnlClaude.ParentBackground := False;
  pnlDeepSeek.StyleElements := pnlDeepSeek.StyleElements - [seClient, seBorder];
  pnlDeepSeek.Color := LColors.BgBase;
  pnlDeepSeek.ParentBackground := False;
  pnlGroq.StyleElements := pnlGroq.StyleElements - [seClient, seBorder];
  pnlGroq.Color := LColors.BgBase;
  pnlGroq.ParentBackground := False;
  pnlOllama.StyleElements := pnlOllama.StyleElements - [seClient, seBorder];
  pnlOllama.Color := LColors.BgBase;
  pnlOllama.ParentBackground := False;
  pnlOpenRouter.StyleElements := pnlOpenRouter.StyleElements - [seClient, seBorder];
  pnlOpenRouter.Color := LColors.BgBase;
  pnlOpenRouter.ParentBackground := False;
  pnlSystemPrompt.StyleElements := pnlSystemPrompt.StyleElements - [seClient, seBorder];
  pnlSystemPrompt.Color := LColors.BgBase;
  pnlSystemPrompt.ParentBackground := False;

  if Assigned(pnlGeneral) then
  begin
    pnlGeneral.StyleElements := pnlGeneral.StyleElements - [seClient, seBorder];
    pnlGeneral.Color := LColors.BgBase;
    pnlGeneral.ParentBackground := False;
  end;

  for var LEdit in FEdtTemperatures.Values do
  begin
    LEdit.StyleElements := LEdit.StyleElements - [seClient, seBorder];
    LEdit.Color := LColors.InputBgColor;
    LEdit.Font.Color := LColors.TextColor;
  end;

  for var LEdit in FEdtMaxTokens.Values do
  begin
    LEdit.StyleElements := LEdit.StyleElements - [seClient, seBorder];
    LEdit.Color := LColors.InputBgColor;
    LEdit.Font.Color := LColors.TextColor;
  end;

  for var LEdit in FEdtTimeouts.Values do
  begin
    LEdit.StyleElements := LEdit.StyleElements - [seClient, seBorder];
    LEdit.Color := LColors.InputBgColor;
    LEdit.Font.Color := LColors.TextColor;
  end;// Memo do System Prompt
  memSystemPrompt.StyleElements := memSystemPrompt.StyleElements - [seClient, seBorder];
  memSystemPrompt.Color := LColors.InputBgColor;
  memSystemPrompt.Font.Color := LColors.TextColor;

  // Inputs
  edtGeminiKey.StyleElements := edtGeminiKey.StyleElements - [seClient, seBorder];
  edtGeminiKey.Color := LColors.InputBgColor;
  edtGeminiKey.Font.Color := LColors.TextColor;
  
  edtOpenAIKey.StyleElements := edtOpenAIKey.StyleElements - [seClient, seBorder];
  edtOpenAIKey.Color := LColors.InputBgColor;
  edtOpenAIKey.Font.Color := LColors.TextColor;
  edtOpenAICustomUrl.StyleElements := edtOpenAICustomUrl.StyleElements - [seClient, seBorder];
  edtOpenAICustomUrl.Color := LColors.InputBgColor;
  edtOpenAICustomUrl.Font.Color := LColors.TextColor;
  
  edtClaudeKey.StyleElements := edtClaudeKey.StyleElements - [seClient, seBorder];
  edtClaudeKey.Color := LColors.InputBgColor;
  edtClaudeKey.Font.Color := LColors.TextColor;
  
  edtDeepSeekKey.StyleElements := edtDeepSeekKey.StyleElements - [seClient, seBorder];
  edtDeepSeekKey.Color := LColors.InputBgColor;
  edtDeepSeekKey.Font.Color := LColors.TextColor;
  
  edtGroqKey.StyleElements := edtGroqKey.StyleElements - [seClient, seBorder];
  edtGroqKey.Color := LColors.InputBgColor;
  edtGroqKey.Font.Color := LColors.TextColor;
  
  edtOllamaUrl.StyleElements := edtOllamaUrl.StyleElements - [seClient, seBorder];
  edtOllamaUrl.Color := LColors.InputBgColor;
  edtOllamaUrl.Font.Color := LColors.TextColor;
  
  edtOpenRouterKey.StyleElements := edtOpenRouterKey.StyleElements - [seClient, seBorder];
  edtOpenRouterKey.Color := LColors.InputBgColor;
  edtOpenRouterKey.Font.Color := LColors.TextColor;

  // Labels
  lblGeminiKey.StyleElements := lblGeminiKey.StyleElements - [seClient, seBorder];
  lblGeminiKey.Font.Color := LColors.TextColor;
  lblOpenAIKey.StyleElements := lblOpenAIKey.StyleElements - [seClient, seBorder];
  lblOpenAIKey.Font.Color := LColors.TextColor;
  lblOpenAICustomUrl.StyleElements := lblOpenAICustomUrl.StyleElements - [seClient, seBorder];
  lblOpenAICustomUrl.Font.Color := LColors.TextColor;
  lblClaudeKey.StyleElements := lblClaudeKey.StyleElements - [seClient, seBorder];
  lblClaudeKey.Font.Color := LColors.TextColor;
  lblDeepSeekKey.StyleElements := lblDeepSeekKey.StyleElements - [seClient, seBorder];
  lblDeepSeekKey.Font.Color := LColors.TextColor;
  lblGroqKey.StyleElements := lblGroqKey.StyleElements - [seClient, seBorder];
  lblGroqKey.Font.Color := LColors.TextColor;
  lblOllamaUrl.StyleElements := lblOllamaUrl.StyleElements - [seClient, seBorder];
  lblOllamaUrl.Font.Color := LColors.TextColor;
  lblOpenRouterKey.StyleElements := lblOpenRouterKey.StyleElements - [seClient, seBorder];
  lblOpenRouterKey.Font.Color := LColors.TextColor;

  // Aba de Templates
  pnlTemplatesLeft.StyleElements := pnlTemplatesLeft.StyleElements - [seClient, seBorder];
  pnlTemplatesLeft.Color := LColors.BgBase;
  pnlTemplatesLeft.ParentBackground := False;
  pnlTemplatesLeftButtons.StyleElements := pnlTemplatesLeftButtons.StyleElements - [seClient, seBorder];
  pnlTemplatesLeftButtons.Color := LColors.BgBase;
  pnlTemplatesLeftButtons.ParentBackground := False;
  pnlTemplatesClient.StyleElements := pnlTemplatesClient.StyleElements - [seClient, seBorder];
  pnlTemplatesClient.Color := LColors.BgBase;
  pnlTemplatesClient.ParentBackground := False;
  
  lstTemplates.StyleElements := lstTemplates.StyleElements - [seClient, seBorder];
  lstTemplates.Color := LColors.InputBgColor;
  lstTemplates.Font.Color := LColors.TextColor;
  edtTemplateName.StyleElements := edtTemplateName.StyleElements - [seClient, seBorder];
  edtTemplateName.Color := LColors.InputBgColor;
  edtTemplateName.Font.Color := LColors.TextColor;
  edtTemplateDesc.StyleElements := edtTemplateDesc.StyleElements - [seClient, seBorder];
  edtTemplateDesc.Color := LColors.InputBgColor;
  edtTemplateDesc.Font.Color := LColors.TextColor;
  memTemplateBody.StyleElements := memTemplateBody.StyleElements - [seClient, seBorder];
  memTemplateBody.Color := LColors.InputBgColor;
  memTemplateBody.Font.Color := LColors.TextColor;
  
  lblTemplateName.StyleElements := lblTemplateName.StyleElements - [seClient, seBorder];
  lblTemplateName.Font.Color := LColors.TextColor;
  lblTemplateDesc.StyleElements := lblTemplateDesc.StyleElements - [seClient, seBorder];
  lblTemplateDesc.Font.Color := LColors.TextColor;
  lblTemplateBody.StyleElements := lblTemplateBody.StyleElements - [seClient, seBorder];
  lblTemplateBody.Font.Color := LColors.TextColor;



  if Assigned(FChkSmartConfig) then
  begin
    FChkSmartConfig.StyleElements := FChkSmartConfig.StyleElements - [seClient, seBorder];
    FChkSmartConfig.Font.Color := LColors.TextColor;
  end;

  if Assigned(tsGeneral) then
  begin
    tsGeneral.StyleElements := tsGeneral.StyleElements - [seClient, seBorder];
    TTabSheetColorHack(tsGeneral).ParentBackground := False;
    TTabSheetColorHack(tsGeneral).Color := LColors.BgBase;
  end;
  if Assigned(chkLogEnabled) then
  begin
    chkLogEnabled.StyleElements := chkLogEnabled.StyleElements - [seClient, seBorder];
    chkLogEnabled.Font.Color := LColors.TextColor;
  end;
  if Assigned(lblLogPath) then
  begin
    lblLogPath.StyleElements := lblLogPath.StyleElements - [seClient, seBorder];
    lblLogPath.Font.Color := LColors.TextColor;
  end;
  if Assigned(edtLogPath) then
  begin
    edtLogPath.StyleElements := edtLogPath.StyleElements - [seClient, seBorder];
    edtLogPath.Color := LColors.InputBgColor;
    edtLogPath.Font.Color := LColors.TextColor;
  end;
  if Assigned(edtLogMaxSize) then
  begin
    edtLogMaxSize.StyleElements := edtLogMaxSize.StyleElements - [seClient, seBorder];
    edtLogMaxSize.Color := LColors.InputBgColor;
    edtLogMaxSize.Font.Color := LColors.TextColor;
  end;
  
  if Assigned(grpQuota) then
  begin
    grpQuota.StyleElements := grpQuota.StyleElements - [seClient, seBorder];
    grpQuota.Font.Color := LColors.TextColor;
    chkQuotaEnabled.StyleElements := chkQuotaEnabled.StyleElements - [seClient, seBorder];
    chkQuotaEnabled.Font.Color := LColors.TextColor;
    lblQuotaLimit.StyleElements := lblQuotaLimit.StyleElements - [seClient, seBorder];
    lblQuotaLimit.Font.Color := LColors.TextColor;
    edtQuotaLimit.StyleElements := edtQuotaLimit.StyleElements - [seClient, seBorder];
    edtQuotaLimit.Color := LColors.InputBgColor;
    edtQuotaLimit.Font.Color := LColors.TextColor;
    lblQuotaUsed.StyleElements := lblQuotaUsed.StyleElements - [seClient, seBorder];
    lblQuotaUsed.Font.Color := LColors.TextColor;
  end;
end;

procedure TFrameAIConfig.LoadConfig;
var
  LFormatSettings: TFormatSettings;
  LProviders: TArray<TProviderMetadata>;
  LActiveId: string;
  LSelectedIndex: Integer;
  I: Integer;
  LPair: TPair<string, TEdit>;
begin
  LFormatSettings := TFormatSettings.Invariant;
  
  edtGeminiKey.Text := FConfig.GetApiKey('Gemini');
  edtOpenAIKey.Text := FConfig.GetApiKey('OpenAI');
  edtOpenAICustomUrl.Text := FConfig.OpenAICustomBaseUrl;
  edtClaudeKey.Text := FConfig.GetApiKey('Claude');
  edtDeepSeekKey.Text := FConfig.GetApiKey('DeepSeek');
  edtGroqKey.Text := FConfig.GetApiKey('Groq');
  edtOpenRouterKey.Text := FConfig.GetApiKey('OpenRouter');
  memSystemPrompt.Text := FConfig.SystemPrompt;
  edtOllamaUrl.Text := FConfig.OllamaBaseUrl;

  if Assigned(FChkSmartConfig) then
    FChkSmartConfig.Checked := FConfig.SmartConfigEnabled;

  for LPair in FEdtTemperatures do
    LPair.Value.Text := FormatFloat('0.0', FConfig.GetTemperature(LPair.Key), LFormatSettings);
  for LPair in FEdtMaxTokens do
    LPair.Value.Text := IntToStr(FConfig.GetMaxTokens(LPair.Key));
  for LPair in FEdtTimeouts do
    LPair.Value.Text := IntToStr(FConfig.GetTimeout(LPair.Key));
  
  // O loop antigo baseado em TAIProviderType foi totalmente removido daqui

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

  if Assigned(tsTemplates) then
    tsTemplates.TabVisible := False;
  
  { Carregar Autocomplete }
  if Assigned(chkAutocompleteEnabled) then
    chkAutocompleteEnabled.Checked := FConfig.GetAutocompleteEnabled;
    
  if Assigned(cmbAutocompleteProvider) then
  begin
    LProviders := TProviderRegistry.GetProviders;
    LActiveId := FConfig.GetAutocompleteProvider;
    cmbAutocompleteProvider.Items.Clear;
    LSelectedIndex := 0;
    
    for I := 0 to Length(LProviders) - 1 do
    begin
      cmbAutocompleteProvider.Items.Add(LProviders[I].DisplayName);
      if SameText(LProviders[I].Id, LActiveId) then
        LSelectedIndex := I;
    end;
    
    if cmbAutocompleteProvider.Items.Count > 0 then
      cmbAutocompleteProvider.ItemIndex := LSelectedIndex;
  end;

  UpdateAutocompleteModels;
  if Assigned(cmbAutocompleteModel) then
    cmbAutocompleteModel.Text := FConfig.GetAutocompleteModel;

  if Assigned(edtAutocompleteDelay) then
    edtAutocompleteDelay.Text := IntToStr(FConfig.GetAutocompleteDelay);

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
  LFormatSettings: TFormatSettings;
  LTemp: Double;
  LProviders: TArray<TProviderMetadata>;
  LMeta: TProviderMetadata;
  LPair: TPair<string, TEdit>;
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

  FConfig.SetApiKey('Gemini', Trim(edtGeminiKey.Text));
  FConfig.SetApiKey('OpenAI', Trim(edtOpenAIKey.Text));
  FConfig.OpenAICustomBaseUrl := LOpenAIUrl;
  FConfig.SetApiKey('Claude', Trim(edtClaudeKey.Text));
  FConfig.SetApiKey('DeepSeek', Trim(edtDeepSeekKey.Text));
  FConfig.SetApiKey('Groq', Trim(edtGroqKey.Text));
  FConfig.SetApiKey('OpenRouter', Trim(edtOpenRouterKey.Text));
  FConfig.SystemPrompt := memSystemPrompt.Text;
  FConfig.OllamaBaseUrl := LOllamaUrl;

  if Assigned(FChkSmartConfig) then
    FConfig.SmartConfigEnabled := FChkSmartConfig.Checked;

  for LPair in FEdtTemperatures do
  begin
    if TryStrToFloat(LPair.Value.Text, LTemp, LFormatSettings) then
    begin
      if (LTemp >= 0.0) and (LTemp <= 2.0) then
        FConfig.SetTemperature(LPair.Key, LTemp);
    end;
  end;

  for LPair in FEdtMaxTokens do
    FConfig.SetMaxTokens(LPair.Key, StrToIntDef(LPair.Value.Text, 2048));

  for LPair in FEdtTimeouts do
    FConfig.SetTimeout(LPair.Key, StrToIntDef(LPair.Value.Text, 60));
  
  // O loop baseado em TAIProviderType foi completamente removido daqui

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

  { Salvar Autocomplete }
  if Assigned(chkAutocompleteEnabled) then
    FConfig.SetAutocompleteEnabled(chkAutocompleteEnabled.Checked);

  if Assigned(cmbAutocompleteProvider) and (cmbAutocompleteProvider.ItemIndex >= 0) then
  begin
    LProviders := TProviderRegistry.GetProviders;
    if (cmbAutocompleteProvider.ItemIndex < Length(LProviders)) then
    begin
      LMeta := LProviders[cmbAutocompleteProvider.ItemIndex];
      try
        FConfig.SetAutocompleteProvider(LMeta.Id);
      except
        on E: Exception do
          TLogger.Log('Error mapping autocomplete provider: ' + E.Message, 'ConfigFrame');
      end;
    end;
  end;

  if Assigned(cmbAutocompleteModel) then
    FConfig.SetAutocompleteModel(Trim(cmbAutocompleteModel.Text));

  if Assigned(edtAutocompleteDelay) then
    FConfig.SetAutocompleteDelay(StrToIntDef(edtAutocompleteDelay.Text, 1000));

  FConfig.Save;

  { Save templates too }
  FTemplateManager.Save;

  LForm := GetParentForm(Self);
  if (LForm <> nil) and SameText(LForm.ClassName, 'TFormAIConfig') then
    LForm.ModalResult := mrOk;
end;

procedure TFrameAIConfig.btnCancelClick(Sender: TObject);
var
  LForm: TCustomForm;
begin
  LoadConfig;
  LForm := GetParentForm(Self);
  if (LForm <> nil) and SameText(LForm.ClassName, 'TFormAIConfig') then
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
    pgcSettings.ActivePage := tsOllama
  else if SameText(ACategoryName, 'OpenRouter') then
    pgcSettings.ActivePage := tsOpenRouter
  else if SameText(ACategoryName, 'Inline Autocomplete') then
    pgcSettings.ActivePage := tsAutocomplete;
end;

end.
