unit RadIA.Core.Config;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.TokenUsage;

type
  TRadIAConfig = class(TInterfacedObject, IAIConfig)
  private
    class var FBaseRegistryPath: string;
    class var FInstance: TRadIAConfig;
    FActiveProvider: string;
    FSystemPrompt: string;
    FOllamaBaseUrl: string;
    FMaxHistoryMessages: Integer;
    FOpenAICustomBaseUrl: string;
    FSmartConfigEnabled: Boolean;
    FLogEnabled: Boolean;
    FLogPath: string;
    FLogMaxSizeKB: Integer;
    FQuotaEnabled: Boolean;
    FQuotaLimit: Int64;
    FQuotaUsed: Int64;
    FQuotaCycleStart: TDateTime;
    FActiveSessionId: string;
    FAutocompleteEnabled: Boolean;
    FAutocompleteProvider: string;
    FAutocompleteModel: string;
    FAutocompleteDelay: Integer;

    { Dynamic String-based settings (avoiding TDictionary generics due to BPL RTL unloading bugs) }
    FApiKeysList: TStringList;
    FModelsList: TStringList;
    FTemperaturesList: TStringList;
    FMaxTokensList: TStringList;
    FTimeoutsList: TStringList;
    FBaseUrlsList: TStringList;

    procedure LoadFromPath(const APath: string);
    procedure SaveToPath(const APath: string);
    function ProtectString(const AValue: string): string;
    function UnprotectString(const AValue: string): string;
    function ReadRegString(const AReg: TObject; const AKey: string; const ADefault: string): string;
    function ReadRegInt(const AReg: TObject; const AKey: string; const ADefault: Integer): Integer;
    function ReadRegDouble(const AReg: TObject; const AKey: string; const ADefault: Double): Double;
    procedure CheckAndResetQuotaCycle;
  protected
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create;
    destructor Destroy; override;
    class function GetInstance: IAIConfig;
    class procedure SetBaseRegistryPath(const APath: string);
    class function GetRegistryPath: string;

    { IAIConfig implementation }
    function GetActiveProvider: string;
    procedure SetActiveProvider(const AProvider: string);
    function GetSystemPrompt: string;
    procedure SetSystemPrompt(const AValue: string);
    function GetOllamaBaseUrl: string;
    procedure SetOllamaBaseUrl(const AValue: string);
    function GetMaxHistoryMessages: Integer;
    procedure SetMaxHistoryMessages(const AValue: Integer);
    function GetOpenAICustomBaseUrl: string;
    procedure SetOpenAICustomBaseUrl(const AValue: string);

    { String-based dynamic provider APIs }
    function GetApiKey(const AProviderName: string): string;
    procedure SetApiKey(const AProviderName: string; const AKey: string);
    function GetActiveModel(const AProviderName: string): string;
    procedure SetActiveModel(const AProviderName: string; const AModel: string);
    function GetTemperature(const AProviderName: string): Double;
    procedure SetTemperature(const AProviderName: string; const AValue: Double);
    function GetMaxTokens(const AProviderName: string): Integer;
    procedure SetMaxTokens(const AProviderName: string; const AValue: Integer);
    function GetTimeout(const AProviderName: string): Integer;
    procedure SetTimeout(const AProviderName: string; const AValue: Integer);
    function GetProviderBaseUrl(const AProviderName: string): string;
    procedure SetProviderBaseUrl(const AProviderName: string; const AUrl: string);

    function GetAutocompleteEnabled: Boolean;
    procedure SetAutocompleteEnabled(const AValue: Boolean);
    function GetAutocompleteProvider: string;
    procedure SetAutocompleteProvider(const AProvider: string);
    function GetAutocompleteModel: string;
    procedure SetAutocompleteModel(const AModel: string);
    function GetAutocompleteDelay: Integer;
    procedure SetAutocompleteDelay(const AValue: Integer);

    function GetSmartConfigEnabled: Boolean;
    procedure SetSmartConfigEnabled(const AValue: Boolean);
    function GetLogEnabled: Boolean;
    procedure SetLogEnabled(const AValue: Boolean);
    function GetLogPath: string;
    procedure SetLogPath(const AValue: string);
    function GetLogMaxSizeKB: Integer;
    procedure SetLogMaxSizeKB(const AValue: Integer);
    function GetQuotaEnabled: Boolean;
    procedure SetQuotaEnabled(const AValue: Boolean);
    function GetQuotaLimit: Int64;
    procedure SetQuotaLimit(const AValue: Int64);
    function GetQuotaUsed: Int64;
    procedure SetQuotaUsed(const AValue: Int64);
    function GetQuotaCycleStart: TDateTime;
    procedure SetQuotaCycleStart(const AValue: TDateTime);
    function GetActiveSessionId: string;
    procedure SetActiveSessionId(const AValue: string);
    procedure AddToQuotaUsage(const AUsage: TTokenUsage);
    procedure Save;
    procedure Load;
  end;

implementation

uses
  Winapi.Windows, System.Win.Registry, System.NetEncoding, System.Math, System.IOUtils, ToolsAPI,
  RadIA.Core.Logger, RadIA.Core.ProviderRegistry;

const
  CDefaultSystemPrompt =
    'You are a Delphi Senior Software Architect. Always reply in Brazilian Portuguese (pt-BR).' + sLineBreak +
    'When generating, refactoring, or optimizing code:' + sLineBreak +
    '1. Output ONLY the specific Pascal code block requested (e.g., a procedure, function, class, or code snippet).' + sLineBreak +
    '2. Do NOT wrap the code in a complete Delphi unit (no "unit", "interface", "implementation", or "end.") unless I explicitly ask you to create a full file.' + sLineBreak +
    '3. Do NOT include any conversational preamble, intro, or concluding remarks before or after the code block.' + sLineBreak +
    '4. If technical explanation is necessary, keep it extremely brief, bulleted, and placed after the code.' + sLineBreak +
    '5. Adhere strictly to Clean Code, SOLID principles, and proper Delphi resource management (e.g., try..finally).';

{ Windows DPAPI Declarations }
type
  TDataBlob = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PDataBlob = ^TDataBlob;

function CryptProtectData(pDataIn: PDataBlob; szDataDescr: LPCWSTR;
  pOptionalEntropy: PDataBlob; pvReserved: Pointer;
  pPromptStruct: Pointer; dwFlags: DWORD;
  pDataOut: PDataBlob): BOOL; stdcall; external 'crypt32.dll';

function CryptUnprotectData(pDataIn: PDataBlob; ppszDataDescr: Pointer;
  pOptionalEntropy: PDataBlob; pvReserved: Pointer;
  pPromptStruct: Pointer; dwFlags: DWORD;
  pDataOut: PDataBlob): BOOL; stdcall; external 'crypt32.dll';

{ TRadIAConfig }

procedure LogDebug(const AMsg: string);
begin
  TLogger.Log(AMsg, 'Config');
end;

function CleanApiKey(const AValue: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(AValue) do
  begin
    C := AValue[I];
    if ((C >= 'a') and (C <= 'z')) or
       ((C >= 'A') and (C <= 'Z')) or
       ((C >= '0') and (C <= '9')) or
       (C = '.') or (C = '-') or (C = '_') or
       (C = '/') or (C = '+') or (C = '=') or
       (C = '@') or (C = ':') then
    begin
      Result := Result + C;
    end;
  end;
end;

constructor TRadIAConfig.Create;
begin
  inherited Create;
  
  LogDebug('TRadIAConfig.Create: Active path = ' + GetRegistryPath);

  FApiKeysList := TStringList.Create;
  FModelsList := TStringList.Create;
  FTemperaturesList := TStringList.Create;
  FMaxTokensList := TStringList.Create;
  FTimeoutsList := TStringList.Create;
  FBaseUrlsList := TStringList.Create;

  FActiveProvider := 'Gemini';
  FSystemPrompt := CDefaultSystemPrompt;
  FOllamaBaseUrl := 'http://localhost:11434';
  FMaxHistoryMessages := 20;
  FOpenAICustomBaseUrl := '';
  
  FSmartConfigEnabled := True;
  FLogEnabled := True;
  FLogPath := TPath.Combine(IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) + 'RadIA', 'Logs');
  FLogMaxSizeKB := 1024;

  FQuotaEnabled := False;
  FQuotaLimit := 1000000;
  FQuotaUsed := 0;
  FQuotaCycleStart := Now;
  FActiveSessionId := '';
  
  FAutocompleteEnabled := True;
  FAutocompleteProvider := 'Gemini';
  FAutocompleteModel := 'gemini-1.5-flash';
  FAutocompleteDelay := 300;
  
  Load;
end;

destructor TRadIAConfig.Destroy;
begin
  FApiKeysList.Free;
  FModelsList.Free;
  FTemperaturesList.Free;
  FMaxTokensList.Free;
  FTimeoutsList.Free;
  FBaseUrlsList.Free;
  inherited Destroy;
end;

class procedure TRadIAConfig.SetBaseRegistryPath(const APath: string);
begin
  FBaseRegistryPath := APath;
end;

function TRadIAConfig.GetActiveProvider: string;
begin
  Result := FActiveProvider;
end;

function TRadIAConfig.GetSystemPrompt: string;
begin
  Result := FSystemPrompt;
end;

{ Registry read helpers — encapsulate the try/except boilerplate }

function TRadIAConfig.ReadRegString(const AReg: TObject; const AKey: string;
  const ADefault: string): string;
var
  LReg: TRegistry;
begin
  LReg := AReg as TRegistry;
  try
    if LReg.ValueExists(AKey) then
      Result := LReg.ReadString(AKey)
    else
      Result := ADefault;
  except
    Result := ADefault;
  end;
end;

function TRadIAConfig.ReadRegInt(const AReg: TObject; const AKey: string;
  const ADefault: Integer): Integer;
var
  LReg: TRegistry;
begin
  LReg := AReg as TRegistry;
  try
    if LReg.ValueExists(AKey) then
      Result := LReg.ReadInteger(AKey)
    else
      Result := ADefault;
  except
    Result := ADefault;
  end;
end;

function TRadIAConfig.ReadRegDouble(const AReg: TObject; const AKey: string;
  const ADefault: Double): Double;
var
  LReg: TRegistry;
begin
  LReg := AReg as TRegistry;
  try
    if LReg.ValueExists(AKey) then
      Result := LReg.ReadFloat(AKey)
    else
      Result := ADefault;
  except
    Result := ADefault;
  end;
end;

class function TRadIAConfig.GetRegistryPath: string;
var
  LOTAServices: IOTAServices;
  LSettings: TFormatSettings;
  LBdsVersion: Double;
begin
  if not FBaseRegistryPath.IsEmpty then
  begin
    Result := FBaseRegistryPath;
    Exit;
  end;

  if Assigned(BorlandIDEServices) and Supports(BorlandIDEServices, IOTAServices, LOTAServices) then
  begin
    Result := LOTAServices.GetBaseRegistryKey + '\RadIA';
    Exit;
  end;

  LSettings := TFormatSettings.Create('en-US');
  if CompilerVersion >= 37.0 then
    LBdsVersion := CompilerVersion
  else
    LBdsVersion := CompilerVersion - 13.0;

  Result := Format('Software\Embarcadero\BDS\%0.1f\RadIA', [LBdsVersion], LSettings);
end;

procedure TRadIAConfig.Load;
begin
  LoadFromPath(GetRegistryPath);
end;

procedure TRadIAConfig.LoadFromPath(const APath: string);
var
  LReg: TRegistry;
  LProvPath: string;
  LMaxHist: Integer;
  LMigratedPath: string;
  LParentPath: string;
  LSubKeys: TStringList;
  LSubKey: string;
  LProviders: TArray<TProviderMetadata>;
  LMeta: TProviderMetadata;
begin
  LogDebug('TRadIAConfig.Load starting. Path = ' + APath);
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    
    { Se a nova chave não existe, tenta fazer a migração das chaves legadas }
    if not LReg.KeyExists(APath) then
    begin
      LogDebug('TRadIAConfig.Load: Path does not exist, checking for migration path...');
      LMigratedPath := '';
      
      { 1. Se o caminho possui contra-barra, tenta migrar caminhos relativos à IDE }
      if Pos('\', APath) > 0 then
      begin
        LParentPath := Copy(APath, 1, LastDelimiter('\', APath));
        if LReg.KeyExists(LParentPath + 'AIPlugin') then
          LMigratedPath := LParentPath + 'AIPlugin'
        else if LReg.KeyExists(LParentPath + 'RadIA') then
          LMigratedPath := LParentPath + 'RadIA';
      end;
      
      { 2. Fallbacks globais }
      if LMigratedPath.IsEmpty then
      begin
        if LReg.KeyExists('Software\RadIA') then
          LMigratedPath := 'Software\RadIA'
        else if LReg.KeyExists('Software\RadAI') then
          LMigratedPath := 'Software\RadAI';
      end;

      if not LMigratedPath.IsEmpty and (LMigratedPath <> APath) then
      begin
        LogDebug('TRadIAConfig.Load: Found migration path: ' + LMigratedPath);
        LoadFromPath(LMigratedPath);
        SaveToPath(APath);
        Exit;
      end;
    end;

    { 1. Ler chaves globais da raiz }
    if LReg.OpenKeyReadOnly(APath) then
    begin
      LogDebug('TRadIAConfig.Load: Opened root path ' + APath);
      FActiveProvider := 'Gemini';
      if LReg.ValueExists('ActiveProvider') then
      begin
        if LReg.GetDataType('ActiveProvider') = rdString then
          FActiveProvider := LReg.ReadString('ActiveProvider');
      end;
      FSystemPrompt      := ReadRegString(LReg, 'SystemPrompt', CDefaultSystemPrompt);
      
      { Fallback temporário das chaves legadas da raiz caso o usuário ainda não as tenha salvado nas subchaves }
      FOllamaBaseUrl     := ReadRegString(LReg, 'OllamaBaseUrl', 'http://localhost:11434');
      FOpenAICustomBaseUrl := ReadRegString(LReg, 'OpenAICustomBaseUrl', '');

      LMaxHist := ReadRegInt(LReg, 'MaxHistoryMessages', 20);
      FMaxHistoryMessages := IfThen(LMaxHist > 0, LMaxHist, 20);
      FSmartConfigEnabled := ReadRegInt(LReg, 'SmartConfigEnabled', 1) <> 0;
      FLogEnabled := ReadRegInt(LReg, 'LogEnabled', 1) <> 0;
      FLogPath := ReadRegString(LReg, 'LogPath', TPath.Combine(IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) + 'RadIA', 'Logs'));
      FLogMaxSizeKB := ReadRegInt(LReg, 'LogMaxSizeKB', 1024);
      FQuotaEnabled := ReadRegInt(LReg, 'QuotaEnabled', 0) <> 0;
      FQuotaLimit := StrToInt64Def(ReadRegString(LReg, 'QuotaLimit', '1000000'), 1000000);
      FQuotaUsed := StrToInt64Def(ReadRegString(LReg, 'QuotaUsed', '0'), 0);
      FQuotaCycleStart := ReadRegDouble(LReg, 'QuotaCycleStart', Now);
      FActiveSessionId := ReadRegString(LReg, 'ActiveSessionId', '');
      
      FAutocompleteEnabled := ReadRegInt(LReg, 'AutocompleteEnabled', 1) <> 0;
      FAutocompleteProvider := 'Gemini';
      if LReg.ValueExists('AutocompleteProvider') then
      begin
        if LReg.GetDataType('AutocompleteProvider') = rdString then
          FAutocompleteProvider := LReg.ReadString('AutocompleteProvider');
      end;
      FAutocompleteModel := ReadRegString(LReg, 'AutocompleteModel', 'gemini-1.5-flash');
      FAutocompleteDelay := ReadRegInt(LReg, 'AutocompleteDelay', 300);
      
      LReg.CloseKey;

      CheckAndResetQuotaCycle;
      TLogger.Configure(FLogEnabled, FLogPath, FLogMaxSizeKB);
    end
    else
      LogDebug('TRadIAConfig.Load: Failed to open root path ' + APath);

    { Initialize default fallback models before loading subkeys }
    LProviders := TProviderRegistry.GetProviders;
    for LMeta in LProviders do
    begin
      if Length(LMeta.DefaultModels) > 0 then
        FModelsList.Values[LMeta.Id.ToLower] := LMeta.DefaultModels[0];
    end;

    { 2. Ler configurações específicas de cada provedor registrado em suas respectivas subchaves }
    LSubKeys := TStringList.Create;
    try
      if LReg.OpenKeyReadOnly(APath) then
      begin
        LReg.GetKeyNames(LSubKeys);
        LReg.CloseKey;
      end;

      for LSubKey in LSubKeys do
      begin
        LProvPath := APath + '\' + LSubKey;
        LogDebug('TRadIAConfig.Load: Reading subkey for provider ' + LSubKey);
        if LReg.OpenKeyReadOnly(LProvPath) then
        begin
          { Load API Key }
          if LReg.ValueExists('ApiKey') then
          begin
            try
              FApiKeysList.Values[LSubKey.ToLower] := UnprotectString(LReg.ReadString('ApiKey'));
            except
              FApiKeysList.Values[LSubKey.ToLower] := '';
            end;
          end;

          { Load Model }
          if LReg.ValueExists('Model') then
            FModelsList.Values[LSubKey.ToLower] := LReg.ReadString('Model')
          else if LReg.ValueExists('ActiveModel') then
            FModelsList.Values[LSubKey.ToLower] := LReg.ReadString('ActiveModel');

          { Load BaseURL }
          if LReg.ValueExists('BaseURL') then
          begin
            FBaseUrlsList.Values[LSubKey.ToLower] := LReg.ReadString('BaseURL');
            { Sync BaseURLs to legacy fields for backward compatibility }
            if SameText(LSubKey, 'openai') then
              FOpenAICustomBaseUrl := LReg.ReadString('BaseURL')
            else if SameText(LSubKey, 'ollama') then
              FOllamaBaseUrl := LReg.ReadString('BaseURL');
          end;

          { Load advanced numeric parameters }
          FTemperaturesList.Values[LSubKey.ToLower] := FloatToStr(ReadRegDouble(LReg, 'Temperature', 0.7), TFormatSettings.Invariant);
          FMaxTokensList.Values[LSubKey.ToLower] := IntToStr(ReadRegInt(LReg, 'MaxTokens', 2048));
          FTimeoutsList.Values[LSubKey.ToLower] := IntToStr(ReadRegInt(LReg, 'Timeout', 60));

          LReg.CloseKey;
        end;
      end;
    finally
      LSubKeys.Free;
    end;
  finally
    LReg.Free;
  end;
end;

function TRadIAConfig.ProtectString(const AValue: string): string;
var
  LInBlob, LOutBlob: TDataBlob;
  LBytes: TBytes;
begin
  Result := '';
  if AValue.IsEmpty then
    Exit;

  LBytes := TEncoding.UTF8.GetBytes(AValue);
  LInBlob.cbData := Length(LBytes);
  LInBlob.pbData := @LBytes[0];

  if CryptProtectData(@LInBlob, nil, nil, nil, nil, 0, @LOutBlob) then
  begin
    try
      Result := TNetEncoding.Base64.EncodeBytesToString(LOutBlob.pbData, LOutBlob.cbData);
      Result := Result.Replace(#13, '').Replace(#10, '');
    finally
      LocalFree(HLOCAL(LOutBlob.pbData));
    end;
  end;
end;

procedure TRadIAConfig.Save;
begin
  SaveToPath(GetRegistryPath);
end;

procedure TRadIAConfig.SaveToPath(const APath: string);
var
  LReg: TRegistry;
  LKey: string;
  LProvPath: string;
  LProviders: TArray<TProviderMetadata>;
  LMeta: TProviderMetadata;
begin
  LogDebug('TRadIAConfig.Save starting. Path = ' + APath);
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    
    { 1. Salvar chaves globais na raiz }
    if LReg.OpenKey(APath, True) then
    begin
      LReg.WriteString('ActiveProvider', FActiveProvider);
      LReg.WriteString('SystemPrompt', FSystemPrompt);
      LReg.WriteInteger('MaxHistoryMessages', FMaxHistoryMessages);
      LReg.WriteInteger('SmartConfigEnabled', IfThen(FSmartConfigEnabled, 1, 0));
      LReg.WriteInteger('LogEnabled', IfThen(FLogEnabled, 1, 0));
      LReg.WriteString('LogPath', FLogPath);
      LReg.WriteInteger('LogMaxSizeKB', FLogMaxSizeKB);
      LReg.WriteInteger('QuotaEnabled', IfThen(FQuotaEnabled, 1, 0));
      LReg.WriteString('QuotaLimit', FQuotaLimit.ToString);
      LReg.WriteString('QuotaUsed', FQuotaUsed.ToString);
      LReg.WriteFloat('QuotaCycleStart', FQuotaCycleStart);
      LReg.WriteString('ActiveSessionId', FActiveSessionId);
      
      LReg.WriteInteger('AutocompleteEnabled', IfThen(FAutocompleteEnabled, 1, 0));
      LReg.WriteString('AutocompleteProvider', FAutocompleteProvider);
      LReg.WriteString('AutocompleteModel', FAutocompleteModel);
      LReg.WriteInteger('AutocompleteDelay', FAutocompleteDelay);
      
      { Sync legacy BaseURLs to root just in case }
      LReg.WriteString('OllamaBaseUrl', FOllamaBaseUrl);
      LReg.WriteString('OpenAICustomBaseUrl', FOpenAICustomBaseUrl);
      LReg.CloseKey;

      TLogger.Configure(FLogEnabled, FLogPath, FLogMaxSizeKB);
    end;

    { Sync memory fields to legacy URLs for consistency }
    SetProviderBaseUrl('openai', FOpenAICustomBaseUrl);
    SetProviderBaseUrl('ollama', FOllamaBaseUrl);

    { 2. Salvar chaves de todos os provedores em subchaves dedicadas }
    LProviders := TProviderRegistry.GetProviders;
    for LMeta in LProviders do
    begin
      LKey := LMeta.Id;
      LProvPath := APath + '\' + LKey;
      if LReg.OpenKey(LProvPath, True) then
      begin
        LReg.WriteString('ApiKey', ProtectString(GetApiKey(LKey)));
        LReg.WriteString('Model', GetActiveModel(LKey));

        if FBaseUrlsList.IndexOfName(LKey.ToLower) >= 0 then
          LReg.WriteString('BaseURL', GetProviderBaseUrl(LKey));

        LReg.WriteFloat('Temperature', GetTemperature(LKey));
        LReg.WriteInteger('MaxTokens', GetMaxTokens(LKey));
        LReg.WriteInteger('Timeout', GetTimeout(LKey));

        LReg.CloseKey;
        LogDebug('TRadIAConfig.Save: Saved ApiKey and Model (' + GetActiveModel(LKey) + ') for ' + LKey);
      end;
    end;
  finally
    LReg.Free;
  end;
end;

procedure TRadIAConfig.SetActiveProvider(const AProvider: string);
begin
  FActiveProvider := AProvider;
end;

procedure TRadIAConfig.SetSystemPrompt(const AValue: string);
begin
  FSystemPrompt := AValue;
end;

function TRadIAConfig.GetOllamaBaseUrl: string;
begin
  Result := FOllamaBaseUrl;
end;

procedure TRadIAConfig.SetOllamaBaseUrl(const AValue: string);
var
  LVal: string;
begin
  LVal := AValue.Trim;
  if LVal.EndsWith('/') then
    LVal := LVal.Substring(0, LVal.Length - 1);
  FOllamaBaseUrl := LVal;
  SetProviderBaseUrl('ollama', LVal);
end;

function TRadIAConfig.GetMaxHistoryMessages: Integer;
begin
  Result := FMaxHistoryMessages;
end;

procedure TRadIAConfig.SetMaxHistoryMessages(const AValue: Integer);
begin
  if AValue > 0 then
    FMaxHistoryMessages := AValue
  else
    FMaxHistoryMessages := 20;
end;

function TRadIAConfig.GetOpenAICustomBaseUrl: string;
begin
  Result := FOpenAICustomBaseUrl;
end;

procedure TRadIAConfig.SetOpenAICustomBaseUrl(const AValue: string);
var
  LVal: string;
begin
  LVal := AValue.Trim;
  if LVal.EndsWith('/') then
    LVal := LVal.Substring(0, LVal.Length - 1);
  FOpenAICustomBaseUrl := LVal;
  SetProviderBaseUrl('openai', LVal);
end;

{ Dynamic String-based getters and setters }

function TRadIAConfig.GetApiKey(const AProviderName: string): string;
begin
  if AProviderName.IsEmpty then
    Exit('');
  Result := FApiKeysList.Values[AProviderName.ToLower];
end;

procedure TRadIAConfig.SetApiKey(const AProviderName: string; const AKey: string);
begin
  if AProviderName.IsEmpty then
    Exit;
  FApiKeysList.Values[AProviderName.ToLower] := CleanApiKey(AKey);
end;

function TRadIAConfig.GetActiveModel(const AProviderName: string): string;
begin
  if AProviderName.IsEmpty then
    Exit('');
  Result := FModelsList.Values[AProviderName.ToLower];
end;

procedure TRadIAConfig.SetActiveModel(const AProviderName: string; const AModel: string);
begin
  if AProviderName.IsEmpty then
    Exit;
  FModelsList.Values[AProviderName.ToLower] := AModel;
end;

function TRadIAConfig.GetTemperature(const AProviderName: string): Double;
var
  LStr: string;
begin
  if AProviderName.IsEmpty then
    Exit(0.7);
  LStr := FTemperaturesList.Values[AProviderName.ToLower];
  Result := StrToFloatDef(LStr, 0.7, TFormatSettings.Invariant);
end;

procedure TRadIAConfig.SetTemperature(const AProviderName: string; const AValue: Double);
begin
  if AProviderName.IsEmpty then
    Exit;
  FTemperaturesList.Values[AProviderName.ToLower] := FloatToStr(AValue, TFormatSettings.Invariant);
end;

function TRadIAConfig.GetMaxTokens(const AProviderName: string): Integer;
var
  LStr: string;
begin
  if AProviderName.IsEmpty then
    Exit(2048);
  LStr := FMaxTokensList.Values[AProviderName.ToLower];
  Result := StrToIntDef(LStr, 2048);
end;

procedure TRadIAConfig.SetMaxTokens(const AProviderName: string; const AValue: Integer);
begin
  if AProviderName.IsEmpty then
    Exit;
  FMaxTokensList.Values[AProviderName.ToLower] := IntToStr(AValue);
end;

function TRadIAConfig.GetTimeout(const AProviderName: string): Integer;
var
  LStr: string;
begin
  if AProviderName.IsEmpty then
    Exit(60);
  LStr := FTimeoutsList.Values[AProviderName.ToLower];
  Result := StrToIntDef(LStr, 60);
end;

procedure TRadIAConfig.SetTimeout(const AProviderName: string; const AValue: Integer);
begin
  if AProviderName.IsEmpty then
    Exit;
  FTimeoutsList.Values[AProviderName.ToLower] := IntToStr(AValue);
end;

function TRadIAConfig.GetProviderBaseUrl(const AProviderName: string): string;
begin
  if AProviderName.IsEmpty then
    Exit('');
  Result := FBaseUrlsList.Values[AProviderName.ToLower];
end;

procedure TRadIAConfig.SetProviderBaseUrl(const AProviderName: string; const AUrl: string);
begin
  if AProviderName.IsEmpty then
    Exit;
  FBaseUrlsList.Values[AProviderName.ToLower] := AUrl;
end;

function TRadIAConfig.GetAutocompleteEnabled: Boolean;
begin
  Result := FAutocompleteEnabled;
end;

procedure TRadIAConfig.SetAutocompleteEnabled(const AValue: Boolean);
begin
  FAutocompleteEnabled := AValue;
end;

function TRadIAConfig.GetAutocompleteProvider: string;
begin
  Result := FAutocompleteProvider;
end;

procedure TRadIAConfig.SetAutocompleteProvider(const AProvider: string);
begin
  FAutocompleteProvider := AProvider;
end;

function TRadIAConfig.GetAutocompleteModel: string;
begin
  Result := FAutocompleteModel;
end;

procedure TRadIAConfig.SetAutocompleteModel(const AModel: string);
begin
  FAutocompleteModel := AModel;
end;

function TRadIAConfig.GetAutocompleteDelay: Integer;
begin
  Result := FAutocompleteDelay;
end;

procedure TRadIAConfig.SetAutocompleteDelay(const AValue: Integer);
begin
  FAutocompleteDelay := AValue;
end;

function TRadIAConfig.GetSmartConfigEnabled: Boolean;
begin
  Result := FSmartConfigEnabled;
end;

procedure TRadIAConfig.SetSmartConfigEnabled(const AValue: Boolean);
begin
  FSmartConfigEnabled := AValue;
end;

function TRadIAConfig.GetLogEnabled: Boolean;
begin
  Result := FLogEnabled;
end;

procedure TRadIAConfig.SetLogEnabled(const AValue: Boolean);
begin
  FLogEnabled := AValue;
end;

function TRadIAConfig.GetLogPath: string;
begin
  Result := FLogPath;
end;

procedure TRadIAConfig.SetLogPath(const AValue: string);
begin
  FLogPath := AValue;
end;

function TRadIAConfig.GetLogMaxSizeKB: Integer;
begin
  Result := FLogMaxSizeKB;
end;

procedure TRadIAConfig.SetLogMaxSizeKB(const AValue: Integer);
begin
  FLogMaxSizeKB := AValue;
end;

function TRadIAConfig.GetQuotaEnabled: Boolean;
begin
  Result := FQuotaEnabled;
end;

procedure TRadIAConfig.SetQuotaEnabled(const AValue: Boolean);
begin
  FQuotaEnabled := AValue;
end;

function TRadIAConfig.GetQuotaLimit: Int64;
begin
  Result := FQuotaLimit;
end;

procedure TRadIAConfig.SetQuotaLimit(const AValue: Int64);
begin
  FQuotaLimit := AValue;
end;

function TRadIAConfig.GetQuotaUsed: Int64;
begin
  Result := FQuotaUsed;
end;

procedure TRadIAConfig.SetQuotaUsed(const AValue: Int64);
begin
  FQuotaUsed := AValue;
end;

function TRadIAConfig.GetQuotaCycleStart: TDateTime;
begin
  Result := FQuotaCycleStart;
end;

procedure TRadIAConfig.SetQuotaCycleStart(const AValue: TDateTime);
begin
  FQuotaCycleStart := AValue;
end;

function TRadIAConfig.GetActiveSessionId: string;
begin
  Result := FActiveSessionId;
end;

procedure TRadIAConfig.SetActiveSessionId(const AValue: string);
begin
  FActiveSessionId := AValue;
end;

procedure TRadIAConfig.AddToQuotaUsage(const AUsage: TTokenUsage);
begin
  if not FQuotaEnabled then
    Exit;
    
  CheckAndResetQuotaCycle;
  FQuotaUsed := FQuotaUsed + AUsage.TotalTokens;
  Save;
end;

procedure TRadIAConfig.CheckAndResetQuotaCycle;
var
  LYear, LMonth, LDay: Word;
  LCycleYear, LCycleMonth, LCycleDay: Word;
begin
  DecodeDate(Now, LYear, LMonth, LDay);
  DecodeDate(FQuotaCycleStart, LCycleYear, LCycleMonth, LCycleDay);
  
  if (LYear <> LCycleYear) or (LMonth <> LCycleMonth) then
  begin
    FQuotaUsed := 0;
    FQuotaCycleStart := Now;
    Save;
  end;
end;

function TRadIAConfig.UnprotectString(const AValue: string): string;
var
  LInBlob, LOutBlob: TDataBlob;
  LBytes: TBytes;
begin
  Result := '';
  if AValue.IsEmpty then
    Exit;

  LogDebug('TRadIAConfig.UnprotectString: Input string length: ' + IntToStr(Length(AValue)));
  try
    LBytes := TNetEncoding.Base64.DecodeStringToBytes(AValue);
  except
    on E: Exception do
    begin
      LogDebug('TRadIAConfig.UnprotectString: Base64 decode failed: ' + E.Message);
      Exit;
    end;
  end;

  if Length(LBytes) = 0 then
  begin
    LogDebug('TRadIAConfig.UnprotectString: Base64 decoded bytes length is 0');
    Exit;
  end;

  LInBlob.cbData := Length(LBytes);
  LInBlob.pbData := @LBytes[0];

  if CryptUnprotectData(@LInBlob, nil, nil, nil, nil, 0, @LOutBlob) then
  begin
    try
      SetLength(LBytes, LOutBlob.cbData);
      Move(LOutBlob.pbData^, LBytes[0], LOutBlob.cbData);
      Result := CleanApiKey(TEncoding.UTF8.GetString(LBytes));
      LogDebug('TRadIAConfig.UnprotectString: Decrypted and cleaned successfully. Result length: ' + IntToStr(Length(Result)));
    finally
      LocalFree(HLOCAL(LOutBlob.pbData));
    end;
  end;
end;

class function TRadIAConfig.GetInstance: IAIConfig;
begin
  if FInstance = nil then
    FInstance := TRadIAConfig.Create;
  Result := FInstance;
end;

function TRadIAConfig._AddRef: Integer;
begin
  Result := -1;
end;

function TRadIAConfig._Release: Integer;
begin
  Result := -1;
end;

initialization

finalization
  if Assigned(TRadIAConfig.FInstance) then
    FreeAndNil(TRadIAConfig.FInstance);

end.
