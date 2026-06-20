unit RadIA.Tests.Analysis;

interface

uses
  DUnitX.TestFramework, RadIA.Core.PromptTemplates;

type
  [TestFixture]
  TTestRadIAAnalysis = class
  private
    FManager: TPromptTemplateManager;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestAnalysisTemplates_ArePresent;
    [Test]
    procedure TestResolveStackTraceTemplate;
    [Test]
    procedure TestResolveReviewTemplate;
  end;

  [TestFixture]
  TTestRadIAOTAHelper = class
  public
    [Test]
    procedure TestNormalizeLineBreaks_WindowsStyle;
    [Test]
    procedure TestNormalizeLineBreaks_MacStyle;
    [Test]
    procedure TestNormalizeLineBreaks_UnixStyle;
    [Test]
    procedure TestNormalizeLineBreaks_MixedStyle;
  end;

implementation

uses
  System.SysUtils, RadIA.OTA.Helper;

{ TTestRadIAAnalysis }

procedure TTestRadIAAnalysis.Setup;
begin
  FManager := TPromptTemplateManager.Create;
  FManager.Load;
end;

procedure TTestRadIAAnalysis.TearDown;
begin
  FManager.Free;
end;

procedure TTestRadIAAnalysis.TestAnalysisTemplates_ArePresent;
var
  LTemplate: TPromptTemplate;
begin
  Assert.IsTrue(FManager.FindTemplate('Analyze Stack Trace', LTemplate), 'Analyze Stack Trace template must be present');
  Assert.IsTrue(FManager.FindTemplate('Review Leaks and SOLID', LTemplate), 'Review Leaks and SOLID template must be present');
end;

procedure TTestRadIAAnalysis.TestResolveStackTraceTemplate;
var
  LTemplate: TPromptTemplate;
  LResolved: string;
const
  STACK = 'EAccessViolation at 00405A12';
  CODE = 'procedure Foo;';
begin
  Assert.IsTrue(FManager.FindTemplate('Analyze Stack Trace', LTemplate));
  LResolved := LTemplate.Template.Replace('{stacktrace}', STACK).Replace('{code}', CODE);
  
  Assert.IsTrue(LResolved.Contains(STACK), 'Should contain the stack trace content');
  Assert.IsTrue(LResolved.Contains(CODE), 'Should contain the active code context');
end;

procedure TTestRadIAAnalysis.TestResolveReviewTemplate;
var
  LResolved: string;
const
  CODE = 'procedure MemoryLeak; begin TObject.Create; end;';
begin
  LResolved := FManager.ResolveTemplate('Review Leaks and SOLID', CODE);
  Assert.IsTrue(LResolved.Contains('static analysis'), 'Should mention static analysis');
  Assert.IsTrue(LResolved.Contains(CODE), 'Should contain the code to analyze');
end;

{ TTestRadIAOTAHelper }

procedure TTestRadIAOTAHelper.TestNormalizeLineBreaks_WindowsStyle;
var
  LInput, LExpected, LActual: string;
begin
  LInput := 'line1'#13#10'line2'#13#10'line3';
  LExpected := 'line1'#10'line2'#10'line3';
  LActual := TRadIAOTAHelper.NormalizeLineBreaks(LInput);
  Assert.AreEqual(LExpected, LActual);
end;

procedure TTestRadIAOTAHelper.TestNormalizeLineBreaks_MacStyle;
var
  LInput, LExpected, LActual: string;
begin
  LInput := 'line1'#13'line2'#13'line3';
  LExpected := 'line1'#10'line2'#10'line3';
  LActual := TRadIAOTAHelper.NormalizeLineBreaks(LInput);
  Assert.AreEqual(LExpected, LActual);
end;

procedure TTestRadIAOTAHelper.TestNormalizeLineBreaks_UnixStyle;
var
  LInput, LExpected, LActual: string;
begin
  LInput := 'line1'#10'line2'#10'line3';
  LExpected := 'line1'#10'line2'#10'line3';
  LActual := TRadIAOTAHelper.NormalizeLineBreaks(LInput);
  Assert.AreEqual(LExpected, LActual);
end;

procedure TTestRadIAOTAHelper.TestNormalizeLineBreaks_MixedStyle;
var
  LInput, LExpected, LActual: string;
begin
  LInput := 'line1'#13#10'line2'#13'line3'#10'line4';
  LExpected := 'line1'#10'line2'#10'line3'#10'line4';
  LActual := TRadIAOTAHelper.NormalizeLineBreaks(LInput);
  Assert.AreEqual(LExpected, LActual);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAAnalysis);
  TDUnitX.RegisterTestFixture(TTestRadIAOTAHelper);

end.
