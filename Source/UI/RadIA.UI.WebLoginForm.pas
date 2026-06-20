unit RadIA.UI.WebLoginForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Buttons,
  Vcl.StdCtrls, Vcl.Edge, System.IOUtils, Winapi.WebView2, Winapi.ActiveX,
  RadIA.Core.Logger;

type
  TRadIAFormWebLogin = class(TForm)
    pnlHeader: TPanel;
    btnDone: TSpeedButton;
    lblTitle: TLabel;
    lblInfo: TLabel;
    pnlBrowserContainer: TPanel;
    EdgeBrowser: TEdgeBrowser;
    pnlBrowserFallback: TPanel;
    lblFallbackTitle: TLabel;
    lblFallbackInfo: TLabel;
    btnUseSessionFallback: TSpeedButton;
    btnRetryBrowser: TSpeedButton;
    pnlFooter: TPanel;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnDoneClick(Sender: TObject);
    procedure btnRetryBrowserClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FEdgeBrowser: TEdgeBrowser;
    FNavigationTimer: TTimer;
    FAutoCloseTimer: TTimer;
    FUrl: string;
    FOnLoginSuccess: TProc;
    procedure CreateEdgeBrowser;
    procedure NavigateToProvider;
    procedure CompleteWithCurrentSession;
    procedure ScheduleAutoClose;
    procedure ShowBrowserFallback(const ATitle, AInfo: string);
    procedure UpdateTheme;
    procedure NavigationTimerElapsed(Sender: TObject);
    procedure AutoCloseTimerElapsed(Sender: TObject);
    procedure EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    procedure EdgeBrowserNavigationCompleted(Sender: TCustomEdgeBrowser; IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
    procedure EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
    procedure ProcessWebMessage(const AMessage: string);
  public
    class procedure ShowLogin(const AParent: TComponent; const AUrl: string; const AOnSuccess: TProc);
  end;

implementation

uses
  System.JSON, ToolsAPI, Vcl.Themes, RadIA.UI.Resources, RadIA.Core.Types;

{$R *.dfm}

type
  ICoreWebView2Settings2_Local = interface(IUnknown)
    ['{ee9a0f68-f96c-4e24-9c00-fd6c778988b4}']
    function Get_UserAgent(out userAgent: PWideChar): HResult; stdcall;
    function Put_UserAgent(userAgent: PWideChar): HResult; stdcall;
  end;

const
  CWebViewScrollbarStyleId = 'radia-scrollbar-style';

function BuildWebViewScrollbarScript: string;
begin
  Result :=
    '(function(){' +
    'var css="::-webkit-scrollbar{width:14px;height:14px;}"+' +
    '"::-webkit-scrollbar-thumb{background:rgba(120,120,120,.55);border-radius:8px;' +
    'border:3px solid transparent;background-clip:content-box;}"+' +
    '"::-webkit-scrollbar-track{background:rgba(120,120,120,.12);}";' +
    'function apply(){if(document.getElementById("' + CWebViewScrollbarStyleId + '"))return;' +
    'var style=document.createElement("style");style.id="' + CWebViewScrollbarStyleId + '";' +
    'style.textContent=css;(document.head||document.documentElement).appendChild(style);}' +
    'if(document.readyState==="loading")document.addEventListener("DOMContentLoaded",apply);' +
    'else apply();' +
    '})();';
end;

procedure InjectWebViewScrollbarStyle(const ABrowser: TEdgeBrowser; const AContext: string);
begin
  if Assigned(ABrowser) and Assigned(ABrowser.DefaultInterface) then
  begin
    try
      ABrowser.DefaultInterface.AddScriptToExecuteOnDocumentCreated(
        PWideChar(BuildWebViewScrollbarScript),
        nil);
    except
      on E: Exception do
        TLogger.Log('Error injecting scrollbar style to ' + AContext + ': ' + E.Message, 'UI');
    end;
  end;
end;

{ TRadIAFormWebLogin }

class procedure TRadIAFormWebLogin.ShowLogin(const AParent: TComponent; const AUrl: string; const AOnSuccess: TProc);
var
  LForm: TRadIAFormWebLogin;
begin
  LForm := TRadIAFormWebLogin.Create(AParent);
  try
    LForm.FUrl := AUrl;
    LForm.FOnLoginSuccess := AOnSuccess;
    LForm.Show;
    LForm.BringToFront;
    while LForm.Visible and (LForm.ModalResult = mrNone) do
    begin
      Application.ProcessMessages;
      Sleep(10);
    end;
  finally
    LForm.Free;
  end;
end;

procedure TRadIAFormWebLogin.FormCreate(Sender: TObject);
begin
  UpdateTheme;
end;

procedure TRadIAFormWebLogin.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
end;

procedure TRadIAFormWebLogin.FormDestroy(Sender: TObject);
begin
  if Assigned(FEdgeBrowser) then
  begin
    RemoveComponent(FEdgeBrowser);
    FEdgeBrowser.Parent := nil;
    if not GIsShuttingDown then
      FreeAndNil(FEdgeBrowser)
    else
      FEdgeBrowser := nil;
  end;
  FreeAndNil(FNavigationTimer);
  FreeAndNil(FAutoCloseTimer);
end;

procedure TRadIAFormWebLogin.FormShow(Sender: TObject);
begin
  CreateEdgeBrowser;
end;

procedure TRadIAFormWebLogin.btnDoneClick(Sender: TObject);
begin
  CompleteWithCurrentSession;
end;

procedure TRadIAFormWebLogin.btnRetryBrowserClick(Sender: TObject);
begin
  pnlBrowserFallback.Visible := False;
  NavigateToProvider;
end;

procedure TRadIAFormWebLogin.CompleteWithCurrentSession;
begin
  lblStatus.Caption := 'Using the confirmed browser session...';
  if Assigned(FOnLoginSuccess) then
    FOnLoginSuccess();
  ModalResult := mrOk;
end;

procedure TRadIAFormWebLogin.ScheduleAutoClose;
begin
  if not Assigned(FAutoCloseTimer) then
  begin
    FAutoCloseTimer := TTimer.Create(Self);
    FAutoCloseTimer.Interval := 900;
    FAutoCloseTimer.OnTimer := AutoCloseTimerElapsed;
  end;

  FAutoCloseTimer.Enabled := True;
end;

procedure TRadIAFormWebLogin.AutoCloseTimerElapsed(Sender: TObject);
begin
  if Assigned(FAutoCloseTimer) then
    FAutoCloseTimer.Enabled := False;

  CompleteWithCurrentSession;
end;

procedure TRadIAFormWebLogin.CreateEdgeBrowser;
begin
  if Assigned(FEdgeBrowser) then
    Exit;

  FEdgeBrowser := EdgeBrowser;
  FEdgeBrowser.OnCreateWebViewCompleted := EdgeBrowserCreateWebViewCompleted;
  FEdgeBrowser.OnNavigationCompleted := EdgeBrowserNavigationCompleted;
  FEdgeBrowser.OnWebMessageReceived := EdgeBrowserWebMessageReceived;
  
  // Share the same data folder used by the background browser session.
  FEdgeBrowser.UserDataFolder := TPath.Combine(TPath.GetHomePath, 'RadIA\WebView2Web');
  NavigateToProvider;
end;

procedure TRadIAFormWebLogin.NavigateToProvider;
begin
  if FUrl.Trim.IsEmpty then
  begin
    lblStatus.Caption := 'Provider login URL is empty.';
    Exit;
  end;

  if not Assigned(FEdgeBrowser) then
    Exit;

  lblStatus.Caption := 'Opening provider sign in page...';
  FEdgeBrowser.Navigate(FUrl);
  lblStatus.Caption := 'Provider sign in page requested. Complete the login in the browser area.';

  if not Assigned(FNavigationTimer) then
  begin
    FNavigationTimer := TTimer.Create(Self);
    FNavigationTimer.Interval := 5000;
    FNavigationTimer.OnTimer := NavigationTimerElapsed;
  end;
  FNavigationTimer.Enabled := True;
end;

procedure TRadIAFormWebLogin.UpdateTheme;
var
  LThemingServices: IOTAIDEThemingServices;
  LThemeName: string;
  LColors: TRadIAThemeColors;
begin
  LThemeName := 'light';
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LThemingServices.ApplyTheme(Self);
      LThemeName := LThemingServices.ActiveTheme;
    end;
  end;

  LColors := TRadIAThemeColors.GetColorsForTheme(LThemeName);

  StyleElements := StyleElements - [seClient, seBorder];
  Color := LColors.BgBase;

  pnlHeader.StyleElements := pnlHeader.StyleElements - [seClient, seBorder];
  pnlHeader.Color := LColors.BgBase;
  pnlHeader.ParentBackground := False;

  pnlFooter.StyleElements := pnlFooter.StyleElements - [seClient, seBorder];
  pnlFooter.Color := LColors.BgBase;
  pnlFooter.ParentBackground := False;

  pnlBrowserContainer.StyleElements := pnlBrowserContainer.StyleElements - [seClient, seBorder];
  pnlBrowserContainer.Color := LColors.BorderColor;
  pnlBrowserContainer.ParentBackground := False;

  pnlBrowserFallback.StyleElements := pnlBrowserFallback.StyleElements - [seClient, seBorder];
  pnlBrowserFallback.Color := LColors.BgElevated;
  pnlBrowserFallback.ParentBackground := False;

  lblTitle.StyleElements := lblTitle.StyleElements - [seClient, seBorder];
  lblTitle.Font.Color := LColors.TextColor;
  lblInfo.StyleElements := lblInfo.StyleElements - [seClient, seBorder];
  lblInfo.Font.Color := LColors.TextColor;
  lblStatus.StyleElements := lblStatus.StyleElements - [seClient, seBorder];
  lblStatus.Font.Color := LColors.TextColor;
  lblFallbackTitle.StyleElements := lblFallbackTitle.StyleElements - [seClient, seBorder];
  lblFallbackTitle.Font.Color := LColors.TextColor;
  lblFallbackInfo.StyleElements := lblFallbackInfo.StyleElements - [seClient, seBorder];
  lblFallbackInfo.Font.Color := LColors.TextColor;

  btnDone.Font.Color := LColors.AccentColor;
  btnUseSessionFallback.Font.Color := LColors.AccentColor;
  btnRetryBrowser.Font.Color := LColors.TextColor;
  TUIHelper.ApplyDarkTitleBar(Self, LColors.IsDark);
end;

procedure TRadIAFormWebLogin.NavigationTimerElapsed(Sender: TObject);
begin
  if Assigned(FNavigationTimer) then
    FNavigationTimer.Enabled := False;

  if Assigned(FEdgeBrowser) and (FEdgeBrowser.BrowserControlState = TCustomEdgeBrowser.TBrowserControlState.Creating) then
  begin
    ShowBrowserFallback(
      'Sign-in page is taking longer than expected',
      'Use your existing session or retry the embedded browser.');
    lblStatus.Caption := 'Embedded browser is still starting.';
    TLogger.Log('TRadIAFormWebLogin: WebView2 is still creating after the navigation timeout.', 'UI');
  end;
end;

procedure TRadIAFormWebLogin.ShowBrowserFallback(const ATitle, AInfo: string);
begin
  lblFallbackTitle.Caption := ATitle;
  lblFallbackInfo.Caption := AInfo;
  pnlBrowserFallback.Visible := True;
  pnlBrowserFallback.BringToFront;
end;

procedure TRadIAFormWebLogin.EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
var
  LSettings: ICoreWebView2Settings;
  LSettings2: ICoreWebView2Settings2_Local;
  LScriptFile: string;
  LScriptContent: string;
begin
  if Succeeded(AResult) then
  begin
    if Assigned(FNavigationTimer) then
      FNavigationTimer.Enabled := False;
    pnlBrowserFallback.Visible := False;

    if Assigned(FEdgeBrowser.DefaultInterface) then
    begin
      if Succeeded(FEdgeBrowser.DefaultInterface.Get_Settings(LSettings)) and Assigned(LSettings) then
      begin
        LSettings.Set_AreDevToolsEnabled(1);
        LSettings.Set_AreDefaultContextMenusEnabled(1);
        
        if Succeeded(LSettings.QueryInterface(ICoreWebView2Settings2_Local, LSettings2)) and Assigned(LSettings2) then
        begin
          LSettings2.Put_UserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        end;
      end;

      InjectWebViewScrollbarStyle(FEdgeBrowser, 'login WebView');

      LScriptFile := TPath.Combine(TPath.GetHomePath, 'RadIA\Web');
      LScriptFile := TPath.Combine(LScriptFile, 'bridge.js');
      if not TFile.Exists(LScriptFile) then
      begin
        LScriptFile := TPath.Combine('C:\Users\Public\Documents\Embarcadero\Studio\37.0\Bpl\Web', 'bridge.js');
      end;

      if TFile.Exists(LScriptFile) then
      begin
        try
          LScriptContent := TFile.ReadAllText(LScriptFile, TEncoding.UTF8);
          FEdgeBrowser.DefaultInterface.AddScriptToExecuteOnDocumentCreated(PWideChar(LScriptContent), nil);
        except
          on E: Exception do
            TLogger.Log('Error injecting bridge in login popup: ' + E.Message, 'UI');
        end;
      end;
    end;
    lblStatus.Caption := 'Provider sign in page loaded. Complete the login in the browser area.';
  end;
  if Failed(AResult) then
  begin
    if Assigned(FNavigationTimer) then
      FNavigationTimer.Enabled := False;

    lblStatus.Caption := Format('Unable to initialize WebView2. HRESULT: %.8x', [Cardinal(AResult)]);
    TLogger.Log(Format('TRadIAFormWebLogin: WebView2 initialization failed. HRESULT: %.8x', [Cardinal(AResult)]), 'UI');
  end;
end;

procedure TRadIAFormWebLogin.EdgeBrowserNavigationCompleted(Sender: TCustomEdgeBrowser; IsSuccess: Boolean;
  WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
begin
  if Assigned(FNavigationTimer) then
    FNavigationTimer.Enabled := False;

  if IsSuccess then
  begin
    pnlBrowserFallback.Visible := False;
    lblStatus.Caption := 'Provider sign in page loaded. Complete the login in the browser area.'
  end
  else
  begin
    ShowBrowserFallback(
      'The sign-in page could not be loaded',
      'Use your existing session or retry the embedded browser.');
    lblStatus.Caption := Format('Provider sign in page failed to load. WebView2 status: %d', [Ord(WebErrorStatus)]);
  end;
end;

procedure TRadIAFormWebLogin.EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
var
  LStr: PWideChar;
  LJsonStr: PWideChar;
begin
  if Assigned(Args.ArgsInterface) then
  begin
    if Succeeded(Args.ArgsInterface.TryGetWebMessageAsString(LStr)) then
    begin
      try
        ProcessWebMessage(string(LStr));
      finally
        CoTaskMemFree(LStr);
      end;
    end
    else
    begin
      Args.ArgsInterface.Get_webMessageAsJson(LJsonStr);
      try
        ProcessWebMessage(string(LJsonStr));
      finally
        CoTaskMemFree(LJsonStr);
      end;
    end;
  end;
end;

procedure TRadIAFormWebLogin.ProcessWebMessage(const AMessage: string);
var
  LParsed: TJSONValue;
  LJson: TJSONObject;
  LAction: string;
begin
  LParsed := TJSONObject.ParseJSONValue(AMessage);
  if not Assigned(LParsed) then
    Exit;
  try
    if not (LParsed is TJSONObject) then
      Exit;

    LJson := LParsed as TJSONObject;
    LAction := LJson.GetValue<string>('action', '');
    
    if SameText(LAction, 'login_complete') then
    begin
      TLogger.Log('TRadIAFormWebLogin: Existing signed-in provider session detected.', 'UI');
      lblStatus.Caption := 'You are already signed in. Returning to Rad IA...';
      ScheduleAutoClose;
    end;
  finally
    LParsed.Free;
  end;
end;

end.
