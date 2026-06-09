unit RadIA.UI.ChatFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Edge, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config,
  RadIA.Core.Service, Vcl.Menus, Vcl.Buttons, Winapi.WebView2, Winapi.ActiveX,
  RadIA.Core.Sessions, RadIA.UI.Resources, RadIA.UI.ChatPresenter,
  RadIA.Core.ProviderRegistry;

type
  TFrameAIChat = class(TFrame, IChatView)
    pnlToolbar: TPanel;
    lblTitle: TLabel;
    btnToggleSessions: TSpeedButton;
    cbProvider: TComboBox;
    cbModel: TComboBox;
    btnSettings: TSpeedButton;
    btnClear: TSpeedButton;
    btnExport: TSpeedButton;
    btnTemplates: TSpeedButton;
    SaveDialog: TSaveDialog;
    pnlInput: TPanel;
    shpInputBg: TShape;
    shpSendBg: TShape;
    memPrompt: TMemo;
    btnSend: TSpeedButton;
    lblContext: TLabel;
    pnlBrowser: TPanel;
    pnlSessions: TPanel;
    pnlSessionsHeader: TPanel;
    btnNewSession: TSpeedButton;
    btnRenameSession: TSpeedButton;
    btnDeleteSession: TSpeedButton;
    lstSessions: TListBox;
    splitterSessions: TSplitter;
    procedure btnSendClick(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure cbModelChange(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnTemplatesClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    {$IF CompilerVersion >= 35.0}
    procedure EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
    {$ELSE}
    procedure EdgeBrowserWebMessageReceivedLegacy(Sender: TCustomEdgeBrowser; const AMessage: string);
    {$ENDIF}
    procedure memPromptKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnToggleSessionsClick(Sender: TObject);
    procedure btnNewSessionClick(Sender: TObject);
    procedure btnRenameSessionClick(Sender: TObject);
    procedure btnDeleteSessionClick(Sender: TObject);
    procedure lstSessionsClick(Sender: TObject);
  private
    FPresenter: TChatPresenter;
    FWebFilesDir: string;
    FBrowserInitialized: Boolean;
    FWebViewInitialized: Boolean;
    FPopupMenuTemplates: TPopupMenu;
    FLifecycleGuard: IInterface;
    EdgeBrowser: TEdgeBrowser;
    FEdgeBrowserWeb: TEdgeBrowser;
    FpnlBrowserWeb: TPanel;
    FBrowserWebInitialized: Boolean;

    procedure CreateEdgeBrowserWeb;
    procedure EdgeBrowserWebCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    procedure EdgeBrowserWebSourceChanged(Sender: TCustomEdgeBrowser; IsNewDocument: Boolean);
    {$IF CompilerVersion >= 35.0}
    procedure EdgeBrowserWebWebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
    {$ELSE}
    procedure EdgeBrowserWebWebMessageReceivedLegacy(Sender: TCustomEdgeBrowser; const AMessage: string);
    {$ENDIF}

    procedure UpdateWebViewNavigation;
    procedure UpdateSendButtonVisual(const AInProgress: Boolean);
    function ColorToHex(AColor: TColor): string;
    procedure CreateEdgeBrowser;
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure InitializeWebView;
    procedure CopyWebFiles;
    procedure CopyDirectory(const ASourceDir, ADestDir: string);
    procedure OnTemplateMenuClick(Sender: TObject);
    procedure UpdateVCLColors(const AColors: TRadIAThemeColors);
    procedure OnGlobalPromptRequest(const APrompt: string; const AOpenChat: Boolean);
  protected
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure SetTheme(const AThemeName: string);

    { IChatView Implementation }
    procedure SetRequestState(const AInProgress: Boolean);
    procedure UpdateTokensStats(const AStats: string);
    procedure PostMessageToWeb(const AJson: string);
    procedure PostMessageToBackgroundWeb(const AJson: string);
    
    procedure CreateBackgroundBrowser;
    function IsBackgroundBrowserInitialized: Boolean;
    procedure NavigateBackgroundBrowser(const AUrl: string);
    procedure ShowLoginWindow(const AUrl: string; AOnLoginSuccess: TProc);
    
    procedure UpdateProviders(const AProviders: TArray<string>; const AActiveProvider: string);
    procedure UpdateModels(const AModels: TArray<string>; const AActiveModel: string; const AEnabled: Boolean);
    procedure UpdateSessions(const ASessions: TArray<TSessionInfo>; const AActiveSessionId: string);
    procedure UpdateTemplates(const ATemplates: TArray<string>);
    
    function GetPromptInput: string;
    procedure SetPromptInput(const APrompt: string);
    procedure FocusPromptInput;
    
    function GetActiveEditorText(out ACode: string; const AOnlySelected: Boolean): Boolean;
    procedure ReplaceActiveEditorText(const ACode: string);
    
    procedure ShowMessageDialog(const AMessage: string);
    function SaveDialogExecute(out AFileName: string): Boolean;
    procedure ToggleSessionsPanel;
    procedure OpenSettingsDialog;
  end;

implementation

uses
  System.IOUtils, System.JSON, ToolsAPI, RadIA.OTA.Helper, RadIA.UI.ConfigForm,
  RadIA.Core.Mediator, RadIA.Core.Logger, Vcl.Themes, RadIA.UI.WebLoginForm;

{$R *.dfm}

type
  ICoreWebView2Settings2_Local = interface(IUnknown)
    ['{ee9a0f68-f96c-4e24-9c00-fd6c778988b4}']
    function Get_UserAgent(out userAgent: PWideChar): HResult; stdcall;
    function Put_UserAgent(userAgent: PWideChar): HResult; stdcall;
  end;

type
  TSessionObject = class
  public
    Id: string;
    constructor Create(const AId: string);
  end;

type
  TProviderObject = class
  public
    Id: string;
    constructor Create(const AId: string);
  end;

constructor TProviderObject.Create(const AId: string);
begin
  inherited Create;
  Id := AId;
end;

constructor TSessionObject.Create(const AId: string);
begin
  inherited Create;
  Id := AId;
end;

{ TFrameAIChat }

constructor TFrameAIChat.Create(AOwner: TComponent);
var
  LThemingServices: IOTAIDEThemingServices;
begin
  inherited Create(AOwner);
  FBrowserInitialized := False;
  FWebViewInitialized := False;
  
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LThemingServices.ApplyTheme(Self);
    end;
  end;
  
  FLifecycleGuard := TLifecycleGuard.Create;
  FPopupMenuTemplates := TPopupMenu.Create(Self);
  FWebFilesDir := TPath.Combine(TPath.GetHomePath, 'RadIA\Web');
  CopyWebFiles;
  
  FPresenter := TChatPresenter.Create(Self);

  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
      UpdateVCLColors(TRadIAThemeColors.GetColorsForTheme(LThemingServices.ActiveTheme))
    else
      UpdateVCLColors(TRadIAThemeColors.GetColorsForTheme('light'));
  end
  else
    UpdateVCLColors(TRadIAThemeColors.GetColorsForTheme('light'));

  FPresenter.Initialize(FWebFilesDir);

  memPrompt.OnKeyDown := Self.memPromptKeyDown;
  TRadIAMediator.Instance.RegisterPromptHandler(Self.OnGlobalPromptRequest);
end;

destructor TFrameAIChat.Destroy;
var
  I: Integer;
begin
  if Assigned(FLifecycleGuard) then
    (FLifecycleGuard as ILifecycleGuard).Invalidate;
  TRadIAMediator.Instance.UnregisterPromptHandler;
  
  if Assigned(FPopupMenuTemplates) then
  begin
    for I := 0 to FPopupMenuTemplates.Items.Count - 1 do
      FPopupMenuTemplates.Items[I].OnClick := nil;
  end;
  
  if Assigned(lstSessions) then
  begin
    for I := 0 to lstSessions.Items.Count - 1 do
      if Assigned(lstSessions.Items.Objects[I]) then
        lstSessions.Items.Objects[I].Free;
  end;

  if Assigned(cbProvider) then
  begin
    for I := 0 to cbProvider.Items.Count - 1 do
      if Assigned(cbProvider.Items.Objects[I]) then
        cbProvider.Items.Objects[I].Free;
  end;

  FPresenter.Free;
  inherited Destroy;
end;

procedure TFrameAIChat.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  if Showing and not FWebViewInitialized then
  begin
    FWebViewInitialized := True;
    CreateEdgeBrowser;
    TThread.ForceQueue(nil,
      TThreadProcedure(
      procedure
      begin
        InitializeWebView;
      end));
  end;
end;

procedure TFrameAIChat.CreateEdgeBrowser;
begin
  if not Assigned(EdgeBrowser) then
  begin
    EdgeBrowser := TEdgeBrowser.Create(Self);
    EdgeBrowser.Parent := pnlBrowser;
    EdgeBrowser.Align := alClient;
    EdgeBrowser.AlignWithMargins := True;
    EdgeBrowser.OnCreateWebViewCompleted := EdgeBrowserCreateWebViewCompleted;
    {$IF CompilerVersion >= 35.0}
    EdgeBrowser.OnWebMessageReceived := EdgeBrowserWebMessageReceived;
    {$ELSE}
    EdgeBrowser.OnWebMessageReceived := EdgeBrowserWebMessageReceivedLegacy;
    {$ENDIF}
  end;
end;

procedure TFrameAIChat.CreateWnd;
begin
  inherited CreateWnd;
  if not FWebViewInitialized and Showing then
  begin
    FWebViewInitialized := True;
    CreateEdgeBrowser;
    TThread.ForceQueue(nil,
      TThreadProcedure(
      procedure
      begin
        InitializeWebView;
      end));
  end;
end;

procedure TFrameAIChat.DestroyWnd;
var
  LEdgeToFree: TEdgeBrowser;
begin
  FBrowserInitialized := False;
  FWebViewInitialized := False;
  if Assigned(EdgeBrowser) then
  begin
    LEdgeToFree := EdgeBrowser;
    EdgeBrowser := nil;
    LEdgeToFree.Parent := nil;
    TThread.Queue(nil,
      TThreadProcedure(
      procedure
      begin
        LEdgeToFree.Free;
      end));
  end;
  inherited DestroyWnd;
end;

procedure TFrameAIChat.CopyDirectory(const ASourceDir, ADestDir: string);
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

procedure TFrameAIChat.CopyWebFiles;
var
  LSourceDir: string;
  LModuleDir: string;
begin
  ForceDirectories(FWebFilesDir);
  
  LModuleDir := ExtractFilePath(GetModuleName(HInstance));
  LSourceDir := TPath.Combine(LModuleDir, 'Web');
  
  if not TDirectory.Exists(LSourceDir) then
  begin
    LSourceDir := TPath.GetFullPath(TPath.Combine(LModuleDir, '..\Web'));
  end;
  
  if not TDirectory.Exists(LSourceDir) then
  begin
    LSourceDir := TPath.GetFullPath(TPath.Combine(LModuleDir, '..\..\..\Source\UI\Web'));
  end;
  
  if not TDirectory.Exists(LSourceDir) then
  begin
    LSourceDir := 'D:\Projetos\PluginDelphiIA\Source\UI\Web';
  end;
  
  if not TDirectory.Exists(LSourceDir) then
    Exit;
    
  CopyDirectory(LSourceDir, FWebFilesDir);
end;

procedure TFrameAIChat.InitializeWebView;
begin
  EdgeBrowser.UserDataFolder := TPath.Combine(TPath.GetHomePath, 'RadIA\WebView2');
  EdgeBrowser.CreateWebView;
end;

procedure TFrameAIChat.UpdateWebViewNavigation;
var
  LTargetUrl: string;
begin
  if FBrowserInitialized then
  begin
    cbProvider.Visible := True;
    cbModel.Visible := True;
    btnTemplates.Visible := True;

    LTargetUrl := 'file:///' + TPath.Combine(FWebFilesDir, 'chat.html').Replace('\', '/');
    TLogger.Log('UpdateWebViewNavigation: Navigating to local chat: ' + LTargetUrl, 'UI');
    EdgeBrowser.Navigate(LTargetUrl);
  end;
end;

procedure TFrameAIChat.btnSendClick(Sender: TObject);
begin
  FPresenter.SendPrompt;
end;

procedure TFrameAIChat.cbProviderChange(Sender: TObject);
begin
  if cbProvider.ItemIndex <> -1 then
  begin
    FPresenter.ChangeProvider(TProviderObject(cbProvider.Items.Objects[cbProvider.ItemIndex]).Id);
  end;
end;

procedure TFrameAIChat.cbModelChange(Sender: TObject);
begin
  if cbModel.ItemIndex <> -1 then
  begin
    FPresenter.ChangeModel(cbModel.Text);
  end;
end;

procedure TFrameAIChat.btnClearClick(Sender: TObject);
begin
  FPresenter.ClearChat;
end;

procedure TFrameAIChat.btnExportClick(Sender: TObject);
begin
  FPresenter.ExportChat;
end;

procedure TFrameAIChat.btnSettingsClick(Sender: TObject);
begin
  FPresenter.OpenSettings;
end;

procedure TFrameAIChat.memPromptKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  FPresenter.HandlePromptInputKeyDown(Key, Shift);
end;

procedure TFrameAIChat.btnToggleSessionsClick(Sender: TObject);
begin
  FPresenter.ToggleSessions;
end;

procedure TFrameAIChat.btnNewSessionClick(Sender: TObject);
begin
  FPresenter.CreateNewSession;
end;

procedure TFrameAIChat.btnRenameSessionClick(Sender: TObject);
var
  LNewName: string;
  LCurrentName: string;
begin
  LCurrentName := '';
  if lstSessions.ItemIndex <> -1 then
    LCurrentName := lstSessions.Items[lstSessions.ItemIndex];
    
  LNewName := InputBox('Renomear Conversa', 'Digite o novo título da conversa:', LCurrentName);
  if not LNewName.Trim.IsEmpty then
  begin
    FPresenter.RenameSession(FPresenter.SessionManager.ActiveSessionId, LNewName);
  end;
end;

procedure TFrameAIChat.btnDeleteSessionClick(Sender: TObject);
begin
  if MessageDlg('Deseja realmente excluir esta conversa e todo o seu histórico?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FPresenter.DeleteSession(FPresenter.SessionManager.ActiveSessionId);
  end;
end;

procedure TFrameAIChat.lstSessionsClick(Sender: TObject);
begin
  if lstSessions.ItemIndex <> -1 then
  begin
    FPresenter.SelectSession(TSessionObject(lstSessions.Items.Objects[lstSessions.ItemIndex]).Id);
  end;
end;

procedure TFrameAIChat.EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
var
  LSettings: ICoreWebView2Settings;
begin
  if Succeeded(AResult) then
  begin
    FBrowserInitialized := True;
    if Assigned(EdgeBrowser.DefaultInterface) then
    begin
      if Succeeded(EdgeBrowser.DefaultInterface.Get_Settings(LSettings)) and Assigned(LSettings) then
      begin
        LSettings.Set_AreDevToolsEnabled(1);
        LSettings.Set_AreDefaultContextMenusEnabled(1);
      end;
    end;
    UpdateWebViewNavigation;
  end;
end;

{$IF CompilerVersion >= 35.0}
procedure TFrameAIChat.EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
var
  LStr: PWideChar;
  LJsonStr: PWideChar;
begin
  if Assigned(Args.ArgsInterface) then
  begin
    if Succeeded(Args.ArgsInterface.TryGetWebMessageAsString(LStr)) then
    begin
      try
        FPresenter.ProcessWebMessage(string(LStr));
      finally
        CoTaskMemFree(LStr);
      end;
    end
    else
    begin
      Args.ArgsInterface.Get_webMessageAsJson(LJsonStr);
      try
        FPresenter.ProcessWebMessage(string(LJsonStr));
      finally
        CoTaskMemFree(LJsonStr);
      end;
    end;
  end;
end;
{$ELSE}
procedure TFrameAIChat.EdgeBrowserWebMessageReceivedLegacy(Sender: TCustomEdgeBrowser; const AMessage: string);
begin
  FPresenter.ProcessWebMessage(AMessage);
end;
{$ENDIF}

procedure TFrameAIChat.btnTemplatesClick(Sender: TObject);
var
  LPoint: TPoint;
begin
  LPoint := btnTemplates.Parent.ClientToScreen(Point(btnTemplates.Left, btnTemplates.Top + btnTemplates.Height));
  FPopupMenuTemplates.Popup(LPoint.X, LPoint.Y);
end;

procedure TFrameAIChat.OnTemplateMenuClick(Sender: TObject);
begin
  if Sender is TMenuItem then
    FPresenter.HandleTemplateSelected(TMenuItem(Sender).Caption);
end;

procedure TFrameAIChat.OnGlobalPromptRequest(const APrompt: string; const AOpenChat: Boolean);
begin
  FPresenter.HandleGlobalPromptRequest(APrompt, AOpenChat);
end;

procedure TFrameAIChat.SetTheme(const AThemeName: string);
var
  LJson: TJSONObject;
  LColors: TRadIAThemeColors;
begin
  LColors := TRadIAThemeColors.GetColorsForTheme(AThemeName);
  UpdateVCLColors(LColors);

  if not FBrowserInitialized then
    Exit;

  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'set_theme');
    LJson.AddPair('theme', AThemeName.ToLower);
    
    LJson.AddPair('bgBase', ColorToHex(LColors.BgBase));
    LJson.AddPair('bgPanel', ColorToHex(LColors.BgBase));
    LJson.AddPair('bgInput', ColorToHex(LColors.InputBgColor));
    LJson.AddPair('fgPrimary', ColorToHex(LColors.TextColor));
    LJson.AddPair('bgElevated', ColorToHex(LColors.BgElevated));
    LJson.AddPair('fgSecondary', LColors.FgSecondary);
    LJson.AddPair('codeBg', LColors.CodeBg);
    LJson.AddPair('codeHeader', ColorToHex(LColors.CodeHeader));
    LJson.AddPair('greenApply', LColors.GreenApply);
    LJson.AddPair('border', ColorToHex(LColors.BorderColor));
    
    if LColors.IsDark then
      LJson.AddPair('accent', '#007acc')
    else
      LJson.AddPair('accent', '#005a9e');

    PostMessageToWeb(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

function TFrameAIChat.ColorToHex(AColor: TColor): string;
var
  LColorRGB: Longint;
  R, G, B: Byte;
begin
  LColorRGB := ColorToRGB(AColor);
  R := GetRValue(LColorRGB);
  G := GetGValue(LColorRGB);
  B := GetBValue(LColorRGB);
  Result := Format('#%.2x%.2x%.2x', [R, G, B]);
end;

procedure TFrameAIChat.UpdateSendButtonVisual(const AInProgress: Boolean);
var
  LIsDark: Boolean;
  LThemingServices: IOTAIDEThemingServices;
  LActiveTheme: string;
begin
  LIsDark := False;
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LActiveTheme := LThemingServices.ActiveTheme;
      LIsDark := IsThemeDark(LActiveTheme);
    end;
  end;

  if AInProgress then
  begin
    shpSendBg.Brush.Color := $003B3BFC;
    shpSendBg.Pen.Color := $003B3BFC;
    shpSendBg.Pen.Style := psSolid;
    btnSend.Caption := #9632;
    btnSend.Font.Color := clWhite;
  end
  else
  begin
    if LIsDark then
    begin
      shpSendBg.Brush.Color := $00E5E5E5;
      shpSendBg.Pen.Color := $00E5E5E5;
      shpSendBg.Pen.Style := psSolid;
      btnSend.Caption := #10148;
      btnSend.Font.Color := $001E1E1E;
    end
    else
    begin
      shpSendBg.Brush.Color := $001E1E1E;
      shpSendBg.Pen.Color := $001E1E1E;
      shpSendBg.Pen.Style := psSolid;
      btnSend.Caption := #10148;
      btnSend.Font.Color := clWhite;
    end;
  end;
end;

procedure TFrameAIChat.UpdateVCLColors(const AColors: TRadIAThemeColors);
begin
  Self.Color := AColors.BgBase;
  pnlToolbar.Color := AColors.BgBase;
  pnlInput.Color := AColors.BgBase;
  pnlSessions.Color := AColors.BgBase;
  pnlSessionsHeader.Color := AColors.BgBase;
  
  lblTitle.Font.Color := AColors.TextColor;
  lblContext.Font.Color := AColors.TextColor;
  
  memPrompt.Color := AColors.InputBgColor;
  memPrompt.Font.Color := AColors.TextColor;
  
  lstSessions.Color := AColors.InputBgColor;
  lstSessions.Font.Color := AColors.TextColor;
  
  shpInputBg.Brush.Color := AColors.InputBgColor;
  shpInputBg.Pen.Color := AColors.BorderColor;
end;

{ IChatView Implementation }

procedure TFrameAIChat.SetRequestState(const AInProgress: Boolean);
begin
  TThread.Queue(nil,
    TThreadProcedure(
    procedure
    begin
      Self.UpdateSendButtonVisual(AInProgress);
      Self.btnSend.Enabled := True;
    end));
end;

procedure TFrameAIChat.UpdateTokensStats(const AStats: string);
begin
end;

procedure TFrameAIChat.PostMessageToWeb(const AJson: string);
begin
  if FBrowserInitialized and Assigned(EdgeBrowser) and Assigned(EdgeBrowser.DefaultInterface) then
  begin
    EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(AJson));
  end;
end;

procedure TFrameAIChat.PostMessageToBackgroundWeb(const AJson: string);
begin
  if FBrowserWebInitialized and Assigned(FEdgeBrowserWeb) and Assigned(FEdgeBrowserWeb.DefaultInterface) then
  begin
    FEdgeBrowserWeb.DefaultInterface.PostWebMessageAsJson(PChar(AJson));
  end;
end;

procedure TFrameAIChat.CreateBackgroundBrowser;
begin
  CreateEdgeBrowserWeb;
end;

function TFrameAIChat.IsBackgroundBrowserInitialized: Boolean;
begin
  Result := FBrowserWebInitialized;
end;

procedure TFrameAIChat.NavigateBackgroundBrowser(const AUrl: string);
begin
  if Assigned(FEdgeBrowserWeb) then
    FEdgeBrowserWeb.Navigate(AUrl);
end;

procedure TFrameAIChat.ShowLoginWindow(const AUrl: string; AOnLoginSuccess: TProc);
begin
  TFormWebLogin.ShowLogin(Self, AUrl, AOnLoginSuccess);
end;

procedure TFrameAIChat.UpdateProviders(const AProviders: TArray<string>; const AActiveProvider: string);
var
  LProviderId: string;
  I, LFoundIndex: Integer;
  LMeta: TProviderMetadata;
  LProvObj: TProviderObject;
begin
  if Assigned(cbProvider) then
  begin
    for I := 0 to cbProvider.Items.Count - 1 do
      if Assigned(cbProvider.Items.Objects[I]) then
        cbProvider.Items.Objects[I].Free;
    cbProvider.Items.Clear;
  end;

  for LProviderId in AProviders do
  begin
    if TProviderRegistry.GetProvider(LProviderId, LMeta) then
    begin
      LProvObj := TProviderObject.Create(LProviderId);
      cbProvider.Items.AddObject(LMeta.DisplayName, LProvObj);
    end;
  end;

  LFoundIndex := -1;
  for I := 0 to cbProvider.Items.Count - 1 do
  begin
    if SameText(TProviderObject(cbProvider.Items.Objects[I]).Id, AActiveProvider) then
    begin
      LFoundIndex := I;
      Break;
    end;
  end;

  if LFoundIndex <> -1 then
    cbProvider.ItemIndex := LFoundIndex
  else if cbProvider.Items.Count > 0 then
    cbProvider.ItemIndex := 0;
end;

procedure TFrameAIChat.UpdateModels(const AModels: TArray<string>; const AActiveModel: string; const AEnabled: Boolean);
var
  LModel: string;
begin
  cbModel.Items.Clear;
  for LModel in AModels do
    cbModel.Items.Add(LModel);
  cbModel.ItemIndex := cbModel.Items.IndexOf(AActiveModel);
  cbModel.Enabled := AEnabled;
end;

procedure TFrameAIChat.UpdateSessions(const ASessions: TArray<TSessionInfo>; const AActiveSessionId: string);
var
  LSession: TSessionInfo;
  I, LIndexToSelect: Integer;
begin
  lstSessions.OnClick := nil;
  try
    for I := 0 to lstSessions.Items.Count - 1 do
      if Assigned(lstSessions.Items.Objects[I]) then
        lstSessions.Items.Objects[I].Free;
    lstSessions.Items.Clear;

    for LSession in ASessions do
    begin
      lstSessions.Items.AddObject(LSession.Name, TSessionObject.Create(LSession.Id));
    end;

    LIndexToSelect := -1;
    for I := 0 to lstSessions.Items.Count - 1 do
    begin
      if SameText(TSessionObject(lstSessions.Items.Objects[I]).Id, AActiveSessionId) then
      begin
        LIndexToSelect := I;
        Break;
      end;
    end;

    if LIndexToSelect <> -1 then
      lstSessions.ItemIndex := LIndexToSelect
    else if lstSessions.Items.Count > 0 then
      lstSessions.ItemIndex := 0;
  finally
    lstSessions.OnClick := Self.lstSessionsClick;
  end;
end;

procedure TFrameAIChat.UpdateTemplates(const ATemplates: TArray<string>);
var
  LTemplateName: string;
  LMenuItem: TMenuItem;
  I: Integer;
begin
  if Assigned(FPopupMenuTemplates) then
  begin
    for I := 0 to FPopupMenuTemplates.Items.Count - 1 do
      FPopupMenuTemplates.Items[I].OnClick := nil;
    FPopupMenuTemplates.Items.Clear;
  end;

  for LTemplateName in ATemplates do
  begin
    LMenuItem := TMenuItem.Create(FPopupMenuTemplates);
    LMenuItem.Caption := LTemplateName;
    LMenuItem.OnClick := OnTemplateMenuClick;
    FPopupMenuTemplates.Items.Add(LMenuItem);
  end;
end;

function TFrameAIChat.GetPromptInput: string;
begin
  Result := memPrompt.Text;
end;

procedure TFrameAIChat.SetPromptInput(const APrompt: string);
begin
  memPrompt.Text := APrompt;
  memPrompt.SelStart := Length(APrompt);
end;

procedure TFrameAIChat.FocusPromptInput;
begin
  memPrompt.SetFocus;
end;

function TFrameAIChat.GetActiveEditorText(out ACode: string; const AOnlySelected: Boolean): Boolean;
begin
  Result := TRadIAOTAHelper.GetActiveEditorText(ACode, AOnlySelected);
end;

procedure TFrameAIChat.ReplaceActiveEditorText(const ACode: string);
begin
  TRadIAOTAHelper.ReplaceActiveEditorText(ACode);
end;

procedure TFrameAIChat.ShowMessageDialog(const AMessage: string);
begin
  ShowMessage(AMessage);
end;

function TFrameAIChat.SaveDialogExecute(out AFileName: string): Boolean;
begin
  Result := SaveDialog.Execute;
  if Result then
    AFileName := SaveDialog.FileName;
end;

procedure TFrameAIChat.ToggleSessionsPanel;
begin
  pnlSessions.Visible := not pnlSessions.Visible;
  splitterSessions.Visible := pnlSessions.Visible;
  if pnlSessions.Visible then
    splitterSessions.Left := pnlSessions.Left + pnlSessions.Width + 1;
end;

procedure TFrameAIChat.OpenSettingsDialog;
var
  LForm: TFormAIConfig;
  LThemingServices: IOTAIDEThemingServices;
begin
  LForm := TFormAIConfig.Create(nil);
  try
    if Assigned(Vcl.Forms.Application.MainForm) then
    begin
      LForm.PopupParent := Vcl.Forms.Application.MainForm;
      LForm.PopupMode := pmExplicit;
    end;

    LForm.LoadConfig;
    
    if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
    begin
      if LThemingServices.IDEThemingEnabled then
      begin
        LThemingServices.ApplyTheme(LForm);
      end;
    end;
    
    LForm.ShowModal;
  finally
    LForm.Free;
  end;
end;

procedure TFrameAIChat.CreateEdgeBrowserWeb;
begin
  if not Assigned(FpnlBrowserWeb) then
  begin
    FpnlBrowserWeb := TPanel.Create(Self);
    FpnlBrowserWeb.Parent := Self;
    FpnlBrowserWeb.BevelOuter := bvNone;
    FpnlBrowserWeb.Caption := '';
    FpnlBrowserWeb.Left := -5000;
    FpnlBrowserWeb.Top := 0;
    FpnlBrowserWeb.Width := 10;
    FpnlBrowserWeb.Height := 10;
    FpnlBrowserWeb.Visible := True;
  end;

  if not Assigned(FEdgeBrowserWeb) then
  begin
    FEdgeBrowserWeb := TEdgeBrowser.Create(Self);
    FEdgeBrowserWeb.Parent := FpnlBrowserWeb;
    FEdgeBrowserWeb.Align := alClient;
    FEdgeBrowserWeb.OnCreateWebViewCompleted := EdgeBrowserWebCreateWebViewCompleted;
    FEdgeBrowserWeb.OnSourceChanged := EdgeBrowserWebSourceChanged;
    {$IF CompilerVersion >= 35.0}
    FEdgeBrowserWeb.OnWebMessageReceived := EdgeBrowserWebWebMessageReceived;
    {$ELSE}
    FEdgeBrowserWeb.OnWebMessageReceived := EdgeBrowserWebWebMessageReceivedLegacy;
    {$ENDIF}
    
    FEdgeBrowserWeb.UserDataFolder := TPath.Combine(TPath.GetHomePath, 'RadIA\WebView2Web');
    FEdgeBrowserWeb.CreateWebView;
  end;
end;

procedure TFrameAIChat.EdgeBrowserWebCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
var
  LSettings: ICoreWebView2Settings;
  LSettings2: ICoreWebView2Settings2_Local;
  LScriptFile: string;
  LScriptContent: string;
begin
  if Succeeded(AResult) then
  begin
    FBrowserWebInitialized := True;
    if Assigned(FEdgeBrowserWeb.DefaultInterface) then
    begin
      if Succeeded(FEdgeBrowserWeb.DefaultInterface.Get_Settings(LSettings)) and Assigned(LSettings) then
      begin
        LSettings.Set_AreDevToolsEnabled(1);
        LSettings.Set_AreDefaultContextMenusEnabled(1);
        
        if Succeeded(LSettings.QueryInterface(ICoreWebView2Settings2_Local, LSettings2)) and Assigned(LSettings2) then
        begin
          LSettings2.Put_UserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        end;
      end;

      LScriptFile := TPath.Combine(FWebFilesDir, 'bridge.js');
      if TFile.Exists(LScriptFile) then
      begin
        try
          LScriptContent := TFile.ReadAllText(LScriptFile, TEncoding.UTF8);
          FEdgeBrowserWeb.DefaultInterface.AddScriptToExecuteOnDocumentCreated(PWideChar(LScriptContent), nil);
        except
          on E: Exception do
            TLogger.Log('Error reading or injecting bridge script to Web view: ' + E.Message, 'UI');
        end;
      end;
    end;

    if Assigned(FPresenter) then
      FPresenter.OnBackgroundBrowserInitialized;
  end;
end;

procedure TFrameAIChat.EdgeBrowserWebSourceChanged(Sender: TCustomEdgeBrowser; IsNewDocument: Boolean);
begin
  if Assigned(FPresenter) then
    FPresenter.OnBackgroundBrowserNavigation(Sender.LocationURL);
end;

{$IF CompilerVersion >= 35.0}
procedure TFrameAIChat.EdgeBrowserWebWebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
var
  LStr: PWideChar;
  LJsonStr: PWideChar;
begin
  if Assigned(Args.ArgsInterface) then
  begin
    if Succeeded(Args.ArgsInterface.TryGetWebMessageAsString(LStr)) then
    begin
      try
        FPresenter.OnBackgroundBrowserMessage(string(LStr));
      finally
        CoTaskMemFree(LStr);
      end;
    end
    else
    begin
      Args.ArgsInterface.Get_webMessageAsJson(LJsonStr);
      try
        FPresenter.OnBackgroundBrowserMessage(string(LJsonStr));
      finally
        CoTaskMemFree(LJsonStr);
      end;
    end;
  end;
end;
{$ELSE}
procedure TFrameAIChat.EdgeBrowserWebWebMessageReceivedLegacy(Sender: TCustomEdgeBrowser; const AMessage: string);
begin
  FPresenter.OnBackgroundBrowserMessage(AMessage);
end;
{$ENDIF}

end.
