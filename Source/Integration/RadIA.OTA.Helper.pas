unit RadIA.OTA.Helper;

interface

uses
  System.SysUtils, System.Classes, ToolsAPI;

type
  { Helper class for interacting with Delphi Open Tools API (OTA) }
  TRadIAOTAHelper = class
  public
    class function GetActiveEditorText(out AText: string; const ASelectedOnly: Boolean = True): Boolean;
    class function ReplaceActiveEditorText(const ANewText: string): Boolean;
    class function InsertTextAtCursor(const AText: string): Boolean;
    class function GetActiveUnitName: string;
    class function GetActiveProjectName: string;
    class function GetActiveProjectFolder: string;
    class function GetCurrentEditBuffer: IOTAEditBuffer;
    class function GetCurrentEditView: IOTAEditView;
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

class function TRadIAOTAHelper.ReplaceActiveEditorText(const ANewText: string): Boolean;
var
  LEditBuffer: IOTAEditBuffer;
  LEditBlock: IOTAEditBlock;
  LView: IOTAEditView;
  LPosition: IOTAEditPosition;
  LWriter: IOTAEditWriter;
  LCharPos: TOTACharPos;
  LStartPos: Longint;
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
    
    LCharPos.Line := LPosition.GetRow;
    LCharPos.CharIndex := LPosition.GetColumn - 1;
    LStartPos := LView.CharPosToPos(LCharPos);
    
    LWriter := LEditBuffer.CreateWriter;
    if Assigned(LWriter) then
    begin
      LWriter.CopyTo(LStartPos);
      LWriter.Insert(PAnsiChar(UTF8String(ANewText)));
      Result := True;
    end;
  end
  else
  begin
    { Fallback to insertion if no selection }
    Result := InsertTextAtCursor(ANewText);
  end;
end;

class function TRadIAOTAHelper.InsertTextAtCursor(const AText: string): Boolean;
var
  LEditBuffer: IOTAEditBuffer;
  LView: IOTAEditView;
  LWriter: IOTAEditWriter;
  LCharPos: TOTACharPos;
  LPos: Longint;
begin
  Result := False;
  LEditBuffer := GetCurrentEditBuffer;
  LView := GetCurrentEditView;
  if Assigned(LEditBuffer) and Assigned(LView) and Assigned(LView.Position) then
  begin
    LCharPos.Line := LView.Position.GetRow;
    LCharPos.CharIndex := LView.Position.GetColumn - 1;
    LPos := LView.CharPosToPos(LCharPos);
    
    LWriter := LEditBuffer.CreateWriter;
    if Assigned(LWriter) then
    begin
      LWriter.CopyTo(LPos);
      LWriter.Insert(PAnsiChar(UTF8String(AText)));
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

end.
