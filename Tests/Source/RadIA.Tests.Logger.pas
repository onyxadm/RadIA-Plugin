unit RadIA.Tests.Logger;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestRadIALogger = class
  private
    FTempDir: string;
    FActiveLogFile: string;
    procedure ClearTempFiles;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLogWriting;
    [Test]
    procedure TestLogDisabled;
    [Test]
    procedure TestLogRotationBySize;
    [Test]
    procedure TestLogRotationByDate;
    [Test]
    procedure TestLoggerExceptions;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, RadIA.Core.Interfaces, RadIA.Core.Logger;

{ TTestRadIALogger }

procedure TTestRadIALogger.ClearTempFiles;
begin
  if TDirectory.Exists(FTempDir) then
  begin
    try
      TDirectory.Delete(FTempDir, True);
    except
      // Ignore cleanup locks in unit tests
    end;
  end;
end;

procedure TTestRadIALogger.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'RadIA_Tests_Logs');
  FActiveLogFile := TPath.Combine(FTempDir, 'radia.log');
  ClearTempFiles;
end;

procedure TTestRadIALogger.TearDown;
begin
  ClearTempFiles;
end;

procedure TTestRadIALogger.TestLogWriting;
var
  LContent: string;
begin
  TLogger.Configure(True, FTempDir, 1024);
  TLogger.Log('Hello test log line', 'UnitTest');

  Assert.IsTrue(TFile.Exists(FActiveLogFile), 'Log file should be created');

  LContent := TFile.ReadAllText(FActiveLogFile, TEncoding.UTF8);
  Assert.IsTrue(LContent.Contains('[UnitTest] Hello test log line'), 'Log content must match');
end;

procedure TTestRadIALogger.TestLogDisabled;
begin
  TLogger.Configure(False, FTempDir, 1024);
  TLogger.Log('This line should not be logged', 'UnitTest');

  Assert.IsFalse(TFile.Exists(FActiveLogFile), 'Log file should not be created when logger is disabled');
end;

procedure TTestRadIALogger.TestLogRotationBySize;
var
  ILine: Integer;
  LFiles: TArray<string>;
  LRotatedFound: Boolean;
  LFile: string;
begin
  // Set max log size to 1 KB
  TLogger.Configure(True, FTempDir, 1);

  // Write enough log messages to exceed 1024 bytes (e.g. 20 lines of ~80 chars)
  for ILine := 1 to 30 do
  begin
    TLogger.Log('This is a relatively long log line used to quickly exceed the one kilobyte rotation limit ' + IntToStr(ILine), 'UnitTest');
  end;

  Assert.IsTrue(TFile.Exists(FActiveLogFile), 'Active log file should still exist');

  LFiles := TDirectory.GetFiles(FTempDir, '*.log');
  LRotatedFound := False;
  for LFile in LFiles do
  begin
    if not SameText(TPath.GetFileName(LFile), 'radia.log') then
    begin
      Assert.IsTrue(TPath.GetFileName(LFile).StartsWith('radia_'), 'Rotated file name prefix');
      LRotatedFound := True;
    end;
  end;

  Assert.IsTrue(LRotatedFound, 'Should find at least one rotated log file');
end;

procedure TTestRadIALogger.TestLogRotationByDate;
var
  LYesterday: TDateTime;
  LYesterdayStr: string;
  LRotatedFile: string;
begin
  TLogger.Configure(True, FTempDir, 1024);

  // 1. Force directory and write initial file
  ForceDirectories(FTempDir);
  TFile.WriteAllText(FActiveLogFile, 'yesterday initial log line' + sLineBreak, TEncoding.UTF8);

  // 2. Set file date to yesterday
  LYesterday := Now - 1.0;
  TFile.SetLastWriteTime(FActiveLogFile, LYesterday);
  LYesterdayStr := FormatDateTime('yyyy-mm-dd', LYesterday);

  // 3. Log a new message
  TLogger.Log('today new log line', 'UnitTest');

  // 4. Verify rotation occurred
  LRotatedFile := TPath.Combine(FTempDir, Format('radia_%s_1.log', [LYesterdayStr]));
  Assert.IsTrue(TFile.Exists(LRotatedFile), 'File from yesterday should be rotated to: ' + LRotatedFile);
  Assert.IsTrue(TFile.Exists(FActiveLogFile), 'New active log file should exist');

  // 5. Verify contents
  Assert.IsTrue(TFile.ReadAllText(LRotatedFile, TEncoding.UTF8).Contains('yesterday initial log line'), 'Rotated file contents');
  Assert.IsTrue(TFile.ReadAllText(FActiveLogFile, TEncoding.UTF8).Contains('today new log line'), 'Active file contents');
end;

procedure TTestRadIALogger.TestLoggerExceptions;
var
  LStream: TFileStream;
  LTempLogger: IRadIALogger;
begin
  // 1. ForÃƒÂ§ar erro de rotaÃƒÂ§ÃƒÂ£o e escrita bloqueando o arquivo de log ativo exclusivamente
  TLogger.Configure(True, FTempDir, 1); // RotaÃƒÂ§ÃƒÂ£o de 1 KB

  // Criar arquivo ativo
  ForceDirectories(FTempDir);
  TFile.WriteAllText(FActiveLogFile, StringOfChar('A', 2000), TEncoding.UTF8);

  // Bloquear o prÃƒÂ³prio arquivo de log ativo exclusivamente
  LStream := TFileStream.Create(FActiveLogFile, fmOpenWrite or fmShareExclusive);
  try
    // Logar algo para forÃƒÂ§ar erros de escrita e rotaÃƒÂ§ÃƒÂ£o (o move e a escrita falharÃƒÂ£o por causa do bloqueio)
    TLogger.Log('Forcing logger exceptions', 'UnitTest');
  finally
    LStream.Free;
  end;

  // 2. Testar SetActiveLogger
  LTempLogger := TConcreteLogger.Create;
  TLogger.SetActiveLogger(LTempLogger);
  TLogger.SetActiveLogger(TConcreteLogger.Create); // Volta para um novo logger limpo

  // 3. Testar Configure com caminho vazio (fallbacks)
  TLogger.Configure(True, '', 0);
  TLogger.Log('Test default fallback path', 'UnitTest');

  // 4. Testar erro de criaÃƒÂ§ÃƒÂ£o de pasta (caminho de rede invÃƒÂ¡lido)
  TLogger.Configure(True, '\\invalid_server_xyz\invalid_share_xyz', 1024);
  TLogger.Log('Test directory creation failure', 'UnitTest');

  // Restaura o logger configurado para os testes do setup
  TLogger.Configure(True, FTempDir, 1024);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIALogger);

end.
