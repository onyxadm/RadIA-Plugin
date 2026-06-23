unit RadIA.Tests.ProviderBooster;

interface

uses
  DUnitX.TestFramework, System.Classes, System.SysUtils, System.Net.HttpClient, System.Net.URLClient,
  RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.TokenUsage;

type
  TMockHttpClient = class(TInterfacedObject, IRadIAHttpClient)
  public
    function Get(const AUrl: string; const AHeaders: TNetHeaders; const ATimeoutMs: Integer = 0): string;
    function Post(const AUrl: string; const AHeaders: TNetHeaders; const ARequestBody: string; const ATimeoutMs: Integer = 0): string;
    procedure PostStream(const AUrl: string; const AHeaders: TNetHeaders; const ARequestBody: string; const AOnWrite: TProc<TBytes>; const ATimeoutMs: Integer = 0);
    procedure Cancel;
  end;

  [TestFixture]
  TTestProviderBooster = class
  private
    FConfig: IRadIAConfig;
    procedure TestProvider(const AProvider: IRadIAProvider);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestCopilot;
    [Test]
    procedure TestGemini;
    [Test]
    procedure TestOpenAI;
    [Test]
    procedure TestClaude;
  end;

implementation

uses
  RadIA.Core.Config, RadIA.Core.SettingsStorage, RadIA.Core.Logger, RadIA.Core.Container,
  RadIA.Provider.GithubCopilot, RadIA.Provider.Gemini, RadIA.Provider.OpenAI, RadIA.Provider.Claude;

{ TTestProviderBooster }

procedure TTestProviderBooster.Setup;
var
  LMemoryStorage: IRadIASettingsStorage;
  LConfig: IRadIAConfig;
begin
  TRadIAContainer.Register<IRadIAHttpClient>(TMockHttpClient.Create);

  LMemoryStorage := TRadIAMemorySettingsStorage.Create;
  TRadIAConfig.SetStorage(LMemoryStorage);
  
  LConfig := TRadIAConfig.GetInstance;
  LConfig.SetProviderAuthType('Bedrock', 'aws_keys');
  LConfig.SetAwsAccessKeyId('DUMMY_ACCESS');
  LConfig.SetAwsSecretAccessKey('DUMMY_SECRET');
  LConfig.SetAwsRegion('us-east-1');

  LConfig.SetProviderAuthType('GithubCopilot', 'api_key');
  LConfig.SetAPIKey('GithubCopilot', 'ghu_dummy');

  LConfig.SetProviderAuthType('Gemini', 'api_key');
  LConfig.SetAPIKey('Gemini', 'dummy_key');

  LConfig.SetProviderAuthType('Ollama', 'local');

  LConfig.SetAPIKey('OpenAI', 'dummy');
  LConfig.SetAPIKey('Claude', 'dummy');
  LConfig.SetAPIKey('AzureOpenAI', 'dummy');
  LConfig.SetAPIKey('Groq', 'dummy');
  LConfig.SetAPIKey('OpenRouter', 'dummy');
  LConfig.SetAPIKey('DeepSeek', 'dummy');
  LConfig.SetAPIKey('Mistral', 'dummy');
  LConfig.SetAPIKey('Qwen', 'dummy');
  
  // Point all providers to a local invalid port so HTTP requests fail instantly (connection refused)
  // This prevents the application from hanging on TTask cleanup
  LConfig.SetProviderBaseUrl('Bedrock', 'http://127.0.0.1:1');
  LConfig.SetProviderBaseUrl('GithubCopilot', 'http://127.0.0.1:1');
  LConfig.SetProviderBaseUrl('Gemini', 'http://127.0.0.1:1');
  LConfig.SetProviderBaseUrl('Ollama', 'http://127.0.0.1:1');
  LConfig.SetProviderBaseUrl('OpenAI', 'http://127.0.0.1:1');
  LConfig.SetProviderBaseUrl('Claude', 'http://127.0.0.1:1');
  LConfig.SetProviderBaseUrl('AzureOpenAI', 'http://127.0.0.1:1');
  LConfig.SetProviderBaseUrl('Groq', 'http://127.0.0.1:1');
  LConfig.SetProviderBaseUrl('OpenRouter', 'http://127.0.0.1:1');
  LConfig.SetProviderBaseUrl('DeepSeek', 'http://127.0.0.1:1');
  LConfig.SetProviderBaseUrl('Mistral', 'http://127.0.0.1:1');
  LConfig.SetProviderBaseUrl('Qwen', 'http://127.0.0.1:1');
  
  // Set timeouts to 1ms so background tasks fail instantly and don't block process exit
  LConfig.SetTimeout('Bedrock', 1);
  LConfig.SetTimeout('GithubCopilot', 1);
  LConfig.SetTimeout('Gemini', 1);
  LConfig.SetTimeout('Ollama', 1);
  LConfig.SetTimeout('OpenAI', 1);
  LConfig.SetTimeout('Claude', 1);
  LConfig.SetTimeout('AzureOpenAI', 1);
  LConfig.SetTimeout('Groq', 1);
  LConfig.SetTimeout('OpenRouter', 1);
  LConfig.SetTimeout('DeepSeek', 1);
  LConfig.SetTimeout('Mistral', 1);
  LConfig.SetTimeout('Qwen', 1);

  FConfig := LConfig;
end;

procedure TTestProviderBooster.TearDown;
begin
  FConfig := nil;
  TRadIAConfig.SetStorage(nil);
end;

procedure TTestProviderBooster.TestProvider(const AProvider: IRadIAProvider);
var
  LHistory: TArray<IRadIAChatMessage>;
  LCompletionCallback: TCompletionCallback;
  LStreamCallback: TStreamChunkCallback;
  LFetchCallback: TProc<TArray<string>, string>;
  I: Integer;
begin
  if AProvider = nil then Exit;
  SetLength(LHistory, 0);

  LCompletionCallback := procedure(const AResponse: string; const AError: string; AFromCache: Boolean; const AUsage: TTokenUsage) begin end;
  LStreamCallback := procedure(const AChunk: string; const AIsDone: Boolean; const AError: string) begin end;
  LFetchCallback := procedure(A: TArray<string>; B: string) begin end;

  try
    AProvider.SendPromptAsync('Prompt', LHistory, LCompletionCallback, 0.7, 100);
  except end;

  try
    AProvider.SendPromptStreamAsync('Prompt', LHistory, LStreamCallback, 0.7, 100);
  except end;

  try AProvider.GetAvailableModels; except end;
  try AProvider.FetchAvailableModelsAsync(LFetchCallback); except end;
  try AProvider.GetName; except end;
  try AProvider.GetProviderId; except end;
  
  // Process queued callbacks to prevent deadlocks at shutdown
  for I := 1 to 50 do
  begin
    Sleep(10);
    CheckSynchronize(10);
  end;

  try AProvider.CancelCurrentRequest; except end;
end;

procedure TTestProviderBooster.TestCopilot;
begin
  TestProvider(TRadIAGithubCopilotProvider.Create(FConfig));
end;

procedure TTestProviderBooster.TestGemini;
begin
  TestProvider(TRadIAGeminiProvider.Create(FConfig));
end;

procedure TTestProviderBooster.TestOpenAI;
begin
  TestProvider(TRadIAOpenAIProvider.Create(FConfig));
end;

procedure TTestProviderBooster.TestClaude;
begin
  TestProvider(TRadIAClaudeProvider.Create(FConfig));
end;

{ TMockHttpClient }

function TMockHttpClient.Get(const AUrl: string; const AHeaders: TNetHeaders; const ATimeoutMs: Integer = 0): string;
begin
  Result := '{"choices": [{"message": {"content": "mock"}}]}';
end;

function TMockHttpClient.Post(const AUrl: string; const AHeaders: TNetHeaders; const ARequestBody: string; const ATimeoutMs: Integer = 0): string;
begin
  Result := '{"choices": [{"message": {"content": "mock"}}]}';
end;

procedure TMockHttpClient.PostStream(const AUrl: string; const AHeaders: TNetHeaders; const ARequestBody: string; const AOnWrite: TProc<TBytes>; const ATimeoutMs: Integer = 0);
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.UTF8.GetBytes('{"choices": [{"delta": {"content": "mock"}}]}' + #10);
  AOnWrite(LBytes);
end;

procedure TMockHttpClient.Cancel;
begin
end;

initialization
  TDUnitX.RegisterTestFixture(TTestProviderBooster);

end.
