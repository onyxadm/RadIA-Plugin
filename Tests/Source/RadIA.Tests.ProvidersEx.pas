unit RadIA.Tests.ProvidersEx;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config,
  RadIA.Core.TokenUsage, RadIA.Provider.DeepSeek, RadIA.Provider.Groq, RadIA.Provider.OpenRouter,
  RadIA.Provider.LMStudio, RadIA.Provider.AzureOpenAI, RadIA.Provider.Qwen, RadIA.Provider.Mistral,
  RadIA.Provider.Bedrock, RadIA.Core.AwsSigner, RadIA.Core.SettingsStorage;

type
  [TestFixture]
  TTestRadIAProvidersEx = class
  private
    FConfig: IRadIAConfig;
    FDeepSeekProv: TRadIADeepSeekProvider;
    FGroqProv: TRadIAGroqProvider;
    FOpenRouterProv: TRadIAOpenRouterProvider;
    FLMStudioProv: TRadIALMStudioProvider;
    FAzureProv: TRadIAAzureOpenAIProvider;
    FQwenProv: TRadIAQwenProvider;
    FMistralProv: TRadIAMistralProvider;
    FBedrockProv: TRadIABedrockProvider;
    
    function InvokeBuildRequestBody(AProvider: TObject; const APrompt: string; 
      const AHistory: TArray<IRadIAChatMessage>; const AStream: Boolean = False): string;
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
    [Test]
    procedure TestBedrock_PayloadAndParsing;
    [Test]
    procedure TestBedrock_AwsSignerSigV4;
    [Test]
    procedure TestBedrock_EventStreamParser;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Rtti, System.JSON, RadIA.Core.Service, RadIA.Tests.Service,
  System.NetEncoding;

{ TTestRadIAProvidersEx }

procedure TTestRadIAProvidersEx.Setup;
begin
  TRadIAConfig.SetBaseRegistryPath('Software\TestRadIAProvidersEx');
  TRadIAConfig.SetStorage(TRadIAMemorySettingsStorage.Create);
  FConfig := TRadIAConfig.Create;
  FConfig.SetActiveModel('DeepSeek', MODEL_DEEPSEEK_CHAT);
  FConfig.SetActiveModel('Groq', MODEL_GROQ_LLAMA33);
  FConfig.SetActiveModel('OpenRouter', MODEL_OPENROUTER_GEMINI25_PRO);
  FConfig.SetActiveModel('LMStudio', 'lms-default');
  FConfig.SetActiveModel('Qwen', MODEL_QWEN_25_CODER_32B);
  FConfig.SetActiveModel('Mistral', MODEL_MISTRAL_CODESTRAL);
  FDeepSeekProv := TRadIADeepSeekProvider.Create(FConfig);
  FGroqProv := TRadIAGroqProvider.Create(FConfig);
  FOpenRouterProv := TRadIAOpenRouterProvider.Create(FConfig);
  FLMStudioProv := TRadIALMStudioProvider.Create(FConfig);
  FAzureProv := TRadIAAzureOpenAIProvider.Create(FConfig);
  FQwenProv := TRadIAQwenProvider.Create(FConfig);
  FMistralProv := TRadIAMistralProvider.Create(FConfig);
  FBedrockProv := TRadIABedrockProvider.Create(FConfig);
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
  FBedrockProv.Free;
  FConfig := nil;
  TRadIAConfig.SetStorage(nil);
  TRadIAConfig.SetBaseRegistryPath('');
end;

function TTestRadIAProvidersEx.InvokeBuildRequestBody(AProvider: TObject; const APrompt: string; 
  const AHistory: TArray<IRadIAChatMessage>; const AStream: Boolean): string;
var
  LContext: TRttiContext;
  LType: TRttiInstanceType;
  LMethod: TRttiMethod;
  LResult: TValue;
begin
  LContext := TRttiContext.Create;
  LType := LContext.GetType(AProvider.ClassType) as TRttiInstanceType;
  LMethod := LType.GetMethod('BuildBedrockRequestBody');
  if not Assigned(LMethod) then
    LMethod := LType.GetMethod('BuildRequestBody');
  if not Assigned(LMethod) then
    LMethod := LType.GetMethod('BuildOpenAICompatibleRequestBody');
  if Assigned(LMethod) then
  begin
    case Length(LMethod.GetParameters) of
      4: LResult := LMethod.Invoke(AProvider, [APrompt, TValue.From<TArray<IRadIAChatMessage>>(AHistory), TValue.From<Double>(0.7), TValue.From<Integer>(2048)]);
      5: LResult := LMethod.Invoke(AProvider, [APrompt, TValue.From<TArray<IRadIAChatMessage>>(AHistory), AStream, TValue.From<Double>(0.7), TValue.From<Integer>(2048)]);
    else
      LResult := LMethod.Invoke(AProvider, [APrompt, TValue.From<TArray<IRadIAChatMessage>>(AHistory), AStream]);
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
  LMethod := LType.GetMethod('ParseBedrockResponse');
  if not Assigned(LMethod) then
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
  LHistory: TArray<IRadIAChatMessage>;
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
  LHistory := [TRadIAChatMessage.CreateMessage(mrUser, 'DeepSeek Query')];
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
  LHistory: TArray<IRadIAChatMessage>;
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
  LHistory := [TRadIAChatMessage.CreateMessage(mrUser, 'Groq Query')];
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
  LHistory: TArray<IRadIAChatMessage>;
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
  LHistory := [TRadIAChatMessage.CreateMessage(mrUser, 'OpenRouter Query')];
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
  LHistory: TArray<IRadIAChatMessage>;
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
  LHistory := [TRadIAChatMessage.CreateMessage(mrUser, 'LM Studio Query')];
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
  LHistory: TArray<IRadIAChatMessage>;
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
  LHistory := [TRadIAChatMessage.CreateMessage(mrUser, 'Azure Query')];
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
  LHistory: TArray<IRadIAChatMessage>;
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
  LHistory := [TRadIAChatMessage.CreateMessage(mrUser, 'Qwen Query')];
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
  LHistory: TArray<IRadIAChatMessage>;
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
  LHistory := [TRadIAChatMessage.CreateMessage(mrUser, 'Mistral Query')];
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

procedure TTestRadIAProvidersEx.TestBedrock_PayloadAndParsing;
var
  LPayload: string;
  LHistory: TArray<IRadIAChatMessage>;
  LJsonObj: TJSONObject;
  LMessages: TJSONArray;
  LText: string;
  LUsage: TTokenUsage;
const
  MOCK_BEDROCK_RESPONSE =
    '{"content": [{"type": "text", "text": "Bedrock Claude response text"}], ' +
    '"usage": {"input_tokens": 14, "output_tokens": 26}}';
begin
  // 1. Test Payload Generation
  LHistory := [TRadIAChatMessage.CreateMessage(mrUser, 'Bedrock Query')];
  LPayload := InvokeBuildRequestBody(FBedrockProv, 'Code review this class', LHistory, False);

  Assert.IsNotEmpty(LPayload);
  LJsonObj := TJSONObject.ParseJSONValue(LPayload) as TJSONObject;
  try
    Assert.IsNotNull(LJsonObj);
    Assert.AreEqual('bedrock-2023-05-31', LJsonObj.GetValue('anthropic_version').Value);
    LMessages := LJsonObj.GetValue('messages') as TJSONArray;
    Assert.IsNotNull(LMessages);
    Assert.AreEqual(2, LMessages.Count);
  finally
    LJsonObj.Free;
  end;

  // 2. Test Response Parsing
  LText := InvokeParseResponseBody(FBedrockProv, MOCK_BEDROCK_RESPONSE, LUsage);
  Assert.AreEqual('Bedrock Claude response text', LText);
  Assert.AreEqual(14, LUsage.PromptTokens);
  Assert.AreEqual(26, LUsage.CompletionTokens);
  Assert.AreEqual(40, LUsage.TotalTokens);
end;

procedure TTestRadIAProvidersEx.TestBedrock_AwsSignerSigV4;
var
  LHeaders: TStringList;
const
  MOCK_ACCESS_KEY = 'AKIAIOSFODNN7EXAMPLE';
  MOCK_SECRET_KEY = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY';
  MOCK_REGION = 'us-east-1';
  MOCK_SERVICE = 'bedrock';
  MOCK_METHOD = 'POST';
  MOCK_URI = '/model/anthropic.claude-3-5-sonnet-20241022-v2:0/invoke';
  MOCK_PAYLOAD = '{"anthropic_version":"bedrock-2023-05-31","messages":[]}';
  MOCK_DATE = '20260608T170000Z';
  MOCK_STAMP = '20260608';
begin
  LHeaders := TAwsSigV4Signer.ComputeSignatureHeaders(
    MOCK_ACCESS_KEY, MOCK_SECRET_KEY, MOCK_REGION, MOCK_SERVICE,
    MOCK_METHOD, MOCK_URI, MOCK_PAYLOAD, MOCK_DATE, MOCK_STAMP
  );
  try
    Assert.IsNotNull(LHeaders);
    Assert.AreEqual('application/json', LHeaders.Values['content-type']);
    Assert.AreEqual(MOCK_DATE, LHeaders.Values['x-amz-date']);
    Assert.IsNotEmpty(LHeaders.Values['x-amz-content-sha256']);
    Assert.IsNotEmpty(LHeaders.Values['Authorization']);
    Assert.IsTrue(LHeaders.Values['Authorization'].StartsWith('AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20260608/us-east-1/bedrock/aws4_request'));
  finally
    LHeaders.Free;
  end;

  // Test with session token
  LHeaders := TAwsSigV4Signer.ComputeSignatureHeaders(
    MOCK_ACCESS_KEY, MOCK_SECRET_KEY, MOCK_REGION, MOCK_SERVICE,
    MOCK_METHOD, MOCK_URI, MOCK_PAYLOAD, MOCK_DATE, MOCK_STAMP, 'session-token-123'
  );
  try
    Assert.AreEqual('session-token-123', LHeaders.Values['x-amz-security-token']);
    Assert.IsTrue(LHeaders.Values['Authorization'].Contains('x-amz-security-token'));
  finally
    LHeaders.Free;
  end;
end;

procedure TTestRadIAProvidersEx.TestBedrock_EventStreamParser;
  function CreateMockEventStreamFrame(const AText: string): TBytes;
  var
    LInnerJson: TJSONObject;
    LOuterJson: TJSONObject;
    LInnerStr: string;
    LOuterStr: string;
    LPayloadBytes: TBytes;
    LBase64: string;
    LTotalLength: Cardinal;
    LHeadersLength: Cardinal;
    LPayloadLen: Cardinal;
  begin
    LInnerJson := TJSONObject.Create;
    try
      LInnerJson.AddPair('type', 'content_block_delta');
      var LDelta := TJSONObject.Create;
      LDelta.AddPair('text', AText);
      LInnerJson.AddPair('delta', LDelta);
      LInnerStr := LInnerJson.ToJSON;
    finally
      LInnerJson.Free;
    end;

    LBase64 := TNetEncoding.Base64.EncodeBytesToString(TEncoding.UTF8.GetBytes(LInnerStr));
    LBase64 := LBase64.Replace(#13, '').Replace(#10, '');

    LOuterJson := TJSONObject.Create;
    try
      LOuterJson.AddPair('bytes', LBase64);
      LOuterStr := LOuterJson.ToJSON;
    finally
      LOuterJson.Free;
    end;

    LPayloadBytes := TEncoding.UTF8.GetBytes(LOuterStr);
    LPayloadLen := Length(LPayloadBytes);
    LHeadersLength := 0;
    LTotalLength := LPayloadLen + LHeadersLength + 16;

    SetLength(Result, LTotalLength);

    // Set total length (Big Endian)
    Result[0] := Byte((LTotalLength shl 0) shr 24);
    Result[1] := Byte((LTotalLength shl 8) shr 24);
    Result[2] := Byte((LTotalLength shl 16) shr 24);
    Result[3] := Byte((LTotalLength shl 24) shr 24);

    // Set headers length (0)
    Result[4] := 0;
    Result[5] := 0;
    Result[6] := 0;
    Result[7] := 0;

    // Prelude CRC (0)
    Result[8] := 0;
    Result[9] := 0;
    Result[10] := 0;
    Result[11] := 0;

    // Payload
    Move(LPayloadBytes[0], Result[12], LPayloadLen);

    // Message CRC (0)
    Result[LTotalLength - 4] := 0;
    Result[LTotalLength - 3] := 0;
    Result[LTotalLength - 2] := 0;
    Result[LTotalLength - 1] := 0;
  end;

var
  LParser: TRadIAAwsEventStreamParser;
  LChunk1, LChunk2: TBytes;
  LReceivedText: string;
  LCallbackCount: Integer;
  LIsDone: Boolean;
begin
  LReceivedText := '';
  LCallbackCount := 0;
  LIsDone := False;

  LParser := TRadIAAwsEventStreamParser.Create(
    procedure(const AChunk: string; AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      LReceivedText := LReceivedText + AChunk;
      if AIsDone then
        LIsDone := True;
      Assert.IsEmpty(AError);
    end
  );
  try
    LChunk1 := CreateMockEventStreamFrame('Claude ');
    LChunk2 := CreateMockEventStreamFrame('says hello!');

    // 1. Process first frame
    LParser.ProcessBytes(LChunk1);
    Assert.AreEqual('Claude ', LReceivedText);
    Assert.AreEqual(1, LCallbackCount);

    // 2. Process second frame
    LParser.ProcessBytes(LChunk2);
    Assert.AreEqual('Claude says hello!', LReceivedText);
    Assert.AreEqual(2, LCallbackCount);

    // 3. Process incremental bytes (simulate network fragmentation)
    LReceivedText := '';
    LCallbackCount := 0;
    var LFrame := CreateMockEventStreamFrame('Incremental!');
    var LHalf := Length(LFrame) div 2;
    var LPart1: TBytes;
    var LPart2: TBytes;
    SetLength(LPart1, LHalf);
    Move(LFrame[0], LPart1[0], LHalf);
    SetLength(LPart2, Length(LFrame) - LHalf);
    Move(LFrame[LHalf], LPart2[0], Length(LFrame) - LHalf);

    LParser.ProcessBytes(LPart1);
    Assert.AreEqual('', LReceivedText); // Shouldn't fire callback yet since frame is incomplete

    LParser.ProcessBytes(LPart2);
    Assert.AreEqual('Incremental!', LReceivedText); // Fires after second half arrives
    Assert.AreEqual(1, LCallbackCount);
  finally
    LParser.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAProvidersEx);

end.
