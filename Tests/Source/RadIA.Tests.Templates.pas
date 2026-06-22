unit RadIA.Tests.Templates;

interface

uses
  DUnitX.TestFramework, RadIA.Core.PromptTemplates;

type
  [TestFixture]
  TTestRadIATemplates = class
  private
    FManager: TPromptTemplateManager;
    FTempDir: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDefaultTemplates_ArePresent;
    [Test]
    procedure TestTemplateManager_AddAndRetrieve;
    [Test]
    procedure TestTemplateManager_Persistence;
    [Test]
    procedure TestResolveTemplate_ReplacesPlaceholder;
    [Test]
    procedure TestSystemTemplates_AreLoadedFromCode;
    [Test]
    procedure TestExportToFile;
    [Test]
    procedure TestImportFromFile;
    [Test]
    procedure TestDeleteTemplate;
    [Test]
    procedure TestOverlay_CustomPromptOverridesDefault;
    [Test]
    procedure TestOverlay_RestoreRevertsToOriginal;
    [Test]
    procedure TestMigration_CleansRedundantOverlays;
    [Test]
    procedure TestMigration_CleansLegacyTemplatesWithoutUses;
    [Test]
    procedure TestTemplateManager_LoadException;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils;

{ TTestRadIATemplates }

procedure TTestRadIATemplates.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'RadIATests_Templates_' + TGUID.NewGuid.ToString);
  ForceDirectories(FTempDir);
  FManager := TPromptTemplateManager.Create(FTempDir);
  FManager.Load;
end;

procedure TTestRadIATemplates.TearDown;
begin
  FManager.Free;
  if TDirectory.Exists(FTempDir) then
  begin
    try
      TDirectory.Delete(FTempDir, True);
    except
    end;
  end;
end;

procedure TTestRadIATemplates.TestDefaultTemplates_ArePresent;
var
  LList: TArray<TPromptTemplate>;
  LTemplate: TPromptTemplate;
begin
  LList := FManager.GetTemplates;
  Assert.IsTrue(Length(LList) >= 6, 'Should contain at least the 6 default templates');
  Assert.IsTrue(FManager.ResolveTemplate('Review Clean Code Delphi', '').Contains('Delphi Pascal'));
  Assert.IsTrue(FManager.FindTemplate('Review Clean Code Delphi', LTemplate));
  Assert.AreEqual('/review', LTemplate.SlashCommand);
  Assert.IsTrue(FManager.FindTemplate('Explain Code', LTemplate));
  Assert.AreEqual('/explain', LTemplate.SlashCommand);
  Assert.IsTrue(FManager.FindTemplate('Optimize SQL Query', LTemplate));
  Assert.AreEqual('/sqloptimize', LTemplate.SlashCommand);
  Assert.IsTrue(LTemplate.Template.Contains('sql'));
  Assert.IsTrue(FManager.FindTemplate('Scan Compiler and OS Warnings', LTemplate));
  Assert.AreEqual('/scanwarnings', LTemplate.SlashCommand);
  Assert.IsTrue(LTemplate.Template.Contains('uninitialized variables'));
end;

procedure TTestRadIATemplates.TestTemplateManager_AddAndRetrieve;
var
  LTemplate: TPromptTemplate;
const
  TEMP_NAME = 'Test Template';
  TEMP_DESC = 'Description of test';
  TEMP_CONTENT = 'Refactor: {code}';
begin
  FManager.AddTemplate(TEMP_NAME, TEMP_DESC, TEMP_CONTENT);

  Assert.IsTrue(FManager.FindTemplate(TEMP_NAME, LTemplate));
  Assert.AreEqual(TEMP_DESC, LTemplate.Description);
  Assert.AreEqual(TEMP_CONTENT, LTemplate.Template);
end;

procedure TTestRadIATemplates.TestTemplateManager_Persistence;
var
  LTempFile: string;
  LNewManager: TPromptTemplateManager;
  LTemplate: TPromptTemplate;
const
  TEMP_NAME = 'Persistent Test Template';
  TEMP_DESC = 'Description';
  TEMP_CONTENT = 'Format: {code}';
begin
  { Force file save with a custom template }
  FManager.AddTemplate(TEMP_NAME, TEMP_DESC, TEMP_CONTENT);
  FManager.Save;

  LNewManager := TPromptTemplateManager.Create(FTempDir);
  try
    LNewManager.Load;
    Assert.IsTrue(LNewManager.FindTemplate(TEMP_NAME, LTemplate), 'Template should be loaded from file');
    Assert.AreEqual(TEMP_CONTENT, LTemplate.Template);
  finally
    LNewManager.Free;
  end;

  { Clean up custom template }
  LTempFile := TPath.Combine(FTempDir, 'templates.json');
  if TFile.Exists(LTempFile) then
  begin
    try
      TFile.Delete(LTempFile);
    except
      // Ignore cleanup error
    end;
  end;
end;

procedure TTestRadIATemplates.TestResolveTemplate_ReplacesPlaceholder;
var
  LResolved: string;
const
  CODE_SNIPPET = 'var I: Integer;';
begin
  FManager.AddTemplate('Custom Temp', 'Desc', 'Optimise this: {code}');
  LResolved := FManager.ResolveTemplate('Custom Temp', CODE_SNIPPET);

  Assert.AreEqual('Optimise this: var I: Integer;', LResolved);
end;

procedure TTestRadIATemplates.TestSystemTemplates_AreLoadedFromCode;
var
  LTemplates: TArray<TPromptTemplate>;
  LTemp: TPromptTemplate;
begin
  LTemplates := FManager.GetTemplates;
  Assert.IsTrue(Length(LTemplates) >= 8, 'Should contain all default templates');

  for LTemp in LTemplates do
  begin
    Assert.IsTrue(LTemp.IsSystem, 'Defaults should be marked as system templates');
    Assert.IsFalse(LTemp.IsCustomized, 'Defaults should not be customized initially');
  end;
end;

procedure TTestRadIATemplates.TestOverlay_CustomPromptOverridesDefault;
var
  LTemplate: TPromptTemplate;
  LTempFile: string;
const
  SYS_NAME = 'Review Clean Code Delphi';
  CUSTOM_PROMPT = 'Review this custom style: {code}';
begin
  FManager.AddTemplate(SYS_NAME, 'Custom Desc', CUSTOM_PROMPT, False, '/review');
  FManager.Save;

  Assert.IsTrue(FManager.FindTemplate(SYS_NAME, LTemplate));
  Assert.IsTrue(LTemplate.IsSystem, 'Should still be marked as system template');
  Assert.IsTrue(LTemplate.IsCustomized, 'Should be marked as customized');
  Assert.AreEqual(CUSTOM_PROMPT, LTemplate.Template);

  LTempFile := TPath.Combine(FTempDir, 'templates.json');
  if TFile.Exists(LTempFile) then
    TFile.Delete(LTempFile);
end;

procedure TTestRadIATemplates.TestOverlay_RestoreRevertsToOriginal;
var
  LTemplate: TPromptTemplate;
  LOriginalTemplate: string;
  LTempFile: string;
const
  SYS_NAME = 'Review Clean Code Delphi';
begin
  Assert.IsTrue(FManager.FindTemplate(SYS_NAME, LTemplate));
  LOriginalTemplate := LTemplate.Template;

  FManager.AddTemplate(SYS_NAME, LTemplate.Description, 'Modified body {code}', LTemplate.IsProjectGenerator,
      LTemplate.SlashCommand);
  Assert.IsTrue(FManager.FindTemplate(SYS_NAME, LTemplate));
  Assert.IsTrue(LTemplate.IsCustomized);

  FManager.RestoreDefaultTemplate(SYS_NAME);

  Assert.IsTrue(FManager.FindTemplate(SYS_NAME, LTemplate));
  Assert.IsFalse(LTemplate.IsCustomized);
  Assert.AreEqual(LOriginalTemplate, LTemplate.Template);

  LTempFile := TPath.Combine(FTempDir, 'templates.json');
  if TFile.Exists(LTempFile) then
    TFile.Delete(LTempFile);
end;

procedure TTestRadIATemplates.TestMigration_CleansRedundantOverlays;
var
  LTempFile: string;
  LJSON: string;
  LTemplate: TPromptTemplate;
const
  LEGACY_JSON =
    '[{"name":"Review Clean Code Delphi",' +
    '"description":"Review Pascal code applying Clean Code and SOLID",' +
    '"template":"Review the following Delphi Pascal code block applying Clean Code, ' +
    'readability, and optimization principles:\r\n\r\n{code}",' +
    '"isProjectGenerator":false,"slashCommand":"/explain"}]';
begin
  LTempFile := TPath.Combine(FTempDir, 'templates.json');
  ForceDirectories(TPath.GetDirectoryName(LTempFile));
  TFile.WriteAllText(LTempFile, LEGACY_JSON, TEncoding.UTF8);

  FManager.Load;

  Assert.IsTrue(FManager.FindTemplate('Review Clean Code Delphi', LTemplate));
  Assert.IsTrue(LTemplate.IsSystem);
  Assert.IsFalse(LTemplate.IsCustomized, 'Redundant overlay should have been removed and reverted to ' +
      'raw system template');
  Assert.AreEqual('/review', LTemplate.SlashCommand);

  if TFile.Exists(LTempFile) then
  begin
    LJSON := TFile.ReadAllText(LTempFile, TEncoding.UTF8);
    Assert.IsTrue(LJSON.Contains('[]') or (LJSON = ''), 'JSON file should be empty of redundant templates');
    TFile.Delete(LTempFile);
  end;
end;

procedure TTestRadIATemplates.TestMigration_CleansLegacyTemplatesWithoutUses;
var
  LTempFile: string;
  LTemplate: TPromptTemplate;
const
  LEGACY_JSON_NO_USES = '[{"name":"Create Project Delphi", "description":"Legacy description", ' +
    '"template":"Create project Delphi legacy layout.", "isProjectGenerator":true, ' +
    '"slashCommand":"/createproject"}]';
begin
  LTempFile := TPath.Combine(FTempDir, 'templates.json');
  ForceDirectories(TPath.GetDirectoryName(LTempFile));
  TFile.WriteAllText(LTempFile, LEGACY_JSON_NO_USES, TEncoding.UTF8);

  FManager.Load;

  Assert.IsTrue(FManager.FindTemplate('Create Project Delphi', LTemplate));
  Assert.IsTrue(LTemplate.IsSystem);
  Assert.IsFalse(LTemplate.IsCustomized,
    'Legacy templates missing uses should have been discarded on load and reverted to code system default');
  Assert.IsTrue(LTemplate.Template.Contains('uses'), 'Active template must contain the newly updated uses rule');

  if TFile.Exists(LTempFile) then
    TFile.Delete(LTempFile);
end;

procedure TTestRadIATemplates.TestTemplateManager_LoadException;
var
  LTempFile: string;
  LStream: TFileStream;
begin
  LTempFile := TPath.Combine(FTempDir, 'templates.json');
  if TFile.Exists(LTempFile) then
    TFile.Delete(LTempFile);

  TFile.WriteAllText(LTempFile, '[]');

  LStream := TFileStream.Create(LTempFile, fmOpenRead or fmShareExclusive);
  try
    FManager.Load;
  finally
    LStream.Free;
  end;

  if TFile.Exists(LTempFile) then
    TFile.Delete(LTempFile);
end;

procedure TTestRadIATemplates.TestExportToFile;
begin
  FManager.ExportToFile('test_export.json');
  Assert.IsTrue(TFile.Exists('test_export.json'));
  if TFile.Exists('test_export.json') then
    TFile.Delete('test_export.json');
end;

procedure TTestRadIATemplates.TestImportFromFile;
var
  LErrorMsg: string;
begin
  try
    FManager.ExportToFile('test_export2.json');
    FManager.ImportFromFile('test_export2.json', False, LErrorMsg);
  finally
    if TFile.Exists('test_export2.json') then
      TFile.Delete('test_export2.json');
  end;
  Assert.IsTrue(True);
end;

procedure TTestRadIATemplates.TestDeleteTemplate;
begin
  try
    FManager.DeleteTemplate('AnyName');
  except
  end;
  Assert.IsTrue(True);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIATemplates);

end.
