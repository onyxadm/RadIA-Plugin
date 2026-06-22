unit RadIA.OTA.MessageViewHook;

interface

type
  { Class to interface and hook compiler errors from Delphi Messages View }
  TRadIAMessageViewHook = class
  public
    class function GetLastCompilerError(out AErrorMessage: string; out AFileName: string; out ALine: Integer): Boolean;
  end;

implementation


uses
  System.SysUtils, ToolsAPI;

{ TRadIAMessageViewHook }

class function TRadIAMessageViewHook.GetLastCompilerError(out AErrorMessage: string; out AFileName: string; out ALine: Integer): Boolean;
var
  LModuleServices: IOTAModuleServices;
  LModule: IOTAModule;
  LModuleErrors: IOTAModuleErrors;
  LErrors: TOTAErrors;
  I: Integer;
begin
  Result := False;
  AErrorMessage := '';
  AFileName := '';
  ALine := 0;

  if not Supports(BorlandIDEServices, IOTAModuleServices, LModuleServices) then
    Exit;

  LModule := LModuleServices.CurrentModule;
  if not Assigned(LModule) then
    Exit;

  if Supports(LModule, IOTAModuleErrors, LModuleErrors) then
  begin
    AFileName := LModule.FileName;
    LErrors := LModuleErrors.GetErrors(AFileName);
    for I := 0 to Length(LErrors) - 1 do
    begin
      if LErrors[I].Severity = 1 then { 1 = Error }
      begin
        AErrorMessage := LErrors[I].Text;
        ALine := LErrors[I].Start.Line;
        Result := True;
        Exit;
      end;
    end;
  end;
end;

end.
