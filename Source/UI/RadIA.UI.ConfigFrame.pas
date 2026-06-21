unit RadIA.UI.ConfigFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, System.Generics.Collections, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config, ToolsAPI,
  RadIA.Core.PromptTemplates, RadIA.UI.ConfigPresenter;

type
  TRadIAFrameAIConfig = class(TFrame, IRadIAConfigView)
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
    btnGeminiWebLogin: TButton;
    btnOpenAIWebLogin: TButton;

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
    procedure btnGeminiWebLoginClick(Sender: TObject);
    procedure btnOpenAIWebLoginClick(Sender: TObject);
  private
    FPresenter: TRadIAConfigPresenter;
    FOnClose: TNotifyEvent;
    lblTemplateOrigin: TLabel;

    FEdtTemperatures: TDictionary<string, TEdit>;
    FEdtMaxTokens: TDictionary<string, TEdit>;
    FEdtTimeouts: TDictionary<string, TEdit>;
    FChkSmartConfig: TCheckBox;
    chkConciseResponses: TCheckBox;

    tsGeneral: TTabSheet;
    pnlGeneral: TPanel;
    chkInjectDelphiVersion: TCheckBox;
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

    function CreateCheckBox(AParent: TWinControl; const ACaption: string; const ALeft, ATop, AWidth: Integer): TCheckBox;
    function CreateEdit(AParent: TWinControl; const ALeft, ATop, AWidth: Integer; const ANumbersOnly: Boolean = False): TEdit;
    function CreateLabel(AParent: TWinControl; const ACaption: string; const ALeft, ATop: Integer): TLabel;
    procedure CreateGeneralTab;
    procedure CreateTemplateOriginLabel;
    procedure CreateProviderAdvancedControls(ATabSheet: TTabSheet; const AProviderId: string);
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

    { IRadIAConfigView Implementation }
    function GetApiKey(const AProviderId: string): string;
    procedure SetApiKey(const AProviderId: string; const AKey: string);
    function GetCustomUrl(const AProviderId: string): string;
    procedure SetCustomUrl(const AProviderId: string; const AUrl: string);
    function GetAuthTypeIndex(const AProviderId: string): Integer;
    procedure SetAuthTypeIndex(const AProviderId: string; const AIndex: Integer);

    function GetTemperatureInput(const AProviderId: string): string;
    procedure SetTemperatureInput(const AProviderId: string; const AValue: string);
    function GetMaxTokensInput(const AProviderId: string): string;
    procedure SetMaxTokensInput(const AProviderId: string; const AValue: string);
    function GetTimeoutInput(const AProviderId: string): string;
    procedure SetTimeoutInput(const AProviderId: string; const AValue: string);

    function GetAzureModel: string;
    procedure SetAzureModel(const AValue: string);
    function GetAzureApiVersion: string;
    procedure SetAzureApiVersion(const AValue: string);

    function GetAwsAccessKeyId: string;
    procedure SetAwsAccessKeyId(const AValue: string);
    function GetAwsSecretAccessKey: string;
    procedure SetAwsSecretAccessKey(const AValue: string);
    function GetAwsRegion: string;
    procedure SetAwsRegion(const AValue: string);
    function GetAwsSessionToken: string;
    procedure SetAwsSessionToken(const AValue: string);

    function GetSystemPrompt: string;
    procedure SetSystemPrompt(const AValue: string);
    function GetSmartConfigEnabled: Boolean;
    procedure SetSmartConfigEnabled(const AValue: Boolean);
    function GetInjectDelphiVersion: Boolean;
    procedure SetInjectDelphiVersion(const AValue: Boolean);
    function GetConciseResponses: Boolean;
    procedure SetConciseResponses(const AValue: Boolean);
    function GetLogEnabled: Boolean;
    procedure SetLogEnabled(const AValue: Boolean);
    function GetLogPath: string;
    procedure SetLogPath(const AValue: string);
    function GetLogMaxSize: string;
    procedure SetLogMaxSize(const AValue: string);

    function GetQuotaEnabled: Boolean;
    procedure SetQuotaEnabled(const AValue: Boolean);
    function GetQuotaLimit: string;
    procedure SetQuotaLimit(const AValue: string);
    procedure SetQuotaUsedText(const AText: string);

    procedure ShowMessageDialog(const AMessage: string);
    function SaveDialogExecute(out AFileName: string): Boolean;
    function OpenDialogExecute(out AFileName: string): Boolean;
    function FolderDialogExecute(out AFolderName: string): Boolean;
    procedure CloseView(const AModalResult: Integer);

    procedure UpdateTemplatesList(const ATemplateNames: TArray<string>; const ASelectedIndex: Integer);
    procedure GetTemplateEditorFields(out AName, ADesc, ABody, ASlash: string; out AIsProjGen: Boolean);
    procedure SetTemplateFields(const AName, ADesc, ABody, ASlash: string; const AIsProjGen: Boolean; const AIsSystem, AIsCustomized: Boolean);
    procedure ClearTemplateFields;
    procedure FocusTemplateName;
    function GetSelectedTemplateIndex: Integer;
    procedure SetSelectedTemplateIndex(const AIndex: Integer);
    procedure SetDeleteTemplateButtonState(const ACaption: string; const AEnabled: Boolean);
    procedure SetTemplateOriginLabel(const AText: string; const AColor: TColor);

    property OnClose: TNotifyEvent read FOnClose write FOnClose;
  end;

implementation

uses
  System.IOUtils, System.JSON, RadIA.UI.Resources, System.UITypes, Vcl.FileCtrl, RadIA.Core.Logger, Vcl.Themes,
  RadIA.Core.ProviderRegistry, Winapi.ShellAPI, RadIA.UI.GithubAuthForm, RadIA.UI.WebLoginForm;

{$R *.dfm}

type
  TWinControlHelper = class helper for TWinControl
  public
    procedure SetColor(const AColor: TColor); inline;
    procedure SetParentBackground(const AValue: Boolean); inline;
  end;

{ TWinControlHelper }

procedure TWinControlHelper.SetColor(const AColor: TColor);
begin
  Self.Color := AColor;
end;

procedure TWinControlHelper.SetParentBackground(const AValue: Boolean);
begin
  Self.ParentBackground := AValue;
end;

function TRadIAFrameAIConfig.CreateCheckBox(AParent: TWinControl; const ACaption: string;
  const ALeft, ATop, AWidth: Integer): TCheckBox;
begin
  Result := TCheckBox.Create(Self);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Height := 23;
  Result.Caption := ACaption;
end;

function TRadIAFrameAIConfig.CreateEdit(AParent: TWinControl; const ALeft, ATop, AWidth: Integer;
  const ANumbersOnly: Boolean): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.NumbersOnly := ANumbersOnly;
end;

function TRadIAFrameAIConfig.CreateLabel(AParent: TWinControl; const ACaption: string;
  const ALeft, ATop: Integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Caption := ACaption;
end;

procedure TRadIAFrameAIConfig.CreateTemplateOriginLabel;
begin
  lblTemplateOrigin := TLabel.Create(Self);
  lblTemplateOrigin.Parent := pnlTemplatesClient;
  lblTemplateOrigin.Left := 14;
  lblTemplateOrigin.Top := btnSaveTemplate.Top + btnSaveTemplate.Height + 12;
  lblTemplateOrigin.Font.Assign(lblTemplateName.Font);
  lblTemplateOrigin.Font.Style := [fsItalic];
  lblTemplateOrigin.Caption := '';
end;

procedure TRadIAFrameAIConfig.CreateGeneralTab;
begin
  tsGeneral := TTabSheet.Create(Self);
  tsGeneral.PageControl := pgcSettings;
  tsGeneral.Caption := 'General / Logs';
  tsGeneral.TabVisible := False;

  pnlGeneral := TPanel.Create(Self);
  pnlGeneral.Parent := tsGeneral;
  pnlGeneral.Align := alClient;
  pnlGeneral.BevelOuter := bvNone;
  pnlGeneral.ShowCaption := False;

  FChkSmartConfig := CreateCheckBox(pnlGeneral, 'Auto (Smart Parameters)', 16, 16, 300);
  chkInjectDelphiVersion := CreateCheckBox(
    pnlGeneral,
    'Inject Delphi version in prompt',
    16,
    48,
    300);
  chkConciseResponses := CreateCheckBox(
    pnlGeneral,
    'Prefer concise AI responses',
    16,
    80,
    300);
  chkLogEnabled := CreateCheckBox(pnlGeneral, 'Enable logging', 16, 112, 200);
  lblLogPath := CreateLabel(pnlGeneral, 'Log Folder Path:', 16, 144);
  edtLogPath := CreateEdit(pnlGeneral, 16, 162, 320);

  btnBrowseLogPath := TButton.Create(Self);
  btnBrowseLogPath.Parent := pnlGeneral;
  btnBrowseLogPath.Left := 342;
  btnBrowseLogPath.Top := 160;
  btnBrowseLogPath.Width := 30;
  btnBrowseLogPath.Height := 23;
  btnBrowseLogPath.Caption := '...';
  btnBrowseLogPath.OnClick := btnBrowseLogPathClick;

  lblLogMaxSize := CreateLabel(pnlGeneral, 'Max Log File Size (KB):', 16, 200);
  edtLogMaxSize := CreateEdit(pnlGeneral, 16, 218, 100, True);

  grpQuota := TGroupBox.Create(Self);
  grpQuota.Parent := pnlGeneral;
  grpQuota.Left := 16;
  grpQuota.Top := 256;
  grpQuota.Width := 356;
  grpQuota.Height := 140;
  grpQuota.Caption := ' Local Token Quota ';

  chkQuotaEnabled := CreateCheckBox(grpQuota, 'Enable local token quota', 16, 24, 200);
  lblQuotaLimit := CreateLabel(grpQuota, 'Monthly Token Limit:', 16, 54);
  edtQuotaLimit := CreateEdit(grpQuota, 16, 72, 150, True);
  lblQuotaUsed := CreateLabel(grpQuota, 'Monthly Used Tokens: 0', 16, 110);

  btnResetQuota := TButton.Create(Self);
  btnResetQuota.Parent := grpQuota;
  btnResetQuota.Left := 240;
  btnResetQuota.Top := 68;
  btnResetQuota.Width := 100;
  btnResetQuota.Height := 25;
  btnResetQuota.Caption := 'Reset Usage';
  btnResetQuota.OnClick := btnResetQuotaClick;
end;

constructor TRadIAFrameAIConfig.Create(AOwner: TComponent);
var
  LThemingServices: IOTAIDEThemingServices;
  LActiveTheme: string;
  LUseIDETheme: Boolean;
begin
  inherited Create(AOwner);
  FPresenter := TRadIAConfigPresenter.Create(Self);

  CreateTemplateOriginLabel;

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

  CreateGeneralTab;

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

  FPresenter.LoadConfig;
end;

destructor TRadIAFrameAIConfig.Destroy;
begin
  FPresenter.Free;
  FEdtTemperatures.Free;
  FEdtMaxTokens.Free;
  FEdtTimeouts.Free;
  inherited Destroy;
end;

procedure TRadIAFrameAIConfig.CreateProviderAdvancedControls(ATabSheet: TTabSheet; const AProviderId: string);
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

procedure TRadIAFrameAIConfig.UpdateVCLColors(const AThemeName: string);
var
  LColors: TRadIAThemeColors;
  I: Integer;
begin
  LColors := TRadIAThemeColors.GetColorsForTheme(AThemeName);

  Self.StyleElements := Self.StyleElements - [seClient, seBorder];
  Self.SetColor(LColors.BgBase);
  pgcSettings.StyleElements := pgcSettings.StyleElements - [seClient, seBorder];
  pgcSettings.SetColor(LColors.BgBase);

  Self.SetParentBackground(False);
  pgcSettings.SetParentBackground(False);
  for I := 0 to pgcSettings.PageCount - 1 do
  begin
    pgcSettings.Pages[I].StyleElements := pgcSettings.Pages[I].StyleElements - [seClient, seBorder];
    pgcSettings.Pages[I].SetParentBackground(False);
    pgcSettings.Pages[I].SetColor(LColors.BgBase);
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
  end;

  memSystemPrompt.StyleElements := memSystemPrompt.StyleElements - [seClient, seBorder];
  memSystemPrompt.Color := LColors.InputBgColor;
  memSystemPrompt.Font.Color := LColors.TextColor;

  grpGeminiAuthType.StyleElements := grpGeminiAuthType.StyleElements - [seClient, seBorder];
  grpGeminiAuthType.Font.Color := LColors.TextColor;
  grpOpenAIAuthType.StyleElements := grpOpenAIAuthType.StyleElements - [seClient, seBorder];
  grpOpenAIAuthType.Font.Color := LColors.TextColor;

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
    tsGeneral.SetParentBackground(False);
    tsGeneral.SetColor(LColors.BgBase);
  end;
  if Assigned(chkInjectDelphiVersion) then
  begin
    chkInjectDelphiVersion.StyleElements := chkInjectDelphiVersion.StyleElements - [seClient, seBorder];
    chkInjectDelphiVersion.Font.Color := LColors.TextColor;
  end;
  if Assigned(chkConciseResponses) then
  begin
    chkConciseResponses.StyleElements := chkConciseResponses.StyleElements - [seClient, seBorder];
    chkConciseResponses.Font.Color := LColors.TextColor;
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

procedure TRadIAFrameAIConfig.LoadConfig;
begin
  FPresenter.LoadConfig;
end;

procedure TRadIAFrameAIConfig.lstTemplatesClick(Sender: TObject);
begin
  FPresenter.HandleTemplateSelected;
end;

procedure TRadIAFrameAIConfig.btnNewTemplateClick(Sender: TObject);
begin
  FPresenter.CreateNewTemplate;
end;

procedure TRadIAFrameAIConfig.btnDeleteTemplateClick(Sender: TObject);
var
  LConfirmMsg: string;
begin
  if lstTemplates.ItemIndex < 0 then
  begin
    ShowMessage('Please select a template.');
    Exit;
  end;

  if SameText(btnDeleteTemplate.Caption, 'Restore Default') then
    LConfirmMsg := 'Do you really want to restore the default template "' + lstTemplates.Items[lstTemplates.ItemIndex] + '" to its original content?'
  else
    LConfirmMsg := 'Are you sure you want to delete the template "' + lstTemplates.Items[lstTemplates.ItemIndex] + '"?';

  if MessageDlg(LConfirmMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FPresenter.DeleteTemplate;
  end;
end;

procedure TRadIAFrameAIConfig.btnSaveTemplateClick(Sender: TObject);
begin
  FPresenter.SaveTemplate;
end;

procedure TRadIAFrameAIConfig.btnRestoreDefaultsClick(Sender: TObject);
begin
  if MessageDlg('Are you sure you want to restore default templates? This will overwrite your changes.',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FPresenter.RestoreDefaultTemplates;
  end;
end;

procedure TRadIAFrameAIConfig.btnExportTemplatesClick(Sender: TObject);
begin
  FPresenter.ExportTemplates;
end;

procedure TRadIAFrameAIConfig.btnImportTemplatesClick(Sender: TObject);
var
  LErrorMsg: string;
  LMerge: Boolean;
  LConfirm: Integer;
begin
  if dlgsTemplatesOpen.Execute then
  begin
    LConfirm := MessageDlg('Do you want to merge imported templates with the current ones?' + sLineBreak +
      'Choose "Yes" to merge or "No" to delete current templates and use only the imported ones.',
      mtConfirmation, [mbYes, mbNo, mbCancel], 0);

    if LConfirm = mrCancel then
      Exit;

    LMerge := LConfirm = mrYes;

    if FPresenter.TemplateManager.ImportFromFile(dlgsTemplatesOpen.FileName, LMerge, LErrorMsg) then
    begin
      FPresenter.LoadConfig;
      ShowMessage('Templates imported successfully.');
    end
    else
    begin
      ShowMessage('Import failed: ' + LErrorMsg);
    end;
  end;
end;

procedure TRadIAFrameAIConfig.btnBrowseLogPathClick(Sender: TObject);
begin
  FPresenter.BrowseLogPath;
end;

procedure TRadIAFrameAIConfig.btnResetQuotaClick(Sender: TObject);
begin
  FPresenter.ResetQuota;
end;

procedure TRadIAFrameAIConfig.tvCategoriesChange(Sender: TObject; Node: TTreeNode);
begin
  if Node <> nil then
    SelectCategoryByName(Node.Text);
end;

procedure TRadIAFrameAIConfig.SelectCategoryByName(const ACategoryName: string);
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

procedure TRadIAFrameAIConfig.grpGeminiAuthTypeClick(Sender: TObject);
var
  LIsApiKey: Boolean;
begin
  LIsApiKey := grpGeminiAuthType.ItemIndex = 0;
  edtGeminiKey.Enabled := LIsApiKey;
  lblGeminiKey.Enabled := LIsApiKey;
  btnGeminiWebLogin.Enabled := not LIsApiKey;
  if not LIsApiKey then
    edtGeminiKey.Text := '';
end;

procedure TRadIAFrameAIConfig.grpOpenAIAuthTypeClick(Sender: TObject);
var
  LIsApiKey: Boolean;
begin
  LIsApiKey := grpOpenAIAuthType.ItemIndex = 0;
  edtOpenAIKey.Enabled := LIsApiKey;
  lblOpenAIKey.Enabled := LIsApiKey;
  edtOpenAICustomUrl.Enabled := LIsApiKey;
  lblOpenAICustomUrl.Enabled := LIsApiKey;
  btnOpenAIWebLogin.Enabled := not LIsApiKey;
  if not LIsApiKey then
  begin
    edtOpenAIKey.Text := '';
    edtOpenAICustomUrl.Text := '';
  end;
end;

procedure TRadIAFrameAIConfig.OpenUrl(const AUrl: string);
begin
  ShellExecute(0, 'open', PChar(AUrl), nil, nil, SW_SHOWNORMAL);
end;

procedure TRadIAFrameAIConfig.lnkGeminiGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://aistudio.google.com/app/apikey');
end;

procedure TRadIAFrameAIConfig.lnkOpenAIGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://platform.openai.com/api-keys');
end;

procedure TRadIAFrameAIConfig.lnkClaudeGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://console.anthropic.com/settings/keys');
end;

procedure TRadIAFrameAIConfig.lnkDeepSeekGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://platform.deepseek.com/api_keys');
end;

procedure TRadIAFrameAIConfig.lnkGroqGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://console.groq.com/keys');
end;

procedure TRadIAFrameAIConfig.lnkOpenRouterGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://openrouter.ai/keys');
end;

procedure TRadIAFrameAIConfig.lnkQwenGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://bailian.console.aliyun.com/');
end;

procedure TRadIAFrameAIConfig.lnkMistralGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://console.mistral.ai/api-keys/');
end;

procedure TRadIAFrameAIConfig.lnkBedrockGetKeyClick(Sender: TObject);
begin
  OpenUrl('https://console.aws.amazon.com/iam/');
end;

procedure TRadIAFrameAIConfig.btnConnectGithubClick(Sender: TObject);
var
  LToken: string;
begin
  if TRadIAFormGithubAuth.Execute(Self, LToken) then
  begin
    FPresenter.ConnectGithub(LToken);
  end;
end;

procedure TRadIAFrameAIConfig.btnImportVSCodeClick(Sender: TObject);
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
    LPath := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) +
      'Code\User\globalStorage\github.copilot-insiders\hosts.json';
  end;

  if not TFile.Exists(LPath) then
  begin
    ShowMessage('Could not find the Copilot configuration in VS Code.');
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
            FPresenter.ImportVSCodeCopilotToken(LToken, LUser);
            Exit;
          end;
        end;

        ShowMessage('The VS Code credentials file was found, but it did not contain a valid token.');
      finally
        LJson.Free;
      end;
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao ler credenciais do VS Code: ' + E.Message);
  end;
end;

procedure TRadIAFrameAIConfig.btnGeminiWebLoginClick(Sender: TObject);
begin
  TRadIAFormWebLogin.ShowLogin(Self, 'https://gemini.google.com',
    procedure
    begin
      grpGeminiAuthType.ItemIndex := 1;
      grpGeminiAuthTypeClick(grpGeminiAuthType);
      FPresenter.SaveConfig;
      ShowMessage('Gemini web login completed successfully.');
    end);
end;

procedure TRadIAFrameAIConfig.btnOpenAIWebLoginClick(Sender: TObject);
begin
  TRadIAFormWebLogin.ShowLogin(Self, 'https://chatgpt.com',
    procedure
    begin
      grpOpenAIAuthType.ItemIndex := 1;
      grpOpenAIAuthTypeClick(grpOpenAIAuthType);
      FPresenter.SaveConfig;
      ShowMessage('OpenAI web login completed successfully.');
    end);
end;

procedure TRadIAFrameAIConfig.btnSaveClick(Sender: TObject);
begin
  FPresenter.SaveConfig;
end;

procedure TRadIAFrameAIConfig.btnCancelClick(Sender: TObject);
begin
  FPresenter.CancelConfig;
end;

{ IRadIAConfigView Implementation }

function TRadIAFrameAIConfig.GetApiKey(const AProviderId: string): string;
begin
  if SameText(AProviderId, 'Gemini') then Result := edtGeminiKey.Text
  else if SameText(AProviderId, 'OpenAI') then Result := edtOpenAIKey.Text
  else if SameText(AProviderId, 'Claude') then Result := edtClaudeKey.Text
  else if SameText(AProviderId, 'DeepSeek') then Result := edtDeepSeekKey.Text
  else if SameText(AProviderId, 'Groq') then Result := edtGroqKey.Text
  else if SameText(AProviderId, 'OpenRouter') then Result := edtOpenRouterKey.Text
  else if SameText(AProviderId, 'GithubCopilot') then Result := edtGithubCopilotKey.Text
  else if SameText(AProviderId, 'AzureOpenAI') then Result := edtAzureKey.Text
  else if SameText(AProviderId, 'Qwen') then Result := edtQwenKey.Text
  else if SameText(AProviderId, 'Mistral') then Result := edtMistralKey.Text
  else Result := '';
end;

procedure TRadIAFrameAIConfig.SetApiKey(const AProviderId: string; const AKey: string);
begin
  if SameText(AProviderId, 'Gemini') then edtGeminiKey.Text := AKey
  else if SameText(AProviderId, 'OpenAI') then edtOpenAIKey.Text := AKey
  else if SameText(AProviderId, 'Claude') then edtClaudeKey.Text := AKey
  else if SameText(AProviderId, 'DeepSeek') then edtDeepSeekKey.Text := AKey
  else if SameText(AProviderId, 'Groq') then edtGroqKey.Text := AKey
  else if SameText(AProviderId, 'OpenRouter') then edtOpenRouterKey.Text := AKey
  else if SameText(AProviderId, 'GithubCopilot') then edtGithubCopilotKey.Text := AKey
  else if SameText(AProviderId, 'AzureOpenAI') then edtAzureKey.Text := AKey
  else if SameText(AProviderId, 'Qwen') then edtQwenKey.Text := AKey
  else if SameText(AProviderId, 'Mistral') then edtMistralKey.Text := AKey;
end;

function TRadIAFrameAIConfig.GetCustomUrl(const AProviderId: string): string;
begin
  if SameText(AProviderId, 'OpenAI') then Result := edtOpenAICustomUrl.Text
  else if SameText(AProviderId, 'Ollama') then Result := edtOllamaUrl.Text
  else if SameText(AProviderId, 'LMStudio') then Result := edtLMStudioUrl.Text
  else if SameText(AProviderId, 'AzureOpenAI') then Result := edtAzureUrl.Text
  else Result := '';
end;

procedure TRadIAFrameAIConfig.SetCustomUrl(const AProviderId: string; const AUrl: string);
begin
  if SameText(AProviderId, 'OpenAI') then edtOpenAICustomUrl.Text := AUrl
  else if SameText(AProviderId, 'Ollama') then edtOllamaUrl.Text := AUrl
  else if SameText(AProviderId, 'LMStudio') then edtLMStudioUrl.Text := AUrl
  else if SameText(AProviderId, 'AzureOpenAI') then edtAzureUrl.Text := AUrl;
end;

function TRadIAFrameAIConfig.GetAuthTypeIndex(const AProviderId: string): Integer;
begin
  if SameText(AProviderId, 'Gemini') then Result := grpGeminiAuthType.ItemIndex
  else if SameText(AProviderId, 'OpenAI') then Result := grpOpenAIAuthType.ItemIndex
  else Result := 0;
end;

procedure TRadIAFrameAIConfig.SetAuthTypeIndex(const AProviderId: string; const AIndex: Integer);
begin
  if SameText(AProviderId, 'Gemini') then
  begin
    grpGeminiAuthType.ItemIndex := AIndex;
    grpGeminiAuthTypeClick(grpGeminiAuthType);
  end
  else if SameText(AProviderId, 'OpenAI') then
  begin
    grpOpenAIAuthType.ItemIndex := AIndex;
    grpOpenAIAuthTypeClick(grpOpenAIAuthType);
  end;
end;

function TRadIAFrameAIConfig.GetTemperatureInput(const AProviderId: string): string;
var
  LEdit: TEdit;
begin
  if FEdtTemperatures.TryGetValue(AProviderId, LEdit) then Result := LEdit.Text else Result := '0.7';
end;

procedure TRadIAFrameAIConfig.SetTemperatureInput(const AProviderId: string; const AValue: string);
var
  LEdit: TEdit;
begin
  if FEdtTemperatures.TryGetValue(AProviderId, LEdit) then LEdit.Text := AValue;
end;

function TRadIAFrameAIConfig.GetMaxTokensInput(const AProviderId: string): string;
var
  LEdit: TEdit;
begin
  if FEdtMaxTokens.TryGetValue(AProviderId, LEdit) then Result := LEdit.Text else Result := '2048';
end;

procedure TRadIAFrameAIConfig.SetMaxTokensInput(const AProviderId: string; const AValue: string);
var
  LEdit: TEdit;
begin
  if FEdtMaxTokens.TryGetValue(AProviderId, LEdit) then LEdit.Text := AValue;
end;

function TRadIAFrameAIConfig.GetTimeoutInput(const AProviderId: string): string;
var
  LEdit: TEdit;
begin
  if FEdtTimeouts.TryGetValue(AProviderId, LEdit) then Result := LEdit.Text else Result := '60';
end;

procedure TRadIAFrameAIConfig.SetTimeoutInput(const AProviderId: string; const AValue: string);
var
  LEdit: TEdit;
begin
  if FEdtTimeouts.TryGetValue(AProviderId, LEdit) then LEdit.Text := AValue;
end;

function TRadIAFrameAIConfig.GetAzureModel: string; begin Result := edtAzureModel.Text; end;
procedure TRadIAFrameAIConfig.SetAzureModel(const AValue: string); begin edtAzureModel.Text := AValue; end;
function TRadIAFrameAIConfig.GetAzureApiVersion: string; begin Result := edtAzureApiVersion.Text; end;
procedure TRadIAFrameAIConfig.SetAzureApiVersion(const AValue: string); begin edtAzureApiVersion.Text := AValue; end;

function TRadIAFrameAIConfig.GetAwsAccessKeyId: string; begin Result := edtAwsAccessKeyId.Text; end;
procedure TRadIAFrameAIConfig.SetAwsAccessKeyId(const AValue: string); begin edtAwsAccessKeyId.Text := AValue; end;
function TRadIAFrameAIConfig.GetAwsSecretAccessKey: string; begin Result := edtAwsSecretAccessKey.Text; end;
procedure TRadIAFrameAIConfig.SetAwsSecretAccessKey(const AValue: string); begin edtAwsSecretAccessKey.Text := AValue; end;
function TRadIAFrameAIConfig.GetAwsRegion: string; begin Result := edtAwsRegion.Text; end;
procedure TRadIAFrameAIConfig.SetAwsRegion(const AValue: string); begin edtAwsRegion.Text := AValue; end;
function TRadIAFrameAIConfig.GetAwsSessionToken: string; begin Result := edtAwsSessionToken.Text; end;
procedure TRadIAFrameAIConfig.SetAwsSessionToken(const AValue: string); begin edtAwsSessionToken.Text := AValue; end;

function TRadIAFrameAIConfig.GetSystemPrompt: string; begin Result := memSystemPrompt.Text; end;
procedure TRadIAFrameAIConfig.SetSystemPrompt(const AValue: string); begin memSystemPrompt.Text := AValue; end;
function TRadIAFrameAIConfig.GetSmartConfigEnabled: Boolean; begin Result := FChkSmartConfig.Checked; end;
procedure TRadIAFrameAIConfig.SetSmartConfigEnabled(const AValue: Boolean); begin FChkSmartConfig.Checked := AValue; end;
function TRadIAFrameAIConfig.GetInjectDelphiVersion: Boolean; begin Result := chkInjectDelphiVersion.Checked; end;
procedure TRadIAFrameAIConfig.SetInjectDelphiVersion(const AValue: Boolean); begin chkInjectDelphiVersion.Checked := AValue; end;
function TRadIAFrameAIConfig.GetConciseResponses: Boolean; begin Result := chkConciseResponses.Checked; end;
procedure TRadIAFrameAIConfig.SetConciseResponses(const AValue: Boolean); begin chkConciseResponses.Checked := AValue; end;
function TRadIAFrameAIConfig.GetLogEnabled: Boolean; begin Result := chkLogEnabled.Checked; end;
procedure TRadIAFrameAIConfig.SetLogEnabled(const AValue: Boolean); begin chkLogEnabled.Checked := AValue; end;
function TRadIAFrameAIConfig.GetLogPath: string; begin Result := edtLogPath.Text; end;
procedure TRadIAFrameAIConfig.SetLogPath(const AValue: string); begin edtLogPath.Text := AValue; end;
function TRadIAFrameAIConfig.GetLogMaxSize: string; begin Result := edtLogMaxSize.Text; end;
procedure TRadIAFrameAIConfig.SetLogMaxSize(const AValue: string); begin edtLogMaxSize.Text := AValue; end;

function TRadIAFrameAIConfig.GetQuotaEnabled: Boolean; begin Result := chkQuotaEnabled.Checked; end;
procedure TRadIAFrameAIConfig.SetQuotaEnabled(const AValue: Boolean); begin chkQuotaEnabled.Checked := AValue; end;
function TRadIAFrameAIConfig.GetQuotaLimit: string; begin Result := edtQuotaLimit.Text; end;
procedure TRadIAFrameAIConfig.SetQuotaLimit(const AValue: string); begin edtQuotaLimit.Text := AValue; end;
procedure TRadIAFrameAIConfig.SetQuotaUsedText(const AText: string); begin lblQuotaUsed.Caption := AText; end;

procedure TRadIAFrameAIConfig.ShowMessageDialog(const AMessage: string);
begin
  ShowMessage(AMessage);
end;

function TRadIAFrameAIConfig.SaveDialogExecute(out AFileName: string): Boolean;
begin
  Result := dlgsTemplatesSave.Execute;
  if Result then AFileName := dlgsTemplatesSave.FileName;
end;

function TRadIAFrameAIConfig.OpenDialogExecute(out AFileName: string): Boolean;
begin
  Result := dlgsTemplatesOpen.Execute;
  if Result then AFileName := dlgsTemplatesOpen.FileName;
end;

function TRadIAFrameAIConfig.FolderDialogExecute(out AFolderName: string): Boolean;
begin
  Result := Vcl.FileCtrl.SelectDirectory('Select Log Folder', '', AFolderName, [sdNewUI, sdNewFolder]);
end;

procedure TRadIAFrameAIConfig.CloseView(const AModalResult: Integer);
var
  LForm: TCustomForm;
begin
  LForm := GetParentForm(Self);
  if (LForm <> nil) and SameText(LForm.ClassName, 'TRadIAFormAIConfig') then
    LForm.ModalResult := AModalResult;
end;

procedure TRadIAFrameAIConfig.UpdateTemplatesList(const ATemplateNames: TArray<string>; const ASelectedIndex: Integer);
var
  LName: string;
begin
  lstTemplates.Items.BeginUpdate;
  try
    lstTemplates.Items.Clear;
    for LName in ATemplateNames do
      lstTemplates.Items.Add(LName);
  finally
    lstTemplates.Items.EndUpdate;
  end;
  lstTemplates.ItemIndex := ASelectedIndex;
end;

procedure TRadIAFrameAIConfig.GetTemplateEditorFields(out AName, ADesc, ABody, ASlash: string; out AIsProjGen: Boolean);
begin
  AName := Trim(edtTemplateName.Text);
  ADesc := Trim(edtTemplateDesc.Text);
  ABody := memTemplateBody.Text;
  ASlash := Trim(edtTemplateSlash.Text);
  AIsProjGen := chkIsProjectGenerator.Checked;
end;

procedure TRadIAFrameAIConfig.SetTemplateFields(const AName, ADesc, ABody, ASlash: string; const AIsProjGen: Boolean; const AIsSystem, AIsCustomized: Boolean);
begin
  edtTemplateName.Text := AName;
  edtTemplateDesc.Text := ADesc;
  memTemplateBody.Text := ABody;
  edtTemplateSlash.Text := ASlash;
  chkIsProjectGenerator.Checked := AIsProjGen;
  edtTemplateName.ReadOnly := AIsSystem;
end;

procedure TRadIAFrameAIConfig.ClearTemplateFields;
begin
  edtTemplateName.Text := '';
  edtTemplateDesc.Text := '';
  memTemplateBody.Text := '';
  edtTemplateSlash.Text := '';
  chkIsProjectGenerator.Checked := False;
  edtTemplateName.ReadOnly := False;
end;

procedure TRadIAFrameAIConfig.FocusTemplateName;
begin
  edtTemplateName.SetFocus;
end;

function TRadIAFrameAIConfig.GetSelectedTemplateIndex: Integer;
begin
  Result := lstTemplates.ItemIndex;
end;

procedure TRadIAFrameAIConfig.SetSelectedTemplateIndex(const AIndex: Integer);
begin
  lstTemplates.ItemIndex := AIndex;
end;

procedure TRadIAFrameAIConfig.SetDeleteTemplateButtonState(const ACaption: string; const AEnabled: Boolean);
begin
  btnDeleteTemplate.Caption := ACaption;
  btnDeleteTemplate.Enabled := AEnabled;
end;

procedure TRadIAFrameAIConfig.SetTemplateOriginLabel(const AText: string; const AColor: TColor);
begin
  lblTemplateOrigin.Caption := AText;
  lblTemplateOrigin.Font.Color := AColor;
end;

end.
