unit RadIA.UI.Resources;

interface

uses
  Vcl.Forms;

type
  TUIHelper = class
  public
    class procedure ApplyDarkTitleBar(AForm: TForm; const AEnable: Boolean);
  end;

implementation

uses
  Winapi.Windows, Winapi.Dwmapi;

const
  RADIA_DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  RADIA_DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1 = 19;

{ TUIHelper }

class procedure TUIHelper.ApplyDarkTitleBar(AForm: TForm; const AEnable: Boolean);
var
  LValue: DWORD;
begin
  if not Assigned(AForm) then
    Exit;

  if AEnable then
    LValue := 1
  else
    LValue := 0;

  { Tenta aplicar usando o atributo moderno do Windows 10 20H1+ e Windows 11 (20) }
  if DwmSetWindowAttribute(AForm.Handle, RADIA_DWMWA_USE_IMMERSIVE_DARK_MODE, @LValue, SizeOf(LValue)) <> S_OK then
  begin
    { Fallback para builds anteriores do Windows 10 entre 1809 e 1909 (19) }
    DwmSetWindowAttribute(AForm.Handle, RADIA_DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1, @LValue, SizeOf(LValue));
  end;
end;

end.
