program RadIATests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  
  // Production Units
  RadIA.Core.Types in '..\Source\Core\RadIA.Core.Types.pas',
  RadIA.Core.Interfaces in '..\Source\Core\RadIA.Core.Interfaces.pas',
  RadIA.Core.Config in '..\Source\Core\RadIA.Core.Config.pas',
  RadIA.Core.Service in '..\Source\Core\RadIA.Core.Service.pas',
  RadIA.Provider.Base in '..\Source\Providers\RadIA.Provider.Base.pas',
  RadIA.Provider.Gemini in '..\Source\Providers\RadIA.Provider.Gemini.pas',
  RadIA.Provider.OpenAI in '..\Source\Providers\RadIA.Provider.OpenAI.pas',
  RadIA.Provider.Claude in '..\Source\Providers\RadIA.Provider.Claude.pas',
  
  // Test Suites
  RadIA.Tests.Config in 'Source\RadIA.Tests.Config.pas',
  RadIA.Tests.Providers in 'Source\RadIA.Tests.Providers.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
begin
  try
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
