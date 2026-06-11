unit RadIA.Core.PascalFormatter;

interface

type
  TRadIAPascalFormatter = class
  public
    class function NormalizeIndentation(const ACode: string): string; static;
  end;

implementation

uses
  System.Classes, System.Math, System.SysUtils;

const
  CIndentSize = 2;

function IsVisibilityLine(const ALine: string): Boolean;
begin
  Result := SameText(ALine, 'private') or SameText(ALine, 'protected') or
    SameText(ALine, 'public') or SameText(ALine, 'published');
end;

function IsSectionLine(const ALine: string): Boolean;
begin
  Result := SameText(ALine, 'interface') or SameText(ALine, 'implementation') or
    SameText(ALine, 'initialization') or SameText(ALine, 'finalization');
end;

function IsDeclarationLine(const ALine: string): Boolean;
begin
  Result := SameText(ALine, 'type') or SameText(ALine, 'var') or
    SameText(ALine, 'const') or SameText(ALine, 'resourcestring') or
    SameText(ALine, 'threadvar');
end;

function StartsWithKeyword(const ALine, AKeyword: string): Boolean;
var
  LLowerLine: string;
  LLowerKeyword: string;
begin
  LLowerLine := ALine.ToLower;
  LLowerKeyword := AKeyword.ToLower;
  Result := LLowerLine.StartsWith(LLowerKeyword) and
    ((LLowerLine.Length = LLowerKeyword.Length) or
     not CharInSet(LLowerLine[LLowerKeyword.Length + 1], ['a'..'z', '0'..'9', '_']));
end;

function EndsWithAny(const ALine: string; const AValues: array of string): Boolean;
var
  LValue: string;
begin
  Result := False;
  for LValue in AValues do
  begin
    if ALine.EndsWith(LValue, True) then
      Exit(True);
  end;
end;

function ShouldDedentBeforeLine(const ALine: string): Boolean;
begin
  Result := StartsWithKeyword(ALine, 'end') or StartsWithKeyword(ALine, 'except') or
    StartsWithKeyword(ALine, 'finally') or StartsWithKeyword(ALine, 'until') or
    StartsWithKeyword(ALine, 'else');
end;

function ShouldIndentAfterLine(const ALine: string): Boolean;
var
  LLowerLine: string;
begin
  LLowerLine := ALine.ToLower;
  Result := SameText(ALine, 'begin') or SameText(ALine, 'try') or
    SameText(ALine, 'finally') or SameText(ALine, 'except') or
    SameText(ALine, 'repeat') or (Pos(' = class', LLowerLine) > 0) or
    (Pos(' = record', LLowerLine) > 0) or (Pos(' = interface', LLowerLine) > 0) or
    EndsWithAny(ALine, [' class', ' class;', ' record', ' record;', ' interface',
    ' interface;']) or ALine.EndsWith(' of', True);
end;

function TrimRightOnly(const AText: string): string;
var
  LIndex: Integer;
begin
  LIndex := AText.Length;
  while (LIndex > 0) and CharInSet(AText[LIndex], [#9, #10, #13, ' ']) do
    Dec(LIndex);
  Result := Copy(AText, 1, LIndex);
end;

{ TRadIAPascalFormatter }

class function TRadIAPascalFormatter.NormalizeIndentation(const ACode: string): string;
var
  LInput: TStringList;
  LOutput: TStringList;
  LIndex: Integer;
  LIndentLevel: Integer;
  LLine: string;
  LTrimmed: string;
  LInUsesSection: Boolean;
  LInDeclarationSection: Boolean;
begin
  LInput := TStringList.Create;
  LOutput := TStringList.Create;
  try
    LInput.Text := ACode;
    LIndentLevel := 0;
    LInUsesSection := False;
    LInDeclarationSection := False;

    for LIndex := 0 to LInput.Count - 1 do
    begin
      LLine := TrimRightOnly(LInput[LIndex]);
      LTrimmed := LLine.Trim;

      if LTrimmed.IsEmpty then
      begin
        LOutput.Add('');
        Continue;
      end;

      if IsSectionLine(LTrimmed) then
      begin
        LIndentLevel := 0;
        LInUsesSection := False;
        LInDeclarationSection := False;
      end
      else if LInDeclarationSection and SameText(LTrimmed, 'begin') then
      begin
        LIndentLevel := Max(0, LIndentLevel - 1);
        LInDeclarationSection := False;
      end
      else if ShouldDedentBeforeLine(LTrimmed) then
        LIndentLevel := Max(0, LIndentLevel - 1)
      else if IsVisibilityLine(LTrimmed) then
        LIndentLevel := Max(1, LIndentLevel - 1);

      LOutput.Add(StringOfChar(' ', LIndentLevel * CIndentSize) + LTrimmed);

      if SameText(LTrimmed, 'uses') then
      begin
        LInUsesSection := True;
        Inc(LIndentLevel);
      end
      else if LInUsesSection and LTrimmed.EndsWith(';') then
      begin
        LInUsesSection := False;
        LIndentLevel := Max(0, LIndentLevel - 1);
      end
      else if IsDeclarationLine(LTrimmed) then
      begin
        LInDeclarationSection := True;
        Inc(LIndentLevel);
      end
      else if ShouldIndentAfterLine(LTrimmed) then
        Inc(LIndentLevel)
      else if IsVisibilityLine(LTrimmed) then
        Inc(LIndentLevel);
    end;

    Result := LOutput.Text.Trim;
  finally
    LOutput.Free;
    LInput.Free;
  end;
end;

end.
