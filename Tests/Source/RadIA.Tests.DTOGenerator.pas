unit RadIA.Tests.DTOGenerator;

interface

uses
  DUnitX.TestFramework, RadIA.Core.DTO.Generator;

type
  [TestFixture]
  TRadIADTOBuilderTests = class
  public
    [Test]
    procedure TestVanillaPrompt;
    [Test]
    procedure TestRecordPrompt;
    [Test]
    procedure TestRESTJsonPrompt;
    [Test]
    procedure TestAureliusPrompt;
    [Test]
    procedure TestDEXTORMPrompt;
  end;

implementation

uses
  System.SysUtils;

procedure TRadIADTOBuilderTests.TestVanillaPrompt;
var
  LPrompt: string;
begin
  LPrompt := TRadIADTOBuilder.BuildPrompt('{"id": 1}', 'json', 'vanilla');
  Assert.IsTrue(LPrompt.Contains('VANILLA'), 'Prompt must contain type information');
  Assert.IsTrue(LPrompt.Contains('constructor (Create)'), 'Prompt must contain vanilla rules');
end;

procedure TRadIADTOBuilderTests.TestRecordPrompt;
var
  LPrompt: string;
begin
  LPrompt := TRadIADTOBuilder.BuildPrompt('{"id": 1}', 'json', 'record');
  Assert.IsTrue(LPrompt.Contains('RECORD'), 'Prompt must contain type information');
  Assert.IsTrue(LPrompt.Contains('Do not use classes, only records'), 'Prompt must contain record rules');
end;

procedure TRadIADTOBuilderTests.TestRESTJsonPrompt;
var
  LPrompt: string;
begin
  LPrompt := TRadIADTOBuilder.BuildPrompt('{"id": 1}', 'json', 'restjson');
  Assert.IsTrue(LPrompt.Contains('RESTJSON'), 'Prompt must contain type information');
  Assert.IsTrue(LPrompt.Contains('[JSONName('), 'Prompt must contain JSONName attribute rule');
end;

procedure TRadIADTOBuilderTests.TestAureliusPrompt;
var
  LPrompt: string;
  LInput: string;
begin
  LInput := 'CREATE TABLE users (id INT, name VARCHAR(100))';
  LPrompt := TRadIADTOBuilder.BuildPrompt(LInput, 'ddl', 'aurelius');
  Assert.IsTrue(LPrompt.Contains('AURELIUS'), 'Prompt must contain type information');
  Assert.IsTrue(LPrompt.Contains('[Entity]'), 'Prompt must contain Entity rule');
end;

procedure TRadIADTOBuilderTests.TestDEXTORMPrompt;
var
  LPrompt: string;
begin
  LPrompt := TRadIADTOBuilder.BuildPrompt('{"id": 1}', 'json', 'dext');
  Assert.IsTrue(LPrompt.Contains('DEXT'), 'Prompt must contain type information');
  Assert.IsTrue(LPrompt.Contains('[Column'), 'Prompt must contain Column attribute rule');
end;

initialization
  TDUnitX.RegisterTestFixture(TRadIADTOBuilderTests);

end.
