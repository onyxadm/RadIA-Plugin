unit RadIA.Tests.Ollama;

interface

uses
  DUnitX.TestFramework, System.Rtti, RadIA.Core.Interfaces, RadIA.Core.Config, RadIA.Core.Types, 
  RadIA.Core.TokenUsage, RadIA.Core.Service, RadIA.Provider.Ollama;

type
  [TestFixture]
  TTestRadIAOllama = class
  private
    FConfig: IAIConfig;
    FProvider: TRadIAOllamaProvider;
    
    function CallPrivateMethod(const AMethodName: string; const AArgs: array of TValue): TValue;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestRequestBodyFormatting;
    [Test]
    procedure TestResponseBodyParsing;
  end;

implementation

uses
  System.SysUtils, System.JSON;

function TTestRadIAOllama.CallPrivateMethod(const AMethodName: string; const AArgs: array of TValue): TValue;
var
  LContext: TRttiContext;
  LType: TRttiType;
  LMethod: TRttiMethod;
begin
  LContext := TRttiContext.Create;
  LType := LContext.GetType(TRadIAOllamaProvider);
  LMethod := LType.GetMethod(AMethodName);
  if LMethod = nil then
    raise Exception.CreateFmt('Method %s not found via RTTI', [AMethodName]);
  Result := LMethod.Invoke(FProvider, AArgs);
end;

procedure TTestRadIAOllama.Setup;
begin
  FConfig := TRadIAConfig.Create;
  FProvider := TRadIAOllamaProvider.Create(FConfig);
end;

procedure TTestRadIAOllama.TearDown;
begin
  FProvider.Free;
  FConfig := nil;
end;

procedure TTestRadIAOllama.TestRequestBodyFormatting;
var
  LPrompt: string;
  LHistory: TArray<IChatMessage>;
  LResultJson: string;
  LJsonObj: TJSONObject;
  LMessages: TJSONArray;
  LMsgObj: TJSONObject;
begin
  LPrompt := 'This is a test prompt';
  LHistory := TArray<IChatMessage>.Create(
    TRadIAService.CreateMessage(mrUser, 'Hello'),
    TRadIAService.CreateMessage(mrAssistant, 'Hi there')
  );
  
  FConfig.SetActiveModel('Ollama', 'llama3:latest');
  
  { Invoke private method BuildRequestBody via RTTI }
  LResultJson := CallPrivateMethod('BuildRequestBody', [LPrompt, TValue.From<TArray<IChatMessage>>(LHistory), False, 0.7, 2048]).AsString;
  
  Assert.IsFalse(LResultJson.IsEmpty, 'JSON Request body should not be empty');
  
  LJsonObj := TJSONObject.ParseJSONValue(LResultJson) as TJSONObject;
  try
    Assert.IsNotNull(LJsonObj, 'Result should be a valid JSON Object');
    Assert.AreEqual('llama3:latest', LJsonObj.GetValue('model').Value);
    Assert.AreEqual('false', LJsonObj.GetValue('stream').ToString.ToLower);
    
    LMessages := LJsonObj.GetValue('messages') as TJSONArray;
    Assert.IsNotNull(LMessages, 'Messages array should be present');
    Assert.AreEqual(3, LMessages.Count, 'Should contain 2 history messages + 1 current prompt');
    
    LMsgObj := LMessages.Items[0] as TJSONObject;
    Assert.AreEqual('user', LMsgObj.GetValue('role').Value);
    Assert.AreEqual('Hello', LMsgObj.GetValue('content').Value);
    
    LMsgObj := LMessages.Items[1] as TJSONObject;
    Assert.AreEqual('assistant', LMsgObj.GetValue('role').Value);
    Assert.AreEqual('Hi there', LMsgObj.GetValue('content').Value);
    
    LMsgObj := LMessages.Items[2] as TJSONObject;
    Assert.AreEqual('user', LMsgObj.GetValue('role').Value);
    Assert.AreEqual('This is a test prompt', LMsgObj.GetValue('content').Value);
  finally
    LJsonObj.Free;
  end;
end;

procedure TTestRadIAOllama.TestResponseBodyParsing;
var
  LResponseJson: string;
  LParsedText: string;
  LArgs: TArray<TValue>;
  LUsage: TTokenUsage;
begin
  LResponseJson := 
    '{"model":"llama3:latest","created_at":"2026-06-02T21:00:00Z",' +
    '"message":{"role":"assistant","content":"This is the AI response content"},' +
    '"prompt_eval_count":15,"eval_count":25,"done":true}';
    
  SetLength(LArgs, 2);
  LArgs[0] := LResponseJson;
  LArgs[1] := TValue.From<TTokenUsage>(TTokenUsage.Empty);
  
  LParsedText := CallPrivateMethod('ParseResponseBody', LArgs).AsString;
  LUsage := LArgs[1].AsType<TTokenUsage>;
  
  Assert.AreEqual('This is the AI response content', LParsedText);
  Assert.AreEqual(15, LUsage.PromptTokens);
  Assert.AreEqual(25, LUsage.CompletionTokens);
  Assert.AreEqual(40, LUsage.TotalTokens);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAOllama);

end.
