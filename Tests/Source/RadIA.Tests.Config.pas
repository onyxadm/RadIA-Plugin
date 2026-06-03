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
    procedure TestActiveModelPersistence;
    [Test]
    procedure TestSystemPromptPersistence;
    [Test]
    procedure TestOllamaBaseUrlPersistence;
  end;

implementation

uses
  System.SysUtils, System.Win.Registry, Winapi.Windows;

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
  FConfig.SetActiveProvider(ptGemini);
  Assert.AreEqual(ptGemini, FConfig.GetActiveProvider);
  
  FConfig.SetActiveProvider(ptClaude);
  Assert.AreEqual(ptClaude, FConfig.GetActiveProvider);
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

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAConfig);

end.
