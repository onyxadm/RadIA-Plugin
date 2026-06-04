unit RadIA.Core.Config;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Interfaces, RadIA.Core.Types;

type
  TRadIAConfig = class(TInterfacedObject, IAIConfig)
  private
    class var FBaseRegistryPath: string;
    FApiKeys: array[TAIProviderType] of string;
    FActiveProvider: TAIProviderType;
    FActiveModels: array[TAIProviderType] of string;
    FSystemPrompt: string;
    FOllamaBaseUrl: string;
    FMaxHistoryMessages: Integer;
    FOpenAICustomBaseUrl: string;
    FTemperatures: array[TAIProviderType] of Double;
    FMaxTokens: array[TAIProviderType] of Integer;
    FTimeouts: array[TAIProviderType] of Integer;
    FSmartConfigEnabled: Boolean;

    procedure LoadFromPath(const APath: string);
    procedure SaveToPath(const APath: string);
    function ProtectString(const AValue: string): string;
    function UnprotectString(const AValue: string): string;
    function ReadRegString(const AReg: TObject; const AKey: string; const ADefault: string): string;
    function ReadRegInt(const AReg: TObject; const AKey: string; const ADefault: Integer): Integer;
    function ReadRegDouble(const AReg: TObject; const AKey: string; const ADefault: Double): Double;
  public
    constructor Create;
    class procedure SetBaseRegistryPath(const APath: string);
    class function GetRegistryPath: string;

    { IAIConfig implementation }
    function GetApiKey(const AProvider: TAIProviderType): string;
    procedure SetApiKey(const AProvider: TAIProviderType; const AKey: string);
    function GetActiveProvider: TAIProviderType;
    procedure SetActiveProvider(const AProvider: TAIProviderType);
    function GetActiveModel(const AProvider: TAIProviderType): string;
    procedure SetActiveModel(const AProvider: TAIProviderType; const AModel: string);
    function GetSystemPrompt: string;
    procedure SetSystemPrompt(const AValue: string);
    function GetOllamaBaseUrl: string;
    procedure SetOllamaBaseUrl(const AValue: string);
    function GetMaxHistoryMessages: Integer;
    procedure SetMaxHistoryMessages(const AValue: Integer);
    function GetOpenAICustomBaseUrl: string;
    procedure SetOpenAICustomBaseUrl(const AValue: string);
    function GetTemperature(const AProvider: TAIProviderType): Double;
    procedure SetTemperature(const AProvider: TAIProviderType; const AValue: Double);
    function GetMaxTokens(const AProvider: TAIProviderType): Integer;
    procedure SetMaxTokens(const AProvider: TAIProviderType; const AValue: Integer);
    function GetTimeout(const AProvider: TAIProviderType): Integer;
    procedure SetTimeout(const AProvider: TAIProviderType; const AValue: Integer);
    function GetSmartConfigEnabled: Boolean;
    procedure SetSmartConfigEnabled(const AValue: Boolean);
    procedure Save;
    procedure Load;
  end;

implementation

uses
  Winapi.Windows, System.Win.Registry, System.NetEncoding, System.Math, System.IOUtils, ToolsAPI;

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
var
  LFolder: string;
  LFile: string;
  LStream: TFileStream;
  LWriter: TStreamWriter;
  LText: string;
begin
  try
    LFolder := IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) + 'RadIA';
    ForceDirectories(LFolder);
    LFile := LFolder + '\log.txt';
    
    if FileExists(LFile) then
      LStream := TFileStream.Create(LFile, fmOpenWrite or fmShareDenyNone)
    else
      LStream := TFileStream.Create(LFile, fmCreate or fmShareDenyNone);
      
    try
      LStream.Seek(0, soEnd);
      LWriter := TStreamWriter.Create(LStream, TEncoding.UTF8);
      try
        LText := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' - ' + AMsg;
        LWriter.WriteLine(LText);
      finally
        LWriter.Free;
      end;
    finally
      LStream.Free;
    end;
  except
    // Silently capture any file access exception to prevent IDE crash on plugin start
  end;
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
var
  LProvider: TAIProviderType;
begin
  inherited Create;
  
  LogDebug('TRadIAConfig.Create: Active path = ' + GetRegistryPath);

  FActiveProvider := ptGemini;
  FApiKeys[ptGemini] := '';
  FApiKeys[ptOpenAI] := '';
  FApiKeys[ptClaude] := '';
  FApiKeys[ptOllama] := '';
  FApiKeys[ptDeepSeek] := '';
  FApiKeys[ptGroq] := '';
  FActiveModels[ptGemini] := MODEL_GEMINI_15_FLASH;
  FActiveModels[ptOpenAI] := MODEL_OPENAI_GPT4O_MINI;
  FActiveModels[ptClaude] := MODEL_CLAUDE_3_HAIKU;
  FActiveModels[ptOllama] := 'llama3:latest';
  FActiveModels[ptDeepSeek] := MODEL_DEEPSEEK_CHAT;
  FActiveModels[ptGroq] := MODEL_GROQ_LLAMA33;
  FSystemPrompt := '';
  FOllamaBaseUrl := 'http://localhost:11434';
  FMaxHistoryMessages := 20;
  FOpenAICustomBaseUrl := '';
  
  FSmartConfigEnabled := True;
  for LProvider := Low(TAIProviderType) to High(TAIProviderType) do
  begin
    FTemperatures[LProvider] := 0.7;
    FMaxTokens[LProvider] := 2048;
    FTimeouts[LProvider] := 60;
  end;
  
  Load;
end;

class procedure TRadIAConfig.SetBaseRegistryPath(const APath: string);
begin
  FBaseRegistryPath := APath;
end;

function TRadIAConfig.GetActiveModel(const AProvider: TAIProviderType): string;
begin
  Result := FActiveModels[AProvider];
end;

function TRadIAConfig.GetActiveProvider: TAIProviderType;
begin
  Result := FActiveProvider;
end;

function TRadIAConfig.GetApiKey(const AProvider: TAIProviderType): string;
begin
  Result := FApiKeys[AProvider];
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
  LProvider: TAIProviderType;
  LProvStr: string;
  LProvPath: string;
  LMaxHist: Integer;
  LMigratedPath: string;
  LParentPath: string;
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
      LReg.CloseKey;
    end
    else
      LogDebug('TRadIAConfig.Load: Failed to open root path ' + APath);

    { 2. Ler configurações específicas de cada provedor em suas respectivas subchaves }
    for LProvider := Low(TAIProviderType) to High(TAIProviderType) do
    begin
      LProvStr := ProviderTypeToString(LProvider);
      LProvPath := APath + '\' + LProvStr;

      LogDebug('TRadIAConfig.Load: Reading subkey for provider ' + LProvStr);
      if LReg.OpenKeyReadOnly(LProvPath) then
      begin
        LogDebug('TRadIAConfig.Load: Opened subkey ' + LProvPath);
        { Load API Key from Subkey }
        try
          if LReg.ValueExists('ApiKey') then
          begin
            LogDebug('TRadIAConfig.Load: ApiKey value exists in subkey for ' + LProvStr);
            FApiKeys[LProvider] := UnprotectString(LReg.ReadString('ApiKey'));
          end
          else
          begin
            LogDebug('TRadIAConfig.Load: ApiKey value does NOT exist in subkey for ' + LProvStr);
            FApiKeys[LProvider] := '';
          end;
        except
          on E: Exception do
          begin
            LogDebug('TRadIAConfig.Load: Exception reading ApiKey from subkey: ' + E.Message);
            FApiKeys[LProvider] := '';
          end;
        end;

        { Load Active Model from Subkey }
        try
          if LReg.ValueExists('Model') then
          begin
            FActiveModels[LProvider] := LReg.ReadString('Model');
            LogDebug('TRadIAConfig.Load: Loaded Model ' + FActiveModels[LProvider] + ' for ' + LProvStr);
          end
          else if LReg.ValueExists('ActiveModel') then
          begin
            FActiveModels[LProvider] := LReg.ReadString('ActiveModel');
            LogDebug('TRadIAConfig.Load: Loaded ActiveModel ' + FActiveModels[LProvider] + ' for ' + LProvStr);
          end;
        except
          on E: Exception do
            LogDebug('TRadIAConfig.Load: Exception reading Model from subkey: ' + E.Message);
        end;

        { Load BaseURL from Subkey }
        if LReg.ValueExists('BaseURL') then
        begin
          if LProvider = ptOpenAI then
          begin
            FOpenAICustomBaseUrl := LReg.ReadString('BaseURL');
            LogDebug('TRadIAConfig.Load: Loaded BaseURL ' + FOpenAICustomBaseUrl + ' for OpenAI');
          end
          else if LProvider = ptOllama then
          begin
            FOllamaBaseUrl := LReg.ReadString('BaseURL');
            LogDebug('TRadIAConfig.Load: Loaded BaseURL ' + FOllamaBaseUrl + ' for Ollama');
          end;
        end;

        FTemperatures[LProvider] := ReadRegDouble(LReg, 'Temperature', 0.7);
        FMaxTokens[LProvider] := ReadRegInt(LReg, 'MaxTokens', 2048);
        FTimeouts[LProvider] := ReadRegInt(LReg, 'Timeout', 60);

        LReg.CloseKey;
      end;
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
  LProvider: TAIProviderType;
  LProvStr: string;
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
      LReg.CloseKey;
    end;

    { 2. Salvar chaves de cada provedor em subchaves dedicadas }
    for LProvider := Low(TAIProviderType) to High(TAIProviderType) do
    begin
      LProvStr := ProviderTypeToString(LProvider);
      LProvPath := APath + '\' + LProvStr;

      if LReg.OpenKey(LProvPath, True) then
      begin
        LReg.WriteString('ApiKey', ProtectString(FApiKeys[LProvider]));
        LReg.WriteString('Model', FActiveModels[LProvider]);

        { Save BaseURL for OpenAI Custom and Ollama }
        if LProvider = ptOpenAI then
          LReg.WriteString('BaseURL', FOpenAICustomBaseUrl)
        else if LProvider = ptOllama then
          LReg.WriteString('BaseURL', FOllamaBaseUrl);

        LReg.WriteFloat('Temperature', FTemperatures[LProvider]);
        LReg.WriteInteger('MaxTokens', FMaxTokens[LProvider]);
        LReg.WriteInteger('Timeout', FTimeouts[LProvider]);

        LReg.CloseKey;
        LogDebug('TRadIAConfig.Save: Saved ApiKey and Model (' + FActiveModels[LProvider] + ') for ' + LProvStr);
      end;
    end;
  finally
    LReg.Free;
  end;
end;

procedure TRadIAConfig.SetActiveModel(const AProvider: TAIProviderType; const AModel: string);
begin
  FActiveModels[AProvider] := AModel;
end;

procedure TRadIAConfig.SetActiveProvider(const AProvider: TAIProviderType);
begin
  FActiveProvider := AProvider;
end;

procedure TRadIAConfig.SetApiKey(const AProvider: TAIProviderType; const AKey: string);
begin
  FApiKeys[AProvider] := CleanApiKey(AKey);
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
begin
  FOllamaBaseUrl := AValue;
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
begin
  FOpenAICustomBaseUrl := AValue;
end;

function TRadIAConfig.GetTemperature(const AProvider: TAIProviderType): Double;
begin
  Result := FTemperatures[AProvider];
end;

procedure TRadIAConfig.SetTemperature(const AProvider: TAIProviderType; const AValue: Double);
begin
  FTemperatures[AProvider] := AValue;
end;

function TRadIAConfig.GetMaxTokens(const AProvider: TAIProviderType): Integer;
begin
  Result := FMaxTokens[AProvider];
end;

procedure TRadIAConfig.SetMaxTokens(const AProvider: TAIProviderType; const AValue: Integer);
begin
  FMaxTokens[AProvider] := AValue;
end;

function TRadIAConfig.GetTimeout(const AProvider: TAIProviderType): Integer;
begin
  Result := FTimeouts[AProvider];
end;

procedure TRadIAConfig.SetTimeout(const AProvider: TAIProviderType; const AValue: Integer);
begin
  FTimeouts[AProvider] := AValue;
end;

function TRadIAConfig.GetSmartConfigEnabled: Boolean;
begin
  Result := FSmartConfigEnabled;
end;

procedure TRadIAConfig.SetSmartConfigEnabled(const AValue: Boolean);
begin
  FSmartConfigEnabled := AValue;
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
