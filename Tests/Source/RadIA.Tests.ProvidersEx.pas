unit RadIA.Tests.ProvidersEx;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config,
  RadIA.Core.TokenUsage, RadIA.Provider.DeepSeek, RadIA.Provider.Groq, RadIA.Provider.OpenRouter,
  RadIA.Provider.LMStudio, RadIA.Provider.AzureOpenAI, RadIA.Provider.Qwen, RadIA.Provider.Mistral;

type
  [TestFixture]
  TTestRadIAProvidersEx = class
  private
    FConfig: IAIConfig;
    FDeepSeekProv: TRadIADeepSeekProvider;
    FGroqProv: TRadIAGroqProvider;
    FOpenRouterProv: TRadIAOpenRouterProvider;
    FLMStudioProv: TRadIALMStudioProvider;
    FAzureProv: TRadIAAzureOpenAIProvider;
    FQwenProv: TRadIAQwenProvider;
    FMistralProv: TRadIAMistralProvider;
    
    function InvokeBuildRequestBody(AProvider: TObject; const APrompt: string; 
      const AHistory: TArray<IChatMessage>; const AStream: Boolean = False): string;
    function InvokeParseResponseBody(AProvider: TObject; const AJson: string; out AUsage: TTokenUsage): string;
    procedure InvokeProcessStreamBuffer(AProvider: TObject; var ABuffer: string; const ACallback: TStreamChunkCallback);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestDeepSeek_PayloadAndParsing;
    [Test]
    procedure TestDeepSeek_StreamingSSE;
    [Test]
    procedure TestGroq_PayloadAndParsing;
    [Test]
    procedure TestGroq_StreamingSSE;
    [Test]
    procedure TestOpenRouter_PayloadAndParsing;
    [Test]
    procedure TestOpenRouter_StreamingSSE;
    [Test]
    procedure TestLMStudio_PayloadAndParsing;
    [Test]
    procedure TestLMStudio_StreamingSSE;
    [Test]
    procedure TestAzureOpenAI_PayloadAndParsing;
    [Test]
    procedure TestAzureOpenAI_StreamingSSE;
    [Test]
    procedure TestQwen_PayloadAndParsing;
    [Test]
    procedure TestQwen_StreamingSSE;
    [Test]
    procedure TestMistral_PayloadAndParsing;
    [Test]
    procedure TestMistral_StreamingSSE;
  end;

implementation

uses
  System.SysUtils, System.Rtti, System.JSON, RadIA.Core.Service, RadIA.Tests.Service;

{ TTestRadIAProvidersEx }

procedure TTestRadIAProvidersEx.Setup;
begin
  FConfig := TRadIAConfig.Create;
  FDeepSeekProv := TRadIADeepSeekProvider.Create(FConfig);
  FGroqProv := TRadIAGroqProvider.Create(FConfig);
  FOpenRouterProv := TRadIAOpenRouterProvider.Create(FConfig);
  FLMStudioProv := TRadIALMStudioProvider.Create(FConfig);
  FAzureProv := TRadIAAzureOpenAIProvider.Create(FConfig);
  FQwenProv := TRadIAQwenProvider.Create(FConfig);
  FMistralProv := TRadIAMistralProvider.Create(FConfig);
end;

procedure TTestRadIAProvidersEx.TearDown;
begin
  FDeepSeekProv.Free;
  FGroqProv.Free;
  FOpenRouterProv.Free;
  FLMStudioProv.Free;
  FAzureProv.Free;
  FQwenProv.Free;
  FMistralProv.Free;
  FConfig := nil;
end;

function TTestRadIAProvidersEx.InvokeBuildRequestBody(AProvider: TObject; const APrompt: string; 
  const AHistory: TArray<IChatMessage>; const AStream: Boolean): string;
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
      5: LResult := LMethod.Invoke(AProvider, [APrompt, TValue.From<TArray<IChatMessage>>(AHistory), AStream, 0.7, 2048]);
    else
      LResult := LMethod.Invoke(AProvider, [APrompt, TValue.From<TArray<IChatMessage>>(AHistory), AStream]);
    end;
    Result := LResult.AsString;
  end
  else
    Result := '';
end;

function TTestRadIAProvidersEx.InvokeParseResponseBody(AProvider: TObject; const AJson: string; out AUsage: TTokenUsage): string;
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

procedure TTestRadIAProvidersEx.InvokeProcessStreamBuffer(AProvider: TObject; var ABuffer: string;
  const ACallback: TStreamChunkCallback);
var
  LContext: TRttiContext;
  LType: TRttiInstanceType;
  LMethod: TRttiMethod;
  LParams: TArray<TValue>;
begin
  LContext := TRttiContext.Create;
  LType := LContext.GetType(AProvider.ClassType) as TRttiInstanceType;
  LMethod := LType.GetMethod('ProcessStreamBuffer');
  if not Assigned(LMethod) then
    LMethod := LType.GetMethod('ProcessOpenAICompatibleStreamBuffer');
  if Assigned(LMethod) then
  begin
    SetLength(LParams, 2);
    LParams[0] := ABuffer;
    LParams[1] := TValue.From<TStreamChunkCallback>(ACallback);
    LMethod.Invoke(AProvider, LParams);
    ABuffer := LParams[0].AsString;
  end
  else
    raise Exception.Create('ProcessStreamBuffer method not found via RTTI');
end;

procedure TTestRadIAProvidersEx.TestDeepSeek_PayloadAndParsing;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJsonObj: TJSONObject;
  LMessages: TJSONArray;
  LText: string;
  LUsage: TTokenUsage;
const
  MOCK_DEEPSEEK_RESPONSE = 
    '{"choices": [{"message": {"role": "assistant", "content": "DeepSeek response text"}}], ' +
    '"usage": {"prompt_tokens": 15, "completion_tokens": 25, "total_tokens": 40}}';
begin
  // 1. Test Payload Generation
  LHistory := [TRadIAService.CreateMessage(mrUser, 'DeepSeek Query')];
  LPayload := InvokeBuildRequestBody(FDeepSeekProv, 'How is the weather?', LHistory, True);
  
  Assert.IsNotEmpty(LPayload);
  LJsonObj := TJSONObject.ParseJSONValue(LPayload) as TJSONObject;
  try
    Assert.IsNotNull(LJsonObj);
    Assert.AreEqual('deepseek-chat', LJsonObj.GetValue('model').Value);
    Assert.IsTrue(LJsonObj.GetValue<Boolean>('stream'));
    LMessages := LJsonObj.GetValue('messages') as TJSONArray;
    Assert.IsNotNull(LMessages);
    Assert.AreEqual(2, LMessages.Count);
  finally
    LJsonObj.Free;
  end;

  // 2. Test Response Parsing
  LText := InvokeParseResponseBody(FDeepSeekProv, MOCK_DEEPSEEK_RESPONSE, LUsage);
  Assert.AreEqual('DeepSeek response text', LText);
  Assert.AreEqual(15, LUsage.PromptTokens);
  Assert.AreEqual(25, LUsage.CompletionTokens);
  Assert.AreEqual(40, LUsage.TotalTokens);
end;

procedure TTestRadIAProvidersEx.TestDeepSeek_StreamingSSE;
var
  LBuffer: string;
  LReceivedText: string;
  LCallbackCount: Integer;
  LIsDone: Boolean;
begin
  LBuffer := 'data: {"choices":[{"delta":{"content":"Deep"}}]}' + #10 + 'data: {"choices":[{"delta":{"content":"Seek"}}]}' + #10 + 'data: [DONE]' + #10;
  LReceivedText := '';
  LCallbackCount := 0;
  LIsDone := False;

  InvokeProcessStreamBuffer(FDeepSeekProv, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      if AIsDone then
        LIsDone := True
      else
        LReceivedText := LReceivedText + AChunk;
      Assert.IsEmpty(AError);
    end);

  Assert.AreEqual(3, LCallbackCount);
  Assert.AreEqual('DeepSeek', LReceivedText);
  Assert.IsTrue(LIsDone);
  Assert.IsEmpty(LBuffer);
end;

procedure TTestRadIAProvidersEx.TestGroq_PayloadAndParsing;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJsonObj: TJSONObject;
  LMessages: TJSONArray;
  LText: string;
  LUsage: TTokenUsage;
const
  MOCK_GROQ_RESPONSE = 
    '{"choices": [{"message": {"role": "assistant", "content": "Groq response text"}}], ' +
    '"usage": {"prompt_tokens": 10, "completion_tokens": 20, "total_tokens": 30}}';
begin
  // 1. Test Payload Generation
  LHistory := [TRadIAService.CreateMessage(mrUser, 'Groq Query')];
  LPayload := InvokeBuildRequestBody(FGroqProv, 'Analyze this code', LHistory, False);
  
  Assert.IsNotEmpty(LPayload);
  LJsonObj := TJSONObject.ParseJSONValue(LPayload) as TJSONObject;
  try
    Assert.IsNotNull(LJsonObj);
    Assert.AreEqual('llama-3.3-70b-versatile', LJsonObj.GetValue('model').Value);
    Assert.IsNull(LJsonObj.GetValue('stream')); // stream should not be present if False
    LMessages := LJsonObj.GetValue('messages') as TJSONArray;
    Assert.IsNotNull(LMessages);
    Assert.AreEqual(2, LMessages.Count);
  finally
    LJsonObj.Free;
  end;

  // 2. Test Response Parsing
  LText := InvokeParseResponseBody(FGroqProv, MOCK_GROQ_RESPONSE, LUsage);
  Assert.AreEqual('Groq response text', LText);
  Assert.AreEqual(10, LUsage.PromptTokens);
  Assert.AreEqual(20, LUsage.CompletionTokens);
  Assert.AreEqual(30, LUsage.TotalTokens);
end;

procedure TTestRadIAProvidersEx.TestGroq_StreamingSSE;
var
  LBuffer: string;
  LReceivedText: string;
  LCallbackCount: Integer;
  LIsDone: Boolean;
begin
  LBuffer := 'data: {"choices":[{"delta":{"content":"Gro"}}]}' + #10 + 'data: {"choices":[{"delta":{"content":"q"}}]}' + #10 + 'data: [DONE]' + #10;
  LReceivedText := '';
  LCallbackCount := 0;
  LIsDone := False;

  InvokeProcessStreamBuffer(FGroqProv, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      if AIsDone then
        LIsDone := True
      else
        LReceivedText := LReceivedText + AChunk;
      Assert.IsEmpty(AError);
    end);

  Assert.AreEqual(3, LCallbackCount);
  Assert.AreEqual('Groq', LReceivedText);
  Assert.IsTrue(LIsDone);
  Assert.IsEmpty(LBuffer);
end;

procedure TTestRadIAProvidersEx.TestOpenRouter_PayloadAndParsing;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJsonObj: TJSONObject;
  LMessages: TJSONArray;
  LText: string;
  LUsage: TTokenUsage;
const
  MOCK_OPENROUTER_RESPONSE = 
    '{"choices": [{"message": {"role": "assistant", "content": "OpenRouter response text"}}], ' +
    '"usage": {"prompt_tokens": 8, "completion_tokens": 12, "total_tokens": 20}}';
begin
  // 1. Test Payload Generation
  LHistory := [TRadIAService.CreateMessage(mrUser, 'OpenRouter Query')];
  LPayload := InvokeBuildRequestBody(FOpenRouterProv, 'Hello', LHistory, True);
  
  Assert.IsNotEmpty(LPayload);
  LJsonObj := TJSONObject.ParseJSONValue(LPayload) as TJSONObject;
  try
    Assert.IsNotNull(LJsonObj);
    Assert.AreEqual('google/gemini-2.5-pro', LJsonObj.GetValue('model').Value);
    Assert.IsTrue(LJsonObj.GetValue<Boolean>('stream'));
    LMessages := LJsonObj.GetValue('messages') as TJSONArray;
    Assert.IsNotNull(LMessages);
    Assert.AreEqual(2, LMessages.Count);
  finally
    LJsonObj.Free;
  end;

  // 2. Test Response Parsing
  LText := InvokeParseResponseBody(FOpenRouterProv, MOCK_OPENROUTER_RESPONSE, LUsage);
  Assert.AreEqual('OpenRouter response text', LText);
  Assert.AreEqual(8, LUsage.PromptTokens);
  Assert.AreEqual(12, LUsage.CompletionTokens);
  Assert.AreEqual(20, LUsage.TotalTokens);
end;

procedure TTestRadIAProvidersEx.TestOpenRouter_StreamingSSE;
var
  LBuffer: string;
  LReceivedText: string;
  LCallbackCount: Integer;
  LIsDone: Boolean;
begin
  LBuffer := 'data: {"choices":[{"delta":{"content":"Open"}}]}' + #10 + 'data: {"choices":[{"delta":{"content":"Router"}}]}' + #10 + 'data: [DONE]' + #10;
  LReceivedText := '';
  LCallbackCount := 0;
  LIsDone := False;

  InvokeProcessStreamBuffer(FOpenRouterProv, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      if AIsDone then
        LIsDone := True
      else
        LReceivedText := LReceivedText + AChunk;
      Assert.IsEmpty(AError);
    end);

  Assert.AreEqual(3, LCallbackCount);
  Assert.AreEqual('OpenRouter', LReceivedText);
  Assert.IsTrue(LIsDone);
  Assert.IsEmpty(LBuffer);
end;

procedure TTestRadIAProvidersEx.TestLMStudio_PayloadAndParsing;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJsonObj: TJSONObject;
  LMessages: TJSONArray;
  LText: string;
  LUsage: TTokenUsage;
const
  MOCK_LMSTUDIO_RESPONSE = 
    '{"choices": [{"message": {"role": "assistant", "content": "LM Studio response text"}}], ' +
    '"usage": {"prompt_tokens": 12, "completion_tokens": 16, "total_tokens": 28}}';
begin
  // 1. Test Payload Generation
  LHistory := [TRadIAService.CreateMessage(mrUser, 'LM Studio Query')];
  LPayload := InvokeBuildRequestBody(FLMStudioProv, 'Test prompt', LHistory, True);
  
  Assert.IsNotEmpty(LPayload);
  LJsonObj := TJSONObject.ParseJSONValue(LPayload) as TJSONObject;
  try
    Assert.IsNotNull(LJsonObj);
    Assert.AreEqual('lms-default', LJsonObj.GetValue('model').Value);
    Assert.IsTrue(LJsonObj.GetValue<Boolean>('stream'));
    LMessages := LJsonObj.GetValue('messages') as TJSONArray;
    Assert.IsNotNull(LMessages);
    Assert.AreEqual(2, LMessages.Count);
  finally
    LJsonObj.Free;
  end;

  // 2. Test Response Parsing
  LText := InvokeParseResponseBody(FLMStudioProv, MOCK_LMSTUDIO_RESPONSE, LUsage);
  Assert.AreEqual('LM Studio response text', LText);
  Assert.AreEqual(12, LUsage.PromptTokens);
  Assert.AreEqual(16, LUsage.CompletionTokens);
  Assert.AreEqual(28, LUsage.TotalTokens);
end;

procedure TTestRadIAProvidersEx.TestLMStudio_StreamingSSE;
var
  LBuffer: string;
  LReceivedText: string;
  LCallbackCount: Integer;
  LIsDone: Boolean;
begin
  LBuffer := 'data: {"choices":[{"delta":{"content":"LM"}}]}' + #10 + 'data: {"choices":[{"delta":{"content":" Studio"}}]}' + #10 + 'data: [DONE]' + #10;
  LReceivedText := '';
  LCallbackCount := 0;
  LIsDone := False;

  InvokeProcessStreamBuffer(FLMStudioProv, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      if AIsDone then
        LIsDone := True
      else
        LReceivedText := LReceivedText + AChunk;
      Assert.IsEmpty(AError);
    end);

  Assert.AreEqual(3, LCallbackCount);
  Assert.AreEqual('LM Studio', LReceivedText);
  Assert.IsTrue(LIsDone);
  Assert.IsEmpty(LBuffer);
end;

procedure TTestRadIAProvidersEx.TestAzureOpenAI_PayloadAndParsing;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJsonObj: TJSONObject;
  LMessages: TJSONArray;
  LText: string;
  LUsage: TTokenUsage;
const
  MOCK_AZURE_RESPONSE = 
    '{"choices": [{"message": {"role": "assistant", "content": "Azure response text"}}], ' +
    '"usage": {"prompt_tokens": 5, "completion_tokens": 10, "total_tokens": 15}}';
begin
  // Set config active model to avoid missing error
  FConfig.SetActiveModel('AzureOpenAI', 'gpt-4o');

  // 1. Test Payload Generation
  LHistory := [TRadIAService.CreateMessage(mrUser, 'Azure Query')];
  LPayload := InvokeBuildRequestBody(FAzureProv, 'Deploy application', LHistory, True);
  
  Assert.IsNotEmpty(LPayload);
  LJsonObj := TJSONObject.ParseJSONValue(LPayload) as TJSONObject;
  try
    Assert.IsNotNull(LJsonObj);
    Assert.AreEqual('gpt-4o', LJsonObj.GetValue('model').Value);
    Assert.IsTrue(LJsonObj.GetValue<Boolean>('stream'));
    LMessages := LJsonObj.GetValue('messages') as TJSONArray;
    Assert.IsNotNull(LMessages);
    Assert.AreEqual(2, LMessages.Count);
  finally
    LJsonObj.Free;
  end;

  // 2. Test Response Parsing
  LText := InvokeParseResponseBody(FAzureProv, MOCK_AZURE_RESPONSE, LUsage);
  Assert.AreEqual('Azure response text', LText);
  Assert.AreEqual(5, LUsage.PromptTokens);
  Assert.AreEqual(10, LUsage.CompletionTokens);
  Assert.AreEqual(15, LUsage.TotalTokens);
end;

procedure TTestRadIAProvidersEx.TestAzureOpenAI_StreamingSSE;
var
  LBuffer: string;
  LReceivedText: string;
  LCallbackCount: Integer;
  LIsDone: Boolean;
begin
  LBuffer := 'data: {"choices":[{"delta":{"content":"Azure"}}]}' + #10 + 'data: {"choices":[{"delta":{"content":" OpenAI"}}]}' + #10 + 'data: [DONE]' + #10;
  LReceivedText := '';
  LCallbackCount := 0;
  LIsDone := False;

  InvokeProcessStreamBuffer(FAzureProv, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      if AIsDone then
        LIsDone := True
      else
        LReceivedText := LReceivedText + AChunk;
      Assert.IsEmpty(AError);
    end);

  Assert.AreEqual(3, LCallbackCount);
  Assert.AreEqual('Azure OpenAI', LReceivedText);
  Assert.IsTrue(LIsDone);
  Assert.IsEmpty(LBuffer);
end;

procedure TTestRadIAProvidersEx.TestQwen_PayloadAndParsing;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJsonObj: TJSONObject;
  LMessages: TJSONArray;
  LText: string;
  LUsage: TTokenUsage;
const
  MOCK_QWEN_RESPONSE = 
    '{"choices": [{"message": {"role": "assistant", "content": "Qwen response text"}}], ' +
    '"usage": {"prompt_tokens": 12, "completion_tokens": 18, "total_tokens": 30}}';
begin
  // 1. Test Payload Generation
  LHistory := [TRadIAService.CreateMessage(mrUser, 'Qwen Query')];
  LPayload := InvokeBuildRequestBody(FQwenProv, 'Write code', LHistory, True);
  
  Assert.IsNotEmpty(LPayload);
  LJsonObj := TJSONObject.ParseJSONValue(LPayload) as TJSONObject;
  try
    Assert.IsNotNull(LJsonObj);
    Assert.AreEqual('qwen2.5-coder-32b-instruct', LJsonObj.GetValue('model').Value);
    Assert.IsTrue(LJsonObj.GetValue<Boolean>('stream'));
    LMessages := LJsonObj.GetValue('messages') as TJSONArray;
    Assert.IsNotNull(LMessages);
    Assert.AreEqual(2, LMessages.Count);
  finally
    LJsonObj.Free;
  end;

  // 2. Test Response Parsing
  LText := InvokeParseResponseBody(FQwenProv, MOCK_QWEN_RESPONSE, LUsage);
  Assert.AreEqual('Qwen response text', LText);
  Assert.AreEqual(12, LUsage.PromptTokens);
  Assert.AreEqual(18, LUsage.CompletionTokens);
  Assert.AreEqual(30, LUsage.TotalTokens);
end;

procedure TTestRadIAProvidersEx.TestQwen_StreamingSSE;
var
  LBuffer: string;
  LReceivedText: string;
  LCallbackCount: Integer;
  LIsDone: Boolean;
begin
  LBuffer := 'data: {"choices":[{"delta":{"content":"Ali"}}]}' + #10 + 'data: {"choices":[{"delta":{"content":"baba"}}]}' + #10 + 'data: [DONE]' + #10;
  LReceivedText := '';
  LCallbackCount := 0;
  LIsDone := False;

  InvokeProcessStreamBuffer(FQwenProv, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      if AIsDone then
        LIsDone := True
      else
        LReceivedText := LReceivedText + AChunk;
      Assert.IsEmpty(AError);
    end);

  Assert.AreEqual(3, LCallbackCount);
  Assert.AreEqual('Alibaba', LReceivedText);
  Assert.IsTrue(LIsDone);
  Assert.IsEmpty(LBuffer);
end;

procedure TTestRadIAProvidersEx.TestMistral_PayloadAndParsing;
var
  LPayload: string;
  LHistory: TArray<IChatMessage>;
  LJsonObj: TJSONObject;
  LMessages: TJSONArray;
  LText: string;
  LUsage: TTokenUsage;
const
  MOCK_MISTRAL_RESPONSE = 
    '{"choices": [{"message": {"role": "assistant", "content": "Mistral response text"}}], ' +
    '"usage": {"prompt_tokens": 20, "completion_tokens": 15, "total_tokens": 35}}';
begin
  // 1. Test Payload Generation
  LHistory := [TRadIAService.CreateMessage(mrUser, 'Mistral Query')];
  LPayload := InvokeBuildRequestBody(FMistralProv, 'Translate', LHistory, True);
  
  Assert.IsNotEmpty(LPayload);
  LJsonObj := TJSONObject.ParseJSONValue(LPayload) as TJSONObject;
  try
    Assert.IsNotNull(LJsonObj);
    Assert.AreEqual('codestral-latest', LJsonObj.GetValue('model').Value);
    Assert.IsTrue(LJsonObj.GetValue<Boolean>('stream'));
    LMessages := LJsonObj.GetValue('messages') as TJSONArray;
    Assert.IsNotNull(LMessages);
    Assert.AreEqual(2, LMessages.Count);
  finally
    LJsonObj.Free;
  end;

  // 2. Test Response Parsing
  LText := InvokeParseResponseBody(FMistralProv, MOCK_MISTRAL_RESPONSE, LUsage);
  Assert.AreEqual('Mistral response text', LText);
  Assert.AreEqual(20, LUsage.PromptTokens);
  Assert.AreEqual(15, LUsage.CompletionTokens);
  Assert.AreEqual(35, LUsage.TotalTokens);
end;

procedure TTestRadIAProvidersEx.TestMistral_StreamingSSE;
var
  LBuffer: string;
  LReceivedText: string;
  LCallbackCount: Integer;
  LIsDone: Boolean;
begin
  LBuffer := 'data: {"choices":[{"delta":{"content":"Mis"}}]}' + #10 + 'data: {"choices":[{"delta":{"content":"tral"}}]}' + #10 + 'data: [DONE]' + #10;
  LReceivedText := '';
  LCallbackCount := 0;
  LIsDone := False;

  InvokeProcessStreamBuffer(FMistralProv, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      if AIsDone then
        LIsDone := True
      else
        LReceivedText := LReceivedText + AChunk;
      Assert.IsEmpty(AError);
    end);

  Assert.AreEqual(3, LCallbackCount);
  Assert.AreEqual('Mistral', LReceivedText);
  Assert.IsTrue(LIsDone);
  Assert.IsEmpty(LBuffer);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAProvidersEx);

end.
