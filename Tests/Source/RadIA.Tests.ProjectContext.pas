unit RadIA.Tests.ProjectContext;

interface

uses
  DUnitX.TestFramework, RadIA.Core.ProjectContext;

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
  end;

implementation

uses
  System.SysUtils, System.IOUtils;

{ TTestRadIAProjectContext }

procedure TTestRadIAProjectContext.Setup;
begin
  FTempFolder := TPath.Combine(TPath.GetTempPath, 'RadIATestProject_' + TGUID.NewGuid.ToString.Replace('{','').Replace('}',''));
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
    '  "system_prompt": "Prompt do sistema específico do projeto.",' +
    '  "context_files": [' +
    '    "docs/architecture.md"' +
    '  ]' +
    '}';
  ARCH_MD = 'Esta unit usa padrão Singleton.';
begin
  CreateFile('.radia', RADIA_JSON);
  CreateFile('docs/architecture.md', ARCH_MD);
  
  LSuccess := TProjectContextLoader.LoadContext(FTempFolder, LContextPrompt);
  
  Assert.IsTrue(LSuccess, 'Should parse valid JSON successfully');
  Assert.IsTrue(LContextPrompt.Contains('[Contexto do Projeto (.radia)]'));
  Assert.IsTrue(LContextPrompt.Contains('Prompt do sistema específico do projeto.'));
  Assert.IsTrue(LContextPrompt.Contains('[Arquivo: docs/architecture.md]'));
  Assert.IsTrue(LContextPrompt.Contains('Esta unit usa padrão Singleton.'));
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
  for I := 1 to 6100 do
    LLargeContent := LLargeContent + '1234567890'; // 61000 characters (~61KB)

  CreateFile('.radia', RADIA_JSON);
  CreateFile('large_file.txt', LLargeContent);
  
  LSuccess := TProjectContextLoader.LoadContext(FTempFolder, LContextPrompt);
  
  Assert.IsTrue(LSuccess);
  Assert.IsTrue(LContextPrompt.Contains('Projeto A.'));
  Assert.IsTrue(LContextPrompt.Contains('[Arquivo: large_file.txt]'));
  Assert.IsTrue(LContextPrompt.Contains('[Aviso: Conteúdo do arquivo "large_file.txt" foi truncado pois excede o limite de 50KB]'));
  // Ensure it was truncated at 51200 bytes
  Assert.IsTrue(LContextPrompt.Length < 60000, 'Context prompt should be significantly shorter than full large file');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAProjectContext);

end.
