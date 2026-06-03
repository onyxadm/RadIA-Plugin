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

uses
  System.StrUtils;

{ TRadIAContextParser }

class function TRadIAContextParser.GetInterfaceSection(const ASourceCode: string): string;
var
  LInterfacePtr, LImplementationPtr: PChar;
  LInterfacePos, LImplementationPos: Integer;
  LBuf: PChar;
  LBufLen: Integer;
begin
  Result := '';
  if ASourceCode.IsEmpty then
    Exit;

  LBuf := PChar(ASourceCode);
  LBufLen := ASourceCode.Length;

  LInterfacePtr := SearchBuf(LBuf, LBufLen, 0, 0, 'interface', [soDown]);
  if LInterfacePtr = nil then
    Exit;

  LInterfacePos := LInterfacePtr - LBuf;

  LImplementationPtr := SearchBuf(LBuf, LBufLen, LInterfacePos, 0, 'implementation', [soDown]);
  if LImplementationPtr = nil then
    LImplementationPos := LBufLen
  else
    LImplementationPos := LImplementationPtr - LBuf;

  if LImplementationPos > LInterfacePos then
  begin
    Result := ASourceCode.Substring(LInterfacePos, LImplementationPos - LInterfacePos);
  end;
end;

class function TRadIAContextParser.GetClassContextAtLine(const ASourceCode: string; const ALine: Integer): string;
var
  LLines: TStringList;
  I: Integer;
  LCurLineText: string;
  LClassName: string;
  LClassStartLine, LClassEndLine: Integer;
  LSb: TStringBuilder;
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
      LCurLineText := LLines[I];
      if ContainsText(LCurLineText, 'class') and ContainsText(LCurLineText, '=') then
      begin
        // Extract class name
        LClassName := LLines[I].Split(['='])[0].Trim;
        LClassStartLine := I;
        Break;
      end;
      
      { Stop searching backwards if we reach unit boundaries }
      if SameText(LCurLineText.Trim, 'interface') or SameText(LCurLineText.Trim, 'implementation') then
        Break;
    end;
    
    if LClassStartLine = -1 then
      Exit; // No class found in this scope
      
    { 2. Find the end of the class declaration (which is usually the next "end;" or a new "type" / "implementation") }
    LClassEndLine := -1;
    for I := LClassStartLine + 1 to LLines.Count - 1 do
    begin
      LCurLineText := LLines[I].Trim;
      
      { Delphi classes in interface end with an "end;" }
      if SameText(LCurLineText, 'end;') or SameText(LCurLineText, 'end') then
      begin
        LClassEndLine := I;
        Break;
      end;
      
      if SameText(LCurLineText, 'implementation') or ContainsText(LCurLineText, 'type') then
      begin
        LClassEndLine := I - 1;
        Break;
      end;
    end;
    
    if LClassEndLine = -1 then
      LClassEndLine := LLines.Count - 1;
      
    { Assemble the class text scope using StringBuilder }
    LSb := TStringBuilder.Create;
    try
      for I := LClassStartLine to LClassEndLine do
      begin
        LSb.AppendLine(LLines[I]);
      end;
      Result := LSb.ToString;
    finally
      LSb.Free;
    end;
  finally
    LLines.Free;
  end;
end;

end.
