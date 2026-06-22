unit RadIA.Tests.ProjectContext;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestRadIAProjectContext = class
  private
    FTempFolder: string;

    procedure CreateFile(const AFileName, AContent: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestParseRadiaFile_ValidJSON;
    [Test]
    procedure TestParseRadiaFile_InvalidJSON_UsesDefaults;
    [Test]
    procedure TestContextLoader_MergesWithSystemPrompt;
    [Test]
    procedure TestContextLoader_FileNotFound_NoError;
    [Test]
    procedure TestContextLoader_TruncatesLargeFile;
    [Test]
    procedure TestContextLoader_Exceptions;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, RadIA.Core.ProjectContext;

{ TTestRadIAProjectContext }

procedure TTestRadIAProjectContext.Setup;
begin
  FTempFolder := TPath.Combine(TPath.GetTempPath, 'RadIATestProject_' + TGUID.NewGuid.ToString.Replace('{',
      '').Replace('}',''));
  ForceDirectories(FTempFolder);
end;

procedure TTestRadIAProjectContext.TearDown;
begin
  if TDirectory.Exists(FTempFolder) then
  begin
    try
      TDirectory.Delete(FTempFolder, True);
    except
      // Ignore cleanup errors
    end;
  end;
end;

procedure TTestRadIAProjectContext.CreateFile(const AFileName, AContent: string);
var
  LFullPath: string;
begin
  LFullPath := TPath.Combine(FTempFolder, AFileName);
  ForceDirectories(TPath.GetDirectoryName(LFullPath));
  TFile.WriteAllText(LFullPath, AContent, TEncoding.UTF8);
end;

procedure TTestRadIAProjectContext.TestParseRadiaFile_ValidJSON;
var
  LContextPrompt: string;
  LSuccess: Boolean;
const
  RADIA_JSON =
    '{' +
    '  "system_prompt": "Prompt do sistema especÃƒÂ­fico do projeto.",' +
    '  "context_files": [' +
    '    "docs/architecture.md"' +
    '  ]' +
    '}';
  ARCH_MD = 'Esta unit usa padrÃƒÂ£o Singleton.';
begin
  CreateFile('.radia', RADIA_JSON);
  CreateFile('docs/architecture.md', ARCH_MD);

  LSuccess := TProjectContextLoader.LoadContext(FTempFolder, LContextPrompt);

  Assert.IsTrue(LSuccess, 'Should parse valid JSON successfully');
  Assert.IsTrue(LContextPrompt.Contains('[Contexto do Projeto (.radia)]'));
  Assert.IsTrue(LContextPrompt.Contains('Prompt do sistema especÃƒÂ­fico do projeto.'));
  Assert.IsTrue(LContextPrompt.Contains('[Arquivo: docs/architecture.md]'));
  Assert.IsTrue(LContextPrompt.Contains('Esta unit usa padrÃƒÂ£o Singleton.'));
end;

procedure TTestRadIAProjectContext.TestParseRadiaFile_InvalidJSON_UsesDefaults;
var
  LContextPrompt: string;
  LSuccess: Boolean;
const
  RADIA_CORRUPT_JSON = '{ "system_prompt": "invalid json because of missing brackets';
begin
  CreateFile('.radia', RADIA_CORRUPT_JSON);

  LSuccess := TProjectContextLoader.LoadContext(FTempFolder, LContextPrompt);

  Assert.IsFalse(LSuccess, 'Should fail to parse invalid JSON');
  Assert.IsEmpty(LContextPrompt, 'Context prompt should be empty on failure');
end;

procedure TTestRadIAProjectContext.TestContextLoader_MergesWithSystemPrompt;
var
  LContextPrompt: string;
  LSuccess: Boolean;
const
  RADIA_JSON =
    '{' +
    '  "system_prompt": "Projeto A."' +
    '}';
begin
  CreateFile('.radia', RADIA_JSON);
  LSuccess := TProjectContextLoader.LoadContext(FTempFolder, LContextPrompt);

  Assert.IsTrue(LSuccess);
  Assert.IsTrue(LContextPrompt.Contains('Projeto A.'));
end;

procedure TTestRadIAProjectContext.TestContextLoader_FileNotFound_NoError;
var
  LContextPrompt: string;
  LSuccess: Boolean;
begin
  { Load from folder without .radia file }
  LSuccess := TProjectContextLoader.LoadContext(FTempFolder, LContextPrompt);

  Assert.IsFalse(LSuccess, 'Should return False if .radia file does not exist');
  Assert.IsEmpty(LContextPrompt, 'Prompt should be empty');
end;

procedure TTestRadIAProjectContext.TestContextLoader_TruncatesLargeFile;
var
  LContextPrompt: string;
  LSuccess: Boolean;
  LLargeContent: string;
  I: Integer;
const
  RADIA_JSON =
    '{' +
    '  "system_prompt": "Projeto A.",' +
    '  "context_files": [' +
    '    "large_file.txt"' +
    '  ]' +
    '}';
begin
  LLargeContent := '';
  for I := 1 to 51198 do
    LLargeContent := LLargeContent + 'a';
  LLargeContent := LLargeContent + 'ðŸš€'; // ðŸš€ occupies 4 bytes in UTF-8

  CreateFile('.radia', RADIA_JSON);
  CreateFile('large_file.txt', LLargeContent);

  LSuccess := TProjectContextLoader.LoadContext(FTempFolder, LContextPrompt);

  Assert.IsTrue(LSuccess);
  Assert.IsTrue(LContextPrompt.Contains('Projeto A.'));
  Assert.IsTrue(LContextPrompt.Contains('[Arquivo: large_file.txt]'));
  Assert.IsTrue(LContextPrompt.Contains('[Aviso: Conteudo do arquivo "large_file.txt" foi truncado pois ' +
      'excede o limite de 50KB]'));
  Assert.IsTrue(LContextPrompt.Length < 60000, 'Context prompt should be significantly shorter than full large file');
end;

procedure TTestRadIAProjectContext.TestContextLoader_Exceptions;
var
  LContextPrompt: string;
  LSuccess: Boolean;
  LStream: TFileStream;
  LRadiaFile: string;
  LContextFile: string;
const
  RADIA_JSON =
    '{' +
    '  "system_prompt": "Projeto A.",' +
    '  "context_files": [' +
    '    "locked_file.txt"' +
    '  ]' +
    '}';
begin
  // Caso 1: ForÃ§ar exceÃ§Ã£o no LoadContext externo (pasta em vez de arquivo)
  LRadiaFile := TPath.Combine(FTempFolder, '.radia');
  ForceDirectories(LRadiaFile);

  LSuccess := TProjectContextLoader.LoadContext(FTempFolder, LContextPrompt);
  Assert.IsFalse(LSuccess, 'Should fail to load context when .radia is a folder');

  TDirectory.Delete(LRadiaFile);

  // Caso 2: ForÃ§ar exceÃ§Ã£o ao ler arquivo especÃ­fico listado em context_files
  CreateFile('.radia', RADIA_JSON);
  CreateFile('locked_file.txt', 'Algum conteudo.');

  LContextFile := TPath.Combine(FTempFolder, 'locked_file.txt');
  LStream := TFileStream.Create(LContextFile, fmOpenWrite or fmShareExclusive);
  try
    LSuccess := TProjectContextLoader.LoadContext(FTempFolder, LContextPrompt);
    Assert.IsTrue(LSuccess, 'Should still succeed in loading other context elements');
  finally
    LStream.Free;
  end;

  // Caso 3: ForÃ§ar exceÃ§Ã£o na leitura do prÃ³prio arquivo .radia (bloqueado exclusivamente)
  CreateFile('.radia', RADIA_JSON);
  LStream := TFileStream.Create(LRadiaFile, fmOpenWrite or fmShareExclusive);
  try
    LSuccess := TProjectContextLoader.LoadContext(FTempFolder, LContextPrompt);
    Assert.IsFalse(LSuccess, 'Should fail to load context when .radia file is exclusively locked');
  finally
    LStream.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAProjectContext);

end.
