unit RadIA.Tests.Providers;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config,
  RadIA.Core.TokenUsage, RadIA.Provider.Gemini, RadIA.Provider.OpenAI, RadIA.Provider.Claude,
  RadIA.Core.SettingsStorage;

type
  [TestFixture]
  TTestRadIAProviders = class
  private
    FConfig: IAIConfig;
    FGeminiProv: TRadIAGeminiProvider;
    FOpenAIProv: TRadIAOpenAIProvider;
    FClaudeProv: TRadIAClaudeProvider;
    
    function InvokeBuildRequestBody(AProvider: TObject; const APrompt: string; 
      const AHistory: TArray<IChatMessage>): string;
    function InvokeParseResponseBody(AProvider: TObject; const AJson: string; out AUsage: TTokenUsage): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestGeminiPayloadGeneration;
    [Test]
    procedure TestGeminiResponseParsing;
    [Test]
    procedure TestOpenAIPayloadGeneration;
    [Test]
    procedure TestOpenAIResponseParsing;
    [Test]
    procedure TestClaudePayloadGeneration;
    [Test]
    procedure TestClaudeResponseParsing;
  end;

  [TestFixture]
  TTestOpenAICustomUrl = class
  public
    [Test]
    procedure TestOpenAI_UsesDefaultUrl_WhenCustomEmpty;
    [Test]
    procedure TestOpenAI_CustomBaseUrl_ReplacesDefault;
    [Test]
    procedure TestOpenAI_CustomBaseUrl_TrailingSlashRemoved;
  end;

implementation

uses
  System.SysUtils, System.Rtti, System.JSON, RadIA.Core.Service, RadIA.Tests.Service;

{ TTestRadIAProviders }

procedure TTestRadIAProviders.Setup;
begin
  TRadIAConfig.SetBaseRegistryPath('Software\TestRadIAProviders');
  TRadIAConfig.SetStorage(TMemorySettingsStorage.Create);
  FConfig := TRadIAConfig.Create;
  FGeminiProv := TRadIAGeminiProvider.Create(FConfig);
  FOpenAIProv := TRadIAOpenAIProvider.Create(FConfig);
  FClaudeProv := TRadIAClaudeProvider.Create(FConfig);
end;

procedure TTestRadIAProviders.TearDown;
begin
  FGeminiProv.Free;
  FOpenAIProv.Free;
  FClaudeProv.Free;
  FConfig := nil;
  TRadIAConfig.SetStorage(nil);
  TRadIAConfig.SetBaseRegistryPath('');
end;

function TTestRadIAProviders.InvokeBuildRequestBody(AProvider: TObject; const APrompt: string; 
  const AHistory: TArray<IChatMessage>): string;
var
  LContext: TRttiContext;
  LType: TRttiInstanceType;
  LMethod: TRttiMethod;
  LResult: TValue;
begin
  LContext := TRttiContext.Create;
  LType := LContext.GetType(AProvider.ClassType) as TRttiInstanceType;
  LMethod := LType.GetMethod('BuildRequestBody');
  if not Assigned(LMethod) then
    LMethod := LType.GetMethod('BuildOpenAICompatibleRequestBody');
  if Assigned(LMethod) then
  begin
    case Length(LMethod.GetParameters) of
      4: LResult := LMethod.Invoke(AProvider, [APrompt, TValue.From<TArray<IChatMessage>>(AHistory), 0.7, 2048]);
      5: LResult := LMethod.Invoke(AProvider, [APrompt, TValue.From<TArray<IChatMessage>>(AHistory), False, 0.7, 2048]);
    else
      if Length(LMethod.GetParameters) = 3 then
        LResult := LMethod.Invoke(AProvider, [APrompt, TValue.From<TArray<IChatMessage>>(AHistory), False])
      else
        LResult := LMethod.Invoke(AProvider, [APrompt, TValue.From<TArray<IChatMessage>>(AHistory)]);
    end;
    Result := LResult.AsString;
  end
  else
    Result := '';
end;

function TTestRadIAProviders.InvokeParseResponseBody(AProvider: TObject; const AJson: string; out AUsage: TTokenUsage): string;
var
  LContext: TRttiContext;
  LType: TRttiInstanceType;
  LMethod: TRttiMethod;
  LResult: TValue;
  LParams: TArray<TValue>;
begin
  LContext := TRttiContext.Create;
  LType := LContext.GetType(AProvider.ClassType) as TRttiInstanceType;
  LMethod := LType.GetMethod('ParseResponseBody');
  if not Assigned(LMethod) then
    LMethod := LType.GetMethod('ParseOpenAICompatibleResponse');
  if Assigned(LMethod) then
  begin
    SetLength(LParams, 2);
    LParams[0] := AJson;
    LParams[1] := TValue.From<TTokenUsage>(TTokenUsage.Empty);
    LResult := LMethod.Invoke(AProvider, LParams);
    AUsage := LParams[1].AsType<TTokenUsage>;
    Result := LResult.AsString;
  end
  else
  begin
    AUsage := TTokenUsage.Empty;
    Result := '';
  end;
end;

procedure TTestRadIAProviders.TestGeminiPayloadGeneration;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJson: TJSONObject;
  LContents: TJSONArray;
begin
  LHistory := [TRadIAChatMessage.CreateMessage(mrUser, 'Hello')];
  LPayload := InvokeBuildRequestBody(FGeminiProv, 'How are you?', LHistory);
  
  Assert.IsNotEmpty(LPayload);
  LJson := TJSONObject.ParseJSONValue(LPayload) as TJSONObject;
  try
    Assert.IsNotNull(LJson, 'Payload should be valid JSON');
    LContents := LJson.GetValue('contents') as TJSONArray;
    Assert.IsNotNull(LContents);
    // 1 from history + 1 current prompt = 2 messages
    Assert.AreEqual(2, LContents.Count);
  finally
    LJson.Free;
  end;
end;

procedure TTestRadIAProviders.TestGeminiResponseParsing;
const
  GEMINI_MOCK_RESPONSE = 
    '{"candidates": [{"content": {"parts": [{"text": "Hello! I am Gemini AI."}]}}], ' +
    '"usageMetadata": {"promptTokenCount": 10, "candidatesTokenCount": 15, "totalTokenCount": 25}}';
var
  LText: string;
  LUsage: TTokenUsage;
begin
  LText := InvokeParseResponseBody(FGeminiProv, GEMINI_MOCK_RESPONSE, LUsage);
  Assert.AreEqual('Hello! I am Gemini AI.', LText);
  Assert.AreEqual(10, LUsage.PromptTokens);
  Assert.AreEqual(15, LUsage.CompletionTokens);
  Assert.AreEqual(25, LUsage.TotalTokens);
end;

procedure TTestRadIAProviders.TestOpenAIPayloadGeneration;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJson: TJSONObject;
  LMessages: TJSONArray;
begin
  LHistory := [TRadIAChatMessage.CreateMessage(mrUser, 'Hi')];
  LPayload := InvokeBuildRequestBody(FOpenAIProv, 'Hello OpenAI', LHistory);
  
  Assert.IsNotEmpty(LPayload);
  LJson := TJSONObject.ParseJSONValue(LPayload) as TJSONObject;
  try
    Assert.IsNotNull(LJson);
    LMessages := LJson.GetValue('messages') as TJSONArray;
    Assert.IsNotNull(LMessages);
    Assert.AreEqual(2, LMessages.Count);
  finally
    LJson.Free;
  end;
end;

procedure TTestRadIAProviders.TestOpenAIResponseParsing;
const
  OPENAI_MOCK_RESPONSE = 
    '{"choices": [{"message": {"role": "assistant", "content": "Hello! I am OpenAI ChatGPT."}}], ' +
    '"usage": {"prompt_tokens": 12, "completion_tokens": 18, "total_tokens": 30}}';
var
  LText: string;
  LUsage: TTokenUsage;
begin
  LText := InvokeParseResponseBody(FOpenAIProv, OPENAI_MOCK_RESPONSE, LUsage);
  Assert.AreEqual('Hello! I am OpenAI ChatGPT.', LText);
  Assert.AreEqual(12, LUsage.PromptTokens);
  Assert.AreEqual(18, LUsage.CompletionTokens);
  Assert.AreEqual(30, LUsage.TotalTokens);
end;

procedure TTestRadIAProviders.TestClaudePayloadGeneration;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJson: TJSONObject;
  LMessages: TJSONArray;
begin
  LHistory := [TRadIAChatMessage.CreateMessage(mrUser, 'Hey')];
  LPayload := InvokeBuildRequestBody(FClaudeProv, 'Hello Claude', LHistory);
  
  Assert.IsNotEmpty(LPayload);
  LJson := TJSONObject.ParseJSONValue(LPayload) as TJSONObject;
  try
    Assert.IsNotNull(LJson);
    LMessages := LJson.GetValue('messages') as TJSONArray;
    Assert.IsNotNull(LMessages);
    Assert.AreEqual(2, LMessages.Count);
  finally
    LJson.Free;
  end;
end;

procedure TTestRadIAProviders.TestClaudeResponseParsing;
const
  CLAUDE_MOCK_RESPONSE = 
    '{"content": [{"type": "text", "text": "Hello! I am Anthropic Claude."}], ' +
    '"usage": {"input_tokens": 14, "output_tokens": 21}}';
var
  LText: string;
  LUsage: TTokenUsage;
begin
  LText := InvokeParseResponseBody(FClaudeProv, CLAUDE_MOCK_RESPONSE, LUsage);
  Assert.AreEqual('Hello! I am Anthropic Claude.', LText);
  Assert.AreEqual(14, LUsage.PromptTokens);
  Assert.AreEqual(21, LUsage.CompletionTokens);
  Assert.AreEqual(35, LUsage.TotalTokens);
end;


{ TTestOpenAICustomUrl }

procedure TTestOpenAICustomUrl.TestOpenAI_UsesDefaultUrl_WhenCustomEmpty;
var
  LConfig: IAIConfig;
  LProvider: TRadIAOpenAIProvider;
begin
  { Use TMockConfig to avoid registry state contamination from other tests }
  LConfig := TMockConfig.Create(20);
  LProvider := TRadIAOpenAIProvider.Create(LConfig);
  try
    Assert.IsEmpty(LConfig.GetOpenAICustomBaseUrl,
      'Custom Base URL must be empty by default — provider will use official OpenAI endpoint');
  finally
    LProvider.Free;
    LConfig := nil;
  end;
end;

procedure TTestOpenAICustomUrl.TestOpenAI_CustomBaseUrl_ReplacesDefault;
var
  LConfig: IAIConfig;
const
  CUSTOM_URL = 'http://localhost:1234/v1';
begin
  LConfig := TMockConfig.Create(20);
  try
    LConfig.OpenAICustomBaseUrl := CUSTOM_URL;
    Assert.AreEqual(CUSTOM_URL, LConfig.GetOpenAICustomBaseUrl,
      'Custom Base URL must be stored and retrievable without modification');
  finally
    LConfig := nil;
  end;
end;

procedure TTestOpenAICustomUrl.TestOpenAI_CustomBaseUrl_TrailingSlashRemoved;
var
  LConfig: IAIConfig;
  LExpectedChatUrl: string;
const
  CUSTOM_URL_WITH_SLASH = 'http://localhost:1234/v1/';
  EXPECTED_CHAT_PATH    = '/chat/completions';
begin
  { Verify that TrimRight(['/']) + path produces the correct URL without double slash }
  LConfig := TMockConfig.Create(20);
  try
    LConfig.OpenAICustomBaseUrl := CUSTOM_URL_WITH_SLASH;
    LExpectedChatUrl := LConfig.GetOpenAICustomBaseUrl.TrimRight(['/']) + EXPECTED_CHAT_PATH;
    Assert.AreEqual('http://localhost:1234/v1' + EXPECTED_CHAT_PATH, LExpectedChatUrl,
      'Trailing slash must be stripped before appending path to avoid double slash');
  finally
    LConfig := nil;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAProviders);
  TDUnitX.RegisterTestFixture(TTestOpenAICustomUrl);

end.
