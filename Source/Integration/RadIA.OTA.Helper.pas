unit RadIA.OTA.Helper;

interface

uses
  System.SysUtils, System.Classes, ToolsAPI;

type
  { Helper class for interacting with Delphi Open Tools API (OTA) }
  TRadIAOTAHelper = class
  private
    class function FormatTextWithIndent(const AText: string; const APosition: IOTAEditPosition): string;
    class function ReadEditorText(const AEditReader: IOTAEditReader; out AText: string): Boolean;
    class function ReadBufferText(const AEditBuffer: IOTAEditBuffer; out AText: string): Boolean;
    class function ReadCurrentSourceEditorText(out AText: string): Boolean;
    class procedure RefreshEditView(const AView: IOTAEditView);
  public
    class function GetActiveEditorText(out AText: string; const ASelectedOnly: Boolean = True): Boolean;
    class function ReplaceActiveEditorText(const ANewText: string; const AReplaceWholeBuffer: Boolean = False;
      const AOriginalText: string = ''): Boolean;
    class function InsertTextAtCursor(const AText: string): Boolean;
    class function InsertTextAtLineColumn(const AText: string; const ALine, AColumn: Integer): Boolean;
    class function GetCurrentCursorLine: Integer;
    class function GetActiveUnitName: string;
    class function GetActiveProjectName: string;
    class function GetActiveProjectFolder: string;
    class function GetCurrentEditBuffer: IOTAEditBuffer;
    class function GetCurrentEditView: IOTAEditView;
    class function OpenProjectInIDE(const AProjectPath: string): Boolean;
    class function GetDelphiVersionName: string;
    class function GetPreferredLanguageInstruction: string;
  end;

implementation

uses
  Winapi.Windows;

{ TRadIAOTAHelper }

class function TRadIAOTAHelper.GetCurrentEditBuffer: IOTAEditBuffer;
var
  LEditorServices: IOTAEditorServices;
begin
  Result := nil;
  if Supports(BorlandIDEServices, IOTAEditorServices, LEditorServices) then
  begin
    Result := LEditorServices.TopBuffer;
  end;
end;

class function TRadIAOTAHelper.GetCurrentEditView: IOTAEditView;
var
  LEditorServices: IOTAEditorServices;
begin
  Result := nil;
  if Supports(BorlandIDEServices, IOTAEditorServices, LEditorServices) then
  begin
    Result := LEditorServices.TopView;
  end;
end;

class function TRadIAOTAHelper.ReadEditorText(const AEditReader: IOTAEditReader; out AText: string): Boolean;
var
  LBuffer: TBytes;
  LTextBytes: TBytes;
  LBytesRead: Integer;
  LOffset: Integer;
const
  CChunkSize = 8192;
begin
  Result := False;
  AText := '';

  if not Assigned(AEditReader) then
    Exit;

  SetLength(LBuffer, CChunkSize);
  LOffset := 0;
  repeat
    LBytesRead := AEditReader.GetText(LOffset, PAnsiChar(@LBuffer[0]), CChunkSize);
    if LBytesRead > 0 then
    begin
      SetLength(LTextBytes, Length(LTextBytes) + LBytesRead);
      Move(LBuffer[0], LTextBytes[Length(LTextBytes) - LBytesRead], LBytesRead);
      Inc(LOffset, LBytesRead);
    end;
  until LBytesRead < CChunkSize;

  if Length(LTextBytes) > 0 then
  begin
    AText := TEncoding.UTF8.GetString(LTextBytes);
    if (Length(AText) > 0) and (AText[Length(AText)] = #0) then
      SetLength(AText, Length(AText) - 1);
  end;

  Result := True;
end;

class function TRadIAOTAHelper.ReadBufferText(const AEditBuffer: IOTAEditBuffer; out AText: string): Boolean;
begin
  Result := False;
  AText := '';

  if not Assigned(AEditBuffer) then
    Exit;

  Result := ReadEditorText(AEditBuffer.CreateReader, AText);
end;

class function TRadIAOTAHelper.ReadCurrentSourceEditorText(out AText: string): Boolean;
var
  LModuleServices: IOTAModuleServices;
  LModule: IOTAModule;
  LSourceEditor: IOTASourceEditor;
  I: Integer;
begin
  Result := False;
  AText := '';

  if not Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) then
    Exit;

  LModule := LModuleServices.CurrentModule;
  if not Assigned(LModule) then
    Exit;

  for I := 0 to LModule.GetModuleFileCount - 1 do
  begin
    if Supports(LModule.GetModuleFileEditor(I), IOTASourceEditor, LSourceEditor) then
    begin
      Result := ReadEditorText(LSourceEditor.CreateReader, AText);
      Exit;
    end;
  end;
end;

class procedure TRadIAOTAHelper.RefreshEditView(const AView: IOTAEditView);
begin
  if not Assigned(AView) then
    Exit;

  try
    AView.MoveCursorToView;
    AView.MoveViewToCursor;
    AView.Paint;
  except
    { Editor refresh is best-effort; the text operation has already succeeded. }
  end;
end;

class function TRadIAOTAHelper.GetActiveEditorText(out AText: string; const ASelectedOnly: Boolean): Boolean;
var
  LEditBuffer: IOTAEditBuffer;
  LEditBlock: IOTAEditBlock;
begin
  Result := False;
  AText := '';
  
  LEditBuffer := GetCurrentEditBuffer;
  if ASelectedOnly and (not Assigned(LEditBuffer)) then
    Exit;
    
  if ASelectedOnly then
  begin
    LEditBlock := LEditBuffer.EditBlock;
    if Assigned(LEditBlock) and (LEditBlock.Size > 0) then
    begin
      AText := LEditBlock.Text;
      Result := True;
    end;
  end
  else
  begin
    { Read the entire buffer }
    Result := ReadBufferText(LEditBuffer, AText);
    if (not Result) or AText.Trim.IsEmpty then
      Result := ReadCurrentSourceEditorText(AText);
  end;
end;

class function TRadIAOTAHelper.FormatTextWithIndent(const AText: string; const APosition: IOTAEditPosition): string;
var
  LOriginalCol, LOriginalRow: Integer;
  LPrefix: string;
  LCol: Integer;
  LLines: TStringList;
  I: Integer;
begin
  Result := AText;
  if not Assigned(APosition) then
    Exit;

  LOriginalCol := APosition.GetColumn;
  LOriginalRow := APosition.GetRow;
  LPrefix := '';

  APosition.Save;
  try
    APosition.Move(LOriginalRow, 1);
    for LCol := 1 to LOriginalCol - 1 do
    begin
      if APosition.Character = #9 then
        LPrefix := LPrefix + #9
      else if APosition.Character = ' ' then
        LPrefix := LPrefix + ' '
      else
        LPrefix := LPrefix + ' ';
      APosition.Move(LOriginalRow, LCol + 1);
    end;
  finally
    APosition.Restore;
  end;

  if LPrefix = '' then
    Exit;

  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    if LLines.Count > 1 then
    begin
      for I := 1 to LLines.Count - 1 do
      begin
        if LLines[I] <> '' then
          LLines[I] := LPrefix + LLines[I];
      end;
      Result := LLines.Text;
      if (Length(AText) > 0) and (AText[Length(AText)] <> #10) and
         (Length(Result) >= 2) and (Result[Length(Result) - 1] = #13) and (Result[Length(Result)] = #10) then
      begin
        SetLength(Result, Length(Result) - 2);
      end;
    end;
  finally
    LLines.Free;
  end;
end;

class function TRadIAOTAHelper.ReplaceActiveEditorText(const ANewText: string; const AReplaceWholeBuffer: Boolean;
  const AOriginalText: string): Boolean;
var
  LEditBuffer: IOTAEditBuffer;
  LEditBlock: IOTAEditBlock;
  LEditWriter: IOTAEditWriter;
  LView: IOTAEditView;
  LPosition: IOTAEditPosition;
  LOptions: IOTABufferOptions;
  LSaveAutoIndent: Boolean;
  LFormattedText: string;
  LBufferSize: Integer;
  LBufferText: string;
  LMatchPos: Integer;
  LStartOffset: Integer;
  LEndOffset: Integer;
  LUtf8Text: UTF8String;
begin
  Result := False;
  LEditBuffer := GetCurrentEditBuffer;
  LView := GetCurrentEditView;
  if not Assigned(LEditBuffer) or not Assigned(LView) then
    Exit;

  if AReplaceWholeBuffer then
  begin
    LBufferText := '';
    if ReadBufferText(LEditBuffer, LBufferText) then
      LBufferSize := Length(UTF8String(LBufferText))
    else
      LBufferSize := 0;

    LEditWriter := LEditBuffer.CreateUndoableWriter;
    if not Assigned(LEditWriter) then
      Exit;

    LEditWriter.CopyTo(0);
    if LBufferSize > 0 then
      LEditWriter.DeleteTo(LBufferSize);

    LUtf8Text := UTF8String(ANewText);
    LEditWriter.Insert(PAnsiChar(LUtf8Text));
    Result := True;
    RefreshEditView(LView);
    Exit;
  end;

  LEditBlock := LEditBuffer.EditBlock;
  if Assigned(LEditBlock) and (LEditBlock.Size > 0) then
  begin
    LPosition := LView.Position;
    LPosition.Move(LEditBlock.StartingRow, LEditBlock.StartingColumn);
    LEditBlock.Delete;
  end;

  if ((not Assigned(LEditBlock)) or (LEditBlock.Size <= 0)) and (not AOriginalText.Trim.IsEmpty) then
  begin
    LBufferText := '';
    if not ReadBufferText(LEditBuffer, LBufferText) then
      Exit;

    LMatchPos := Pos(AOriginalText, LBufferText);
    if LMatchPos <= 0 then
      Exit;

    LEditWriter := LEditBuffer.CreateUndoableWriter;
    if not Assigned(LEditWriter) then
      Exit;

    LStartOffset := Length(UTF8String(Copy(LBufferText, 1, LMatchPos - 1)));
    LEndOffset := LStartOffset + Length(UTF8String(AOriginalText));

    LEditWriter.CopyTo(LStartOffset);
    LEditWriter.DeleteTo(LEndOffset);

    LUtf8Text := UTF8String(ANewText);
    LEditWriter.Insert(PAnsiChar(LUtf8Text));
    Result := True;
    RefreshEditView(LView);
    Exit;
  end;

  LPosition := LView.Position;
  LFormattedText := FormatTextWithIndent(ANewText, LPosition);

  LOptions := LEditBuffer.BufferOptions;
  if Assigned(LOptions) then
  begin
    LSaveAutoIndent := LOptions.AutoIndent;
    LOptions.AutoIndent := False;
    try
      LPosition.InsertText(LFormattedText);
      Result := True;
    finally
      LOptions.AutoIndent := LSaveAutoIndent;
    end;
  end
  else
  begin
    LPosition.InsertText(LFormattedText);
    Result := True;
  end;

  if Result then
    RefreshEditView(LView);
end;

class function TRadIAOTAHelper.InsertTextAtCursor(const AText: string): Boolean;
var
  LEditBuffer: IOTAEditBuffer;
  LView: IOTAEditView;
  LPosition: IOTAEditPosition;
  LOptions: IOTABufferOptions;
  LSaveAutoIndent: Boolean;
  LFormattedText: string;
begin
  Result := False;
  LEditBuffer := GetCurrentEditBuffer;
  LView := GetCurrentEditView;
  if Assigned(LEditBuffer) and Assigned(LView) and Assigned(LView.Position) then
  begin
    LPosition := LView.Position;
    LFormattedText := FormatTextWithIndent(AText, LPosition);

    LOptions := LEditBuffer.BufferOptions;
    if Assigned(LOptions) then
    begin
      LSaveAutoIndent := LOptions.AutoIndent;
      LOptions.AutoIndent := False;
      try
        LPosition.InsertText(LFormattedText);
        Result := True;
      finally
        LOptions.AutoIndent := LSaveAutoIndent;
      end;
    end
    else
    begin
      LPosition.InsertText(LFormattedText);
      Result := True;
    end;

    if Result then
      RefreshEditView(LView);
  end;
end;

class function TRadIAOTAHelper.InsertTextAtLineColumn(const AText: string; const ALine, AColumn: Integer): Boolean;
var
  LEditBuffer: IOTAEditBuffer;
  LView: IOTAEditView;
  LPosition: IOTAEditPosition;
  LOptions: IOTABufferOptions;
  LSaveAutoIndent: Boolean;
begin
  Result := False;
  if (ALine <= 0) or (AColumn <= 0) then
    Exit;

  LEditBuffer := GetCurrentEditBuffer;
  LView := GetCurrentEditView;
  if Assigned(LEditBuffer) and Assigned(LView) and Assigned(LView.Position) then
  begin
    LPosition := LView.Position;
    LPosition.Move(ALine, AColumn);

    LOptions := LEditBuffer.BufferOptions;
    if Assigned(LOptions) then
    begin
      LSaveAutoIndent := LOptions.AutoIndent;
      LOptions.AutoIndent := False;
      try
        LPosition.InsertText(AText);
        Result := True;
      finally
        LOptions.AutoIndent := LSaveAutoIndent;
      end;
    end
    else
    begin
      LPosition.InsertText(AText);
      Result := True;
    end;

    if Result then
      RefreshEditView(LView);
  end;
end;

class function TRadIAOTAHelper.GetCurrentCursorLine: Integer;
var
  LView: IOTAEditView;
begin
  Result := 0;
  LView := GetCurrentEditView;
  if Assigned(LView) and Assigned(LView.Position) then
    Result := LView.Position.GetRow;
end;

class function TRadIAOTAHelper.GetActiveUnitName: string;
var
  LEditBuffer: IOTAEditBuffer;
begin
  Result := '';
  LEditBuffer := GetCurrentEditBuffer;
  if Assigned(LEditBuffer) then
  begin
    Result := ChangeFileExt(ExtractFileName(LEditBuffer.FileName), '');
  end;
end;

class function TRadIAOTAHelper.GetActiveProjectName: string;
var
  LModuleServices: IOTAModuleServices;
  LProject: IOTAProject;
begin
  Result := '';
  if Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) then
  begin
    LProject := LModuleServices.GetActiveProject;
    if Assigned(LProject) then
    begin
      Result := ChangeFileExt(ExtractFileName(LProject.FileName), '');
    end;
  end;
end;

class function TRadIAOTAHelper.GetActiveProjectFolder: string;
var
  LModuleServices: IOTAModuleServices;
  LProject: IOTAProject;
begin
  Result := '';
  if Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) then
  begin
    LProject := LModuleServices.GetActiveProject;
    if Assigned(LProject) then
    begin
      Result := ExtractFilePath(LProject.FileName);
    end;
  end;
end;

class function TRadIAOTAHelper.OpenProjectInIDE(const AProjectPath: string): Boolean;
var
  LModuleServices: IOTAModuleServices;
begin
  Result := False;
  if Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) then
  begin
    LModuleServices.OpenModule(AProjectPath);
    Result := True;
  end;
end;

class function TRadIAOTAHelper.GetDelphiVersionName: string;
begin
  {$IF CompilerVersion = 37.0}
  Result := 'Delphi 13 Florence';
  {$ELSEIF CompilerVersion = 36.0}
  Result := 'Delphi 12 Athens';
  {$ELSEIF CompilerVersion = 35.0}
  Result := 'Delphi 11 Alexandria';
  {$ELSEIF CompilerVersion = 34.0}
  Result := 'Delphi 10.4 Sydney';
  {$ELSEIF CompilerVersion = 33.0}
  Result := 'Delphi 10.3 Rio';
  {$ELSEIF CompilerVersion = 32.0}
  Result := 'Delphi 10.2 Tokyo';
  {$ELSEIF CompilerVersion = 31.0}
  Result := 'Delphi 10.1 Berlin';
  {$ELSEIF CompilerVersion = 30.0}
  Result := 'Delphi 10 Seattle';
  {$ELSEIF CompilerVersion = 29.0}
  Result := 'Delphi XE8';
  {$ELSE}
  Result := 'Delphi (CompilerVersion ' + FloatToStr(CompilerVersion) + ')';
  {$ENDIF}
end;

class function TRadIAOTAHelper.GetPreferredLanguageInstruction: string;
var
  LLangID: LANGID;
  LPrimaryLang: Byte;
begin
  LLangID := GetUserDefaultUILanguage;
  LPrimaryLang := LLangID and $3FF;
  
  case LPrimaryLang of
    $16: Result := 'Please reply in Brazilian Portuguese.'; // LANG_PORTUGUESE
    $0A: Result := 'Please reply in Spanish.';              // LANG_SPANISH
    $0C: Result := 'Please reply in French.';               // LANG_FRENCH
    $07: Result := 'Please reply in German.';               // LANG_GERMAN
    $10: Result := 'Please reply in Italian.';              // LANG_ITALIAN
    else
      Result := 'Please reply in English.';                 // Default
  end;
end;

end.
