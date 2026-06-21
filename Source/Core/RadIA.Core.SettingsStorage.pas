unit RadIA.Core.SettingsStorage;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  IRadIASettingsStorage = interface
    ['{8A95E81A-98C3-4874-8A83-AC5EE2298FDF}']
    function OpenKey(const APath: string; ACanCreate: Boolean): Boolean;
    procedure CloseKey;
    function KeyExists(const APath: string): Boolean;
    function ValueExists(const AName: string): Boolean;
    procedure GetKeyNames(AList: TStrings);

    function ReadString(const AName, ADefault: string): string;
    procedure WriteString(const AName, AValue: string);
    function ReadInteger(const AName: string; ADefault: Integer): Integer;
    procedure WriteInteger(const AName: string; AValue: Integer);
    function ReadFloat(const AName: string; ADefault: Double): Double;
    procedure WriteFloat(const AName: string; AValue: Double);
  end;

  TRadIARegistrySettingsStorage = class(TInterfacedObject, IRadIASettingsStorage)
  private
    FReg: TObject; // Typed as TObject to reduce interface namespace pollution
  public
    constructor Create;
    destructor Destroy; override;

    function OpenKey(const APath: string; ACanCreate: Boolean): Boolean;
    procedure CloseKey;
    function KeyExists(const APath: string): Boolean;
    function ValueExists(const AName: string): Boolean;
    procedure GetKeyNames(AList: TStrings);

    function ReadString(const AName, ADefault: string): string;
    procedure WriteString(const AName, AValue: string);
    function ReadInteger(const AName: string; ADefault: Integer): Integer;
    procedure WriteInteger(const AName: string; AValue: Integer);
    function ReadFloat(const AName: string; ADefault: Double): Double;
    procedure WriteFloat(const AName: string; AValue: Double);
  end;

  TRadIAMemorySettingsStorage = class(TInterfacedObject, IRadIASettingsStorage)
  private
    FData: TDictionary<string, TDictionary<string, string>>;
    FCurrentPath: string;
    function GetOrCreatePathData(const APath: string): TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;

    function OpenKey(const APath: string; ACanCreate: Boolean): Boolean;
    procedure CloseKey;
    function KeyExists(const APath: string): Boolean;
    function ValueExists(const AName: string): Boolean;
    procedure GetKeyNames(AList: TStrings);

    // In-memory CRUD methods
    function ReadString(const AName, ADefault: string): string;
    procedure WriteString(const AName, AValue: string);
    function ReadInteger(const AName: string; ADefault: Integer): Integer;
    procedure WriteInteger(const AName: string; AValue: Integer);
    function ReadFloat(const AName: string; ADefault: Double): Double;
    procedure WriteFloat(const AName: string; AValue: Double);
  end;

implementation

uses
  System.Win.Registry, Winapi.Windows, System.Math;

{ TRadIARegistrySettingsStorage }

constructor TRadIARegistrySettingsStorage.Create;
var
  LRegistry: TRegistry;
begin
  inherited Create;
  LRegistry := TRegistry.Create;
  LRegistry.RootKey := HKEY_CURRENT_USER;
  FReg := LRegistry;
end;

destructor TRadIARegistrySettingsStorage.Destroy;
begin
  if Assigned(FReg) then
    TRegistry(FReg).Free;
  inherited Destroy;
end;



function TRadIARegistrySettingsStorage.OpenKey(const APath: string; ACanCreate: Boolean): Boolean;
begin
  Result := TRegistry(FReg).OpenKey(APath, ACanCreate);
end;

procedure TRadIARegistrySettingsStorage.CloseKey;
begin
  TRegistry(FReg).CloseKey;
end;

function TRadIARegistrySettingsStorage.KeyExists(const APath: string): Boolean;
begin
  Result := TRegistry(FReg).KeyExists(APath);
end;

function TRadIARegistrySettingsStorage.ValueExists(const AName: string): Boolean;
begin
  Result := TRegistry(FReg).ValueExists(AName);
end;

procedure TRadIARegistrySettingsStorage.GetKeyNames(AList: TStrings);
begin
  TRegistry(FReg).GetKeyNames(AList);
end;

function TRadIARegistrySettingsStorage.ReadString(const AName, ADefault: string): string;
begin
  try
    if TRegistry(FReg).ValueExists(AName) then
      Result := TRegistry(FReg).ReadString(AName)
    else
      Result := ADefault;
  except
    Result := ADefault;
  end;
end;

procedure TRadIARegistrySettingsStorage.WriteString(const AName, AValue: string);
begin
  TRegistry(FReg).WriteString(AName, AValue);
end;

function TRadIARegistrySettingsStorage.ReadInteger(const AName: string; ADefault: Integer): Integer;
begin
  try
    if TRegistry(FReg).ValueExists(AName) then
      Result := TRegistry(FReg).ReadInteger(AName)
    else
      Result := ADefault;
  except
    Result := ADefault;
  end;
end;

procedure TRadIARegistrySettingsStorage.WriteInteger(const AName: string; AValue: Integer);
begin
  TRegistry(FReg).WriteInteger(AName, AValue);
end;

function TRadIARegistrySettingsStorage.ReadFloat(const AName: string; ADefault: Double): Double;
begin
  try
    if TRegistry(FReg).ValueExists(AName) then
      Result := TRegistry(FReg).ReadFloat(AName)
    else
      Result := ADefault;
  except
    Result := ADefault;
  end;
end;

procedure TRadIARegistrySettingsStorage.WriteFloat(const AName: string; AValue: Double);
begin
  TRegistry(FReg).WriteFloat(AName, AValue);
end;


{ TRadIAMemorySettingsStorage }

constructor TRadIAMemorySettingsStorage.Create;
begin
  inherited Create;
  FData := TDictionary<string, TDictionary<string, string>>.Create;
  FCurrentPath := '';
end;

destructor TRadIAMemorySettingsStorage.Destroy;
var
  LPair: TPair<string, TDictionary<string, string>>;
begin
  for LPair in FData do
    LPair.Value.Free;
  FData.Free;
  inherited Destroy;
end;

function TRadIAMemorySettingsStorage.GetOrCreatePathData(const APath: string): TDictionary<string, string>;
var
  LKey: string;
begin
  LKey := APath.ToLower;
  if not FData.TryGetValue(LKey, Result) then
  begin
    Result := TDictionary<string, string>.Create;
    FData.Add(LKey, Result);
  end;
end;

function TRadIAMemorySettingsStorage.OpenKey(const APath: string; ACanCreate: Boolean): Boolean;
begin
  if ACanCreate then
  begin
    GetOrCreatePathData(APath);
    FCurrentPath := APath;
    Exit(True);
  end;

  Result := FData.ContainsKey(APath.ToLower);
  if Result then
    FCurrentPath := APath;
end;

procedure TRadIAMemorySettingsStorage.CloseKey;
begin
  // In-memory doesn't lock handles, so just clear the current path
  FCurrentPath := '';
end;

function TRadIAMemorySettingsStorage.KeyExists(const APath: string): Boolean;
begin
  Result := FData.ContainsKey(APath.ToLower);
end;

function TRadIAMemorySettingsStorage.ValueExists(const AName: string): Boolean;
var
  LPathData: TDictionary<string, string>;
begin
  if FCurrentPath.IsEmpty then
    Exit(False);
  LPathData := GetOrCreatePathData(FCurrentPath);
  Result := LPathData.ContainsKey(AName.ToLower);
end;

procedure TRadIAMemorySettingsStorage.GetKeyNames(AList: TStrings);
var
  LKey: string;
  LSubKey: string;
  LPrefix: string;
begin
  AList.Clear;
  if FCurrentPath.IsEmpty then
    Exit;

  LPrefix := FCurrentPath.ToLower + '\';
  for LKey in FData.Keys do
  begin
    if LKey.StartsWith(LPrefix) then
    begin
      LSubKey := LKey.Substring(Length(LPrefix));
      if not LSubKey.Contains('\') then
        AList.Add(LSubKey);
    end;
  end;
end;

function TRadIAMemorySettingsStorage.ReadString(const AName, ADefault: string): string;
var
  LPathData: TDictionary<string, string>;
begin
  if FCurrentPath.IsEmpty then
    Exit(ADefault);
  LPathData := GetOrCreatePathData(FCurrentPath);
  if not LPathData.TryGetValue(AName.ToLower, Result) then
    Result := ADefault;
end;

procedure TRadIAMemorySettingsStorage.WriteString(const AName, AValue: string);
var
  LPathData: TDictionary<string, string>;
begin
  if FCurrentPath.IsEmpty then
    Exit;
  LPathData := GetOrCreatePathData(FCurrentPath);
  LPathData.AddOrSetValue(AName.ToLower, AValue);
end;

function TRadIAMemorySettingsStorage.ReadInteger(const AName: string; ADefault: Integer): Integer;
var
  LValStr: string;
begin
  LValStr := ReadString(AName, '');
  if LValStr.IsEmpty then
    Exit(ADefault);
  Result := StrToIntDef(LValStr, ADefault);
end;

procedure TRadIAMemorySettingsStorage.WriteInteger(const AName: string; AValue: Integer);
begin
  WriteString(AName, IntToStr(AValue));
end;

function TRadIAMemorySettingsStorage.ReadFloat(const AName: string; ADefault: Double): Double;
var
  LValStr: string;
begin
  LValStr := ReadString(AName, '');
  if LValStr.IsEmpty then
    Exit(ADefault);
  Result := StrToFloatDef(LValStr, ADefault, TFormatSettings.Invariant);
end;

procedure TRadIAMemorySettingsStorage.WriteFloat(const AName: string; AValue: Double);
begin
  WriteString(AName, FloatToStr(AValue, TFormatSettings.Invariant));
end;

end.
