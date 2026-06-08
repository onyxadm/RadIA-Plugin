unit RadIA.OTA.Helper;

interface

uses
  System.SysUtils, System.Classes, ToolsAPI;

type
  { Helper class for interacting with Delphi Open Tools API (OTA) }
  TRadIAOTAHelper = class
  private
    class function FormatTextWithIndent(const AText: string; const APosition: IOTAEditPosition): string;
  public
    class function GetActiveEditorText(out AText: string; const ASelectedOnly: Boolean = True): Boolean;
    class function ReplaceActiveEditorText(const ANewText: string): Boolean;
    class function InsertTextAtCursor(const AText: string): Boolean;
    class function GetActiveUnitName: string;
    class function GetActiveProjectName: string;
    class function GetActiveProjectFolder: string;
    class function GetCurrentEditBuffer: IOTAEditBuffer;
    class function GetCurrentEditView: IOTAEditView;
    class function OpenProjectInIDE(const AProjectPath: string): Boolean;
  end;

implementation

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

class function TRadIAOTAHelper.GetActiveEditorText(out AText: string; const ASelectedOnly: Boolean): Boolean;
var
  LEditBuffer: IOTAEditBuffer;
  LEditBlock: IOTAEditBlock;
  LEditReader: IOTAEditReader;
  LBytes: TBytes;
  LBytesRead: Integer;
begin
  Result := False;
  AText := '';
  
  LEditBuffer := GetCurrentEditBuffer;
  if not Assigned(LEditBuffer) then
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
    LEditReader := LEditBuffer.CreateReader;
    if Assigned(LEditReader) then
    begin
      SetLength(LBytes, LEditReader.GetText(0, nil, 0)); // Get size first
      if Length(LBytes) > 0 then
      begin
        LBytesRead := LEditReader.GetText(0, PAnsiChar(@LBytes[0]), Length(LBytes));
        SetLength(LBytes, LBytesRead);
        AText := TEncoding.UTF8.GetString(LBytes);
        Result := True;
      end
      else
      begin
        AText := '';
        Result := True;
      end;
    end;
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

class function TRadIAOTAHelper.ReplaceActiveEditorText(const ANewText: string): Boolean;
var
  LEditBuffer: IOTAEditBuffer;
  LEditBlock: IOTAEditBlock;
  LView: IOTAEditView;
  LPosition: IOTAEditPosition;
  LOptions: IOTABufferOptions;
  LSaveAutoIndent: Boolean;
  LFormattedText: string;
begin
  Result := False;
  LEditBuffer := GetCurrentEditBuffer;
  LView := GetCurrentEditView;
  if not Assigned(LEditBuffer) or not Assigned(LView) then
    Exit;

  LEditBlock := LEditBuffer.EditBlock;
  if Assigned(LEditBlock) and (LEditBlock.Size > 0) then
  begin
    LPosition := LView.Position;
    LPosition.Move(LEditBlock.StartingRow, LEditBlock.StartingColumn);
    LEditBlock.Delete;
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
  end;
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

end.
