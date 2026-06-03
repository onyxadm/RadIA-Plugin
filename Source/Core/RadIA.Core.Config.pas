unit RadIA.Core.Config;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Interfaces, RadIA.Core.Types;

type
  TRadIAConfig = class(TInterfacedObject, IAIConfig)
  private
    class var FBaseRegistryPath: string;
    FRegistryPath: string;
    FApiKeys: array[TAIProviderType] of string;
    FActiveProvider: TAIProviderType;
    FActiveModels: array[TAIProviderType] of string;
    FSystemPrompt: string;
    FOllamaBaseUrl: string;
    FMaxHistoryMessages: Integer;
    FOpenAICustomBaseUrl: string;

    function ProtectString(const AValue: string): string;
    function UnprotectString(const AValue: string): string;
    function ReadRegString(const AReg: TObject; const AKey: string; const ADefault: string): string;
    function ReadRegInt(const AReg: TObject; const AKey: string; const ADefault: Integer): Integer;
  public
    constructor Create;
    class procedure SetBaseRegistryPath(const APath: string);

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
    procedure Save;
    procedure Load;
  end;

implementation

uses
  Winapi.Windows, System.Win.Registry, System.NetEncoding, System.Math;

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

constructor TRadIAConfig.Create;
var
  LSettings: TFormatSettings;
  LBdsVersion: Double;
begin
  inherited Create;
  LSettings := TFormatSettings.Create('en-US');
  if FBaseRegistryPath.IsEmpty then
  begin
    { Delphi BDS version in registry is always compiler version minus 13.0, }
    { except from Delphi 13 (CompilerVersion 37.0) onwards where it matches CompilerVersion }
    if CompilerVersion >= 37.0 then
      LBdsVersion := CompilerVersion
    else
      LBdsVersion := CompilerVersion - 13.0;
      
    FRegistryPath := Format('Software\Embarcadero\BDS\%0.1f\AIPlugin', [LBdsVersion], LSettings);
  end
  else
    FRegistryPath := FBaseRegistryPath;
    
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

procedure TRadIAConfig.Load;
var
  LReg: TRegistry;
  LProvider: TAIProviderType;
  LProvStr: string;
  LProvPath: string;
  LMaxHist: Integer;
  LMigratedPath: string;
  LParentPath: string;
  LOldPath: string;
begin
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    
    { Se a nova chave não existe, tenta fazer a migração das chaves legadas }
    if not LReg.KeyExists(FRegistryPath) then
    begin
      LMigratedPath := '';
      
      { 1. Se o caminho possui contra-barra, tenta migrar caminhos relativos à IDE }
      if Pos('\', FRegistryPath) > 0 then
      begin
        LParentPath := Copy(FRegistryPath, 1, LastDelimiter('\', FRegistryPath));
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

      if not LMigratedPath.IsEmpty and (LMigratedPath <> FRegistryPath) then
      begin
        LOldPath := FRegistryPath;
        FRegistryPath := LMigratedPath;
        try
          Load;
        finally
          FRegistryPath := LOldPath;
        end;
        Save;
      end;
    end;

    { 1. Ler chaves globais da raiz (AIPlugin) }
    if LReg.OpenKeyReadOnly(FRegistryPath) then
    begin
      FActiveProvider    := TAIProviderType(ReadRegInt(LReg, 'ActiveProvider', Integer(ptGemini)));
      FSystemPrompt      := ReadRegString(LReg, 'SystemPrompt', '');
      
      { Fallback temporário das chaves legadas da raiz caso o usuário ainda não as tenha salvado nas subchaves }
      FOllamaBaseUrl     := ReadRegString(LReg, 'OllamaBaseUrl', 'http://localhost:11434');
      FOpenAICustomBaseUrl := ReadRegString(LReg, 'OpenAICustomBaseUrl', '');

      LMaxHist := ReadRegInt(LReg, 'MaxHistoryMessages', 20);
      FMaxHistoryMessages := IfThen(LMaxHist > 0, LMaxHist, 20);
      LReg.CloseKey;
    end;

    { 2. Ler configurações específicas de cada provedor em suas respectivas subchaves }
    for LProvider := Low(TAIProviderType) to High(TAIProviderType) do
    begin
      LProvStr := ProviderTypeToString(LProvider);
      LProvPath := FRegistryPath + '\' + LProvStr;

      if LReg.OpenKeyReadOnly(LProvPath) then
      begin
        { Load API Key from Subkey }
        try
          if LReg.ValueExists('ApiKey') then
            FApiKeys[LProvider] := UnprotectString(LReg.ReadString('ApiKey'))
          else
            FApiKeys[LProvider] := '';
        except
          FApiKeys[LProvider] := '';
        end;

        { Load Active Model from Subkey (matching 'Model' as shown in Registry) }
        try
          if LReg.ValueExists('Model') then
            FActiveModels[LProvider] := LReg.ReadString('Model')
          else if LReg.ValueExists('ActiveModel') then
            FActiveModels[LProvider] := LReg.ReadString('ActiveModel');
        except
        end;

        { Load BaseURL from Subkey (matching 'BaseURL' in Registry) }
        if LReg.ValueExists('BaseURL') then
        begin
          if LProvider = ptOpenAI then
            FOpenAICustomBaseUrl := LReg.ReadString('BaseURL')
          else if LProvider = ptOllama then
            FOllamaBaseUrl := LReg.ReadString('BaseURL');
        end;

        LReg.CloseKey;
      end
      else
      begin
        { Fallback: Tenta ler no formato legado prefixado diretamente na raiz }
        if LReg.OpenKeyReadOnly(FRegistryPath) then
        begin
          try
            if LReg.ValueExists(LProvStr + '_ApiKey') then
              FApiKeys[LProvider] := UnprotectString(LReg.ReadString(LProvStr + '_ApiKey'))
            else
              FApiKeys[LProvider] := '';
          except
            FApiKeys[LProvider] := '';
          end;

          try
            if LReg.ValueExists(LProvStr + '_ActiveModel') then
              FActiveModels[LProvider] := LReg.ReadString(LProvStr + '_ActiveModel');
          except
          end;
          LReg.CloseKey;
        end;
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
var
  LReg: TRegistry;
  LProvider: TAIProviderType;
  LProvStr: string;
  LProvPath: string;
begin
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    
    { 1. Salvar chaves globais na raiz }
    if LReg.OpenKey(FRegistryPath, True) then
    begin
      LReg.WriteInteger('ActiveProvider', Integer(FActiveProvider));
      LReg.WriteString('SystemPrompt', FSystemPrompt);
      LReg.WriteInteger('MaxHistoryMessages', FMaxHistoryMessages);
      LReg.CloseKey;
    end;

    { 2. Salvar chaves de cada provedor em subchaves dedicadas }
    for LProvider := Low(TAIProviderType) to High(TAIProviderType) do
    begin
      LProvStr := ProviderTypeToString(LProvider);
      LProvPath := FRegistryPath + '\' + LProvStr;

      if LReg.OpenKey(LProvPath, True) then
      begin
        LReg.WriteString('ApiKey', ProtectString(FApiKeys[LProvider]));
        LReg.WriteString('Model', FActiveModels[LProvider]);

        { Save BaseURL for OpenAI Custom and Ollama }
        if LProvider = ptOpenAI then
          LReg.WriteString('BaseURL', FOpenAICustomBaseUrl)
        else if LProvider = ptOllama then
          LReg.WriteString('BaseURL', FOllamaBaseUrl);

        LReg.CloseKey;
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
  FApiKeys[AProvider] := AKey;
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

function TRadIAConfig.UnprotectString(const AValue: string): string;
var
  LInBlob, LOutBlob: TDataBlob;
  LBytes: TBytes;
begin
  Result := '';
  if AValue.IsEmpty then
    Exit;

  try
    LBytes := TNetEncoding.Base64.DecodeStringToBytes(AValue);
  except
    Exit;
  end;

  if Length(LBytes) = 0 then
    Exit;

  LInBlob.cbData := Length(LBytes);
  LInBlob.pbData := @LBytes[0];

  if CryptUnprotectData(@LInBlob, nil, nil, nil, nil, 0, @LOutBlob) then
  begin
    try
      SetLength(LBytes, LOutBlob.cbData);
      Move(LOutBlob.pbData^, LBytes[0], LOutBlob.cbData);
      Result := TEncoding.UTF8.GetString(LBytes);
    finally
      LocalFree(HLOCAL(LOutBlob.pbData));
    end;
  end;
end;

end.
