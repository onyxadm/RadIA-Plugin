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
  end;

implementation

uses
  System.SysUtils, Registry, Winapi.Windows;

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
begin
  FConfig.SetApiKey(ptGemini, TEST_KEY);
  FConfig.Save;
  
  FConfig.Load;
  Assert.AreEqual(TEST_KEY, FConfig.GetApiKey(ptGemini));
  
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    if LReg.OpenKeyReadOnly('Software\RadIA') then
    begin
      if LReg.ValueExists('ApiKey_Gemini') then
      begin
        LStoredValue := LReg.ReadString('ApiKey_Gemini');
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

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAConfig);

end.
