unit RadIA.OTA.MessageViewHook;

interface

uses
  System.SysUtils, System.Classes, ToolsAPI;

type
  { Class to interface and hook compiler errors from Delphi Messages View }
  TRadIAMessageViewHook = class
  public
    class function GetLastCompilerError(out AErrorMessage: string; out AFileName: string; out ALine: Integer): Boolean;
  end;

implementation

{ TRadIAMessageViewHook }

class function TRadIAMessageViewHook.GetLastCompilerError(out AErrorMessage: string; out AFileName: string; out ALine: Integer): Boolean;
var
  LMessageServices: IOTAMessageServices;
  LGroup: IOTAMessageGroup;
  I: Integer;
  LMsgText: string;
  LRef: string;
  LPosColon1, LPosColon2: Integer;
begin
  Result := False;
  AErrorMessage := '';
  AFileName := '';
  ALine := 0;
  
  if not Supports(BorlandIDEServices, IOTAMessageServices, LMessageServices) then
    Exit;
    
  { Get the main build messages group }
  LGroup := LMessageServices.GetGroup('Build');
  if not Assigned(LGroup) then
    Exit;
    
  { Iterate backwards to find the last error }
  for I := LGroup.MessageCount - 1 downto 0 do
  begin
    LMsgText := LGroup.GetMessage(I);
    
    { Delphi compiler errors usually look like: 
      "D:\Path\Unit1.pas(25): E2003 Undefined identifier: 'SomeVar'"
      or contain "Error:" or "[dcc32 Error]" }
    if (Pos('Error:', LMsgText) > 0) or (Pos('error', LowerCase(LMsgText)) > 0) or (Pos('): E', LMsgText) > 0) then
    begin
      { Parse line number and file path if formatted as Path(Line): E... }
      LPosColon1 := Pos('(', LMsgText);
      LPosColon2 := Pos('):', LMsgText);
      if (LPosColon1 > 0) and (LPosColon2 > LPosColon1) then
      begin
        AFileName := Copy(LMsgText, 1, LPosColon1 - 1);
        LRef := Copy(LMsgText, LPosColon1 + 1, LPosColon2 - LPosColon1 - 1);
        TryStrToInt(LRef, ALine);
        AErrorMessage := Copy(LMsgText, LPosColon2 + 2, Length(LMsgText)).Trim;
      end
      else
      begin
        AErrorMessage := LMsgText;
      end;
      
      Result := True;
      Break;
    end;
  end;
end;

end.
