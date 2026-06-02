unit RadIA.OTA.ContextParser;

interface

uses
  System.SysUtils, System.Classes;

type
  { Simple parser to extract Pascal unit interfaces and class scopes }
  TRadIAContextParser = class
  public
    class function GetInterfaceSection(const ASourceCode: string): string;
    class function GetClassContextAtLine(const ASourceCode: string; const ALine: Integer): string;
  end;

implementation

{ TRadIAContextParser }

class function TRadIAContextParser.GetInterfaceSection(const ASourceCode: string): string;
var
  LInterfacePos, LImplementationPos: Integer;
begin
  Result := '';
  
  LInterfacePos := Pos('interface', LowerCase(ASourceCode));
  if LInterfacePos = 0 then
    Exit;
    
  LImplementationPos := Pos('implementation', LowerCase(ASourceCode));
  if LImplementationPos = 0 then
    LImplementationPos := Length(ASourceCode) + 1;
    
  if LImplementationPos > LInterfacePos then
  begin
    Result := Copy(ASourceCode, LInterfacePos, LImplementationPos - LInterfacePos);
  end;
end;

class function TRadIAContextParser.GetClassContextAtLine(const ASourceCode: string; const ALine: Integer): string;
var
  LLines: TStringList;
  I: Integer;
  LCurLineText: string;
  LClassName: string;
  LClassStartLine, LClassEndLine: Integer;
begin
  Result := '';
  if ASourceCode.IsEmpty then
    Exit;
    
  LLines := TStringList.Create;
  try
    LLines.Text := ASourceCode;
    if (ALine < 1) or (ALine > LLines.Count) then
      Exit;
      
    { 1. Look backwards from the cursor line to find a class declaration like "TMyClass = class" }
    LClassName := '';
    LClassStartLine := -1;
    
    for I := ALine - 1 downto 0 do
    begin
      LCurLineText := LLines[I].Trim.ToLower;
      if (Pos('class', LCurLineText) > 0) and (Pos('=', LCurLineText) > 0) then
      begin
        // Extract class name
        LClassName := LLines[I].Split(['='])[0].Trim;
        LClassStartLine := I;
        Break;
      end;
      
      { Stop searching backwards if we reach unit boundaries }
      if (LCurLineText = 'interface') or (LCurLineText = 'implementation') then
        Break;
    end;
    
    if LClassStartLine = -1 then
      Exit; // No class found in this scope
      
    { 2. Find the end of the class declaration (which is usually the next "end;" or a new "type" / "implementation") }
    LClassEndLine := -1;
    for I := LClassStartLine + 1 to LLines.Count - 1 do
    begin
      LCurLineText := LLines[I].Trim.ToLower;
      
      { Delphi classes in interface end with an "end;" }
      if (LCurLineText = 'end;') or (LCurLineText = 'end') then
      begin
        LClassEndLine := I;
        Break;
      end;
      
      if (LCurLineText = 'implementation') or (Pos('type', LCurLineText) > 0) then
      begin
        LClassEndLine := I - 1;
        Break;
      end;
    end;
    
    if LClassEndLine = -1 then
      LClassEndLine := LLines.Count - 1;
      
    { Assemble the class text scope }
    for I := LClassStartLine to LClassEndLine do
    begin
      Result := Result + LLines[I] + sLineBreak;
    end;
  finally
    LLines.Free;
  end;
end;

end.
