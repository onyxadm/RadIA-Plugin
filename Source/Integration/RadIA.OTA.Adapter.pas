unit RadIA.OTA.Adapter;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Interfaces;

type
  TConcreteIDEAdapter = class(TInterfacedObject, IIDEAdapter)
  public
    function GetActiveEditorText(out AText: string; const ASelectedOnly: Boolean = True): Boolean;
    function ReplaceActiveEditorText(const ANewText: string; const AReplaceWholeBuffer: Boolean = False;
      const AOriginalText: string = ''): Boolean;
    function InsertTextAtCursor(const AText: string): Boolean;
    function InsertTextAtLineColumn(const AText: string; const ALine, AColumn: Integer): Boolean;
    function GetCurrentCursorLine: Integer;
    function GetActiveUnitName: string;
    function GetActiveProjectName: string;
    function GetActiveProjectFolder: string;
    function OpenProjectInIDE(const AProjectPath: string): Boolean;
    function GetDelphiVersionName: string;
    function GetPreferredLanguageInstruction: string;
    function GetLastCompilerError(out AErrorMsg: string; out AFileName: string; out ALine: Integer): Boolean;
  end;

implementation

uses
  RadIA.OTA.Helper, RadIA.OTA.MessageViewHook;

{ TConcreteIDEAdapter }

function TConcreteIDEAdapter.GetActiveEditorText(out AText: string; const ASelectedOnly: Boolean): Boolean;
begin
  Result := TRadIAOTAHelper.GetActiveEditorText(AText, ASelectedOnly);
end;

function TConcreteIDEAdapter.ReplaceActiveEditorText(const ANewText: string; const AReplaceWholeBuffer: Boolean;
  const AOriginalText: string): Boolean;
begin
  Result := TRadIAOTAHelper.ReplaceActiveEditorText(ANewText, AReplaceWholeBuffer, AOriginalText);
end;

function TConcreteIDEAdapter.InsertTextAtCursor(const AText: string): Boolean;
begin
  Result := TRadIAOTAHelper.InsertTextAtCursor(AText);
end;

function TConcreteIDEAdapter.InsertTextAtLineColumn(const AText: string; const ALine, AColumn: Integer): Boolean;
begin
  Result := TRadIAOTAHelper.InsertTextAtLineColumn(AText, ALine, AColumn);
end;

function TConcreteIDEAdapter.GetCurrentCursorLine: Integer;
begin
  Result := TRadIAOTAHelper.GetCurrentCursorLine;
end;

function TConcreteIDEAdapter.GetActiveUnitName: string;
begin
  Result := TRadIAOTAHelper.GetActiveUnitName;
end;

function TConcreteIDEAdapter.GetActiveProjectName: string;
begin
  Result := TRadIAOTAHelper.GetActiveProjectName;
end;

function TConcreteIDEAdapter.GetActiveProjectFolder: string;
begin
  Result := TRadIAOTAHelper.GetActiveProjectFolder;
end;

function TConcreteIDEAdapter.OpenProjectInIDE(const AProjectPath: string): Boolean;
begin
  Result := TRadIAOTAHelper.OpenProjectInIDE(AProjectPath);
end;

function TConcreteIDEAdapter.GetDelphiVersionName: string;
begin
  Result := TRadIAOTAHelper.GetDelphiVersionName;
end;

function TConcreteIDEAdapter.GetPreferredLanguageInstruction: string;
begin
  Result := TRadIAOTAHelper.GetPreferredLanguageInstruction;
end;

function TConcreteIDEAdapter.GetLastCompilerError(out AErrorMsg: string; out AFileName: string; out ALine: Integer): Boolean;
begin
  Result := TRadIAMessageViewHook.GetLastCompilerError(AErrorMsg, AFileName, ALine);
end;

end.
