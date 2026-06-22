unit RadIA.Core.ProjectContext;

interface

uses
  System.SysUtils;

type
  { Loader for project-specific context configured via a .radia JSON file }
  TProjectContextLoader = class
  private
    class function ReadContextFileSafe(const APath: string; out AContent: string): Boolean; static;
    class function FindUTF8StartByte(const ABytes: TBytes; ALength: Integer;
      out ACountBack: Integer): Integer; static;
    class function CalculateUTF8CharLen(AStartByte: Byte): Integer; static;
    class procedure SafeTruncateUTF8Bytes(var ABytes: TBytes; var ALength: Integer); static;
  public
    { Loads the context from a .radia file in the specified project folder,
      merging the custom system prompt and the contents of any listed context files. }
    class function LoadContext(const AProjectFolder: string; out AContextPrompt: string): Boolean; static;
  end;

implementation

uses
  System.IOUtils, System.JSON, RadIA.Core.Logger, System.Classes;

{ TProjectContextLoader }

class function TProjectContextLoader.FindUTF8StartByte(const ABytes: TBytes;
  ALength: Integer; out ACountBack: Integer): Integer;
var
  LIdx: Integer;
begin
  LIdx := ALength - 1;
  ACountBack := 0;
  while (LIdx >= 0) and ((ABytes[LIdx] and $C0) = $80) do
  begin
    Dec(LIdx);
    Inc(ACountBack);
  end;
  Result := LIdx;
end;

class function TProjectContextLoader.CalculateUTF8CharLen(AStartByte: Byte): Integer;
begin
  if (AStartByte and $80) = 0 then
    Result := 1
  else if (AStartByte and $F8) = $F0 then
    Result := 4
  else if (AStartByte and $F0) = $E0 then
    Result := 3
  else if (AStartByte and $E0) = $C0 then
    Result := 2
  else
    Result := 1;
end;

class procedure TProjectContextLoader.SafeTruncateUTF8Bytes(var ABytes: TBytes; var ALength: Integer);
var
  LIdx, LCountBack, LCharLen: Integer;
begin
  if ALength <= 0 then Exit;
  LIdx := FindUTF8StartByte(ABytes, ALength, LCountBack);
  if LIdx >= 0 then
  begin
    LCharLen := CalculateUTF8CharLen(ABytes[LIdx]);
    if LCountBack < (LCharLen - 1) then
      ALength := LIdx;
  end;
end;

class function TProjectContextLoader.ReadContextFileSafe(const APath: string; out AContent: string): Boolean;
var
  LStream: TFileStream;
  LBytes: TBytes;
  LReadLen: Integer;
begin
  Result := False;
  AContent := '';
  if not TFile.Exists(APath) then
    Exit;

  try
    LStream := TFileStream.Create(APath, fmOpenRead or fmShareDenyNone);
    try
      if LStream.Size > 51200 then
      begin
        SetLength(LBytes, 51200);
        LReadLen := LStream.Read(LBytes[0], 51200);
        SafeTruncateUTF8Bytes(LBytes, LReadLen);
        SetLength(LBytes, LReadLen);
        AContent := TEncoding.UTF8.GetString(LBytes);
        Result := True; // indicates it was truncated
      end
      else
      begin
        AContent := TFile.ReadAllText(APath, TEncoding.UTF8);
        Result := False; // not truncated
      end;
    finally
      LStream.Free;
    end;
  except
    on E: Exception do
      TLogger.Log(Format('LoadContext: Failed to read context file "%s": %s',
        [APath, E.Message]), 'Context');
  end;
end;

class function TProjectContextLoader.LoadContext(const AProjectFolder: string; out AContextPrompt: string): Boolean;
var
  LRadiaFile: string;
  LJsonContent: string;
  LJsonObj: TJSONObject;
  LSystemPrompt: string;
  LContextFiles: TJSONArray;
  LVal: TJSONValue;
  LFileRelPath: string;
  LFileAbsPath: string;
  LFileContent: string;
  LSb: TStringBuilder;
  LIsTruncated: Boolean;
begin
  Result := False;
  AContextPrompt := '';

  if AProjectFolder.IsEmpty then
    Exit;

  LRadiaFile := TPath.Combine(AProjectFolder, '.radia');
  if not TFile.Exists(LRadiaFile) then
    Exit;

  LSb := TStringBuilder.Create;
  try
    try
      LJsonContent := TFile.ReadAllText(LRadiaFile, TEncoding.UTF8);
      LJsonObj := TJSONObject.ParseJSONValue(LJsonContent) as TJSONObject;

      if Assigned(LJsonObj) then
      begin
        try
          Result := True;

          { 1. Load system_prompt }
          LSystemPrompt := LJsonObj.GetValue<string>('system_prompt', '');
          if not LSystemPrompt.IsEmpty then
          begin
            LSb.AppendLine('[Contexto do Projeto (.radia)]');
            LSb.AppendLine(LSystemPrompt.Trim);
            LSb.AppendLine;
          end;

          { 2. Load context_files }
          LContextFiles := LJsonObj.GetValue('context_files') as TJSONArray;
          if Assigned(LContextFiles) then
          begin
            for LVal in LContextFiles do
            begin
              LFileRelPath := LVal.Value;
              if LFileRelPath.IsEmpty then
                Continue;

              LFileAbsPath := TPath.Combine(AProjectFolder, LFileRelPath);
              if TFile.Exists(LFileAbsPath) then
              begin
                LFileContent := '';
                LIsTruncated := ReadContextFileSafe(LFileAbsPath, LFileContent);
                if not LFileContent.IsEmpty then
                begin
                  LSb.AppendLine(Format('[Arquivo: %s]', [LFileRelPath.Replace('\', '/')]));
                  LSb.AppendLine(LFileContent.Trim);
                  if LIsTruncated then
                  begin
                    LSb.AppendLine(Format('[Aviso: Conteudo do arquivo "%s" foi truncado pois excede ' +
                        'o limite de 50KB]', [LFileRelPath.Replace('\', '/')]));
                  end;
                  LSb.AppendLine;
                end;
              end;
            end;
          end;
        finally
          LJsonObj.Free;
        end;
      end;
    except
      on E: Exception do
      begin
        TLogger.Log('LoadContext: Failed to load project context from .radia: ' + E.Message, 'Context');
        Result := False;
      end;
    end;

    AContextPrompt := LSb.ToString.Trim;
  finally
    LSb.Free;
  end;
end;

end.
