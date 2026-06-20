unit RadIA.Tests.ConfigPresenter;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Graphics, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.PromptTemplates,
  RadIA.UI.ConfigPresenter;

type
  TMockConfigView = class(TInterfacedObject, IRadIAConfigView)
  public
    ApiKeyMap: TDictionary<string, string>;
    CustomUrlMap: TDictionary<string, string>;
    AuthTypeMap: TDictionary<string, Integer>;
    TempMap: TDictionary<string, string>;
    MaxTokensMap: TDictionary<string, string>;
    TimeoutMap: TDictionary<string, string>;

    AzureModel: string;
    AzureApiVersion: string;

    AwsAccessKeyId: string;
    AwsSecretAccessKey: string;
    AwsRegion: string;
    AwsSessionToken: string;

    SystemPrompt: string;
    SmartConfigEnabled: Boolean;
    InjectDelphiVersion: Boolean;
    ConciseResponses: Boolean;
    LogEnabled: Boolean;
    LogPath: string;
    LogMaxSize: string;
    
    QuotaEnabled: Boolean;
    QuotaLimit: string;
    QuotaUsedText: string;

    LastMessageDialogText: string;
    SaveDialogResult: Boolean;
    SaveDialogSelectedFileName: string;
    OpenDialogResult: Boolean;
    OpenDialogSelectedFileName: string;
    FolderDialogResult: Boolean;
    FolderDialogSelectedFolderName: string;
    CloseViewCalled: Boolean;
    CloseViewModalResult: Integer;

    TemplatesList: TArray<string>;
    SelectedTemplateIndex: Integer;
    
    TemplateName: string;
    TemplateDesc: string;
    TemplateBody: string;
    TemplateSlash: string;
    TemplateIsProjGen: Boolean;
    
    TemplateIsSystem: Boolean;
    TemplateIsCustomized: Boolean;
    DeleteTemplateButtonCaption: string;
    DeleteTemplateButtonEnabled: Boolean;
    TemplateOriginLabelText: string;
    TemplateOriginLabelColor: TColor;
    
    FocusTemplateNameCalled: Boolean;

    constructor Create;
    destructor Destroy; override;

    { IRadIAConfigView }
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
  end;

  [TestFixture]
  TTestConfigPresenter = class
  private
    FMockView: TMockConfigView;
    FPresenter: TRadIAConfigPresenter;
    FConfig: IRadIAConfig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestLoadConfigLoadsToView;
    [Test]
    procedure TestSaveConfigValidatesUrlGeminiAndAzure;
    [Test]
    procedure TestSaveConfigValidatesTemperatureRange;
    [Test]
    procedure TestSaveConfigValidatesIntegersRobustly;
    [Test]
    procedure TestTemplateCreationAndSelection;
    [Test]
    procedure TestResetQuotaUsage;
  end;

implementation

uses
  RadIA.Core.Config, RadIA.Core.SettingsStorage;

{ TMockConfigView }

constructor TMockConfigView.Create;
begin
  inherited Create;
  ApiKeyMap := TDictionary<string, string>.Create;
  CustomUrlMap := TDictionary<string, string>.Create;
  AuthTypeMap := TDictionary<string, Integer>.Create;
  TempMap := TDictionary<string, string>.Create;
  MaxTokensMap := TDictionary<string, string>.Create;
  TimeoutMap := TDictionary<string, string>.Create;
  
  SaveDialogResult := True;
  OpenDialogResult := True;
  FolderDialogResult := True;
  CloseViewCalled := False;
  FocusTemplateNameCalled := False;
  InjectDelphiVersion := True;
  ConciseResponses := True;
end;

destructor TMockConfigView.Destroy;
begin
  ApiKeyMap.Free;
  CustomUrlMap.Free;
  AuthTypeMap.Free;
  TempMap.Free;
  MaxTokensMap.Free;
  TimeoutMap.Free;
  inherited Destroy;
end;

function TMockConfigView.GetApiKey(const AProviderId: string): string;
begin
  if not ApiKeyMap.TryGetValue(AProviderId, Result) then Result := '';
end;

procedure TMockConfigView.SetApiKey(const AProviderId: string; const AKey: string);
begin
  ApiKeyMap.AddOrSetValue(AProviderId, AKey);
end;

function TMockConfigView.GetCustomUrl(const AProviderId: string): string;
begin
  if not CustomUrlMap.TryGetValue(AProviderId, Result) then Result := '';
end;

procedure TMockConfigView.SetCustomUrl(const AProviderId: string; const AUrl: string);
begin
  CustomUrlMap.AddOrSetValue(AProviderId, AUrl);
end;

function TMockConfigView.GetAuthTypeIndex(const AProviderId: string): Integer;
begin
  if not AuthTypeMap.TryGetValue(AProviderId, Result) then Result := 0;
end;

procedure TMockConfigView.SetAuthTypeIndex(const AProviderId: string; const AIndex: Integer);
begin
  AuthTypeMap.AddOrSetValue(AProviderId, AIndex);
end;

function TMockConfigView.GetTemperatureInput(const AProviderId: string): string;
begin
  if not TempMap.TryGetValue(AProviderId, Result) then Result := '0.7';
end;

procedure TMockConfigView.SetTemperatureInput(const AProviderId: string; const AValue: string);
begin
  TempMap.AddOrSetValue(AProviderId, AValue);
end;

function TMockConfigView.GetMaxTokensInput(const AProviderId: string): string;
begin
  if not MaxTokensMap.TryGetValue(AProviderId, Result) then Result := '2048';
end;

procedure TMockConfigView.SetMaxTokensInput(const AProviderId: string; const AValue: string);
begin
  MaxTokensMap.AddOrSetValue(AProviderId, AValue);
end;

function TMockConfigView.GetTimeoutInput(const AProviderId: string): string;
begin
  if not TimeoutMap.TryGetValue(AProviderId, Result) then Result := '60';
end;

procedure TMockConfigView.SetTimeoutInput(const AProviderId: string; const AValue: string);
begin
  TimeoutMap.AddOrSetValue(AProviderId, AValue);
end;

function TMockConfigView.GetAzureModel: string; begin Result := AzureModel; end;
procedure TMockConfigView.SetAzureModel(const AValue: string); begin AzureModel := AValue; end;
function TMockConfigView.GetAzureApiVersion: string; begin Result := AzureApiVersion; end;
procedure TMockConfigView.SetAzureApiVersion(const AValue: string); begin AzureApiVersion := AValue; end;

function TMockConfigView.GetAwsAccessKeyId: string; begin Result := AwsAccessKeyId; end;
procedure TMockConfigView.SetAwsAccessKeyId(const AValue: string); begin AwsAccessKeyId := AValue; end;
function TMockConfigView.GetAwsSecretAccessKey: string; begin Result := AwsSecretAccessKey; end;
procedure TMockConfigView.SetAwsSecretAccessKey(const AValue: string); begin AwsSecretAccessKey := AValue; end;
function TMockConfigView.GetAwsRegion: string; begin Result := AwsRegion; end;
procedure TMockConfigView.SetAwsRegion(const AValue: string); begin AwsRegion := AValue; end;
function TMockConfigView.GetAwsSessionToken: string; begin Result := AwsSessionToken; end;
procedure TMockConfigView.SetAwsSessionToken(const AValue: string); begin AwsSessionToken := AValue; end;

function TMockConfigView.GetSystemPrompt: string; begin Result := SystemPrompt; end;
procedure TMockConfigView.SetSystemPrompt(const AValue: string); begin SystemPrompt := AValue; end;
function TMockConfigView.GetSmartConfigEnabled: Boolean; begin Result := SmartConfigEnabled; end;
procedure TMockConfigView.SetSmartConfigEnabled(const AValue: Boolean); begin SmartConfigEnabled := AValue; end;
function TMockConfigView.GetInjectDelphiVersion: Boolean; begin Result := InjectDelphiVersion; end;
procedure TMockConfigView.SetInjectDelphiVersion(const AValue: Boolean); begin InjectDelphiVersion := AValue; end;
function TMockConfigView.GetConciseResponses: Boolean; begin Result := ConciseResponses; end;
procedure TMockConfigView.SetConciseResponses(const AValue: Boolean); begin ConciseResponses := AValue; end;
function TMockConfigView.GetLogEnabled: Boolean; begin Result := LogEnabled; end;
procedure TMockConfigView.SetLogEnabled(const AValue: Boolean); begin LogEnabled := AValue; end;
function TMockConfigView.GetLogPath: string; begin Result := LogPath; end;
procedure TMockConfigView.SetLogPath(const AValue: string); begin LogPath := AValue; end;
function TMockConfigView.GetLogMaxSize: string; begin Result := LogMaxSize; end;
procedure TMockConfigView.SetLogMaxSize(const AValue: string); begin LogMaxSize := AValue; end;

function TMockConfigView.GetQuotaEnabled: Boolean; begin Result := QuotaEnabled; end;
procedure TMockConfigView.SetQuotaEnabled(const AValue: Boolean); begin QuotaEnabled := AValue; end;
function TMockConfigView.GetQuotaLimit: string; begin Result := QuotaLimit; end;
procedure TMockConfigView.SetQuotaLimit(const AValue: string); begin QuotaLimit := AValue; end;
procedure TMockConfigView.SetQuotaUsedText(const AText: string); begin QuotaUsedText := AText; end;

procedure TMockConfigView.ShowMessageDialog(const AMessage: string);
begin
  LastMessageDialogText := AMessage;
end;

function TMockConfigView.SaveDialogExecute(out AFileName: string): Boolean;
begin
  AFileName := SaveDialogSelectedFileName;
  Result := SaveDialogResult;
end;

function TMockConfigView.OpenDialogExecute(out AFileName: string): Boolean;
begin
  AFileName := OpenDialogSelectedFileName;
  Result := OpenDialogResult;
end;

function TMockConfigView.FolderDialogExecute(out AFolderName: string): Boolean;
begin
  AFolderName := FolderDialogSelectedFolderName;
  Result := FolderDialogResult;
end;

procedure TMockConfigView.CloseView(const AModalResult: Integer);
begin
  CloseViewCalled := True;
  CloseViewModalResult := AModalResult;
end;

procedure TMockConfigView.UpdateTemplatesList(const ATemplateNames: TArray<string>; const ASelectedIndex: Integer);
begin
  TemplatesList := ATemplateNames;
  SelectedTemplateIndex := ASelectedIndex;
end;

procedure TMockConfigView.GetTemplateEditorFields(out AName, ADesc, ABody, ASlash: string; out AIsProjGen: Boolean);
begin
  AName := TemplateName;
  ADesc := TemplateDesc;
  ABody := TemplateBody;
  ASlash := TemplateSlash;
  AIsProjGen := TemplateIsProjGen;
end;

procedure TMockConfigView.SetTemplateFields(const AName, ADesc, ABody, ASlash: string; const AIsProjGen: Boolean; const AIsSystem, AIsCustomized: Boolean);
begin
  TemplateName := AName;
  TemplateDesc := ADesc;
  TemplateBody := ABody;
  TemplateSlash := ASlash;
  TemplateIsProjGen := AIsProjGen;
  TemplateIsSystem := AIsSystem;
  TemplateIsCustomized := AIsCustomized;
end;

procedure TMockConfigView.ClearTemplateFields;
begin
  TemplateName := '';
  TemplateDesc := '';
  TemplateBody := '';
  TemplateSlash := '';
  TemplateIsProjGen := False;
end;

procedure TMockConfigView.FocusTemplateName;
begin
  FocusTemplateNameCalled := True;
end;

function TMockConfigView.GetSelectedTemplateIndex: Integer;
begin
  Result := SelectedTemplateIndex;
end;

procedure TMockConfigView.SetSelectedTemplateIndex(const AIndex: Integer);
begin
  SelectedTemplateIndex := AIndex;
end;

procedure TMockConfigView.SetDeleteTemplateButtonState(const ACaption: string; const AEnabled: Boolean);
begin
  DeleteTemplateButtonCaption := ACaption;
  DeleteTemplateButtonEnabled := AEnabled;
end;

procedure TMockConfigView.SetTemplateOriginLabel(const AText: string; const AColor: TColor);
begin
  TemplateOriginLabelText := AText;
  TemplateOriginLabelColor := AColor;
end;

{ TTestConfigPresenter }

procedure TTestConfigPresenter.Setup;
var
  LMemoryStorage: IRadIASettingsStorage;
begin
  LMemoryStorage := TRadIAMemorySettingsStorage.Create;
  TRadIAConfig.SetStorage(LMemoryStorage);
  FConfig := TRadIAConfig.GetInstance;
  FConfig.Load;
  
  FMockView := TMockConfigView.Create;
  FPresenter := TRadIAConfigPresenter.Create(FMockView, FConfig);
end;

procedure TTestConfigPresenter.TearDown;
begin
  FPresenter.Free;
  FConfig := nil;
  TRadIAConfig.SetStorage(nil);
end;

procedure TTestConfigPresenter.TestLoadConfigLoadsToView;
begin
  FConfig.SetApiKey('Gemini', 'gemini-key-123');
  FConfig.OllamaBaseUrl := 'http://localhost:11434';
  
  FPresenter.LoadConfig;
  
  Assert.AreEqual('gemini-key-123', FMockView.GetApiKey('Gemini'));
  Assert.AreEqual('http://localhost:11434', FMockView.GetCustomUrl('Ollama'));
end;

procedure TTestConfigPresenter.TestSaveConfigValidatesUrlGeminiAndAzure;
begin
  FPresenter.LoadConfig;
  
  // URL inválida (sem http:// ou https://)
  FMockView.SetCustomUrl('Ollama', 'localhost:11434');
  
  FPresenter.SaveConfig;
  
  // Deve exibir diálogo de erro e não deve fechar a View com mrOk (1)
  Assert.IsFalse(FMockView.LastMessageDialogText.IsEmpty);
  Assert.IsFalse(FMockView.CloseViewCalled);
end;

procedure TTestConfigPresenter.TestSaveConfigValidatesTemperatureRange;
begin
  FPresenter.LoadConfig;
  
  // Temperatura fora do limite (abc ou maior que 2.0)
  FMockView.SetTemperatureInput('Gemini', '2.5');
  
  FPresenter.SaveConfig;
  
  Assert.IsFalse(FMockView.LastMessageDialogText.IsEmpty);
  Assert.IsFalse(FMockView.CloseViewCalled);
end;

procedure TTestConfigPresenter.TestSaveConfigValidatesIntegersRobustly;
begin
  FPresenter.LoadConfig;
  
  // Timeout inválido
  FMockView.SetTimeoutInput('Gemini', '-5');
  
  FPresenter.SaveConfig;
  
  Assert.IsFalse(FMockView.LastMessageDialogText.IsEmpty);
  Assert.IsFalse(FMockView.CloseViewCalled);
end;

procedure TTestConfigPresenter.TestTemplateCreationAndSelection;
begin
  FPresenter.LoadConfig;
  
  // Criar novo template na View
  FPresenter.CreateNewTemplate;
  Assert.IsTrue(FMockView.FocusTemplateNameCalled);
  Assert.AreEqual('', FMockView.TemplateName);
  
  // Simular preenchimento
  FMockView.TemplateName := 'Custom Optimizer';
  FMockView.TemplateDesc := 'Optimize code';
  FMockView.TemplateBody := 'Optimize {code}';
  FMockView.TemplateSlash := '/opt';
  
  FPresenter.SaveTemplate;
  
  // Deve salvar e registrar
  Assert.IsTrue(Length(FMockView.TemplatesList) > 0);
end;

procedure TTestConfigPresenter.TestResetQuotaUsage;
begin
  FConfig.QuotaUsed := 50000;
  FPresenter.LoadConfig;
  
  FPresenter.ResetQuota;
  
  Assert.AreEqual(Int64(0), FConfig.QuotaUsed);
  Assert.AreEqual('Monthly Used Tokens: 0', FMockView.QuotaUsedText);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConfigPresenter);

end.
