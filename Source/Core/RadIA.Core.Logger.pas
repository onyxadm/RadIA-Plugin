unit RadIA.Core.Logger;

interface

uses  RadIA.Core.Interfaces;

type
  TConcreteLogger = class(TInterfacedObject, IRadIALogger)
  private
    FLogEnabled: Boolean;
    FLogPath: string;
    FLogMaxSizeKB: Integer;
    FLock: TObject;

    function GetDefaultLogPath: string;
    procedure RotateLogFile(const AActiveFile: string; const ADateStr: string);
    procedure CheckRotation(const AActiveFile: string; var ANeedRotation: Boolean; var AFileDateStr: string);
    procedure WriteLogEntry(const AActiveFile, AMsg, ATag: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Configure(const AEnabled: Boolean; const APath: string; const AMaxSizeKB: Integer);
    procedure Log(const AMsg: string; const ATag: string = 'Debug');
  end;

  TLogger = class
  private
    class var FActiveLogger: IRadIALogger;
  public
    class constructor Create;
    class destructor Destroy;

    class procedure SetActiveLogger(const ALogger: IRadIALogger);
    class procedure Configure(const AEnabled: Boolean; const APath: string; const AMaxSizeKB: Integer);
    class procedure Log(const AMsg: string; const ATag: string = 'Debug');
  end;

implementation

uses
  System.IOUtils, System.Win.Registry, Winapi.Windows, System.SysUtils, System.Classes;

{ TConcreteLogger }

constructor TConcreteLogger.Create;
var
  LReg: TRegistry;
  LPath: string;
  LBdsVersion: Double;
  LSettings: TFormatSettings;
begin
  inherited Create;
  FLock := TObject.Create;

  // Default values
  FLogEnabled := True;
  FLogPath := GetDefaultLogPath;
  FLogMaxSizeKB := 1024;

  // Initial read from registry to start logging early with user settings
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;

    LSettings := TFormatSettings.Create('en-US');
    if CompilerVersion >= 37.0 then
      LBdsVersion := CompilerVersion
    else
      LBdsVersion := CompilerVersion - 13.0;

    LPath := Format('Software\Embarcadero\BDS\%0.1f\RadIA', [LBdsVersion], LSettings);

    if LReg.OpenKeyReadOnly(LPath) then
    begin
      if LReg.ValueExists('LogEnabled') then
        FLogEnabled := LReg.ReadInteger('LogEnabled') <> 0;

      if LReg.ValueExists('LogPath') then
        FLogPath := LReg.ReadString('LogPath');

      if LReg.ValueExists('LogMaxSizeKB') then
        FLogMaxSizeKB := LReg.ReadInteger('LogMaxSizeKB');

      LReg.CloseKey;
    end;
  except
    on E: Exception do
      OutputDebugString(PChar('RadIA.Logger.Create Registry Error: ' + E.Message));
  end;
end;

destructor TConcreteLogger.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

function TConcreteLogger.GetDefaultLogPath: string;
begin
  Result := TPath.Combine(IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) + 'RadIA', 'Logs');
end;

procedure TConcreteLogger.Configure(const AEnabled: Boolean; const APath: string; const AMaxSizeKB: Integer);
begin
  TMonitor.Enter(FLock);
  try
    FLogEnabled := AEnabled;
    if APath.IsEmpty then
      FLogPath := GetDefaultLogPath
    else
      FLogPath := APath;
    if AMaxSizeKB > 0 then
      FLogMaxSizeKB := AMaxSizeKB
    else
      FLogMaxSizeKB := 1024;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TConcreteLogger.RotateLogFile(const AActiveFile: string; const ADateStr: string);
var
  LIndex: Integer;
  LRotatedFile: string;
  LDir: string;
begin
  LDir := TPath.GetDirectoryName(AActiveFile);
  LIndex := 1;
  repeat
    LRotatedFile := TPath.Combine(LDir, Format('radia_%s_%d.log', [ADateStr, LIndex]));
    Inc(LIndex);
  until not TFile.Exists(LRotatedFile);

  try
    TFile.Move(AActiveFile, LRotatedFile);
  except
    on E: Exception do
      OutputDebugString(PChar('RadIA.Logger.Rotate Error: ' + E.Message));
  end;
end;

procedure TConcreteLogger.CheckRotation(const AActiveFile: string; var ANeedRotation: Boolean; var AFileDateStr: string);
var
  LFileDate: TDateTime;
  LTodayStr: string;
  LSize: Int64;
begin
  if not TFile.Exists(AActiveFile) then
    Exit;

  // 1. Check Date Rotation
  try
    LFileDate := TFile.GetLastWriteTime(AActiveFile);
    LTodayStr := FormatDateTime('yyyy-mm-dd', Now);
    AFileDateStr := FormatDateTime('yyyy-mm-dd', LFileDate);
    if LTodayStr <> AFileDateStr then
      ANeedRotation := True;
  except
    on E: Exception do
      OutputDebugString(PChar('RadIA.Logger.CheckRotation Date Error: ' + E.Message));
  end;

  // 2. Check Size Rotation
  if not ANeedRotation then
  begin
    try
      LSize := TFile.GetSize(AActiveFile);
      if LSize >= (Int64(FLogMaxSizeKB) * 1024) then
        ANeedRotation := True;
    except
      on E: Exception do
        OutputDebugString(PChar('RadIA.Logger.CheckRotation Size Error: ' + E.Message));
    end;
  end;
end;

procedure TConcreteLogger.WriteLogEntry(const AActiveFile, AMsg, ATag: string);
var
  LStream: TFileStream;
  LWriter: TStreamWriter;
  LText: string;
begin
  try
    if TFile.Exists(AActiveFile) then
      LStream := TFileStream.Create(AActiveFile, fmOpenWrite or fmShareDenyNone)
    else
      LStream := TFileStream.Create(AActiveFile, fmCreate or fmShareDenyNone);
    try
      LStream.Seek(0, soEnd);
      LWriter := TStreamWriter.Create(LStream, TEncoding.UTF8);
      try
        LText := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' - [' + ATag + '] ' + AMsg;
        LWriter.WriteLine(LText);
      finally
        LWriter.Free;
      end;
    finally
      LStream.Free;
    end;
  except
    on E: Exception do
      OutputDebugString(PChar('RadIA.Logger.Write Error: ' + E.Message));
  end;
end;

procedure TConcreteLogger.Log(const AMsg: string; const ATag: string);
var
  LDir: string;
  LActiveFile: string;
  LNeedRotation: Boolean;
  LFileDateStr: string;
begin
  if not FLogEnabled then
    Exit;

  TMonitor.Enter(FLock);
  try
    LDir := FLogPath;

    try
      ForceDirectories(LDir);
    except
      Exit; // Cannot write if directory creation fails
    end;

    LActiveFile := TPath.Combine(LDir, 'radia.log');
    LNeedRotation := False;
    LFileDateStr := FormatDateTime('yyyy-mm-dd', Now);

    CheckRotation(LActiveFile, LNeedRotation, LFileDateStr);

    if LNeedRotation then
      RotateLogFile(LActiveFile, LFileDateStr);

    WriteLogEntry(LActiveFile, AMsg, ATag);
  finally
    TMonitor.Exit(FLock);
  end;
end;

{ TLogger }

class constructor TLogger.Create;
begin
  FActiveLogger := TConcreteLogger.Create;
end;

class destructor TLogger.Destroy;
begin
  FActiveLogger := nil;
end;

class procedure TLogger.SetActiveLogger(const ALogger: IRadIALogger);
begin
  FActiveLogger := ALogger;
end;

class procedure TLogger.Configure(const AEnabled: Boolean; const APath: string; const AMaxSizeKB: Integer);
begin
  if Assigned(FActiveLogger) then
    FActiveLogger.Configure(AEnabled, APath, AMaxSizeKB);
end;

class procedure TLogger.Log(const AMsg: string; const ATag: string);
begin
  if Assigned(FActiveLogger) then
    FActiveLogger.Log(AMsg, ATag);
end;

end.
