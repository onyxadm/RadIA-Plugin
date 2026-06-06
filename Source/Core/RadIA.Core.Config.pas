unit RadIA.Core.Config;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.TokenUsage;

type
  TRadIAConfig = class(TInterfacedObject, IAIConfig)
  private
    class var FBaseRegistryPath: string;
    FActiveProvider: TAIProviderType;
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

    { Dynamic String-based Dictionaries for settings }
    FDynamicApiKeys: System.Generics.Collections.TDictionary<string, string>;
    FDynamicModels: System.Generics.Collections.TDictionary<string, string>;
    FDynamicTemperatures: System.Generics.Collections.TDictionary<string, Double>;
    FDynamicMaxTokens: System.Generics.Collections.TDictionary<string, Integer>;
    FDynamicTimeouts: System.Generics.Collections.TDictionary<string, Integer>;
    FDynamicBaseUrls: System.Generics.Collections.TDictionary<string, string>;

    procedure LoadFromPath(const APath: string);
    procedure SaveToPath(const APath: string);
    function ProtectString(const AValue: string): string;
    function UnprotectString(const AValue: string): string;
    function ReadRegString(const AReg: TObject; const AKey: string; const ADefault: string): string;
    function ReadRegInt(const AReg: TObject; const AKey: string; const ADefault: Integer): Integer;
    function ReadRegDouble(const AReg: TObject; const AKey: string; const ADefault: Double): Double;
    procedure CheckAndResetQuotaCycle;
  public
    constructor Create;
    destructor Destroy; override;
    class procedure SetBaseRegistryPath(const APath: string);
    class function GetRegistryPath: string;

    { IAIConfig implementation }
    function GetApiKey(const AProvider: TAIProviderType): string; overload;
    procedure SetApiKey(const AProvider: TAIProviderType; const AKey: string); overload;
    function GetActiveProvider: TAIProviderType;
    procedure SetActiveProvider(const AProvider: TAIProviderType);
    function GetActiveModel(const AProvider: TAIProviderType): string; overload;
    procedure SetActiveModel(const AProvider: TAIProviderType; const AModel: string); overload;
    function GetSystemPrompt: string;
    procedure SetSystemPrompt(const AValue: string);
    function GetOllamaBaseUrl: string;
    procedure SetOllamaBaseUrl(const AValue: string);
    function GetMaxHistoryMessages: Integer;
    procedure SetMaxHistoryMessages(const AValue: Integer);
    function GetOpenAICustomBaseUrl: string;
    procedure SetOpenAICustomBaseUrl(const AValue: string);
    function GetTemperature(const AProvider: TAIProviderType): Double; overload;
    procedure SetTemperature(const AProvider: TAIProviderType; const AValue: Double); overload;
    function GetMaxTokens(const AProvider: TAIProviderType): Integer; overload;
    procedure SetMaxTokens(const AProvider: TAIProviderType; const AValue: Integer); overload;
    function GetTimeout(const AProvider: TAIProviderType): Integer; overload;
    procedure SetTimeout(const AProvider: TAIProviderType; const AValue: Integer); overload;

    { String-based dynamic provider APIs }
    function GetApiKey(const AProviderName: string): string; overload;
    procedure SetApiKey(const AProviderName: string; const AKey: string); overload;
    function GetActiveModel(const AProviderName: string): string; overload;
    procedure SetActiveModel(const AProviderName: string; const AModel: string); overload;
    function GetTemperature(const AProviderName: string): Double; overload;
    procedure SetTemperature(const AProviderName: string; const AValue: Double); overload;
    function GetMaxTokens(const AProviderName: string): Integer; overload;
    procedure SetMaxTokens(const AProviderName: string; const AValue: Integer); overload;
    function GetTimeout(const AProviderName: string): Integer; overload;
    procedure SetTimeout(const AProviderName: string; const AValue: Integer); overload;
    function GetProviderBaseUrl(const AProviderName: string): string;
    procedure SetProviderBaseUrl(const AProviderName: string; const AUrl: string);

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
  RadIA.Core.Logger;

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

  FDynamicApiKeys := System.Generics.Collections.TDictionary<string, string>.Create;
  FDynamicModels := System.Generics.Collections.TDictionary<string, string>.Create;
  FDynamicTemperatures := System.Generics.Collections.TDictionary<string, Double>.Create;
  FDynamicMaxTokens := System.Generics.Collections.TDictionary<string, Integer>.Create;
  FDynamicTimeouts := System.Generics.Collections.TDictionary<string, Integer>.Create;
  FDynamicBaseUrls := System.Generics.Collections.TDictionary<string, string>.Create;

  FActiveProvider := ptGemini;
  FSystemPrompt := '';
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
  
  Load;
end;

destructor TRadIAConfig.Destroy;
begin
  FDynamicApiKeys.Free;
  FDynamicModels.Free;
  FDynamicTemperatures.Free;
  FDynamicMaxTokens.Free;
  FDynamicTimeouts.Free;
  FDynamicBaseUrls.Free;
  inherited Destroy;
end;

class procedure TRadIAConfig.SetBaseRegistryPath(const APath: string);
begin
  FBaseRegistryPath := APath;
end;

function TRadIAConfig.GetActiveModel(const AProvider: TAIProviderType): string;
begin
  Result := GetActiveModel(ProviderTypeToString(AProvider));
end;

function TRadIAConfig.GetActiveProvider: TAIProviderType;
begin
  Result := FActiveProvider;
end;

function TRadIAConfig.GetApiKey(const AProvider: TAIProviderType): string;
begin
  Result := GetApiKey(ProviderTypeToString(AProvider));
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
  LProv: TAIProviderType;
  LProvStr: string;
  LProvPath: string;
  LMaxHist: Integer;
  LMigratedPath: string;
  LParentPath: string;
  LSubKeys: TStringList;
  LSubKey: string;
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
      FActiveProvider    := TAIProviderType(ReadRegInt(LReg, 'ActiveProvider', Integer(ptGemini)));
      FSystemPrompt      := ReadRegString(LReg, 'SystemPrompt', '');
      
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
      LReg.CloseKey;

      CheckAndResetQuotaCycle;
      TLogger.Configure(FLogEnabled, FLogPath, FLogMaxSizeKB);
    end
    else
      LogDebug('TRadIAConfig.Load: Failed to open root path ' + APath);

    { Initialize default fallback models before loading subkeys }
    FDynamicModels.AddOrSetValue('gemini', MODEL_GEMINI_15_FLASH);
    FDynamicModels.AddOrSetValue('openai', MODEL_OPENAI_GPT4O_MINI);
    FDynamicModels.AddOrSetValue('claude', MODEL_CLAUDE_3_HAIKU);
    FDynamicModels.AddOrSetValue('ollama', 'llama3:latest');
    FDynamicModels.AddOrSetValue('deepseek', MODEL_DEEPSEEK_CHAT);
    FDynamicModels.AddOrSetValue('groq', MODEL_GROQ_LLAMA33);
    FDynamicModels.AddOrSetValue('openrouter', MODEL_OPENROUTER_GEMINI25_PRO);

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
              FDynamicApiKeys.AddOrSetValue(LSubKey.ToLower, UnprotectString(LReg.ReadString('ApiKey')));
            except
              FDynamicApiKeys.AddOrSetValue(LSubKey.ToLower, '');
            end;
          end;

          { Load Model }
          if LReg.ValueExists('Model') then
            FDynamicModels.AddOrSetValue(LSubKey.ToLower, LReg.ReadString('Model'))
          else if LReg.ValueExists('ActiveModel') then
            FDynamicModels.AddOrSetValue(LSubKey.ToLower, LReg.ReadString('ActiveModel'));

          { Load BaseURL }
          if LReg.ValueExists('BaseURL') then
          begin
            FDynamicBaseUrls.AddOrSetValue(LSubKey.ToLower, LReg.ReadString('BaseURL'));
            { Sync BaseURLs to legacy fields for backward compatibility }
            if SameText(LSubKey, 'openai') then
              FOpenAICustomBaseUrl := LReg.ReadString('BaseURL')
            else if SameText(LSubKey, 'ollama') then
              FOllamaBaseUrl := LReg.ReadString('BaseURL');
          end;

          { Load advanced numeric parameters }
          FDynamicTemperatures.AddOrSetValue(LSubKey.ToLower, ReadRegDouble(LReg, 'Temperature', 0.7));
          FDynamicMaxTokens.AddOrSetValue(LSubKey.ToLower, ReadRegInt(LReg, 'MaxTokens', 2048));
          FDynamicTimeouts.AddOrSetValue(LSubKey.ToLower, ReadRegInt(LReg, 'Timeout', 60));

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
begin
  LogDebug('TRadIAConfig.Save starting. Path = ' + APath);
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    
    { 1. Salvar chaves globais na raiz }
    if LReg.OpenKey(APath, True) then
    begin
      LReg.WriteInteger('ActiveProvider', Integer(FActiveProvider));
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
      
      { Sync legacy BaseURLs to root just in case }
      LReg.WriteString('OllamaBaseUrl', FOllamaBaseUrl);
      LReg.WriteString('OpenAICustomBaseUrl', FOpenAICustomBaseUrl);
      LReg.CloseKey;

      TLogger.Configure(FLogEnabled, FLogPath, FLogMaxSizeKB);
    end;

    { Sync memory fields to legacy URLs for consistency }
    SetProviderBaseUrl('openai', FOpenAICustomBaseUrl);
    SetProviderBaseUrl('ollama', FOllamaBaseUrl);

    { 2. Salvar chaves de todos os provedores em subchaves baseados no dicionário de chaves }
    for LKey in FDynamicApiKeys.Keys do
    begin
      LProvPath := APath + '\' + LKey;
      if LReg.OpenKey(LProvPath, True) then
      begin
        LReg.WriteString('ApiKey', ProtectString(GetApiKey(LKey)));
        LReg.WriteString('Model', GetActiveModel(LKey));

        if FDynamicBaseUrls.ContainsKey(LKey) then
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

procedure TRadIAConfig.SetActiveModel(const AProvider: TAIProviderType; const AModel: string);
begin
  SetActiveModel(ProviderTypeToString(AProvider), AModel);
end;

procedure TRadIAConfig.SetActiveProvider(const AProvider: TAIProviderType);
begin
  FActiveProvider := AProvider;
end;

procedure TRadIAConfig.SetApiKey(const AProvider: TAIProviderType; const AKey: string);
begin
  SetApiKey(ProviderTypeToString(AProvider), AKey);
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

function TRadIAConfig.GetTemperature(const AProvider: TAIProviderType): Double;
begin
  Result := GetTemperature(ProviderTypeToString(AProvider));
end;

procedure TRadIAConfig.SetTemperature(const AProvider: TAIProviderType; const AValue: Double);
begin
  SetTemperature(ProviderTypeToString(AProvider), AValue);
end;

function TRadIAConfig.GetMaxTokens(const AProvider: TAIProviderType): Integer;
begin
  Result := GetMaxTokens(ProviderTypeToString(AProvider));
end;

procedure TRadIAConfig.SetMaxTokens(const AProvider: TAIProviderType; const AValue: Integer);
begin
  SetMaxTokens(ProviderTypeToString(AProvider), AValue);
end;

function TRadIAConfig.GetTimeout(const AProvider: TAIProviderType): Integer;
begin
  Result := GetTimeout(ProviderTypeToString(AProvider));
end;

procedure TRadIAConfig.SetTimeout(const AProvider: TAIProviderType; const AValue: Integer);
begin
  SetTimeout(ProviderTypeToString(AProvider), AValue);
end;

{ Dynamic String-based getters and setters }

function TRadIAConfig.GetApiKey(const AProviderName: string): string;
begin
  if not FDynamicApiKeys.TryGetValue(AProviderName.ToLower, Result) then
    Result := '';
end;

procedure TRadIAConfig.SetApiKey(const AProviderName: string; const AKey: string);
begin
  FDynamicApiKeys.AddOrSetValue(AProviderName.ToLower, CleanApiKey(AKey));
end;

function TRadIAConfig.GetActiveModel(const AProviderName: string): string;
begin
  if not FDynamicModels.TryGetValue(AProviderName.ToLower, Result) then
    Result := '';
end;

procedure TRadIAConfig.SetActiveModel(const AProviderName: string; const AModel: string);
begin
  FDynamicModels.AddOrSetValue(AProviderName.ToLower, AModel);
end;

function TRadIAConfig.GetTemperature(const AProviderName: string): Double;
begin
  if not FDynamicTemperatures.TryGetValue(AProviderName.ToLower, Result) then
    Result := 0.7;
end;

procedure TRadIAConfig.SetTemperature(const AProviderName: string; const AValue: Double);
begin
  FDynamicTemperatures.AddOrSetValue(AProviderName.ToLower, AValue);
end;

function TRadIAConfig.GetMaxTokens(const AProviderName: string): Integer;
begin
  if not FDynamicMaxTokens.TryGetValue(AProviderName.ToLower, Result) then
    Result := 2048;
end;

procedure TRadIAConfig.SetMaxTokens(const AProviderName: string; const AValue: Integer);
begin
  FDynamicMaxTokens.AddOrSetValue(AProviderName.ToLower, AValue);
end;

function TRadIAConfig.GetTimeout(const AProviderName: string): Integer;
begin
  if not FDynamicTimeouts.TryGetValue(AProviderName.ToLower, Result) then
    Result := 60;
end;

procedure TRadIAConfig.SetTimeout(const AProviderName: string; const AValue: Integer);
begin
  FDynamicTimeouts.AddOrSetValue(AProviderName.ToLower, AValue);
end;

function TRadIAConfig.GetProviderBaseUrl(const AProviderName: string): string;
begin
  if not FDynamicBaseUrls.TryGetValue(AProviderName.ToLower, Result) then
    Result := '';
end;

procedure TRadIAConfig.SetProviderBaseUrl(const AProviderName: string; const AUrl: string);
begin
  FDynamicBaseUrls.AddOrSetValue(AProviderName.ToLower, AUrl);
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

end.
