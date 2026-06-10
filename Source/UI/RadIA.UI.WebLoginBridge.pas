unit RadIA.UI.WebLoginBridge;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Edge, Vcl.ExtCtrls;

type
  TRadIAWebLoginBridge = class(TComponent)
  private
    FBrowser: TEdgeBrowser;
    FHost: TWinControl;
    FInitialized: Boolean;
    FReady: Boolean;
    FCurrentUrl: string;
    FPendingProvider: string;
    FPendingPrompt: string;
    FLoginPopupOpen: Boolean;
    FWebFilesDir: string;
    procedure CreateBrowser;
    procedure DispatchPrompt(const APrompt: string);
    procedure HandleMessage(const AMessage: string);
    procedure HandleNavigation(const AUrl: string);
    procedure HandleLoginComplete;
    procedure OpenLoginWindow(const AProviderName: string);
    procedure PostMessageToBrowser(const AJson: string);
    procedure BrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    procedure BrowserSourceChanged(Sender: TCustomEdgeBrowser; IsNewDocument: Boolean);
    {$IF CompilerVersion >= 35.0}
    procedure BrowserWebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
    {$ELSE}
    procedure BrowserWebMessageReceivedLegacy(Sender: TCustomEdgeBrowser; const AMessage: string);
    {$ENDIF}
    class function GetWebLoginUrl(const AProviderName: string): string; static;
    class procedure CopyDirectory(const ASourceDir, ADestDir: string); static;
    class procedure CopyWebFiles(const ADestDir: string); static;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure EnsureBrowser;
    procedure SendPrompt(const AProviderName, APrompt: string);
    procedure CancelRequest;
    class function Instance: TRadIAWebLoginBridge; static;
    class procedure ReleaseInstance; static;
  end;

implementation

uses
  Winapi.ActiveX, Winapi.WebView2, System.IOUtils, System.JSON, Vcl.Forms,
  RadIA.Core.Logger, RadIA.Core.Types, RadIA.Provider.WebViewBridge,
  RadIA.UI.WebLoginForm;

type
  ICoreWebView2Settings2_Local = interface(IUnknown)
    ['{EE9A0F68-F46C-4E32-AC23-EF8CAC224D2A}']
    function Get_UserAgent(out UserAgent: PWideChar): HResult; stdcall;
    function Put_UserAgent(UserAgent: PWideChar): HResult; stdcall;
  end;

var
  GInstance: TRadIAWebLoginBridge = nil;

{ TRadIAWebLoginBridge }

constructor TRadIAWebLoginBridge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInitialized := False;
  FReady := False;
  FCurrentUrl := '';
  FPendingProvider := '';
  FPendingPrompt := '';
  FLoginPopupOpen := False;
  FWebFilesDir := TPath.Combine(TPath.GetHomePath, 'RadIA\Web');
  CopyWebFiles(FWebFilesDir);
end;

destructor TRadIAWebLoginBridge.Destroy;
begin
  if Assigned(FBrowser) then
  begin
    FBrowser.Parent := nil;
    if not GIsShuttingDown then
      FreeAndNil(FBrowser);
  end;

  if Assigned(FHost) then
  begin
    FHost.Parent := nil;
    if not GIsShuttingDown then
      FreeAndNil(FHost);
  end;

  inherited Destroy;
end;

class function TRadIAWebLoginBridge.Instance: TRadIAWebLoginBridge;
begin
  if not Assigned(GInstance) then
    GInstance := TRadIAWebLoginBridge.Create(nil);
  Result := GInstance;
end;

class procedure TRadIAWebLoginBridge.ReleaseInstance;
begin
  if Assigned(GInstance) then
    FreeAndNil(GInstance);
end;

class function TRadIAWebLoginBridge.GetWebLoginUrl(const AProviderName: string): string;
begin
  if SameText(AProviderName, 'Gemini') then
    Result := 'https://gemini.google.com'
  else if SameText(AProviderName, 'OpenAI') then
    Result := 'https://chatgpt.com'
  else
    Result := '';
end;

class procedure TRadIAWebLoginBridge.CopyDirectory(const ASourceDir, ADestDir: string);
var
  LFile: string;
  LDir: string;
  LFileName: string;
  LSubDir: string;
begin
  if not TDirectory.Exists(ASourceDir) then
    Exit;

  ForceDirectories(ADestDir);

  for LFile in TDirectory.GetFiles(ASourceDir) do
  begin
    LFileName := TPath.GetFileName(LFile);
    TFile.Copy(LFile, TPath.Combine(ADestDir, LFileName), True);
  end;

  for LDir in TDirectory.GetDirectories(ASourceDir) do
  begin
    LSubDir := TPath.GetFileName(LDir);
    CopyDirectory(LDir, TPath.Combine(ADestDir, LSubDir));
  end;
end;

class procedure TRadIAWebLoginBridge.CopyWebFiles(const ADestDir: string);
var
  LSourceDir: string;
  LModuleDir: string;
begin
  ForceDirectories(ADestDir);

  LModuleDir := ExtractFilePath(GetModuleName(HInstance));
  LSourceDir := TPath.Combine(LModuleDir, 'Web');

  if not TDirectory.Exists(LSourceDir) then
    LSourceDir := TPath.GetFullPath(TPath.Combine(LModuleDir, '..\Web'));

  if not TDirectory.Exists(LSourceDir) then
    LSourceDir := TPath.GetFullPath(TPath.Combine(LModuleDir, '..\..\..\Source\UI\Web'));

  if not TDirectory.Exists(LSourceDir) then
    LSourceDir := 'D:\Projetos\PluginDelphiIA\Source\UI\Web';

  if TDirectory.Exists(LSourceDir) then
    CopyDirectory(LSourceDir, ADestDir);
end;

procedure TRadIAWebLoginBridge.EnsureBrowser;
begin
  if Assigned(FBrowser) then
    Exit;

  if not Assigned(FHost) then
  begin
    FHost := TPanel.Create(nil);
    FHost.ParentWindow := Application.Handle;
    FHost.Left := -5000;
    FHost.Top := 0;
    FHost.Width := 10;
    FHost.Height := 10;
    FHost.Visible := True;
  end;

  CreateBrowser;
end;

procedure TRadIAWebLoginBridge.CreateBrowser;
begin
  if Assigned(FBrowser) then
    Exit;

  FBrowser := TEdgeBrowser.Create(nil);
  FBrowser.Parent := FHost;
  FBrowser.Align := alClient;
  FBrowser.OnCreateWebViewCompleted := BrowserCreateWebViewCompleted;
  FBrowser.OnSourceChanged := BrowserSourceChanged;
  {$IF CompilerVersion >= 35.0}
  FBrowser.OnWebMessageReceived := BrowserWebMessageReceived;
  {$ELSE}
  FBrowser.OnWebMessageReceived := BrowserWebMessageReceivedLegacy;
  {$ENDIF}
  FBrowser.UserDataFolder := TPath.Combine(TPath.GetHomePath, 'RadIA\WebView2Web');
  FBrowser.CreateWebView;
end;

procedure TRadIAWebLoginBridge.SendPrompt(const AProviderName, APrompt: string);
var
  LUrl: string;
begin
  LUrl := GetWebLoginUrl(AProviderName);
  if LUrl.IsEmpty then
  begin
    TLogger.Log('WebLoginBridge: Provider does not support Web Login: ' + AProviderName, 'UI');
    TRadIAWebViewBridgeProvider.ReceiveChunk('', True, 'Provider does not support Web Login.');
    Exit;
  end;

  EnsureBrowser;
  FPendingProvider := AProviderName;

  if not FInitialized then
  begin
    TLogger.Log('WebLoginBridge: Browser is not initialized yet. Queueing prompt.', 'UI');
    FPendingPrompt := APrompt;
    FReady := False;
    Exit;
  end;

  if not SameText(FCurrentUrl, LUrl) then
  begin
    TLogger.Log('WebLoginBridge: Navigating background browser to ' + LUrl, 'UI');
    FPendingPrompt := APrompt;
    FReady := False;
    FCurrentUrl := LUrl;
    FBrowser.Navigate(LUrl);
    Exit;
  end;

  if not FReady then
  begin
    TLogger.Log('WebLoginBridge: Browser is loading. Queueing prompt.', 'UI');
    FPendingPrompt := APrompt;
    Exit;
  end;

  DispatchPrompt(APrompt);
end;

procedure TRadIAWebLoginBridge.DispatchPrompt(const APrompt: string);
var
  LJson: TJSONObject;
begin
  TLogger.Log('WebLoginBridge: Dispatching prompt to background browser.', 'UI');
  FPendingPrompt := '';
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'send_prompt');
    LJson.AddPair('text', APrompt);
    PostMessageToBrowser(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

procedure TRadIAWebLoginBridge.CancelRequest;
var
  LJson: TJSONObject;
begin
  if not FInitialized then
    Exit;

  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'cancel_request');
    PostMessageToBrowser(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

procedure TRadIAWebLoginBridge.PostMessageToBrowser(const AJson: string);
begin
  if FInitialized and Assigned(FBrowser) and Assigned(FBrowser.DefaultInterface) then
    FBrowser.DefaultInterface.PostWebMessageAsJson(PChar(AJson));
end;

procedure TRadIAWebLoginBridge.BrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
var
  LSettings: ICoreWebView2Settings;
  LSettings2: ICoreWebView2Settings2_Local;
  LScriptFile: string;
  LScriptContent: string;
  LUrl: string;
begin
  if not Succeeded(AResult) then
    Exit;

  FInitialized := True;
  if Assigned(FBrowser.DefaultInterface) then
  begin
    if Succeeded(FBrowser.DefaultInterface.Get_Settings(LSettings)) and Assigned(LSettings) then
    begin
      LSettings.Set_AreDevToolsEnabled(1);
      LSettings.Set_AreDefaultContextMenusEnabled(1);

      if Succeeded(LSettings.QueryInterface(ICoreWebView2Settings2_Local, LSettings2)) and Assigned(LSettings2) then
        LSettings2.Put_UserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
          'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    end;

    LScriptFile := TPath.Combine(FWebFilesDir, 'bridge.js');
    if TFile.Exists(LScriptFile) then
    begin
      try
        LScriptContent := TFile.ReadAllText(LScriptFile, TEncoding.UTF8);
        FBrowser.DefaultInterface.AddScriptToExecuteOnDocumentCreated(PWideChar(LScriptContent), nil);
      except
        on E: Exception do
          TLogger.Log('WebLoginBridge: Error injecting bridge script: ' + E.Message, 'UI');
      end;
    end;
  end;

  LUrl := GetWebLoginUrl(FPendingProvider);
  if not LUrl.IsEmpty then
  begin
    TLogger.Log('WebLoginBridge: Browser created. Navigating to ' + LUrl, 'UI');
    FReady := False;
    FCurrentUrl := LUrl;
    FBrowser.Navigate(LUrl);
  end;
end;

procedure TRadIAWebLoginBridge.BrowserSourceChanged(Sender: TCustomEdgeBrowser; IsNewDocument: Boolean);
begin
  HandleNavigation(Sender.LocationURL);
end;

procedure TRadIAWebLoginBridge.HandleNavigation(const AUrl: string);
var
  LIsAuthPage: Boolean;
begin
  LIsAuthPage := AUrl.Contains('accounts.google.com') or
                 AUrl.Contains('auth.openai.com') or
                 AUrl.Contains('accounts.openai.com') or
                 AUrl.Contains('/auth/login') or
                 AUrl.Contains('ServiceLogin');

  if LIsAuthPage then
  begin
    TLogger.Log('WebLoginBridge: Auth page redirect detected. URL: ' + AUrl, 'UI');
    OpenLoginWindow(FPendingProvider);
  end;
end;

procedure TRadIAWebLoginBridge.OpenLoginWindow(const AProviderName: string);
var
  LUrl: string;
begin
  if FLoginPopupOpen then
    Exit;

  LUrl := GetWebLoginUrl(AProviderName);
  if LUrl.IsEmpty then
    Exit;

  FLoginPopupOpen := True;
  try
    TFormWebLogin.ShowLogin(nil, LUrl,
      procedure
      begin
        FLoginPopupOpen := False;
        TLogger.Log('WebLoginBridge: Login completed. Refreshing background browser.', 'UI');
        FReady := False;
        FBrowser.Navigate(LUrl);
      end);
  except
    on E: Exception do
    begin
      FLoginPopupOpen := False;
      TLogger.Log('WebLoginBridge: Error showing login window: ' + E.Message, 'UI');
    end;
  end;
end;

procedure TRadIAWebLoginBridge.HandleLoginComplete;
begin
  FReady := True;
  TLogger.Log('WebLoginBridge: Background browser is ready.', 'UI');
  if not FPendingPrompt.IsEmpty then
    DispatchPrompt(FPendingPrompt);
end;

procedure TRadIAWebLoginBridge.HandleMessage(const AMessage: string);
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

    LJson := TJSONObject(LParsed);
    LAction := LJson.GetValue<string>('action', '');

    if SameText(LAction, 'login_complete') then
      HandleLoginComplete
    else if SameText(LAction, 'web_login_connect') then
      OpenLoginWindow(FPendingProvider)
    else if SameText(LAction, 'error') then
      TRadIAWebViewBridgeProvider.ReceiveChunk('', True, LJson.GetValue<string>('text', ''))
    else if SameText(LAction, 'update_stream') then
    begin
      if LJson.GetValue<Boolean>('isDone', False) then
        TRadIAWebViewBridgeProvider.ReceiveChunk(LJson.GetValue<string>('text', ''), True, '');
    end
    else if SameText(LAction, 'stream_chunk') then
      TRadIAWebViewBridgeProvider.ReceiveChunk(
        LJson.GetValue<string>('text', ''),
        LJson.GetValue<Boolean>('isDone', False),
        LJson.GetValue<string>('error', ''));
  finally
    LParsed.Free;
  end;
end;

{$IF CompilerVersion >= 35.0}
procedure TRadIAWebLoginBridge.BrowserWebMessageReceived(Sender: TCustomEdgeBrowser;
  Args: TWebMessageReceivedEventArgs);
var
  LStr: PWideChar;
  LJsonStr: PWideChar;
begin
  if Assigned(Args.ArgsInterface) then
  begin
    if Succeeded(Args.ArgsInterface.TryGetWebMessageAsString(LStr)) then
    begin
      try
        HandleMessage(string(LStr));
      finally
        CoTaskMemFree(LStr);
      end;
    end
    else
    begin
      Args.ArgsInterface.Get_webMessageAsJson(LJsonStr);
      try
        HandleMessage(string(LJsonStr));
      finally
        CoTaskMemFree(LJsonStr);
      end;
    end;
  end;
end;
{$ELSE}
procedure TRadIAWebLoginBridge.BrowserWebMessageReceivedLegacy(Sender: TCustomEdgeBrowser;
  const AMessage: string);
begin
  HandleMessage(AMessage);
end;
{$ENDIF}

procedure EnsureWebLoginBridge;
begin
  TRadIAWebLoginBridge.Instance.EnsureBrowser;
end;

procedure SendWebLoginPrompt(const AProviderName, APrompt: string);
begin
  TRadIAWebLoginBridge.Instance.SendPrompt(AProviderName, APrompt);
end;

procedure CancelWebLoginRequest;
begin
  TRadIAWebLoginBridge.Instance.CancelRequest;
end;

initialization
  TRadIAWebViewBridgeProvider.OnEnsureBridge := EnsureWebLoginBridge;
  TRadIAWebViewBridgeProvider.OnSendPrompt := SendWebLoginPrompt;
  TRadIAWebViewBridgeProvider.OnCancel := CancelWebLoginRequest;

finalization
  TRadIAWebViewBridgeProvider.OnEnsureBridge := nil;
  TRadIAWebViewBridgeProvider.OnSendPrompt := nil;
  TRadIAWebViewBridgeProvider.OnCancel := nil;
  TRadIAWebLoginBridge.ReleaseInstance;

end.
