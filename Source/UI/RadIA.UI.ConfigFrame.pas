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
    tsLMStudio: TTabSheet;
    pnlLMStudio: TPanel;
    lblLMStudioUrl: TLabel;
    edtLMStudioUrl: TEdit;
    
    tsGithubCopilot: TTabSheet;
    pnlGithubCopilot: TPanel;
    lblGithubCopilotKey: TLabel;
    edtGithubCopilotKey: TEdit;
    btnConnectGithub: TButton;
    btnImportVSCode: TButton;

    tsAzureOpenAI: TTabSheet;
    pnlAzureOpenAI: TPanel;
    lblAzureKey: TLabel;
    edtAzureKey: TEdit;
    lblAzureUrl: TLabel;
    edtAzureUrl: TEdit;
    lblAzureModel: TLabel;
    edtAzureModel: TEdit;
    lblAzureApiVersion: TLabel;
    edtAzureApiVersion: TEdit;

    tsQwen: TTabSheet;
    pnlQwen: TPanel;
    lblQwenKey: TLabel;
    edtQwenKey: TEdit;
    lnkQwenGetKey: TLabel;

    tsMistral: TTabSheet;
    pnlMistral: TPanel;
    lblMistralKey: TLabel;
    edtMistralKey: TEdit;
    lnkMistralGetKey: TLabel;

    tsBedrock: TTabSheet;
    pnlBedrock: TPanel;
    lblAwsAccessKeyId: TLabel;
    edtAwsAccessKeyId: TEdit;
    lblAwsSecretAccessKey: TLabel;
    edtAwsSecretAccessKey: TEdit;
    lblAwsRegion: TLabel;
    edtAwsRegion: TEdit;
    lblAwsSessionToken: TLabel;
    edtAwsSessionToken: TEdit;
    lnkBedrockGetKey: TLabel;

    lnkGeminiGetKey: TLabel;
    lnkOpenAIGetKey: TLabel;
    lnkClaudeGetKey: TLabel;
    lnkDeepSeekGetKey: TLabel;
    lnkGroqGetKey: TLabel;
    lnkOpenRouterGetKey: TLabel;
    
    tsSystemPrompt: TTabSheet;
    pnlSystemPrompt: TPanel;
    lblGeminiKey: TLabel;
    edtGeminiKey: TEdit;
    grpGeminiAuthType: TRadioGroup;
    lblOpenAIKey: TLabel;
    edtOpenAIKey: TEdit;
    lblOpenAICustomUrl: TLabel;
    edtOpenAICustomUrl: TEdit;
    grpOpenAIAuthType: TRadioGroup;
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
    lblTemplateSlash: TLabel;
    edtTemplateSlash: TEdit;
    chkIsProjectGenerator: TCheckBox;
    btnExportTemplates: TButton;
    btnImportTemplates: TButton;
    dlgsTemplatesSave: TSaveDialog;
    dlgsTemplatesOpen: TOpenDialog;
    procedure lstTemplatesClick(Sender: TObject);
    procedure btnNewTemplateClick(Sender: TObject);
    procedure btnDeleteTemplateClick(Sender: TObject);
    procedure btnSaveTemplateClick(Sender: TObject);
    procedure btnRestoreDefaultsClick(Sender: TObject);
    procedure btnExportTemplatesClick(Sender: TObject);
    procedure btnImportTemplatesClick(Sender: TObject);
    procedure grpGeminiAuthTypeClick(Sender: TObject);
    procedure grpOpenAIAuthTypeClick(Sender: TObject);
    procedure lnkGeminiGetKeyClick(Sender: TObject);
    procedure lnkOpenAIGetKeyClick(Sender: TObject);
    procedure lnkClaudeGetKeyClick(Sender: TObject);
    procedure lnkDeepSeekGetKeyClick(Sender: TObject);
    procedure lnkGroqGetKeyClick(Sender: TObject);
    procedure lnkOpenRouterGetKeyClick(Sender: TObject);
    procedure lnkQwenGetKeyClick(Sender: TObject);
    procedure lnkMistralGetKeyClick(Sender: TObject);
    procedure lnkBedrockGetKeyClick(Sender: TObject);
    procedure btnConnectGithubClick(Sender: TObject);
    procedure btnImportVSCodeClick(Sender: TObject);
  private
    FConfig: IAIConfig;
    FTemplateManager: TPromptTemplateManager;
    FOnClose: TNotifyEvent;
    lblTemplateOrigin: TLabel;
    
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

    procedure btnBrowseLogPathClick(Sender: TObject);
    procedure btnResetQuotaClick(Sender: TObject);
    
    procedure CreateProviderAdvancedControls(ATabSheet: TTabSheet; const AProviderId: string);
    procedure PopulateTemplatesList;
    procedure OpenUrl(const AUrl: string);
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
  RadIA.Core.ProviderRegistry, Winapi.ShellAPI, RadIA.UI.GithubAuthForm;

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

  lblTemplateOrigin := TLabel.Create(Self);
  lblTemplateOrigin.Parent := pnlTemplatesClient;
  lblTemplateOrigin.AutoSize := False;
  lblTemplateOrigin.Width := 200;
  lblTemplateOrigin.Alignment := taRightJustify;
  lblTemplateOrigin.Left := pnlTemplatesClient.Width - 217;
  lblTemplateOrigin.Top := lblTemplateName.Top;
  lblTemplateOrigin.Anchors := [akTop, akRight];
  lblTemplateOrigin.Font.Assign(lblTemplateName.Font);
  lblTemplateOrigin.Font.Style := [];
  lblTemplateOrigin.Caption := '';

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
  CreateProviderAdvancedControls(tsLMStudio, 'LMStudio');
  CreateProviderAdvancedControls(tsGithubCopilot, 'GithubCopilot');
  CreateProviderAdvancedControls(tsAzureOpenAI, 'AzureOpenAI');
  CreateProviderAdvancedControls(tsQwen, 'Qwen');
  CreateProviderAdvancedControls(tsMistral, 'Mistral');
  CreateProviderAdvancedControls(tsBedrock, 'Bedrock');
 
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
  pnlLMStudio.StyleElements := pnlLMStudio.StyleElements - [seClient, seBorder];
  pnlLMStudio.Color := LColors.BgBase;
  pnlLMStudio.ParentBackground := False;
  pnlGithubCopilot.StyleElements := pnlGithubCopilot.StyleElements - [seClient, seBorder];
  pnlGithubCopilot.Color := LColors.BgBase;
  pnlGithubCopilot.ParentBackground := False;
  pnlAzureOpenAI.StyleElements := pnlAzureOpenAI.StyleElements - [seClient, seBorder];
  pnlAzureOpenAI.Color := LColors.BgBase;
  pnlAzureOpenAI.ParentBackground := False;
  pnlQwen.StyleElements := pnlQwen.StyleElements - [seClient, seBorder];
  pnlQwen.Color := LColors.BgBase;
  pnlQwen.ParentBackground := False;
  pnlMistral.StyleElements := pnlMistral.StyleElements - [seClient, seBorder];
  pnlMistral.Color := LColors.BgBase;
  pnlMistral.ParentBackground := False;
  pnlBedrock.StyleElements := pnlBedrock.StyleElements - [seClient, seBorder];
  pnlBedrock.Color := LColors.BgBase;
  pnlBedrock.ParentBackground := False;
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

  // Auth Type Radio Groups
  grpGeminiAuthType.StyleElements := grpGeminiAuthType.StyleElements - [seClient, seBorder];
  grpGeminiAuthType.Font.Color := LColors.TextColor;
  grpOpenAIAuthType.StyleElements := grpOpenAIAuthType.StyleElements - [seClient, seBorder];
  grpOpenAIAuthType.Font.Color := LColors.TextColor;

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
  edtLMStudioUrl.StyleElements := edtLMStudioUrl.StyleElements - [seClient, seBorder];
  edtLMStudioUrl.Color := LColors.InputBgColor;
  edtLMStudioUrl.Font.Color := LColors.TextColor;
  edtGithubCopilotKey.StyleElements := edtGithubCopilotKey.StyleElements - [seClient, seBorder];
  edtGithubCopilotKey.Color := LColors.InputBgColor;
  edtGithubCopilotKey.Font.Color := LColors.TextColor;
  
  edtAzureKey.StyleElements := edtAzureKey.StyleElements - [seClient, seBorder];
  edtAzureKey.Color := LColors.InputBgColor;
  edtAzureKey.Font.Color := LColors.TextColor;
  edtAzureUrl.StyleElements := edtAzureUrl.StyleElements - [seClient, seBorder];
  edtAzureUrl.Color := LColors.InputBgColor;
  edtAzureUrl.Font.Color := LColors.TextColor;
  edtAzureModel.StyleElements := edtAzureModel.StyleElements - [seClient, seBorder];
  edtAzureModel.Color := LColors.InputBgColor;
  edtAzureModel.Font.Color := LColors.TextColor;
  edtAzureApiVersion.StyleElements := edtAzureApiVersion.StyleElements - [seClient, seBorder];
  edtAzureApiVersion.Color := LColors.InputBgColor;
  edtAzureApiVersion.Font.Color := LColors.TextColor;

  edtQwenKey.StyleElements := edtQwenKey.StyleElements - [seClient, seBorder];
  edtQwenKey.Color := LColors.InputBgColor;
  edtQwenKey.Font.Color := LColors.TextColor;

  edtMistralKey.StyleElements := edtMistralKey.StyleElements - [seClient, seBorder];
  edtMistralKey.Color := LColors.InputBgColor;
  edtMistralKey.Font.Color := LColors.TextColor;
  
  edtAwsAccessKeyId.StyleElements := edtAwsAccessKeyId.StyleElements - [seClient, seBorder];
  edtAwsAccessKeyId.Color := LColors.InputBgColor;
  edtAwsAccessKeyId.Font.Color := LColors.TextColor;
  edtAwsSecretAccessKey.StyleElements := edtAwsSecretAccessKey.StyleElements - [seClient, seBorder];
  edtAwsSecretAccessKey.Color := LColors.InputBgColor;
  edtAwsSecretAccessKey.Font.Color := LColors.TextColor;
  edtAwsRegion.StyleElements := edtAwsRegion.StyleElements - [seClient, seBorder];
  edtAwsRegion.Color := LColors.InputBgColor;
  edtAwsRegion.Font.Color := LColors.TextColor;
  edtAwsSessionToken.StyleElements := edtAwsSessionToken.StyleElements - [seClient, seBorder];
  edtAwsSessionToken.Color := LColors.InputBgColor;
  edtAwsSessionToken.Font.Color := LColors.TextColor;

  // Labels Link
  lnkGeminiGetKey.StyleElements := lnkGeminiGetKey.StyleElements - [seClient, seBorder];
  lnkGeminiGetKey.Font.Color := LColors.AccentColor;
  lnkOpenAIGetKey.StyleElements := lnkOpenAIGetKey.StyleElements - [seClient, seBorder];
  lnkOpenAIGetKey.Font.Color := LColors.AccentColor;
  lnkClaudeGetKey.StyleElements := lnkClaudeGetKey.StyleElements - [seClient, seBorder];
  lnkClaudeGetKey.Font.Color := LColors.AccentColor;
  lnkDeepSeekGetKey.StyleElements := lnkDeepSeekGetKey.StyleElements - [seClient, seBorder];
  lnkDeepSeekGetKey.Font.Color := LColors.AccentColor;
  lnkGroqGetKey.StyleElements := lnkGroqGetKey.StyleElements - [seClient, seBorder];
  lnkGroqGetKey.Font.Color := LColors.AccentColor;
  lnkOpenRouterGetKey.StyleElements := lnkOpenRouterGetKey.StyleElements - [seClient, seBorder];
  lnkOpenRouterGetKey.Font.Color := LColors.AccentColor;
  
  lnkQwenGetKey.StyleElements := lnkQwenGetKey.StyleElements - [seClient, seBorder];
  lnkQwenGetKey.Font.Color := LColors.AccentColor;
  lnkMistralGetKey.StyleElements := lnkMistralGetKey.StyleElements - [seClient, seBorder];
  lnkMistralGetKey.Font.Color := LColors.AccentColor;
  
  lnkBedrockGetKey.StyleElements := lnkBedrockGetKey.StyleElements - [seClient, seBorder];
  lnkBedrockGetKey.Font.Color := LColors.AccentColor;

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
  lblLMStudioUrl.StyleElements := lblLMStudioUrl.StyleElements - [seClient, seBorder];
  lblLMStudioUrl.Font.Color := LColors.TextColor;
  
  lblAzureKey.StyleElements := lblAzureKey.StyleElements - [seClient, seBorder];
  lblAzureKey.Font.Color := LColors.TextColor;
  lblAzureUrl.StyleElements := lblAzureUrl.StyleElements - [seClient, seBorder];
  lblAzureUrl.Font.Color := LColors.TextColor;
  lblAzureModel.StyleElements := lblAzureModel.StyleElements - [seClient, seBorder];
  lblAzureModel.Font.Color := LColors.TextColor;
  lblAzureApiVersion.StyleElements := lblAzureApiVersion.StyleElements - [seClient, seBorder];
  lblAzureApiVersion.Font.Color := LColors.TextColor;

  lblQwenKey.StyleElements := lblQwenKey.StyleElements - [seClient, seBorder];
  lblQwenKey.Font.Color := LColors.TextColor;
  lblMistralKey.StyleElements := lblMistralKey.StyleElements - [seClient, seBorder];
  lblMistralKey.Font.Color := LColors.TextColor;
  
  lblAwsAccessKeyId.StyleElements := lblAwsAccessKeyId.StyleElements - [seClient, seBorder];
  lblAwsAccessKeyId.Font.Color := LColors.TextColor;
  lblAwsSecretAccessKey.StyleElements := lblAwsSecretAccessKey.StyleElements - [seClient, seBorder];
  lblAwsSecretAccessKey.Font.Color := LColors.TextColor;
  lblAwsRegion.StyleElements := lblAwsRegion.StyleElements - [seClient, seBorder];
  lblAwsRegion.Font.Color := LColors.TextColor;
  lblAwsSessionToken.StyleElements := lblAwsSessionToken.StyleElements - [seClient, seBorder];
  lblAwsSessionToken.Font.Color := LColors.TextColor;

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
  
  edtTemplateSlash.StyleElements := edtTemplateSlash.StyleElements - [seClient, seBorder];
  edtTemplateSlash.Color := LColors.InputBgColor;
  edtTemplateSlash.Font.Color := LColors.TextColor;
  
  chkIsProjectGenerator.StyleElements := chkIsProjectGenerator.StyleElements - [seClient, seBorder];
  chkIsProjectGenerator.Font.Color := LColors.TextColor;
  
  memTemplateBody.StyleElements := memTemplateBody.StyleElements - [seClient, seBorder];
  memTemplateBody.Color := LColors.InputBgColor;
  memTemplateBody.Font.Color := LColors.TextColor;
  
  lblTemplateName.StyleElements := lblTemplateName.StyleElements - [seClient, seBorder];
  lblTemplateName.Font.Color := LColors.TextColor;
  lblTemplateDesc.StyleElements := lblTemplateDesc.StyleElements - [seClient, seBorder];
  lblTemplateDesc.Font.Color := LColors.TextColor;
  lblTemplateSlash.StyleElements := lblTemplateSlash.StyleElements - [seClient, seBorder];
  lblTemplateSlash.Font.Color := LColors.TextColor;
  lblTemplateBody.StyleElements := lblTemplateBody.StyleElements - [seClient, seBorder];
  lblTemplateBody.Font.Color := LColors.TextColor;
  lblTemplateOrigin.StyleElements := lblTemplateOrigin.StyleElements - [seClient, seBorder];
  lblTemplateOrigin.Font.Color := LColors.TextColor;



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
  LPair: TPair<string, TEdit>;
begin
  LFormatSettings := TFormatSettings.Invariant;
  
  if FConfig.GetProviderAuthType('Gemini') = 'web_login' then
    grpGeminiAuthType.ItemIndex := 1
  else
    grpGeminiAuthType.ItemIndex := 0;
  grpGeminiAuthTypeClick(nil);

  if FConfig.GetProviderAuthType('OpenAI') = 'web_login' then
    grpOpenAIAuthType.ItemIndex := 1
  else
    grpOpenAIAuthType.ItemIndex := 0;
  grpOpenAIAuthTypeClick(nil);

  edtGeminiKey.Text := FConfig.GetApiKey('Gemini');
  edtOpenAIKey.Text := FConfig.GetApiKey('OpenAI');
  edtOpenAICustomUrl.Text := FConfig.OpenAICustomBaseUrl;
  edtClaudeKey.Text := FConfig.GetApiKey('Claude');
  edtDeepSeekKey.Text := FConfig.GetApiKey('DeepSeek');
  edtGroqKey.Text := FConfig.GetApiKey('Groq');
  edtOpenRouterKey.Text := FConfig.GetApiKey('OpenRouter');
  memSystemPrompt.Text := FConfig.SystemPrompt;
  edtOllamaUrl.Text := FConfig.OllamaBaseUrl;
  
  edtLMStudioUrl.Text := FConfig.GetProviderBaseUrl('LMStudio');
  if edtLMStudioUrl.Text = '' then
    edtLMStudioUrl.Text := 'http://localhost:1234/v1';

  edtGithubCopilotKey.Text := FConfig.GetApiKey('GithubCopilot');

  edtAzureKey.Text := FConfig.GetApiKey('AzureOpenAI');
  edtAzureUrl.Text := FConfig.GetProviderBaseUrl('AzureOpenAI');
  edtAzureModel.Text := FConfig.GetActiveModel('AzureOpenAI');
  edtAzureApiVersion.Text := FConfig.AzureApiVersion;

  edtQwenKey.Text := FConfig.GetApiKey('Qwen');
  edtMistralKey.Text := FConfig.GetApiKey('Mistral');
  edtAwsAccessKeyId.Text := FConfig.AwsAccessKeyId;
  edtAwsSecretAccessKey.Text := FConfig.AwsSecretAccessKey;
  edtAwsRegion.Text := FConfig.AwsRegion;
  edtAwsSessionToken.Text := FConfig.AwsSessionToken;
 
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
  LPair: TPair<string, TEdit>;
begin
  LOllamaUrl := Trim(edtOllamaUrl.Text);
  LOpenAIUrl := Trim(edtOpenAICustomUrl.Text);
  var LLMStudioUrl := Trim(edtLMStudioUrl.Text);
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

  if not LLMStudioUrl.IsEmpty and not (LLMStudioUrl.StartsWith('http://', True) or LLMStudioUrl.StartsWith('https://', True)) then
  begin
    ShowMessage('LM Studio URL must start with http:// or https://');
    Exit;
  end;

  var LAzureUrl := Trim(edtAzureUrl.Text);
  if not LAzureUrl.IsEmpty and not (LAzureUrl.StartsWith('http://', True) or LAzureUrl.StartsWith('https://', True)) then
  begin
    ShowMessage('Azure OpenAI Endpoint URL must start with http:// or https://');
    Exit;
  end;

  if grpGeminiAuthType.ItemIndex = 1 then
    FConfig.SetProviderAuthType('Gemini', 'web_login')
  else
    FConfig.SetProviderAuthType('Gemini', 'api_key');

  if grpOpenAIAuthType.ItemIndex = 1 then
    FConfig.SetProviderAuthType('OpenAI', 'web_login')
  else
    FConfig.SetProviderAuthType('OpenAI', 'api_key');

  FConfig.SetApiKey('Gemini', Trim(edtGeminiKey.Text));
  FConfig.SetApiKey('OpenAI', Trim(edtOpenAIKey.Text));
  FConfig.OpenAICustomBaseUrl := LOpenAIUrl;
  FConfig.SetApiKey('Claude', Trim(edtClaudeKey.Text));
  FConfig.SetApiKey('DeepSeek', Trim(edtDeepSeekKey.Text));
  FConfig.SetApiKey('Groq', Trim(edtGroqKey.Text));
  FConfig.SetApiKey('OpenRouter', Trim(edtOpenRouterKey.Text));
  FConfig.SetApiKey('GithubCopilot', Trim(edtGithubCopilotKey.Text));
  
  FConfig.SetApiKey('AzureOpenAI', Trim(edtAzureKey.Text));
  FConfig.SetProviderBaseUrl('AzureOpenAI', LAzureUrl);
  FConfig.SetActiveModel('AzureOpenAI', Trim(edtAzureModel.Text));
  FConfig.AzureApiVersion := Trim(edtAzureApiVersion.Text);

  FConfig.SetApiKey('Qwen', Trim(edtQwenKey.Text));
  FConfig.SetApiKey('Mistral', Trim(edtMistralKey.Text));
  FConfig.AwsAccessKeyId := Trim(edtAwsAccessKeyId.Text);
  FConfig.AwsSecretAccessKey := Trim(edtAwsSecretAccessKey.Text);
  FConfig.AwsRegion := Trim(edtAwsRegion.Text);
  FConfig.AwsSessionToken := Trim(edtAwsSessionToken.Text);
 
  FConfig.SystemPrompt := memSystemPrompt.Text;
  FConfig.OllamaBaseUrl := LOllamaUrl;
  FConfig.SetProviderBaseUrl('LMStudio', LLMStudioUrl);

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
    edtTemplateSlash.Text := '';
    chkIsProjectGenerator.Checked := False;
    
    edtTemplateName.ReadOnly := False;
    btnDeleteTemplate.Caption := 'Delete';
    btnDeleteTemplate.Enabled := False;
    lblTemplateOrigin.Caption := '';
    Exit;
  end;

  LName := lstTemplates.Items[lstTemplates.ItemIndex];
  if FTemplateManager.FindTemplate(LName, LTemplate) then
  begin
    edtTemplateName.Text := LTemplate.Name;
    edtTemplateDesc.Text := LTemplate.Description;
    memTemplateBody.Text := LTemplate.Template;
    edtTemplateSlash.Text := LTemplate.SlashCommand;
    chkIsProjectGenerator.Checked := LTemplate.IsProjectGenerator;
    
    if LTemplate.IsSystem then
    begin
      edtTemplateName.ReadOnly := True;
      if LTemplate.IsCustomized then
      begin
        btnDeleteTemplate.Caption := 'Restore Default';
        btnDeleteTemplate.Enabled := True;
        lblTemplateOrigin.Caption := 'Origin: System (Customized)';
        lblTemplateOrigin.Font.Color := $00008CFF; // Laranja premium suave
      end
      else
      begin
        btnDeleteTemplate.Caption := 'Delete';
        btnDeleteTemplate.Enabled := False;
        lblTemplateOrigin.Caption := 'Origin: System (Read-Only)';
        lblTemplateOrigin.Font.Color := clGrayText;
      end;
    end
    else
    begin
      edtTemplateName.ReadOnly := False;
      btnDeleteTemplate.Caption := 'Delete';
      btnDeleteTemplate.Enabled := True;
      lblTemplateOrigin.Caption := 'Origin: User';
      lblTemplateOrigin.Font.Color := clHighlight;
    end;
  end;
end;

procedure TFrameAIConfig.btnNewTemplateClick(Sender: TObject);
begin
  lstTemplates.ItemIndex := -1;
  edtTemplateName.Text := '';
  edtTemplateDesc.Text := '';
  memTemplateBody.Text := '';
  edtTemplateSlash.Text := '';
  chkIsProjectGenerator.Checked := False;
  
  edtTemplateName.ReadOnly := False;
  btnDeleteTemplate.Caption := 'Delete';
  btnDeleteTemplate.Enabled := False;
  lblTemplateOrigin.Caption := '';
  edtTemplateName.SetFocus;
end;

procedure TFrameAIConfig.btnDeleteTemplateClick(Sender: TObject);
var
  LName: string;
  LTemplate: TPromptTemplate;
begin
  if lstTemplates.ItemIndex < 0 then
  begin
    ShowMessage('Please select a template.');
    Exit;
  end;

  LName := lstTemplates.Items[lstTemplates.ItemIndex];
  if FTemplateManager.FindTemplate(LName, LTemplate) then
  begin
    if LTemplate.IsSystem then
    begin
      if LTemplate.IsCustomized then
      begin
        if MessageDlg(Format('Deseja realmente restaurar o template padrão "%s" para o conteúdo original de fábrica?', [LName]),
          mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
          FTemplateManager.RestoreDefaultTemplate(LName);
          PopulateTemplatesList;
          lstTemplatesClick(nil);
        end;
      end;
    end
    else
    begin
      if MessageDlg(Format('Are you sure you want to delete the template "%s"?', [LName]),
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        FTemplateManager.DeleteTemplate(LName);
        FTemplateManager.Save;
        PopulateTemplatesList;
        lstTemplatesClick(nil);
      end;
    end;
  end;
end;

procedure TFrameAIConfig.btnSaveTemplateClick(Sender: TObject);
var
  LName, LDesc, LBody, LSlash: string;
  LIsProjGen: Boolean;
  LIndex: Integer;
begin
  LName := Trim(edtTemplateName.Text);
  LDesc := Trim(edtTemplateDesc.Text);
  LBody := memTemplateBody.Text;
  LSlash := Trim(edtTemplateSlash.Text);
  LIsProjGen := chkIsProjectGenerator.Checked;

  if LName.IsEmpty then
  begin
    ShowMessage('Template Name cannot be empty.');
    Exit;
  end;

  FTemplateManager.AddTemplate(LName, LDesc, LBody, LIsProjGen, LSlash);
  FTemplateManager.Save; // Salva o JSON local após salvar/atualizar
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

procedure TFrameAIConfig.btnExportTemplatesClick(Sender: TObject);
begin
  if dlgsTemplatesSave.Execute then
  begin
    try
      FTemplateManager.ExportToFile(dlgsTemplatesSave.FileName);
      ShowMessage('Templates exported successfully.');
    except
      on E: Exception do
        ShowMessage('Failed to export templates: ' + E.Message);
    end;
  end;
end;

procedure TFrameAIConfig.btnImportTemplatesClick(Sender: TObject);
var
  LErrorMsg: string;
  LMerge: Boolean;
  LConfirm: Integer;
begin
  if dlgsTemplatesOpen.Execute then
  begin
    LConfirm := MessageDlg('Deseja mesclar os templates importados com os atuais?' + sLineBreak +
      'Escolha "Yes" para mesclar ou "No" para apagar os templates atuais e usar apenas os importados.',
      mtConfirmation, [mbYes, mbNo, mbCancel], 0);
      
    if LConfirm = mrCancel then
      Exit;
      
    LMerge := LConfirm = mrYes;
    
    if FTemplateManager.ImportFromFile(dlgsTemplatesOpen.FileName, LMerge, LErrorMsg) then
    begin
      PopulateTemplatesList;
      if lstTemplates.Count > 0 then
      begin
        lstTemplates.ItemIndex := 0;
        lstTemplatesClick(nil);
      end;
      ShowMessage('Templates imported successfully.');
    end
    else
    begin
      ShowMessage('Import failed: ' + LErrorMsg);
    end;
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
  else if SameText(ACategoryName, 'LM Studio') then
    pgcSettings.ActivePage := tsLMStudio
  else if SameText(ACategoryName, 'GitHub Copilot') then
    pgcSettings.ActivePage := tsGithubCopilot
  else if SameText(ACategoryName, 'Azure OpenAI') then
    pgcSettings.ActivePage := tsAzureOpenAI
  else if SameText(ACategoryName, 'Alibaba Qwen') then
    pgcSettings.ActivePage := tsQwen
  else if SameText(ACategoryName, 'Mistral AI') then
    pgcSettings.ActivePage := tsMistral
  else if SameText(ACategoryName, 'AWS Bedrock') then
    pgcSettings.ActivePage := tsBedrock

end;

procedure TFrameAIConfig.grpGeminiAuthTypeClick(Sender: TObject);
var
  LIsApiKey: Boolean;
begin
  LIsApiKey := grpGeminiAuthType.ItemIndex = 0;
  edtGeminiKey.Enabled := LIsApiKey;
  lblGeminiKey.Enabled := LIsApiKey;
  if not LIsApiKey then
    edtGeminiKey.Text := '';
end;

procedure TFrameAIConfig.grpOpenAIAuthTypeClick(Sender: TObject);
var
  LIsApiKey: Boolean;
begin
  LIsApiKey := grpOpenAIAuthType.ItemIndex = 0;
  edtOpenAIKey.Enabled := LIsApiKey;
  lblOpenAIKey.Enabled := LIsApiKey;
  edtOpenAICustomUrl.Enabled := LIsApiKey;
  lblOpenAICustomUrl.Enabled := LIsApiKey;
  if not LIsApiKey then
  begin
    edtOpenAIKey.Text := '';
    edtOpenAICustomUrl.Text := '';
  end;
end;

procedure TFrameAIConfig.OpenUrl(const AUrl: string);
begin
  ShellExecute(0, 'open', PChar(AUrl), nil, nil, SW_SHOWNORMAL);
end;

procedure TFrameAIConfig.lnkGeminiGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://aistudio.google.com/app/apikey');
end;

procedure TFrameAIConfig.lnkOpenAIGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://platform.openai.com/api-keys');
end;

procedure TFrameAIConfig.lnkClaudeGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://console.anthropic.com/settings/keys');
end;

procedure TFrameAIConfig.lnkDeepSeekGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://platform.deepseek.com/api_keys');
end;

procedure TFrameAIConfig.lnkGroqGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://console.groq.com/keys');
end;

procedure TFrameAIConfig.lnkOpenRouterGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://openrouter.ai/keys');
end;

procedure TFrameAIConfig.lnkQwenGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://bailian.console.aliyun.com/');
end;

procedure TFrameAIConfig.lnkMistralGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://console.mistral.ai/api-keys/');
end;

procedure TFrameAIConfig.lnkBedrockGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://console.aws.amazon.com/iam/');
end;

procedure TFrameAIConfig.btnConnectGithubClick(Sender: TObject);
var
  LToken: string;
begin
  if TFormGithubAuth.Execute(Self, LToken) then
  begin
    edtGithubCopilotKey.Text := LToken;
    ShowMessage('Autenticado com sucesso no GitHub Copilot!');
  end;
end;

procedure TFrameAIConfig.btnImportVSCodeClick(Sender: TObject);
var
  LPath: string;
  LJsonStr: string;
  LJson, LGitHubNode: TJSONObject;
  LValue: TJSONValue;
  LToken: string;
  LUser: string;
begin
  LPath := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) +
    'Code\User\globalStorage\github.copilot\hosts.json';
    
  if not TFile.Exists(LPath) then
  begin
    { Fallback para VS Code Insiders }
    LPath := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) +
      'Code\User\globalStorage\github.copilot-insiders\hosts.json';
  end;

  if not TFile.Exists(LPath) then
  begin
    ShowMessage('Não foi possível encontrar a configuração do Copilot no VS Code.' + sLineBreak +
      'Certifique-se de que o VS Code está instalado e conectado ao Copilot nesta máquina.');
    Exit;
  end;

  try
    LJsonStr := TFile.ReadAllText(LPath, TEncoding.UTF8);
    LJson := TJSONObject.ParseJSONValue(LJsonStr) as TJSONObject;
    if Assigned(LJson) then
    begin
      try
        LGitHubNode := LJson.GetValue('github.com') as TJSONObject;
        if Assigned(LGitHubNode) then
        begin
          LValue := LGitHubNode.GetValue('oauth_token');
          if Assigned(LValue) then
            LToken := LValue.Value
          else
            LToken := '';
            
          LValue := LGitHubNode.GetValue('user');
          if Assigned(LValue) then
            LUser := LValue.Value
          else
            LUser := '';

          if not LToken.IsEmpty then
          begin
            edtGithubCopilotKey.Text := LToken;
            if not LUser.IsEmpty then
              ShowMessage(Format('Token importado com sucesso da conta do GitHub "%s" do VS Code!', [LUser]))
            else
              ShowMessage('Token importado com sucesso do VS Code!');
            Exit;
          end;
        end;
        
        ShowMessage('O arquivo de credenciais do VS Code foi encontrado, mas não continha um token válido.');
      finally
        LJson.Free;
      end;
    end
    else
    begin
      ShowMessage('Falha ao ler o arquivo de credenciais do VS Code (formato inválido).');
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Erro ao ler credenciais do VS Code: ' + E.Message);
    end;
  end;
end;

end.
