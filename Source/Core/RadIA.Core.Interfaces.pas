unit RadIA.Core.Interfaces;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Types, RadIA.Core.TokenUsage;

type
  ILifecycleGuard = interface
    ['{F4EED9A6-6CBA-43B6-9E39-1E38AA2C7301}']
    function GetIsAlive: Boolean;
    procedure Invalidate;
    property IsAlive: Boolean read GetIsAlive;
  end;

  TLifecycleGuard = class(TInterfacedObject, ILifecycleGuard)
  private
    FIsAlive: Boolean;
    function GetIsAlive: Boolean;
  public
    constructor Create;
    procedure Invalidate;
  end;

  { Callback type for asynchronous AI responses.
    AResponse   : Text returned by the AI (empty on error)
    AError      : Error description (empty on success)
    AFromCache  : True when the response was served from local cache
    AUsage      : Token counters (may be empty for providers that do not report usage) }
  TCompletionCallback = reference to procedure(
    const AResponse: string;
    const AError: string;
    AFromCache: Boolean;
    const AUsage: TTokenUsage);

  { Callback type for incremental streaming of AI responses }
  TStreamChunkCallback = reference to procedure(
    const AChunk: string;
    const AIsDone: Boolean;
    const AError: string);

  { Interface representing a message in the chat history }
  IChatMessage = interface
    ['{69A8A5DC-0F88-46E1-AD7A-8A46101EA97D}']
    function GetRole: TAIMessageRole;
    function GetContent: string;
    procedure SetContent(const AValue: string);
    function GetProvider: string;
    procedure SetProvider(const AValue: string);
    function GetModel: string;
    procedure SetModel(const AValue: string);
    property Role: TAIMessageRole read GetRole;
    property Content: string read GetContent write SetContent;
    property Provider: string read GetProvider write SetProvider;
    property Model: string read GetModel write SetModel;
  end;

  { Interface representing an AI Provider }
  IIAProvider = interface
    ['{A2833F50-9A0B-432D-8B8D-20DFF15FF25D}']
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback; const ATemperature: Double; const AMaxTokens: Integer);
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TStreamChunkCallback; const ATemperature: Double; const AMaxTokens: Integer);
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>);
    function GetAvailableModels: TArray<string>;
    function GetName: string;
    function GetProviderId: string;
    procedure CancelCurrentRequest;
  end;

  { Interface representing Configuration Management }
  IAIConfig = interface
    ['{88A9678F-520E-4BF5-BFB4-5C04A5826A6F}']
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

    { String-based dynamic provider APIs }
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
    function GetConciseResponses: Boolean;
    procedure SetConciseResponses(const AValue: Boolean);
    procedure AddToQuotaUsage(const AUsage: TTokenUsage);
    procedure Save;
    procedure Load;
    property SystemPrompt: string read GetSystemPrompt write SetSystemPrompt;
    property OllamaBaseUrl: string read GetOllamaBaseUrl write SetOllamaBaseUrl;
    property MaxHistoryMessages: Integer read GetMaxHistoryMessages write SetMaxHistoryMessages;
    property OpenAICustomBaseUrl: string read GetOpenAICustomBaseUrl write SetOpenAICustomBaseUrl;
    property AzureApiVersion: string read GetAzureApiVersion write SetAzureApiVersion;
    property AwsAccessKeyId: string read GetAwsAccessKeyId write SetAwsAccessKeyId;
    property AwsSecretAccessKey: string read GetAwsSecretAccessKey write SetAwsSecretAccessKey;
    property AwsRegion: string read GetAwsRegion write SetAwsRegion;
    property AwsSessionToken: string read GetAwsSessionToken write SetAwsSessionToken;
    property AutocompleteEnabled: Boolean read GetAutocompleteEnabled write SetAutocompleteEnabled;
    property AutocompleteProvider: string read GetAutocompleteProvider write SetAutocompleteProvider;
    property AutocompleteModel: string read GetAutocompleteModel write SetAutocompleteModel;
    property AutocompleteDelay: Integer read GetAutocompleteDelay write SetAutocompleteDelay;
    property SmartConfigEnabled: Boolean read GetSmartConfigEnabled write SetSmartConfigEnabled;
    property LogEnabled: Boolean read GetLogEnabled write SetLogEnabled;
    property LogPath: string read GetLogPath write SetLogPath;
    property LogMaxSizeKB: Integer read GetLogMaxSizeKB write SetLogMaxSizeKB;
    property QuotaEnabled: Boolean read GetQuotaEnabled write SetQuotaEnabled;
    property QuotaLimit: Int64 read GetQuotaLimit write SetQuotaLimit;
    property QuotaUsed: Int64 read GetQuotaUsed write SetQuotaUsed;
    property QuotaCycleStart: TDateTime read GetQuotaCycleStart write SetQuotaCycleStart;
    property ActiveSessionId: string read GetActiveSessionId write SetActiveSessionId;
    property InjectDelphiVersion: Boolean read GetInjectDelphiVersion write SetInjectDelphiVersion;
    property ConciseResponses: Boolean read GetConciseResponses write SetConciseResponses;
  end;

implementation

{ TLifecycleGuard }

constructor TLifecycleGuard.Create;
begin
  inherited Create;
  FIsAlive := True;
end;

function TLifecycleGuard.GetIsAlive: Boolean;
begin
  Result := FIsAlive;
end;

procedure TLifecycleGuard.Invalidate;
begin
  FIsAlive := False;
end;

end.
