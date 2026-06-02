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
    class function GetCurrentEditBuffer: IOTAEditBuffer;
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

class function TRadIAOTAHelper.GetActiveEditorText(out AText: string; const ASelectedOnly: Boolean): Boolean;
var
  LEditBuffer: IOTAEditBuffer;
  LEditBlock: IOTAEditBlock;
  LEditReader: IOTAEditReader;
  LCharCount: Integer;
  LBufferText: AnsiString;
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
    LCharCount := LEditBuffer.BufferLinesCount; // Approximation or read via EditReader
    LEditReader := LEditBuffer.CreateReader;
    if Assigned(LEditReader) then
    begin
      SetLength(LBufferText, LEditBuffer.CreateReader.GetText(0, nil, 0)); // Get size first
      LBytesRead := LEditReader.GetText(0, PAnsiChar(LBufferText), Length(LBufferText));
      SetLength(LBufferText, LBytesRead);
      AText := string(LBufferText);
      Result := True;
    end;
  end;
end;

class function TRadIAOTAHelper.ReplaceActiveEditorText(const ANewText: string): Boolean;
var
  LEditBuffer: IOTAEditBuffer;
  LEditBlock: IOTAEditBlock;
  LPosition: IOTAEditPosition;
begin
  Result := False;
  LEditBuffer := GetCurrentEditBuffer;
  if not Assigned(LEditBuffer) then
    Exit;

  LEditBlock := LEditBuffer.EditBlock;
  if Assigned(LEditBlock) and (LEditBlock.Size > 0) then
  begin
    LPosition := LEditBuffer.EditViews[0].Position;
    LPosition.Move(LEditBlock.StartRow, LEditBlock.StartColumn);
    LEditBlock.Delete;
    LEditBuffer.EditViews[0].Position.InsertText(ANewText);
    Result := True;
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
begin
  Result := False;
  LEditBuffer := GetCurrentEditBuffer;
  if Assigned(LEditBuffer) and (LEditBuffer.EditViewsCount > 0) then
  begin
    LView := LEditBuffer.EditViews[0];
    if Assigned(LView) and Assigned(LView.Position) then
    begin
      LView.Position.InsertText(AText);
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
  LModule: IOTAModule;
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

end.
