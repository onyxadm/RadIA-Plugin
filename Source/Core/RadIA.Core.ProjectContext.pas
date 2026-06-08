unit RadIA.Core.ProjectContext;

interface

uses
  System.SysUtils, System.Classes;

type
  { Loader for project-specific context configured via a .radia JSON file }
  TProjectContextLoader = class
  public
    { Loads the context from a .radia file in the specified project folder, 
      merging the custom system prompt and the contents of any listed context files. }
    class function LoadContext(const AProjectFolder: string; out AContextPrompt: string): Boolean; static;
  end;

implementation

uses
  System.IOUtils, System.JSON;

{ TProjectContextLoader }

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
  LStream: TFileStream;
  LBytes: TBytes;
  LReadLen: Integer;
  LIdx: Integer;
  LCountBack: Integer;
  LCharLen: Integer;
  LStartByte: Byte;
begin
  Result := False;
  AContextPrompt := '';
  
  if AProjectFolder.IsEmpty then
    Exit;

  LRadiaFile := TPath.Combine(AProjectFolder, '.radia');
  if not TFile.Exists(LRadiaFile) then
    Exit; { File not found - return False without error }

  LSb := TStringBuilder.Create;
  try
    try
      LJsonContent := TFile.ReadAllText(LRadiaFile, TEncoding.UTF8);
      LJsonObj := TJSONObject.ParseJSONValue(LJsonContent) as TJSONObject;
      
      if Assigned(LJsonObj) then
      begin
        try
          Result := True; { Valid JSON parsed, we have context! }
          
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
                try
                  LStream := TFileStream.Create(LFileAbsPath, fmOpenRead or fmShareDenyNone);
                  try
                    if LStream.Size > 51200 then
                    begin
                      SetLength(LBytes, 51200);
                      LReadLen := LStream.Read(LBytes[0], 51200);
                      
                      { UTF-8 Truncation Safety Check }
                      if LReadLen > 0 then
                      begin
                        LIdx := LReadLen - 1;
                        LCountBack := 0;
                        while (LIdx >= 0) and ((LBytes[LIdx] and $C0) = $80) do
                        begin
                          Dec(LIdx);
                          Inc(LCountBack);
                        end;
                        
                        if LIdx >= 0 then
                        begin
                          LStartByte := LBytes[LIdx];
                          LCharLen := 1;
                          if (LStartByte and $80) <> 0 then
                          begin
                            if (LStartByte and $F8) = $F0 then
                              LCharLen := 4
                            else if (LStartByte and $F0) = $E0 then
                              LCharLen := 3
                            else if (LStartByte and $E0) = $C0 then
                              LCharLen := 2;
                              
                            if LCountBack < (LCharLen - 1) then
                            begin
                              LReadLen := LIdx;
                            end;
                          end;
                        end;
                      end;
                      
                      SetLength(LBytes, LReadLen);
                      LFileContent := TEncoding.UTF8.GetString(LBytes);
                      
                      LSb.AppendLine(Format('[Arquivo: %s]', [LFileRelPath.Replace('\', '/')]));
                      LSb.AppendLine(LFileContent.Trim);
                      LSb.AppendLine(Format('[Aviso: Conteúdo do arquivo "%s" foi truncado pois excede o limite de 50KB]', [LFileRelPath.Replace('\', '/')]));
                      LSb.AppendLine;
                    end
                    else
                    begin
                      LFileContent := TFile.ReadAllText(LFileAbsPath, TEncoding.UTF8);
                      LSb.AppendLine(Format('[Arquivo: %s]', [LFileRelPath.Replace('\', '/')]));
                      LSb.AppendLine(LFileContent.Trim);
                      LSb.AppendLine;
                    end;
                  finally
                    LStream.Free;
                  end;
                except
                  { Ignore read error for specific file and continue }
                end;
              end;
            end;
          end;
        finally
          LJsonObj.Free;
        end;
      end;
    except
      { JSON is invalid or file error - return False but do not crash }
      Result := False;
    end;
    
    AContextPrompt := LSb.ToString.Trim;
  finally
    LSb.Free;
  end;
end;

end.
