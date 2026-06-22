unit RadIA.OTA.ContextParser;

interface

uses  System.Classes;

type
  TMethodExampleContext = record
    MethodText: string;
    CommentText: string;
    BodyIndent: string;
    InsertionLine: Integer;
    InsertionColumn: Integer;
  end;

  { Simple parser to extract Pascal unit interfaces and class scopes }
  TRadIAContextParser = class
  private
    class function FindMatchingMethodEnd(const ALines: TStrings; const ABeginLine: Integer): Integer;
    class function GetLeadingWhitespace(const ALine: string): string;
    class function IsMethodDeclarationLine(const ALine: string): Boolean;
    class function IsOnlyWhitespaceOrComment(const ALines: TStrings; const AStartLine, AEndLine: Integer;
      const AIgnoreStartLine, AIgnoreEndLine: Integer): Boolean;
    class function StripCommentsAndStrings(const ALine: string; var AInBraceComment: Boolean;
      var AInParenComment: Boolean): string;
    class function TryExtractFirstBodyComment(const ALines: TStrings; const AStartLine, AEndLine: Integer;
      out ACommentText: string; out ACommentStartLine, ACommentEndLine: Integer): Boolean;
    class function ExtractWindowText(const ASourceCode: string; const ALine: Integer; out AStartLine: Integer): string;
    class function FindClassDeclarationBackwards(const ALines: TStrings; const ARelativeLine: Integer): Integer;
    class function FindClassDeclarationEnd(const ALines: TStrings; const AClassStartLine: Integer): Integer;
  public
    class function GetInterfaceSection(const ASourceCode: string): string;
    class function GetClassContextAtLine(const ASourceCode: string; const ALine: Integer): string;
    class function TryGetMethodExampleContext(const ASourceCode: string; const ACursorLine: Integer;
      out AContext: TMethodExampleContext; out AErrorMessage: string): Boolean;
  end;

implementation

uses
  System.StrUtils, System.SysUtils;

{ TRadIAContextParser }

class function TRadIAContextParser.GetLeadingWhitespace(const ALine: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := Low(ALine) to High(ALine) do
  begin
    if not CharInSet(ALine[I], [' ', #9]) then
      Exit;
    Result := Result + ALine[I];
  end;
end;

class function TRadIAContextParser.IsMethodDeclarationLine(const ALine: string): Boolean;
var
  LLine: string;
begin
  LLine := ALine.TrimLeft.ToLower;
  Result :=
    LLine.StartsWith('procedure ') or
    LLine.StartsWith('function ') or
    LLine.StartsWith('constructor ') or
    LLine.StartsWith('destructor ') or
    LLine.StartsWith('operator ') or
    LLine.StartsWith('class procedure ') or
    LLine.StartsWith('class function ');
end;

class function TRadIAContextParser.StripCommentsAndStrings(const ALine: string; var AInBraceComment: Boolean;
  var AInParenComment: Boolean): string;
var
  I: Integer;
  LInString: Boolean;
begin
  Result := '';
  I := Low(ALine);
  LInString := False;

  while I <= High(ALine) do
  begin
    if AInBraceComment then
    begin
      if ALine[I] = '}' then
        AInBraceComment := False;
      Result := Result + ' ';
      Inc(I);
      Continue;
    end;

    if AInParenComment then
    begin
      if (ALine[I] = '*') and (I < High(ALine)) and (ALine[I + 1] = ')') then
      begin
        AInParenComment := False;
        Result := Result + '  ';
        Inc(I, 2);
      end
      else
      begin
        Result := Result + ' ';
        Inc(I);
      end;
      Continue;
    end;

    if LInString then
    begin
      if ALine[I] = '''' then
      begin
        if (I < High(ALine)) and (ALine[I + 1] = '''') then
        begin
          Result := Result + '  ';
          Inc(I, 2);
          Continue;
        end;
        LInString := False;
      end;
      Result := Result + ' ';
      Inc(I);
      Continue;
    end;

    if (ALine[I] = '/') and (I < High(ALine)) and (ALine[I + 1] = '/') then
      Break;

    if ALine[I] = '{' then
    begin
      AInBraceComment := True;
      Result := Result + ' ';
      Inc(I);
      Continue;
    end;

    if (ALine[I] = '(') and (I < High(ALine)) and (ALine[I + 1] = '*') then
    begin
      AInParenComment := True;
      Result := Result + '  ';
      Inc(I, 2);
      Continue;
    end;

    if ALine[I] = '''' then
    begin
      LInString := True;
      Result := Result + ' ';
      Inc(I);
      Continue;
    end;

    Result := Result + ALine[I];
    Inc(I);
  end;
end;

class function TRadIAContextParser.FindMatchingMethodEnd(const ALines: TStrings; const ABeginLine: Integer): Integer;
var
  I: Integer;
  LDepth: Integer;
  LLine: string;
  LInBraceComment: Boolean;
  LInParenComment: Boolean;

  function ContainsWord(const AText, AWord: string): Boolean;
  var
    LText: string;
    LWord: string;
    LPos: Integer;
    LBefore: Char;
    LAfter: Char;
  begin
    Result := False;
    LText := AText.ToLower;
    LWord := AWord.ToLower;
    LPos := Pos(LWord, LText);
    while LPos > 0 do
    begin
      if LPos = 1 then
        LBefore := ' '
      else
        LBefore := LText[LPos - 1];

      if LPos + Length(LWord) > Length(LText) then
        LAfter := ' '
      else
        LAfter := LText[LPos + Length(LWord)];

      if (not CharInSet(LBefore, ['a'..'z', '0'..'9', '_'])) and
         (not CharInSet(LAfter, ['a'..'z', '0'..'9', '_'])) then
        Exit(True);

      LPos := PosEx(LWord, LText, LPos + Length(LWord));
    end;
  end;

begin
  Result := -1;
  LDepth := 0;
  LInBraceComment := False;
  LInParenComment := False;

  for I := ABeginLine to ALines.Count - 1 do
  begin
    LLine := StripCommentsAndStrings(ALines[I], LInBraceComment, LInParenComment);

    if ContainsWord(LLine, 'begin') or ContainsWord(LLine, 'try') or
       ContainsWord(LLine, 'case') or ContainsWord(LLine, 'record') then
      Inc(LDepth);

    if ContainsWord(LLine, 'end') then
    begin
      Dec(LDepth);
      if LDepth = 0 then
        Exit(I);
    end;
  end;
end;

class function TRadIAContextParser.TryExtractFirstBodyComment(const ALines: TStrings; const AStartLine,
  AEndLine: Integer; out ACommentText: string; out ACommentStartLine, ACommentEndLine: Integer): Boolean;
var
  I: Integer;
  LLine: string;
  LTrimmed: string;
  LClosePos: Integer;
  LBuilder: TStringBuilder;
begin
  Result := False;
  ACommentText := '';
  ACommentStartLine := -1;
  ACommentEndLine := -1;

  LBuilder := TStringBuilder.Create;
  try
    I := AStartLine;
    while I <= AEndLine do
    begin
      LLine := ALines[I];
      LTrimmed := LLine.Trim;
      if LTrimmed.IsEmpty then
      begin
        Inc(I);
        Continue;
      end;

      ACommentStartLine := I;

      if LTrimmed.StartsWith('//') then
      begin
        ACommentEndLine := I;
        LBuilder.AppendLine(LTrimmed.Substring(2).Trim);
        while (ACommentEndLine + 1 <= AEndLine) and
              ALines[ACommentEndLine + 1].Trim.StartsWith('//') do
        begin
          Inc(ACommentEndLine);
          LBuilder.AppendLine(ALines[ACommentEndLine].Trim.Substring(2).Trim);
        end;
        ACommentText := LBuilder.ToString.Trim;
        Exit(not ACommentText.IsEmpty);
      end;

      if LTrimmed.StartsWith('{') then
      begin
        LLine := LTrimmed.Substring(1);
        while True do
        begin
          LClosePos := Pos('}', LLine);
          if LClosePos > 0 then
          begin
            LBuilder.AppendLine(Copy(LLine, 1, LClosePos - 1).Trim);
            ACommentEndLine := I;
            ACommentText := LBuilder.ToString.Trim;
            Exit(not ACommentText.IsEmpty);
          end;

          LBuilder.AppendLine(LLine.Trim);
          Inc(I);
          if I > AEndLine then
            Exit(False);
          LLine := ALines[I];
        end;
      end;

      if LTrimmed.StartsWith('(*') then
      begin
        LLine := LTrimmed.Substring(2);
        while True do
        begin
          LClosePos := Pos('*)', LLine);
          if LClosePos > 0 then
          begin
            LBuilder.AppendLine(Copy(LLine, 1, LClosePos - 1).Trim);
            ACommentEndLine := I;
            ACommentText := LBuilder.ToString.Trim;
            Exit(not ACommentText.IsEmpty);
          end;

          LBuilder.AppendLine(LLine.Trim);
          Inc(I);
          if I > AEndLine then
            Exit(False);
          LLine := ALines[I];
        end;
      end;

      Exit(False);
    end;
  finally
    LBuilder.Free;
  end;
end;

class function TRadIAContextParser.IsOnlyWhitespaceOrComment(const ALines: TStrings; const AStartLine,
  AEndLine: Integer; const AIgnoreStartLine, AIgnoreEndLine: Integer): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := AStartLine to AEndLine do
  begin
    if (I >= AIgnoreStartLine) and (I <= AIgnoreEndLine) then
      Continue;

    if not ALines[I].Trim.IsEmpty then
      Exit(False);
  end;
end;

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
  if not Assigned(LInterfacePtr) then
    Exit;

  LInterfacePos := LInterfacePtr - LBuf;

  LImplementationPtr := SearchBuf(LBuf, LBufLen, LInterfacePos, 0, 'implementation', [soDown]);
  if not Assigned(LImplementationPtr) then
    LImplementationPos := LBufLen
  else
    LImplementationPos := LImplementationPtr - LBuf;

  if LImplementationPos > LInterfacePos then
  begin
    Result := ASourceCode.Substring(LInterfacePos, LImplementationPos - LInterfacePos);
  end;
end;

class function TRadIAContextParser.ExtractWindowText(const ASourceCode: string; const ALine: Integer; out AStartLine: Integer): string;
var
  LStartPos, LEndPos: Integer;
  LCharCount, LCurLine: Integer;
  I: Integer;
  LEndLine: Integer;
begin
  AStartLine := ALine - 200;
  if AStartLine < 1 then
    AStartLine := 1;
  LEndLine := ALine + 200;

  LStartPos := 1;
  LEndPos := ASourceCode.Length;
  LCharCount := ASourceCode.Length;
  LCurLine := 1;
  I := 1;
  while I <= LCharCount do
  begin
    if ASourceCode.Chars[I - 1] = #10 then
    begin
      Inc(LCurLine);
      if LCurLine = AStartLine then
        LStartPos := I + 1;
      if LCurLine = LEndLine + 1 then
      begin
        LEndPos := I;
        Break;
      end;
    end;
    Inc(I);
  end;

  Result := ASourceCode.Substring(LStartPos - 1, LEndPos - LStartPos + 1);
end;

class function TRadIAContextParser.FindClassDeclarationBackwards(const ALines: TStrings; const ARelativeLine: Integer): Integer;
var
  I: Integer;
  LCurLineText: string;
begin
  Result := -1;
  for I := ARelativeLine - 1 downto 0 do
  begin
    LCurLineText := ALines[I];
    if ContainsText(LCurLineText, 'class') and ContainsText(LCurLineText, '=') then
      Exit(I);

    if SameText(LCurLineText.Trim, 'interface') or SameText(LCurLineText.Trim, 'implementation') then
      Break;
  end;
end;

class function TRadIAContextParser.FindClassDeclarationEnd(const ALines: TStrings; const AClassStartLine: Integer): Integer;
var
  I: Integer;
  LCurLineText: string;
begin
  Result := ALines.Count - 1;
  for I := AClassStartLine + 1 to ALines.Count - 1 do
  begin
    LCurLineText := ALines[I].Trim;
    if SameText(LCurLineText, 'end;') or SameText(LCurLineText, 'end') then
      Exit(I);

    if SameText(LCurLineText, 'implementation') or ContainsText(LCurLineText, 'type') then
      Exit(I - 1);
  end;
end;

class function TRadIAContextParser.GetClassContextAtLine(const ASourceCode: string; const ALine: Integer): string;
var
  LLines: TStringList;
  LClassStartLine, LClassEndLine: Integer;
  LSb: TStringBuilder;
  LStartLine: Integer;
  LWindowText: string;
  LRelativeLine: Integer;
  I: Integer;
begin
  Result := '';
  if ASourceCode.IsEmpty then
    Exit;

  LWindowText := ExtractWindowText(ASourceCode, ALine, LStartLine);
  LRelativeLine := ALine - LStartLine + 1;

  LLines := TStringList.Create;
  try
    LLines.Text := LWindowText;
    if (LRelativeLine < 1) or (LRelativeLine > LLines.Count) then
      Exit;

    LClassStartLine := FindClassDeclarationBackwards(LLines, LRelativeLine);
    if LClassStartLine = -1 then
      Exit;

    LClassEndLine := FindClassDeclarationEnd(LLines, LClassStartLine);

    LSb := TStringBuilder.Create;
    try
      for I := LClassStartLine to LClassEndLine do
        LSb.AppendLine(LLines[I]);
      Result := LSb.ToString;
    finally
      LSb.Free;
    end;
  finally
    LLines.Free;
  end;
end;

class function TRadIAContextParser.TryGetMethodExampleContext(const ASourceCode: string;
  const ACursorLine: Integer; out AContext: TMethodExampleContext; out AErrorMessage: string): Boolean;
var
  LLines: TStringList;
  LCursorIndex: Integer;
  LMethodStartLine: Integer;
  LBeginLine: Integer;
  LEndLine: Integer;
  LCommentStartLine: Integer;
  LCommentEndLine: Integer;
  I: Integer;
  LLine: string;
  LBuilder: TStringBuilder;
  LInBraceComment: Boolean;
  LInParenComment: Boolean;
begin
  Result := False;
  AContext := Default(TMethodExampleContext);
  AErrorMessage := '';

  if ASourceCode.Trim.IsEmpty then
  begin
    AErrorMessage := 'No active code file open in the editor.';
    Exit;
  end;

  LLines := TStringList.Create;
  try
    LLines.Text := ASourceCode;
    LCursorIndex := ACursorLine - 1;
    if (LCursorIndex < 0) or (LCursorIndex >= LLines.Count) then
    begin
      AErrorMessage := 'Place the cursor inside a method body before using Create Example from Comment.';
      Exit;
    end;

    LMethodStartLine := -1;
    for I := LCursorIndex downto 0 do
    begin
      if IsMethodDeclarationLine(LLines[I]) then
      begin
        LMethodStartLine := I;
        Break;
      end;

      if SameText(LLines[I].Trim, 'implementation') then
        Break;
    end;

    if LMethodStartLine < 0 then
    begin
      AErrorMessage := 'Place the cursor inside an implementation method before using Create Example from Comment.';
      Exit;
    end;

    LBeginLine := -1;
    LInBraceComment := False;
    LInParenComment := False;
    for I := LMethodStartLine to LCursorIndex do
    begin
      LLine := StripCommentsAndStrings(LLines[I], LInBraceComment, LInParenComment).Trim.ToLower;
      if SameText(LLine, 'begin') or LLine.EndsWith(' begin') or LLine.Contains(' begin ') then
      begin
        LBeginLine := I;
        Break;
      end;
    end;

    if LBeginLine < 0 then
    begin
      AErrorMessage := 'Place the cursor inside the method body, after begin.';
      Exit;
    end;

    LEndLine := FindMatchingMethodEnd(LLines, LBeginLine);
    if (LEndLine < 0) or (LCursorIndex > LEndLine) then
    begin
      AErrorMessage := 'Could not locate the end of the current method.';
      Exit;
    end;

    if not TryExtractFirstBodyComment(LLines, LBeginLine + 1, LEndLine - 1,
      AContext.CommentText, LCommentStartLine, LCommentEndLine) then
    begin
      AErrorMessage := 'Add a natural-language comment inside the empty method body before using Create ' +
          'Example from Comment.';
      Exit;
    end;

    if not IsOnlyWhitespaceOrComment(LLines, LBeginLine + 1, LEndLine - 1,
      LCommentStartLine, LCommentEndLine) then
    begin
      AErrorMessage := 'Create Example from Comment only works when the method body is empty except for the comment.';
      Exit;
    end;

    AContext.BodyIndent := GetLeadingWhitespace(LLines[LCommentStartLine]);
    AContext.InsertionLine := LCommentEndLine + 2;
    AContext.InsertionColumn := 1;

    LBuilder := TStringBuilder.Create;
    try
      for I := LMethodStartLine to LEndLine do
        LBuilder.AppendLine(LLines[I]);
      AContext.MethodText := LBuilder.ToString.TrimRight;
    finally
      LBuilder.Free;
    end;

    Result := True;
  finally
    LLines.Free;
  end;
end;

end.
