unit RadIA.UI.WebLoginForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Buttons,
  Vcl.StdCtrls, Vcl.Edge, System.IOUtils, Winapi.WebView2, Winapi.ActiveX,
  RadIA.Core.Logger;

type
  TFormWebLogin = class(TForm)
    pnlHeader: TPanel;
    btnDone: TSpeedButton;
    lblInfo: TLabel;
    pnlBrowserContainer: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnDoneClick(Sender: TObject);
  private
    FEdgeBrowser: TEdgeBrowser;
    FUrl: string;
    FOnLoginSuccess: TProc;
    procedure CreateEdgeBrowser;
    procedure EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    {$IF CompilerVersion >= 35.0}
    procedure EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
    {$ELSE}
    procedure EdgeBrowserWebMessageReceivedLegacy(Sender: TCustomEdgeBrowser; const AMessage: string);
    {$ENDIF}
    procedure ProcessWebMessage(const AMessage: string);
  public
    class procedure ShowLogin(const AParent: TComponent; const AUrl: string; const AOnSuccess: TProc);
  end;

implementation

uses
  System.JSON;

{$R *.dfm}

type
  ICoreWebView2Settings2_Local = interface(IUnknown)
    ['{ee9a0f68-f96c-4e24-9c00-fd6c778988b4}']
    function Get_UserAgent(out userAgent: PWideChar): HResult; stdcall;
    function Put_UserAgent(userAgent: PWideChar): HResult; stdcall;
  end;

{ TFormWebLogin }

class procedure TFormWebLogin.ShowLogin(const AParent: TComponent; const AUrl: string; const AOnSuccess: TProc);
var
  LForm: TFormWebLogin;
begin
  LForm := TFormWebLogin.Create(AParent);
  LForm.FUrl := AUrl;
  LForm.FOnLoginSuccess := AOnSuccess;
  LForm.ShowModal;
end;

procedure TFormWebLogin.FormCreate(Sender: TObject);
begin
  CreateEdgeBrowser;
end;

procedure TFormWebLogin.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFormWebLogin.btnDoneClick(Sender: TObject);
begin
  Close;
end;

procedure TFormWebLogin.CreateEdgeBrowser;
begin
  FEdgeBrowser := TEdgeBrowser.Create(Self);
  FEdgeBrowser.Parent := pnlBrowserContainer;
  FEdgeBrowser.Align := alClient;
  FEdgeBrowser.OnCreateWebViewCompleted := EdgeBrowserCreateWebViewCompleted;
  {$IF CompilerVersion >= 35.0}
  FEdgeBrowser.OnWebMessageReceived := EdgeBrowserWebMessageReceived;
  {$ELSE}
  FEdgeBrowser.OnWebMessageReceived := EdgeBrowserWebMessageReceivedLegacy;
  {$ENDIF}
  
  // Compartilha o mesmo diretório de dados para manter a mesma sessão logada!
  FEdgeBrowser.UserDataFolder := TPath.Combine(TPath.GetHomePath, 'RadIA\WebView2Web');
end;

procedure TFormWebLogin.EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
var
  LSettings: ICoreWebView2Settings;
  LSettings2: ICoreWebView2Settings2_Local;
  LScriptFile: string;
  LScriptContent: string;
begin
  if Succeeded(AResult) then
  begin
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

      // Injeta o bridge.js para detectar o login e mandar a mensagem
      LScriptFile := TPath.Combine(TPath.GetHomePath, 'RadIA\Web');
      LScriptFile := TPath.Combine(LScriptFile, 'bridge.js');
      if not TFile.Exists(LScriptFile) then
      begin
        // Fallback para pasta padrão BDS Common se não achar no Home
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
    
    FEdgeBrowser.Navigate(FUrl);
  end;
end;

{$IF CompilerVersion >= 35.0}
procedure TFormWebLogin.EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
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
{$ELSE}
procedure TFormWebLogin.EdgeBrowserWebMessageReceivedLegacy(Sender: TCustomEdgeBrowser; const AMessage: string);
begin
  ProcessWebMessage(AMessage);
end;
{$ENDIF}

procedure TFormWebLogin.ProcessWebMessage(const AMessage: string);
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
      TLogger.Log('TFormWebLogin: Login detected via bridge.js. Closing popup.', 'UI');
      if Assigned(FOnLoginSuccess) then
        FOnLoginSuccess();
      ModalResult := mrOk;
    end;
  finally
    LParsed.Free;
  end;
end;

end.
