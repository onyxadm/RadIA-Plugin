unit RadIA.Tests.Config;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces, RadIA.Core.Config, RadIA.Core.Types;

type
  [TestFixture]
  TTestRadIAConfig = class
  private
    FConfig: IAIConfig;
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
    procedure TestOllamaBaseUrlPersistence;
    [Test]
    procedure TestJsonNewlineHandling;
    [Test]
    procedure TestAdvancedSettingsPersistence;
  end;

implementation

uses
  System.SysUtils, System.Win.Registry, Winapi.Windows, System.JSON;

{ TTestRadIAConfig }

procedure TTestRadIAConfig.Setup;
begin
  FConfig := TRadIAConfig.Create;
  FConfig.Load;
end;

procedure TTestRadIAConfig.TearDown;
begin
  FConfig := nil;
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
  LReg: TRegistry;
  LStoredValue: string;
  LSettings: TFormatSettings;
  LRegPath: string;
begin
  FConfig.SetApiKey(ptGemini, TEST_KEY);
  FConfig.Save;
  
  FConfig.Load;
  Assert.AreEqual(TEST_KEY, FConfig.GetApiKey(ptGemini));
  
  LSettings := TFormatSettings.Create('en-US');
  LRegPath := Format('Software\Embarcadero\BDS\%0.1f\RadIA', [CompilerVersion], LSettings);
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    if LReg.OpenKeyReadOnly(LRegPath) then
    begin
      if LReg.ValueExists('Gemini_ApiKey') then
      begin
        LStoredValue := LReg.ReadString('Gemini_ApiKey');
        Assert.AreNotEqual(TEST_KEY, LStoredValue, 'API Key should be encrypted in the registry!');
      end;
    end;
  finally
    LReg.Free;
  end;
end;

procedure TTestRadIAConfig.TestSpecificUserKeyEncryptionAndDecryption;
const
  TEST_KEY = 'AQ.A_TEST_KEY_THAT_HAS_EXACTLY_53_CHARS_LONG_FOR_TESTS';
begin
  FConfig.SetApiKey(ptGemini, TEST_KEY);
  FConfig.Save;
  
  FConfig.Load;
  Assert.AreEqual(TEST_KEY, FConfig.GetApiKey(ptGemini));
end;

procedure TTestRadIAConfig.TestActiveModelPersistence;
const
  TEST_MODEL = 'gemini-1.5-pro';
begin
  FConfig.SetActiveModel(ptGemini, TEST_MODEL);
  FConfig.Save;
  
  FConfig.Load;
  Assert.AreEqual(TEST_MODEL, FConfig.GetActiveModel(ptGemini));
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
  FConfig.SetTemperature(ptGemini, 0.4);
  FConfig.SetMaxTokens(ptGemini, 1024);
  FConfig.SetTimeout(ptGemini, 30);
  FConfig.SmartConfigEnabled := False;
  FConfig.Save;

  FConfig.Load;
  Assert.AreEqual(0.4, FConfig.GetTemperature(ptGemini), 0.01);
  Assert.AreEqual(1024, FConfig.GetMaxTokens(ptGemini));
  Assert.AreEqual(30, FConfig.GetTimeout(ptGemini));
  Assert.IsFalse(FConfig.SmartConfigEnabled);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAConfig);

end.
