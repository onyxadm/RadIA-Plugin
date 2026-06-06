unit RadIA.Tests.Templates;

interface

uses
  DUnitX.TestFramework, RadIA.Core.PromptTemplates;

type
  [TestFixture]
  TTestRadIATemplates = class
  private
    FManager: TPromptTemplateManager;
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
  end;

implementation

uses
  System.SysUtils, System.IOUtils;

{ TTestRadIATemplates }

procedure TTestRadIATemplates.Setup;
begin
  FManager := TPromptTemplateManager.Create;
  FManager.Load;
end;

procedure TTestRadIATemplates.TearDown;
begin
  FManager.Free;
end;

procedure TTestRadIATemplates.TestDefaultTemplates_ArePresent;
var
  LList: TArray<TPromptTemplate>;
begin
  LList := FManager.GetTemplates;
  Assert.IsTrue(Length(LList) >= 6, 'Should contain at least the 6 default templates');
  Assert.IsTrue(FManager.ResolveTemplate('Review Clean Code Delphi', '').Contains('Delphi Pascal'));
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

  LNewManager := TPromptTemplateManager.Create;
  try
    LNewManager.Load;
    Assert.IsTrue(LNewManager.FindTemplate(TEMP_NAME, LTemplate), 'Template should be loaded from file');
    Assert.AreEqual(TEMP_CONTENT, LTemplate.Template);
  finally
    LNewManager.Free;
  end;

  { Clean up custom template }
  LTempFile := TPath.Combine(TPath.GetHomePath, 'RadIA\templates.json');
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

initialization
  TDUnitX.RegisterTestFixture(TTestRadIATemplates);

end.
