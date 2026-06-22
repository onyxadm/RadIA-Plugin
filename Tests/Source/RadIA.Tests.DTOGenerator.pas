unit RadIA.Tests.DTOGenerator;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces;

type
  [TestFixture]
  TRadIADTOBuilderTests = class
  private
    FBuilder: IRadIADTOBuilder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

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
  System.SysUtils, RadIA.Core.DTO.Generator;

procedure TRadIADTOBuilderTests.Setup;
begin
  FBuilder := TRadIADTOBuilder.Create;
end;

procedure TRadIADTOBuilderTests.TearDown;
begin
  FBuilder := nil;
end;

procedure TRadIADTOBuilderTests.TestVanillaPrompt;
var
  LPrompt: string;
begin
  LPrompt := FBuilder.BuildPrompt('{"id": 1}', 'json', 'vanilla');
  Assert.IsTrue(LPrompt.Contains('VANILLA'), 'Prompt must contain type information');
  Assert.IsTrue(LPrompt.Contains('constructor (Create)'), 'Prompt must contain vanilla rules');
end;

procedure TRadIADTOBuilderTests.TestRecordPrompt;
var
  LPrompt: string;
begin
  LPrompt := FBuilder.BuildPrompt('{"id": 1}', 'json', 'record');
  Assert.IsTrue(LPrompt.Contains('RECORD'), 'Prompt must contain type information');
  Assert.IsTrue(LPrompt.Contains('Do not use classes, only records'), 'Prompt must contain record rules');
end;

procedure TRadIADTOBuilderTests.TestRESTJsonPrompt;
var
  LPrompt: string;
begin
  LPrompt := FBuilder.BuildPrompt('{"id": 1}', 'json', 'restjson');
  Assert.IsTrue(LPrompt.Contains('RESTJSON'), 'Prompt must contain type information');
  Assert.IsTrue(LPrompt.Contains('[JSONName('), 'Prompt must contain JSONName attribute rule');
end;

procedure TRadIADTOBuilderTests.TestAureliusPrompt;
var
  LPrompt: string;
  LInput: string;
begin
  LInput := 'CREATE TABLE users (id INT, name VARCHAR(100))';
  LPrompt := FBuilder.BuildPrompt(LInput, 'ddl', 'aurelius');
  Assert.IsTrue(LPrompt.Contains('AURELIUS'), 'Prompt must contain type information');
  Assert.IsTrue(LPrompt.Contains('[Entity]'), 'Prompt must contain Entity rule');
end;

procedure TRadIADTOBuilderTests.TestDEXTORMPrompt;
var
  LPrompt: string;
begin
  LPrompt := FBuilder.BuildPrompt('{"id": 1}', 'json', 'dext');
  Assert.IsTrue(LPrompt.Contains('DEXT'), 'Prompt must contain type information');
  Assert.IsTrue(LPrompt.Contains('[Column'), 'Prompt must contain Column attribute rule');
end;

initialization
  TDUnitX.RegisterTestFixture(TRadIADTOBuilderTests);

end.
