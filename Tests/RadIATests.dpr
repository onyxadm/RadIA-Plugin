program RadIATests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  
  // Production Units
  RadIA.Core.Types in '..\Source\Core\RadIA.Core.Types.pas',
  RadIA.Core.Interfaces in '..\Source\Core\RadIA.Core.Interfaces.pas',
  RadIA.Core.Logger in '..\Source\Core\RadIA.Core.Logger.pas',
  RadIA.Core.Config in '..\Source\Core\RadIA.Core.Config.pas',
  RadIA.Core.ProviderRegistry in '..\Source\Core\RadIA.Core.ProviderRegistry.pas',
  RadIA.Core.Cache in '..\Source\Core\RadIA.Core.Cache.pas',
  RadIA.Core.Service in '..\Source\Core\RadIA.Core.Service.pas',
  RadIA.Core.PromptHistory in '..\Source\Core\RadIA.Core.PromptHistory.pas',
  RadIA.Core.TokenUsage in '..\Source\Core\RadIA.Core.TokenUsage.pas',
  RadIA.Core.ConversationExporter in '..\Source\Core\RadIA.Core.ConversationExporter.pas',
  RadIA.Core.PromptTemplates in '..\Source\Core\RadIA.Core.PromptTemplates.pas',
  RadIA.Core.ProjectContext in '..\Source\Core\RadIA.Core.ProjectContext.pas',
  RadIA.Core.Sessions in '..\Source\Core\RadIA.Core.Sessions.pas',
  RadIA.Core.DTO.Generator in '..\Source\Core\RadIA.Core.DTO.Generator.pas',
  RadIA.OTA.Helper in '..\Source\Integration\RadIA.OTA.Helper.pas',
  RadIA.Provider.Base in '..\Source\Providers\RadIA.Provider.Base.pas',
  RadIA.Provider.Gemini in '..\Source\Providers\RadIA.Provider.Gemini.pas',
  RadIA.Provider.OpenAI in '..\Source\Providers\RadIA.Provider.OpenAI.pas',
  RadIA.Provider.Claude in '..\Source\Providers\RadIA.Provider.Claude.pas',
  RadIA.Provider.Ollama in '..\Source\Providers\RadIA.Provider.Ollama.pas',
  RadIA.Provider.DeepSeek in '..\Source\Providers\RadIA.Provider.DeepSeek.pas',
  RadIA.Provider.Groq in '..\Source\Providers\RadIA.Provider.Groq.pas',
  RadIA.Provider.OpenRouter in '..\Source\Providers\RadIA.Provider.OpenRouter.pas',
  RadIA.Provider.Generic in '..\Source\Providers\RadIA.Provider.Generic.pas',
  RadIA.Provider.LMStudio in '..\Source\Providers\RadIA.Provider.LMStudio.pas',
  
  // Test Suites
  RadIA.Tests.Config in 'Source\RadIA.Tests.Config.pas',
  RadIA.Tests.Providers in 'Source\RadIA.Tests.Providers.pas',
  RadIA.Tests.Cache in 'Source\RadIA.Tests.Cache.pas',
  RadIA.Tests.Ollama in 'Source\RadIA.Tests.Ollama.pas',
  RadIA.Tests.Service in 'Source\RadIA.Tests.Service.pas',
  RadIA.Tests.PromptHistory in 'Source\RadIA.Tests.PromptHistory.pas',
  RadIA.Tests.TokenUsage in 'Source\RadIA.Tests.TokenUsage.pas',
  RadIA.Tests.Exporter in 'Source\RadIA.Tests.Exporter.pas',
  RadIA.Tests.Templates in 'Source\RadIA.Tests.Templates.pas',
  RadIA.Tests.ProjectContext in 'Source\RadIA.Tests.ProjectContext.pas',
  RadIA.Tests.Streaming in 'Source\RadIA.Tests.Streaming.pas',
  RadIA.Tests.ProvidersEx in 'Source\RadIA.Tests.ProvidersEx.pas',
  RadIA.Tests.Logger in 'Source\RadIA.Tests.Logger.pas',
  RadIA.Tests.Sessions in 'Source\RadIA.Tests.Sessions.pas',
  RadIA.Tests.Quota in 'Source\RadIA.Tests.Quota.pas',
  RadIA.Tests.DTOGenerator in 'Source\RadIA.Tests.DTOGenerator.pas',
  RadIA.Tests.JSONProviders in 'Source\RadIA.Tests.JSONProviders.pas',
  RadIA.Tests.Analysis in 'Source\RadIA.Tests.Analysis.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
begin
  try
    TRadIAConfig.SetBaseRegistryPath('Software\RadIA\Tests');
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    
    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);
    
    Results := Runner.Execute;
    
    if not Results.AllPassed then
      System.ExitCode := 1
    else
      System.ExitCode := 0;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.
