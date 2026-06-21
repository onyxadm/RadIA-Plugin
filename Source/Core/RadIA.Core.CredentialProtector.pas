unit RadIA.Core.CredentialProtector;

interface

uses
  System.SysUtils;

type
  TCredentialProtector = record
  public
    class function CleanApiKey(const AValue: string): string; static;
    class function Protect(const AValue: string): string; static;
    class function Unprotect(const AValue: string): string; static;
  end;

implementation

uses
  Winapi.Windows, System.NetEncoding, RadIA.Core.Logger;

type
  TDataBlob = record
    cbData: DWORD;
    pbData: PByte;
  end;
  PDataBlob = ^TDataBlob;

function CryptProtectData(APDataIn: PDataBlob; ASzDataDescr: LPCWSTR;
  APOptionalEntropy: PDataBlob; APvReserved: Pointer;
  APPromptStruct: Pointer; ADwFlags: DWORD;
  APDataOut: PDataBlob): BOOL; stdcall; external 'crypt32.dll';

function CryptUnprotectData(APDataIn: PDataBlob; APpszDataDescr: Pointer;
  APOptionalEntropy: PDataBlob; APvReserved: Pointer;
  APPromptStruct: Pointer; ADwFlags: DWORD;
  APDataOut: PDataBlob): BOOL; stdcall; external 'crypt32.dll';

procedure LogDebug(const AMsg: string);
begin
  TLogger.Log(AMsg, 'Config');
end;

class function TCredentialProtector.CleanApiKey(const AValue: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := Low(AValue) to High(AValue) do
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

class function TCredentialProtector.Protect(const AValue: string): string;
var
  LInBlob: TDataBlob;
  LOutBlob: TDataBlob;
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

class function TCredentialProtector.Unprotect(const AValue: string): string;
var
  LInBlob: TDataBlob;
  LOutBlob: TDataBlob;
  LBytes: TBytes;
begin
  Result := '';
  if AValue.IsEmpty then
    Exit;

  LogDebug('TCredentialProtector.Unprotect: Input string length: ' + IntToStr(Length(AValue)));
  try
    LBytes := TNetEncoding.Base64.DecodeStringToBytes(AValue);
  except
    on E: Exception do
    begin
      LogDebug('TCredentialProtector.Unprotect: Base64 decode failed: ' + E.Message);
      Exit;
    end;
  end;

  if Length(LBytes) = 0 then
  begin
    LogDebug('TCredentialProtector.Unprotect: Base64 decoded bytes length is 0');
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
      LogDebug(
        'TCredentialProtector.Unprotect: Decrypted and cleaned successfully. Result length: ' +
        IntToStr(Length(Result)));
    finally
      LocalFree(HLOCAL(LOutBlob.pbData));
    end;
  end;
end;

end.
