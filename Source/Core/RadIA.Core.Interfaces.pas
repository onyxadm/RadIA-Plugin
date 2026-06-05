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
    function GetProviderType: TAIProviderType;
    procedure CancelCurrentRequest;
  end;

  { Interface representing Configuration Management }
  IAIConfig = interface
    ['{88A9678F-520E-4BF5-BFB4-5C04A5826A6F}']
    function GetApiKey(const AProvider: TAIProviderType): string;
    procedure SetApiKey(const AProvider: TAIProviderType; const AKey: string);
    function GetActiveProvider: TAIProviderType;
    procedure SetActiveProvider(const AProvider: TAIProviderType);
    function GetActiveModel(const AProvider: TAIProviderType): string;
    procedure SetActiveModel(const AProvider: TAIProviderType; const AModel: string);
    function GetSystemPrompt: string;
    procedure SetSystemPrompt(const AValue: string);
    function GetOllamaBaseUrl: string;
    procedure SetOllamaBaseUrl(const AValue: string);
    function GetMaxHistoryMessages: Integer;
    procedure SetMaxHistoryMessages(const AValue: Integer);
    function GetOpenAICustomBaseUrl: string;
    procedure SetOpenAICustomBaseUrl(const AValue: string);
    function GetTemperature(const AProvider: TAIProviderType): Double;
    procedure SetTemperature(const AProvider: TAIProviderType; const AValue: Double);
    function GetMaxTokens(const AProvider: TAIProviderType): Integer;
    procedure SetMaxTokens(const AProvider: TAIProviderType; const AValue: Integer);
    function GetTimeout(const AProvider: TAIProviderType): Integer;
    procedure SetTimeout(const AProvider: TAIProviderType; const AValue: Integer);
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
    procedure AddToQuotaUsage(const AUsage: TTokenUsage);
    procedure Save;
    procedure Load;
    property SystemPrompt: string read GetSystemPrompt write SetSystemPrompt;
    property OllamaBaseUrl: string read GetOllamaBaseUrl write SetOllamaBaseUrl;
    property MaxHistoryMessages: Integer read GetMaxHistoryMessages write SetMaxHistoryMessages;
    property OpenAICustomBaseUrl: string read GetOpenAICustomBaseUrl write SetOpenAICustomBaseUrl;
    property SmartConfigEnabled: Boolean read GetSmartConfigEnabled write SetSmartConfigEnabled;
    property LogEnabled: Boolean read GetLogEnabled write SetLogEnabled;
    property LogPath: string read GetLogPath write SetLogPath;
    property LogMaxSizeKB: Integer read GetLogMaxSizeKB write SetLogMaxSizeKB;
    property QuotaEnabled: Boolean read GetQuotaEnabled write SetQuotaEnabled;
    property QuotaLimit: Int64 read GetQuotaLimit write SetQuotaLimit;
    property QuotaUsed: Int64 read GetQuotaUsed write SetQuotaUsed;
    property QuotaCycleStart: TDateTime read GetQuotaCycleStart write SetQuotaCycleStart;
    property ActiveSessionId: string read GetActiveSessionId write SetActiveSessionId;
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
