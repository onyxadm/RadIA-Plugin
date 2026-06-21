unit RadIA.UI.Resources;

interface

uses
  Vcl.Forms, Vcl.Graphics, System.SysUtils;

type
  TRadIAThemeColors = record
    IsDark: Boolean;
    BgBase: TColor;
    TextColor: TColor;
    InputBgColor: TColor;
    BorderColor: TColor;
    AccentColor: TColor;
    BgElevated: TColor;
    FgSecondary: string;
    CodeBg: string;
    CodeHeader: TColor;
    GreenApply: string;
    class function GetColorsForTheme(const AThemeName: string): TRadIAThemeColors; static;
  end;

  TRadIAUIHelper = class
  public
    class procedure ApplyDarkTitleBar(AForm: TForm; const AEnable: Boolean);
  end;

function IsThemeDark(const AThemeName: string): Boolean;

implementation

uses
  Winapi.Windows, Winapi.Dwmapi;

const
  RADIA_DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  RADIA_DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1 = 19;

{ TRadIAUIHelper }

class procedure TRadIAUIHelper.ApplyDarkTitleBar(AForm: TForm; const AEnable: Boolean);
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

function IsThemeDark(const AThemeName: string): Boolean;
begin
  Result := AThemeName.ToLower.Contains('dark') or
            SameText(AThemeName, 'carbon') or
            SameText(AThemeName, 'glow') or
            SameText(AThemeName, 'onyx');
end;

{ TRadIAThemeColors }

class function TRadIAThemeColors.GetColorsForTheme(const AThemeName: string): TRadIAThemeColors;
begin
  Result.IsDark := IsThemeDark(AThemeName);

  if Result.IsDark then
  begin
    Result.BgBase := $004A4136;
    Result.TextColor := $00F0F0F0;
    Result.InputBgColor := $00322F2D;
    Result.BorderColor := $006A6053;
    Result.AccentColor := $00CC7A00;
    Result.BgElevated := $00322F2D;
    Result.FgSecondary := '#C7D1D8';
    Result.CodeBg := '#2D2F32';
    Result.CodeHeader := $00322F2D;
    Result.GreenApply := '#3AA655';
  end
  else
  begin
    Result.BgBase := clBtnFace;
    Result.TextColor := clWindowText;
    Result.InputBgColor := clWindow;
    Result.BorderColor := $00C8C8C8;
    Result.AccentColor := $009E5A00;
    Result.BgElevated := $00EAEAEA;
    Result.FgSecondary := '#6e6e6e';
    Result.CodeBg := '#ffffff';
    Result.CodeHeader := $00F0F0F0;
    Result.GreenApply := '#237c3c';
  end;
end;

end.
