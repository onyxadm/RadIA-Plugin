unit RadIA.Core.InlineCompletionService;

interface

uses
  System.SysUtils, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.TokenUsage,
  RadIA.Core.RequestOrchestrator;

type
  TInlineCompletionCallback = reference to procedure(
    const ASuggestion: string; const AError: string);

  TInlineCompletionService = class
  private
    FConfig: IAIConfig;
    FOrchestrator: IAIRequestOrchestrator;
  public
    constructor Create(const AConfig: IAIConfig); overload;
    constructor Create(const AConfig: IAIConfig;
      const AOrchestrator: IAIRequestOrchestrator); overload;
    procedure RequestCompletion(const APrompt: string; const ACallback: TInlineCompletionCallback);
  end;

implementation

uses
  RadIA.Core.InlineCompletion;

type
  TInlineCompletionConfigAdapter = class(TInterfacedObject, IAIConfig)
  private
    FInner: IAIConfig;
  public
    constructor Create(const AInner: IAIConfig);
    function GetActiveProvider: string;
    procedure SetActiveProvider(const AProvider: string);
    function GetSystemPrompt: string;
    procedure SetSystemPrompt(const AValue: string);
    function GetOllamaBaseUrl: string;
    procedure SetOllamaBaseUrl(const AValue: string);
    function GetMaxHistoryMessages: Integer;
    procedure SetMaxHistoryMessages(const AValue: Integer);
    function GetOpenAICustomBaseUrl: string;
    procedure SetOpenAICustomBaseUrl(const AValue: string);
    function GetApiKey(const AProviderName: string): string;
    procedure SetApiKey(const AProviderName: string; const AKey: string);
    function GetActiveModel(const AProviderName: string): string;
    procedure SetActiveModel(const AProviderName: string; const AModel: string);
    function GetTemperature(const AProviderName: string): Double;
    procedure SetTemperature(const AProviderName: string; const AValue: Double);
    function GetMaxTokens(const AProviderName: string): Integer;
    procedure SetMaxTokens(const AProviderName: string; const AValue: Integer);
    function GetTimeout(const AProviderName: string): Integer;
    procedure SetTimeout(const AProviderName: string; const AValue: Integer);
    function GetProviderBaseUrl(const AProviderName: string): string;
    procedure SetProviderBaseUrl(const AProviderName: string; const AUrl: string);
    function GetProviderAuthType(const AProviderName: string): string;
    procedure SetProviderAuthType(const AProviderName: string; const AValue: string);
    function GetAutocompleteEnabled: Boolean;
    procedure SetAutocompleteEnabled(const AValue: Boolean);
    function GetAutocompleteProvider: string;
    procedure SetAutocompleteProvider(const AProvider: string);
    function GetAutocompleteModel: string;
    procedure SetAutocompleteModel(const AModel: string);
    function GetAutocompleteDelay: Integer;
    procedure SetAutocompleteDelay(const AValue: Integer);
    function GetAutocompleteShortcut: string;
    procedure SetAutocompleteShortcut(const AValue: string);
    function GetAutocompleteContextMode: TInlineCompletionContextMode;
    procedure SetAutocompleteContextMode(const AValue: TInlineCompletionContextMode);
    function GetAutocompleteContextBeforeLines: Integer;
    procedure SetAutocompleteContextBeforeLines(const AValue: Integer);
    function GetAutocompleteContextAfterLines: Integer;
    procedure SetAutocompleteContextAfterLines(const AValue: Integer);
    function GetAutocompleteSuggestionColor: Integer;
    procedure SetAutocompleteSuggestionColor(const AValue: Integer);
    function GetAutocompleteMaxTokens: Integer;
    procedure SetAutocompleteMaxTokens(const AValue: Integer);
    function GetSmartConfigEnabled: Boolean;
    procedure SetSmartConfigEnabled(const AValue: Boolean);
    function GetLogEnabled: Boolean;
    procedure SetLogEnabled(const AValue: Boolean);
    function GetLogPath: string;
    procedure SetLogPath(const AValue: string);
    function GetLogMaxSizeKB: Integer;
    procedure SetLogMaxSizeKB(const AValue: Integer);
    function GetQuotaEnabled: Boolean;
    procedure SetQuotaEnabled(const AValue: Boolean);
    function GetQuotaLimit: Int64;
    procedure SetQuotaLimit(const AValue: Int64);
    function GetQuotaUsed: Int64;
    procedure SetQuotaUsed(const AValue: Int64);
    function GetQuotaCycleStart: TDateTime;
    procedure SetQuotaCycleStart(const AValue: TDateTime);
    function GetActiveSessionId: string;
    procedure SetActiveSessionId(const AValue: string);
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
    function GetInjectDelphiVersion: Boolean;
    procedure SetInjectDelphiVersion(const AValue: Boolean);
    procedure AddToQuotaUsage(const AUsage: TTokenUsage);
    procedure Save;
    procedure Load;
  end;

constructor TInlineCompletionService.Create(const AConfig: IAIConfig);
var
  LConfig: IAIConfig;
begin
  inherited Create;
  FConfig := AConfig;
  LConfig := TInlineCompletionConfigAdapter.Create(FConfig);
  FOrchestrator := TRadIARequestOrchestrator.Create(LConfig);
end;

constructor TInlineCompletionService.Create(const AConfig: IAIConfig;
  const AOrchestrator: IAIRequestOrchestrator);
begin
  inherited Create;
  FConfig := AConfig;
  FOrchestrator := AOrchestrator;
end;

procedure TInlineCompletionService.RequestCompletion(const APrompt: string;
  const ACallback: TInlineCompletionCallback);
var
  LRequest: TAIRequest;
  LOrchestrator: IAIRequestOrchestrator;
begin
  LRequest := TAIRequest.Create(
    APrompt,
    ruInlineCompletion,
    rpInlineCompletion,
    [],
    rmComplete);

  LOrchestrator := FOrchestrator;
  LOrchestrator.ExecuteAsync(LRequest,
    procedure(const AResponse: string; const AError: string; const AUsage: TTokenUsage)
    var
      LSuggestion: string;
    begin
      if LOrchestrator = nil then
        Exit;

      if not AError.IsEmpty then
        ACallback('', AError)
      else
      begin
        LSuggestion := TInlineCompletionResponseCleaner.Clean(AResponse);
        ACallback(LSuggestion, '');
      end;
    end);
end;

constructor TInlineCompletionConfigAdapter.Create(const AInner: IAIConfig);
begin
  inherited Create;
  FInner := AInner;
end;

function TInlineCompletionConfigAdapter.GetActiveProvider: string;
begin
  Result := FInner.GetAutocompleteProvider;
end;

procedure TInlineCompletionConfigAdapter.SetActiveProvider(const AProvider: string);
begin
  FInner.SetAutocompleteProvider(AProvider);
end;

function TInlineCompletionConfigAdapter.GetActiveModel(const AProviderName: string): string;
begin
  if SameText(AProviderName, FInner.GetAutocompleteProvider) and not FInner.GetAutocompleteModel.IsEmpty then
    Result := FInner.GetAutocompleteModel
  else
    Result := FInner.GetActiveModel(AProviderName);
end;

procedure TInlineCompletionConfigAdapter.SetActiveModel(const AProviderName, AModel: string);
begin
  FInner.SetActiveModel(AProviderName, AModel);
end;

function TInlineCompletionConfigAdapter.GetSystemPrompt: string;
begin
  Result := FInner.GetSystemPrompt;
end;

procedure TInlineCompletionConfigAdapter.SetSystemPrompt(const AValue: string);
begin
  FInner.SetSystemPrompt(AValue);
end;

function TInlineCompletionConfigAdapter.GetOllamaBaseUrl: string;
begin
  Result := FInner.GetOllamaBaseUrl;
end;

procedure TInlineCompletionConfigAdapter.SetOllamaBaseUrl(const AValue: string);
begin
  FInner.SetOllamaBaseUrl(AValue);
end;

function TInlineCompletionConfigAdapter.GetMaxHistoryMessages: Integer;
begin
  Result := FInner.GetMaxHistoryMessages;
end;

procedure TInlineCompletionConfigAdapter.SetMaxHistoryMessages(const AValue: Integer);
begin
  FInner.SetMaxHistoryMessages(AValue);
end;

function TInlineCompletionConfigAdapter.GetOpenAICustomBaseUrl: string;
begin
  Result := FInner.GetOpenAICustomBaseUrl;
end;

procedure TInlineCompletionConfigAdapter.SetOpenAICustomBaseUrl(const AValue: string);
begin
  FInner.SetOpenAICustomBaseUrl(AValue);
end;

function TInlineCompletionConfigAdapter.GetApiKey(const AProviderName: string): string;
begin
  Result := FInner.GetApiKey(AProviderName);
end;

procedure TInlineCompletionConfigAdapter.SetApiKey(const AProviderName, AKey: string);
begin
  FInner.SetApiKey(AProviderName, AKey);
end;

function TInlineCompletionConfigAdapter.GetTemperature(const AProviderName: string): Double;
begin
  Result := FInner.GetTemperature(AProviderName);
end;

procedure TInlineCompletionConfigAdapter.SetTemperature(const AProviderName: string; const AValue: Double);
begin
  FInner.SetTemperature(AProviderName, AValue);
end;

function TInlineCompletionConfigAdapter.GetMaxTokens(const AProviderName: string): Integer;
begin
  Result := FInner.GetMaxTokens(AProviderName);
end;

procedure TInlineCompletionConfigAdapter.SetMaxTokens(const AProviderName: string; const AValue: Integer);
begin
  FInner.SetMaxTokens(AProviderName, AValue);
end;

function TInlineCompletionConfigAdapter.GetTimeout(const AProviderName: string): Integer;
begin
  Result := FInner.GetTimeout(AProviderName);
end;

procedure TInlineCompletionConfigAdapter.SetTimeout(const AProviderName: string; const AValue: Integer);
begin
  FInner.SetTimeout(AProviderName, AValue);
end;

function TInlineCompletionConfigAdapter.GetProviderBaseUrl(const AProviderName: string): string;
begin
  Result := FInner.GetProviderBaseUrl(AProviderName);
end;

procedure TInlineCompletionConfigAdapter.SetProviderBaseUrl(const AProviderName, AUrl: string);
begin
  FInner.SetProviderBaseUrl(AProviderName, AUrl);
end;

function TInlineCompletionConfigAdapter.GetProviderAuthType(const AProviderName: string): string;
begin
  Result := FInner.GetProviderAuthType(AProviderName);
end;

procedure TInlineCompletionConfigAdapter.SetProviderAuthType(const AProviderName, AValue: string);
begin
  FInner.SetProviderAuthType(AProviderName, AValue);
end;

function TInlineCompletionConfigAdapter.GetAutocompleteEnabled: Boolean;
begin
  Result := FInner.GetAutocompleteEnabled;
end;

procedure TInlineCompletionConfigAdapter.SetAutocompleteEnabled(const AValue: Boolean);
begin
  FInner.SetAutocompleteEnabled(AValue);
end;

function TInlineCompletionConfigAdapter.GetAutocompleteProvider: string;
begin
  Result := FInner.GetAutocompleteProvider;
end;

procedure TInlineCompletionConfigAdapter.SetAutocompleteProvider(const AProvider: string);
begin
  FInner.SetAutocompleteProvider(AProvider);
end;

function TInlineCompletionConfigAdapter.GetAutocompleteModel: string;
begin
  Result := FInner.GetAutocompleteModel;
end;

procedure TInlineCompletionConfigAdapter.SetAutocompleteModel(const AModel: string);
begin
  FInner.SetAutocompleteModel(AModel);
end;

function TInlineCompletionConfigAdapter.GetAutocompleteDelay: Integer;
begin
  Result := FInner.GetAutocompleteDelay;
end;

procedure TInlineCompletionConfigAdapter.SetAutocompleteDelay(const AValue: Integer);
begin
  FInner.SetAutocompleteDelay(AValue);
end;

function TInlineCompletionConfigAdapter.GetAutocompleteShortcut: string;
begin
  Result := FInner.GetAutocompleteShortcut;
end;

procedure TInlineCompletionConfigAdapter.SetAutocompleteShortcut(const AValue: string);
begin
  FInner.SetAutocompleteShortcut(AValue);
end;

function TInlineCompletionConfigAdapter.GetAutocompleteContextMode: TInlineCompletionContextMode;
begin
  Result := FInner.GetAutocompleteContextMode;
end;

procedure TInlineCompletionConfigAdapter.SetAutocompleteContextMode(const AValue: TInlineCompletionContextMode);
begin
  FInner.SetAutocompleteContextMode(AValue);
end;

function TInlineCompletionConfigAdapter.GetAutocompleteContextBeforeLines: Integer;
begin
  Result := FInner.GetAutocompleteContextBeforeLines;
end;

procedure TInlineCompletionConfigAdapter.SetAutocompleteContextBeforeLines(const AValue: Integer);
begin
  FInner.SetAutocompleteContextBeforeLines(AValue);
end;

function TInlineCompletionConfigAdapter.GetAutocompleteContextAfterLines: Integer;
begin
  Result := FInner.GetAutocompleteContextAfterLines;
end;

procedure TInlineCompletionConfigAdapter.SetAutocompleteContextAfterLines(const AValue: Integer);
begin
  FInner.SetAutocompleteContextAfterLines(AValue);
end;

function TInlineCompletionConfigAdapter.GetAutocompleteSuggestionColor: Integer;
begin
  Result := FInner.GetAutocompleteSuggestionColor;
end;

procedure TInlineCompletionConfigAdapter.SetAutocompleteSuggestionColor(const AValue: Integer);
begin
  FInner.SetAutocompleteSuggestionColor(AValue);
end;

function TInlineCompletionConfigAdapter.GetAutocompleteMaxTokens: Integer;
begin
  Result := FInner.GetAutocompleteMaxTokens;
end;

procedure TInlineCompletionConfigAdapter.SetAutocompleteMaxTokens(const AValue: Integer);
begin
  FInner.SetAutocompleteMaxTokens(AValue);
end;

function TInlineCompletionConfigAdapter.GetSmartConfigEnabled: Boolean;
begin
  Result := FInner.GetSmartConfigEnabled;
end;

procedure TInlineCompletionConfigAdapter.SetSmartConfigEnabled(const AValue: Boolean);
begin
  FInner.SetSmartConfigEnabled(AValue);
end;

function TInlineCompletionConfigAdapter.GetLogEnabled: Boolean;
begin
  Result := FInner.GetLogEnabled;
end;

procedure TInlineCompletionConfigAdapter.SetLogEnabled(const AValue: Boolean);
begin
  FInner.SetLogEnabled(AValue);
end;

function TInlineCompletionConfigAdapter.GetLogPath: string;
begin
  Result := FInner.GetLogPath;
end;

procedure TInlineCompletionConfigAdapter.SetLogPath(const AValue: string);
begin
  FInner.SetLogPath(AValue);
end;

function TInlineCompletionConfigAdapter.GetLogMaxSizeKB: Integer;
begin
  Result := FInner.GetLogMaxSizeKB;
end;

procedure TInlineCompletionConfigAdapter.SetLogMaxSizeKB(const AValue: Integer);
begin
  FInner.SetLogMaxSizeKB(AValue);
end;

function TInlineCompletionConfigAdapter.GetQuotaEnabled: Boolean;
begin
  Result := FInner.GetQuotaEnabled;
end;

procedure TInlineCompletionConfigAdapter.SetQuotaEnabled(const AValue: Boolean);
begin
  FInner.SetQuotaEnabled(AValue);
end;

function TInlineCompletionConfigAdapter.GetQuotaLimit: Int64;
begin
  Result := FInner.GetQuotaLimit;
end;

procedure TInlineCompletionConfigAdapter.SetQuotaLimit(const AValue: Int64);
begin
  FInner.SetQuotaLimit(AValue);
end;

function TInlineCompletionConfigAdapter.GetQuotaUsed: Int64;
begin
  Result := FInner.GetQuotaUsed;
end;

procedure TInlineCompletionConfigAdapter.SetQuotaUsed(const AValue: Int64);
begin
  FInner.SetQuotaUsed(AValue);
end;

function TInlineCompletionConfigAdapter.GetQuotaCycleStart: TDateTime;
begin
  Result := FInner.GetQuotaCycleStart;
end;

procedure TInlineCompletionConfigAdapter.SetQuotaCycleStart(const AValue: TDateTime);
begin
  FInner.SetQuotaCycleStart(AValue);
end;

function TInlineCompletionConfigAdapter.GetActiveSessionId: string;
begin
  Result := FInner.GetActiveSessionId;
end;

procedure TInlineCompletionConfigAdapter.SetActiveSessionId(const AValue: string);
begin
  FInner.SetActiveSessionId(AValue);
end;

function TInlineCompletionConfigAdapter.GetAzureApiVersion: string;
begin
  Result := FInner.GetAzureApiVersion;
end;

procedure TInlineCompletionConfigAdapter.SetAzureApiVersion(const AValue: string);
begin
  FInner.SetAzureApiVersion(AValue);
end;

function TInlineCompletionConfigAdapter.GetAwsAccessKeyId: string;
begin
  Result := FInner.GetAwsAccessKeyId;
end;

procedure TInlineCompletionConfigAdapter.SetAwsAccessKeyId(const AValue: string);
begin
  FInner.SetAwsAccessKeyId(AValue);
end;

function TInlineCompletionConfigAdapter.GetAwsSecretAccessKey: string;
begin
  Result := FInner.GetAwsSecretAccessKey;
end;

procedure TInlineCompletionConfigAdapter.SetAwsSecretAccessKey(const AValue: string);
begin
  FInner.SetAwsSecretAccessKey(AValue);
end;

function TInlineCompletionConfigAdapter.GetAwsRegion: string;
begin
  Result := FInner.GetAwsRegion;
end;

procedure TInlineCompletionConfigAdapter.SetAwsRegion(const AValue: string);
begin
  FInner.SetAwsRegion(AValue);
end;

function TInlineCompletionConfigAdapter.GetAwsSessionToken: string;
begin
  Result := FInner.GetAwsSessionToken;
end;

procedure TInlineCompletionConfigAdapter.SetAwsSessionToken(const AValue: string);
begin
  FInner.SetAwsSessionToken(AValue);
end;

function TInlineCompletionConfigAdapter.GetInjectDelphiVersion: Boolean;
begin
  Result := FInner.GetInjectDelphiVersion;
end;

procedure TInlineCompletionConfigAdapter.SetInjectDelphiVersion(const AValue: Boolean);
begin
  FInner.SetInjectDelphiVersion(AValue);
end;

procedure TInlineCompletionConfigAdapter.AddToQuotaUsage(const AUsage: TTokenUsage);
begin
  FInner.AddToQuotaUsage(AUsage);
end;

procedure TInlineCompletionConfigAdapter.Save;
begin
  FInner.Save;
end;

procedure TInlineCompletionConfigAdapter.Load;
begin
  FInner.Load;
end;

end.
