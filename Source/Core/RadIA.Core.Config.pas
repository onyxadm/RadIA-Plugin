unit RadIA.Core.Config;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Interfaces, RadIA.Core.Types;

type
  TRadIAConfig = class(TInterfacedObject, IAIConfig)
  private
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
  public
    constructor Create;
    
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
  Winapi.Windows, System.Win.Registry, System.NetEncoding;

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
begin
  inherited Create;
  FRegistryPath := 'Software\RadIA';
  FActiveProvider := ptGemini;
  FApiKeys[ptGemini] := '';
  FApiKeys[ptOpenAI] := '';
  FApiKeys[ptClaude] := '';
  FApiKeys[ptOllama] := '';
  FActiveModels[ptGemini] := MODEL_GEMINI_15_FLASH;
  FActiveModels[ptOpenAI] := MODEL_OPENAI_GPT4O_MINI;
  FActiveModels[ptClaude] := MODEL_CLAUDE_3_HAIKU;
  FActiveModels[ptOllama] := 'llama3:latest';
  FSystemPrompt := '';
  FOllamaBaseUrl := 'http://localhost:11434';
  FMaxHistoryMessages := 20;
  FOpenAICustomBaseUrl := '';
  Load;
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

procedure TRadIAConfig.Load;
var
  LReg: TRegistry;
  LProvider: TAIProviderType;
  LProvStr: string;
begin
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    if LReg.OpenKeyReadOnly(FRegistryPath) then
    begin
      try
        if LReg.ValueExists('ActiveProvider') then
          FActiveProvider := TAIProviderType(LReg.ReadInteger('ActiveProvider'));
      except
        FActiveProvider := ptGemini;
      end;

      try
        if LReg.ValueExists('SystemPrompt') then
          FSystemPrompt := LReg.ReadString('SystemPrompt')
        else
          FSystemPrompt := '';
      except
        FSystemPrompt := '';
      end;

      try
        if LReg.ValueExists('OllamaBaseUrl') then
          FOllamaBaseUrl := LReg.ReadString('OllamaBaseUrl')
        else
          FOllamaBaseUrl := 'http://localhost:11434';
      except
        FOllamaBaseUrl := 'http://localhost:11434';
      end;

      try
        if LReg.ValueExists('MaxHistoryMessages') then
          FMaxHistoryMessages := LReg.ReadInteger('MaxHistoryMessages')
        else
          FMaxHistoryMessages := 20;
        if FMaxHistoryMessages <= 0 then
          FMaxHistoryMessages := 20;
      except
        FMaxHistoryMessages := 20;
      end;

      try
        if LReg.ValueExists('OpenAICustomBaseUrl') then
          FOpenAICustomBaseUrl := LReg.ReadString('OpenAICustomBaseUrl')
        else
          FOpenAICustomBaseUrl := '';
      except
        FOpenAICustomBaseUrl := '';
      end;

      for LProvider := Low(TAIProviderType) to High(TAIProviderType) do
      begin
        LProvStr := ProviderTypeToString(LProvider);
        
        { Load API Key }
        try
          if LReg.ValueExists(LProvStr + '_ApiKey') then
            FApiKeys[LProvider] := UnprotectString(LReg.ReadString(LProvStr + '_ApiKey'))
          else
            FApiKeys[LProvider] := '';
        except
          FApiKeys[LProvider] := '';
        end;

        { Load Active Model }
        try
          if LReg.ValueExists(LProvStr + '_ActiveModel') then
            FActiveModels[LProvider] := LReg.ReadString(LProvStr + '_ActiveModel');
        except
          // Keep defaults if failed
        end;
      end;
      LReg.CloseKey;
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
begin
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    if LReg.OpenKey(FRegistryPath, True) then
    begin
      LReg.WriteInteger('ActiveProvider', Integer(FActiveProvider));
      LReg.WriteString('SystemPrompt', FSystemPrompt);
      LReg.WriteString('OllamaBaseUrl', FOllamaBaseUrl);
      LReg.WriteInteger('MaxHistoryMessages', FMaxHistoryMessages);
      LReg.WriteString('OpenAICustomBaseUrl', FOpenAICustomBaseUrl);

      for LProvider := Low(TAIProviderType) to High(TAIProviderType) do
      begin
        LProvStr := ProviderTypeToString(LProvider);
        LReg.WriteString(LProvStr + '_ApiKey', ProtectString(FApiKeys[LProvider]));
        LReg.WriteString(LProvStr + '_ActiveModel', FActiveModels[LProvider]);
      end;
      LReg.CloseKey;
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
