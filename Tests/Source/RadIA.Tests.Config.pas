unit RadIA.Tests.Config;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces, RadIA.Core.Config, RadIA.Core.Types,
  RadIA.Core.SettingsStorage;

type
  [TestFixture]
  TTestRadIAConfig = class
  private
    FConfig: IRadIAConfig;
    FStorage: IRadIASettingsStorage;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestActiveProviderPersistence;
    [Test]
    procedure TestApiKeyEncryptionAndDecryption;
    [Test]
    procedure TestSpecificUserKeyEncryptionAndDecryption;
    [Test]
    procedure TestActiveModelPersistence;
    [Test]
    procedure TestSystemPromptPersistence;
    [Test]
    procedure TestConciseResponsesPersistence;
    [Test]
    procedure TestOllamaBaseUrlPersistence;
    [Test]
    procedure TestJsonNewlineHandling;
    [Test]
    procedure TestAdvancedSettingsPersistence;
    [Test]
    procedure TestProviderSpecificSettingsAreSavedUnderProviderKeys;
  end;

implementation

uses
  System.SysUtils, System.JSON;

{ TTestRadIAConfig }

procedure TTestRadIAConfig.Setup;
begin
  TRadIAConfig.SetBaseRegistryPath('Software\TestRadIAConfig');
  FStorage := TRadIAMemorySettingsStorage.Create;
  TRadIAConfig.SetStorage(FStorage);
  FConfig := TRadIAConfig.Create;
  FConfig.Load;
end;

procedure TTestRadIAConfig.TearDown;
begin
  FConfig := nil;
  FStorage := nil;
  TRadIAConfig.SetStorage(nil);
  TRadIAConfig.SetBaseRegistryPath('');
end;

procedure TTestRadIAConfig.TestActiveProviderPersistence;
begin
  FConfig.SetActiveProvider('Gemini');
  Assert.AreEqual('Gemini', FConfig.GetActiveProvider);
  
  FConfig.SetActiveProvider('Claude');
  Assert.AreEqual('Claude', FConfig.GetActiveProvider);
end;

procedure TTestRadIAConfig.TestApiKeyEncryptionAndDecryption;
const
  TEST_KEY = 'test-api-key-12345-gemini';
var
  LStoredValue: string;
begin
  FConfig.SetApiKey('Gemini', TEST_KEY);
  FConfig.Save;
  
  FConfig.Load;
  Assert.AreEqual(TEST_KEY, FConfig.GetApiKey('Gemini'));

  Assert.IsTrue(FStorage.OpenKey('Software\TestRadIAConfig\Gemini', False));
  try
    Assert.IsTrue(FStorage.ValueExists('ApiKey'));
    LStoredValue := FStorage.ReadString('ApiKey', '');
    Assert.AreNotEqual(TEST_KEY, LStoredValue, 'API Key should be encrypted in settings storage.');
  finally
    FStorage.CloseKey;
  end;
end;

procedure TTestRadIAConfig.TestSpecificUserKeyEncryptionAndDecryption;
const
  TEST_KEY = 'AQ.A_TEST_KEY_THAT_HAS_EXACTLY_53_CHARS_LONG_FOR_TESTS';
begin
  FConfig.SetApiKey('Gemini', TEST_KEY);
  FConfig.Save;
  
  FConfig.Load;
  Assert.AreEqual(TEST_KEY, FConfig.GetApiKey('Gemini'));
end;

procedure TTestRadIAConfig.TestActiveModelPersistence;
const
  TEST_MODEL = 'gemini-1.5-pro';
begin
  FConfig.SetActiveModel('Gemini', TEST_MODEL);
  FConfig.Save;
  
  FConfig.Load;
  Assert.AreEqual(TEST_MODEL, FConfig.GetActiveModel('Gemini'));
end;

procedure TTestRadIAConfig.TestSystemPromptPersistence;
const
  TEST_PROMPT = 'You are a Delphi Senior Software Architect. Output only Pascal code.';
begin
  FConfig.SystemPrompt := TEST_PROMPT;
  FConfig.Save;
  
  FConfig.Load;
  Assert.AreEqual(TEST_PROMPT, FConfig.SystemPrompt);
end;

procedure TTestRadIAConfig.TestConciseResponsesPersistence;
begin
  Assert.IsTrue(FConfig.ConciseResponses);

  FConfig.ConciseResponses := False;
  FConfig.Save;

  FConfig.Load;
  Assert.IsFalse(FConfig.ConciseResponses);
end;

procedure TTestRadIAConfig.TestOllamaBaseUrlPersistence;
const
  TEST_URL = 'http://192.168.1.50:11434';
begin
  FConfig.OllamaBaseUrl := TEST_URL;
  FConfig.Save;
  
  FConfig.Load;
  Assert.AreEqual(TEST_URL, FConfig.OllamaBaseUrl);
end;

procedure TTestRadIAConfig.TestJsonNewlineHandling;
var
  LJsonStr: string;
  LParsed: TJSONValue;
  LJson: TJSONObject;
  LCode: string;
begin
  LJsonStr := '{"action":"apply_code","code":"line1\nline2"}';
  LParsed := TJSONObject.ParseJSONValue(LJsonStr);
  try
    Assert.IsNotNull(LParsed);
    Assert.IsTrue(LParsed is TJSONObject);
    LJson := LParsed as TJSONObject;
    LCode := LJson.GetValue<string>('code', '');
    
    Assert.AreEqual(11, LCode.Length);
    Assert.AreEqual(Char(#10), LCode[6]);
  finally
    LParsed.Free;
  end;
end;

procedure TTestRadIAConfig.TestAdvancedSettingsPersistence;
begin
  FConfig.SetTemperature('Gemini', 0.4);
  FConfig.SetMaxTokens('Gemini', 1024);
  FConfig.SetTimeout('Gemini', 30);
  FConfig.SmartConfigEnabled := False;
  FConfig.Save;

  FConfig.Load;
  Assert.AreEqual(0.4, FConfig.GetTemperature('Gemini'), 0.01);
  Assert.AreEqual(1024, FConfig.GetMaxTokens('Gemini'));
  Assert.AreEqual(30, FConfig.GetTimeout('Gemini'));
  Assert.IsFalse(FConfig.SmartConfigEnabled);
end;

procedure TTestRadIAConfig.TestProviderSpecificSettingsAreSavedUnderProviderKeys;
const
  TEST_ROOT = 'Software\TestRadIAProviderSpecificSettings';
  TEST_OPENAI_URL = 'https://openai.test/v1';
  TEST_OLLAMA_URL = 'http://localhost:11434';
  TEST_AZURE_VERSION = '2024-02-15-preview';
  TEST_AWS_ACCESS_KEY = 'aws-access-key';
  TEST_AWS_SECRET_KEY = 'aws-secret-key';
  TEST_AWS_REGION = 'us-west-2';
  TEST_AWS_SESSION_TOKEN = 'aws-session-token';
  LEGACY_VALUE = 'legacy-value';
var
  LStorage: IRadIASettingsStorage;
  LConfig: IRadIAConfig;
begin
  LStorage := TRadIAMemorySettingsStorage.Create;
  TRadIAConfig.SetBaseRegistryPath(TEST_ROOT);
  TRadIAConfig.SetStorage(LStorage);
  try
    Assert.IsTrue(LStorage.OpenKey(TEST_ROOT, True));
    try
      LStorage.WriteString('OpenAICustomBaseUrl', LEGACY_VALUE);
      LStorage.WriteString('OllamaBaseUrl', LEGACY_VALUE);
      LStorage.WriteString('AzureApiVersion', LEGACY_VALUE);
      LStorage.WriteString('AwsAccessKeyId', LEGACY_VALUE);
      LStorage.WriteString('AwsSecretAccessKey', LEGACY_VALUE);
      LStorage.WriteString('AwsRegion', LEGACY_VALUE);
      LStorage.WriteString('AwsSessionToken', LEGACY_VALUE);
    finally
      LStorage.CloseKey;
    end;

    LConfig := TRadIAConfig.Create;
    LConfig.OpenAICustomBaseUrl := TEST_OPENAI_URL;
    LConfig.OllamaBaseUrl := TEST_OLLAMA_URL;
    LConfig.AzureApiVersion := TEST_AZURE_VERSION;
    LConfig.AwsAccessKeyId := TEST_AWS_ACCESS_KEY;
    LConfig.AwsSecretAccessKey := TEST_AWS_SECRET_KEY;
    LConfig.AwsRegion := TEST_AWS_REGION;
    LConfig.AwsSessionToken := TEST_AWS_SESSION_TOKEN;
    LConfig.Save;

    Assert.IsTrue(LStorage.OpenKey(TEST_ROOT, False));
    try
      Assert.AreEqual(LEGACY_VALUE, LStorage.ReadString('OpenAICustomBaseUrl', ''));
      Assert.AreEqual(LEGACY_VALUE, LStorage.ReadString('OllamaBaseUrl', ''));
      Assert.AreEqual(LEGACY_VALUE, LStorage.ReadString('AzureApiVersion', ''));
      Assert.AreEqual(LEGACY_VALUE, LStorage.ReadString('AwsAccessKeyId', ''));
      Assert.AreEqual(LEGACY_VALUE, LStorage.ReadString('AwsSecretAccessKey', ''));
      Assert.AreEqual(LEGACY_VALUE, LStorage.ReadString('AwsRegion', ''));
      Assert.AreEqual(LEGACY_VALUE, LStorage.ReadString('AwsSessionToken', ''));
    finally
      LStorage.CloseKey;
    end;

    Assert.IsTrue(LStorage.OpenKey(TEST_ROOT + '\OpenAI', False));
    try
      Assert.AreEqual(TEST_OPENAI_URL, LStorage.ReadString('BaseURL', ''));
    finally
      LStorage.CloseKey;
    end;

    Assert.IsTrue(LStorage.OpenKey(TEST_ROOT + '\Ollama', False));
    try
      Assert.AreEqual(TEST_OLLAMA_URL, LStorage.ReadString('BaseURL', ''));
    finally
      LStorage.CloseKey;
    end;

    Assert.IsTrue(LStorage.OpenKey(TEST_ROOT + '\AzureOpenAI', False));
    try
      Assert.AreEqual(TEST_AZURE_VERSION, LStorage.ReadString('ApiVersion', ''));
    finally
      LStorage.CloseKey;
    end;

    Assert.IsTrue(LStorage.OpenKey(TEST_ROOT + '\Bedrock', False));
    try
      Assert.AreEqual(TEST_AWS_REGION, LStorage.ReadString('Region', ''));
      Assert.IsTrue(LStorage.ValueExists('AccessKeyId'));
      Assert.IsTrue(LStorage.ValueExists('SecretAccessKey'));
      Assert.IsTrue(LStorage.ValueExists('SessionToken'));
    finally
      LStorage.CloseKey;
    end;

    LConfig.Load;
    Assert.AreEqual(TEST_OPENAI_URL, LConfig.OpenAICustomBaseUrl);
    Assert.AreEqual(TEST_OLLAMA_URL, LConfig.OllamaBaseUrl);
    Assert.AreEqual(TEST_AZURE_VERSION, LConfig.AzureApiVersion);
    Assert.AreEqual(TEST_AWS_ACCESS_KEY, LConfig.AwsAccessKeyId);
    Assert.AreEqual(TEST_AWS_SECRET_KEY, LConfig.AwsSecretAccessKey);
    Assert.AreEqual(TEST_AWS_REGION, LConfig.AwsRegion);
    Assert.AreEqual(TEST_AWS_SESSION_TOKEN, LConfig.AwsSessionToken);
  finally
    LConfig := nil;
    TRadIAConfig.SetStorage(nil);
    TRadIAConfig.SetBaseRegistryPath('');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAConfig);

end.
