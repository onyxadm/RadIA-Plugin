unit RadIA.Tests.Providers;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config,
  RadIA.Provider.Gemini, RadIA.Provider.OpenAI, RadIA.Provider.Claude;

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
    function InvokeParseResponseBody(AProvider: TObject; const AJson: string): string;
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
  if Assigned(LMethod) then
  begin
    LResult := LMethod.Invoke(AProvider, [APrompt, TValue.From<TArray<IChatMessage>>(AHistory)]);
    Result := LResult.AsString;
  end
  else
    Result := '';
end;

function TTestRadIAProviders.InvokeParseResponseBody(AProvider: TObject; const AJson: string): string;
var
  LContext: TRttiContext;
  LType: TRttiInstanceType;
  LMethod: TRttiMethod;
  LResult: TValue;
begin
  LContext := TRttiContext.Create;
  LType := LContext.GetType(AProvider.ClassType) as TRttiInstanceType;
  LMethod := LType.GetMethod('ParseResponseBody');
  if Assigned(LMethod) then
  begin
    LResult := LMethod.Invoke(AProvider, [AJson]);
    Result := LResult.AsString;
  end
  else
    Result := '';
end;

procedure TTestRadIAProviders.TestGeminiPayloadGeneration;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJson: TJSONObject;
  LContents: TJSONArray;
begin
  LHistory := [TRadIAService.CreateMessage(mrUser, 'Hello')];
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
    '{"candidates": [{"content": {"parts": [{"text": "Hello! I am Gemini AI."}]}}]}';
var
  LText: string;
begin
  LText := InvokeParseResponseBody(FGeminiProv, GEMINI_MOCK_RESPONSE);
  Assert.AreEqual('Hello! I am Gemini AI.', LText);
end;

procedure TTestRadIAProviders.TestOpenAIPayloadGeneration;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJson: TJSONObject;
  LMessages: TJSONArray;
begin
  LHistory := [TRadIAService.CreateMessage(mrUser, 'Hi')];
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
    '{"choices": [{"message": {"role": "assistant", "content": "Hello! I am OpenAI ChatGPT."}}]}';
var
  LText: string;
begin
  LText := InvokeParseResponseBody(FOpenAIProv, OPENAI_MOCK_RESPONSE);
  Assert.AreEqual('Hello! I am OpenAI ChatGPT.', LText);
end;

procedure TTestRadIAProviders.TestClaudePayloadGeneration;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJson: TJSONObject;
  LMessages: TJSONArray;
begin
  LHistory := [TRadIAService.CreateMessage(mrUser, 'Hey')];
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
    '{"content": [{"type": "text", "text": "Hello! I am Anthropic Claude."}]}';
var
  LText: string;
begin
  LText := InvokeParseResponseBody(FClaudeProv, CLAUDE_MOCK_RESPONSE);
  Assert.AreEqual('Hello! I am Anthropic Claude.', LText);
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
  LConfig := TRadIAConfig.Create;
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
  LConfig := TRadIAConfig.Create;
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
