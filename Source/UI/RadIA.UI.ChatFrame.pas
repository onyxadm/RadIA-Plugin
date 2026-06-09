unit RadIA.UI.ChatFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Edge, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config,
  RadIA.Core.Service, RadIA.Core.PromptHistory, RadIA.Core.TokenUsage, Vcl.Menus,
  RadIA.Core.PromptTemplates, Vcl.Buttons, Winapi.WebView2, Winapi.ActiveX,
  RadIA.Core.Sessions, RadIA.UI.Resources;

type
  TFrameAIChat = class(TFrame)
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
    FConfig: IAIConfig;
    FAIService: TRadIAService;
    FSessionManager: TRadIASessionManager;
    FHistory: TArray<IChatMessage>;
    FWebFilesDir: string;
    FBrowserInitialized: Boolean;
    FWebViewInitialized: Boolean;
    FWebViewReady: Boolean;
    FPromptHistoryManager: TPromptHistoryManager;
    FAccumulatedUsage: TTokenUsage;
    FTemplateManager: TPromptTemplateManager;
    FPopupMenuTemplates: TPopupMenu;
    FLoadingConfig: Boolean;  { Guard: prevents OnChange events from saving during LoadConfig }
    FLifecycleGuard: IInterface;
    FRequestInProgress: Boolean;
    FCancelledByUser: Boolean;
    EdgeBrowser: TEdgeBrowser;
    FEdgeBrowserWeb: TEdgeBrowser;
    FpnlBrowserWeb: TPanel;
    FbtnWebLoginConnect: TSpeedButton;
    FBrowserWebInitialized: Boolean;

    procedure CreateEdgeBrowserWeb;
    procedure OnbtnWebLoginConnectClick(Sender: TObject);
    procedure EdgeBrowserWebCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    {$IF CompilerVersion >= 35.0}
    procedure EdgeBrowserWebWebMessageReceived(Sender: TCustomEdgeBrowser; Args: TWebMessageReceivedEventArgs);
    {$ELSE}
    procedure EdgeBrowserWebWebMessageReceivedLegacy(Sender: TCustomEdgeBrowser; const AMessage: string);
    {$ENDIF}

    procedure UpdateWebViewNavigation;
    procedure OnWebViewBridgeSendPrompt(const APrompt: string);
    procedure OnWebViewBridgeCancel;
    
    procedure UpdateSendButtonVisual;
    function ColorToHex(AColor: TColor): string;
    procedure CreateEdgeBrowser;
    
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure InitializeWebView;
    procedure CopyWebFiles;
    function IsProviderConfigured(const AProviderId: string): Boolean;
    procedure LoadConfig;
    procedure UpdateModelsCombo;
    procedure SendPromptToAI(const APromptText: string);
    procedure PostToWebView(const AAction, ARole, AText: string; const AProvider: string = ''; const AModel: string = ''); overload;
    procedure PostToWebView(const AAction, ARole, AText: string; AIsDone: Boolean; const AProvider: string = ''; const AModel: string = ''); overload;
    procedure OnGlobalPromptRequest(const APrompt: string; const AOpenChat: Boolean);
    procedure LoadChatHistory;
    procedure SaveChatHistory;
    procedure LoadPromptHistory;
    procedure SavePromptHistory;
    procedure UpdateSessionsList;
    procedure LoadTemplatesMenu;
    procedure OnTemplateMenuClick(Sender: TObject);
    procedure ApplyIDETheme;
    procedure UpdateVCLColors(const AColors: TRadIAThemeColors);
    procedure ProcessWebMessage(const AMessage: string);
    function PreProcessPrompt(const APromptText: string): string;
    procedure GenerateDTO(const AInput, AInputType, AOutputType: string);
    
    procedure SendInitialConfigToWeb;
    procedure SendModelsUpdateToWeb;
    procedure PostRequestStateToWeb(AInProgress: Boolean);
    procedure SendSessionsUpdateToWeb;
  protected
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure SetTheme(const AThemeName: string);
  end;

implementation

uses
  System.IOUtils, System.JSON, ToolsAPI, RadIA.OTA.Helper, RadIA.UI.ConfigForm,
  RadIA.Core.Mediator, RadIA.Core.ConversationExporter, RadIA.Core.Logger, Vcl.Themes,
  RadIA.Core.DTO.Generator, RadIA.Core.ProjectGenerator, RadIA.Core.ProviderRegistry, 
  RadIA.Provider.WebViewBridge, RadIA.UI.WebLoginForm;

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



constructor TFrameAIChat.Create(AOwner: TComponent);
var
  LThemingServices: IOTAIDEThemingServices;
begin
  inherited Create(AOwner);
  FBrowserInitialized := False;
  FWebViewInitialized := False;
  FHistory := [];
  
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LThemingServices.ApplyTheme(Self);
    end;
  end;
  
  FLifecycleGuard := TLifecycleGuard.Create;
  FConfig := TRadIAConfig.GetInstance;
  FAIService := TRadIAService.Create(FConfig);
  FPromptHistoryManager := TPromptHistoryManager.Create;
  FAccumulatedUsage := TTokenUsage.Empty;
  FTemplateManager := TPromptTemplateManager.Create;
  FTemplateManager.Load;
  FPopupMenuTemplates := TPopupMenu.Create(Self);
  LoadTemplatesMenu;
  
  FWebFilesDir := TPath.Combine(TPath.GetHomePath, 'RadIA\Web');
  CopyWebFiles;
  
  FSessionManager := TRadIASessionManager.Create;
  FSessionManager.ActiveSessionId := FConfig.ActiveSessionId;
  
  LoadConfig;
  UpdateSessionsList;
  LoadPromptHistory;

  { Detect current IDE theme and apply colors to VCL controls }
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
      UpdateVCLColors(TRadIAThemeColors.GetColorsForTheme(LThemingServices.ActiveTheme))
    else
      UpdateVCLColors(TRadIAThemeColors.GetColorsForTheme('light'));
  end
  else
    UpdateVCLColors(TRadIAThemeColors.GetColorsForTheme('light'));

  memPrompt.OnKeyDown := Self.memPromptKeyDown;
  TRadIAMediator.Instance.RegisterPromptHandler(Self.OnGlobalPromptRequest);

  TRadIAWebViewBridgeProvider.OnSendPrompt := Self.OnWebViewBridgeSendPrompt;
  TRadIAWebViewBridgeProvider.OnCancel := Self.OnWebViewBridgeCancel;
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
    begin
      if Assigned(lstSessions.Items.Objects[I]) then
        lstSessions.Items.Objects[I].Free;
    end;
  end;

  if Assigned(cbProvider) then
  begin
    for I := 0 to cbProvider.Items.Count - 1 do
    begin
      if Assigned(cbProvider.Items.Objects[I]) then
        cbProvider.Items.Objects[I].Free;
    end;
  end;

  TRadIAWebViewBridgeProvider.OnSendPrompt := nil;
  TRadIAWebViewBridgeProvider.OnCancel := nil;

  FPromptHistoryManager.Free;
  FreeAndNil(FTemplateManager);
  FreeAndNil(FSessionManager);
  inherited Destroy;
end;

procedure TFrameAIChat.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  if Showing and not FWebViewInitialized then
  begin
    FWebViewInitialized := True;
    FWebViewReady := False;
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
    FWebViewReady := False;
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
  FWebViewReady := False;
  if Assigned(EdgeBrowser) then
  begin
    LEdgeToFree := EdgeBrowser;
    EdgeBrowser := nil;
    LEdgeToFree.Parent := nil; // Desvincula visualmente de forma síncrona
    TThread.Queue(nil,
      TThreadProcedure(
      procedure
      begin
        LEdgeToFree.Free; // Libera da memória de forma assíncrona (thread-safe/layout-safe)
      end));
  end;
  inherited DestroyWnd;
end;

procedure TFrameAIChat.CopyWebFiles;
var
  LSourceDir: string;
  LModuleDir: string;
  LFile: string;
  LFilesToCopy: TArray<string>;
begin
  ForceDirectories(FWebFilesDir);
  
  { 1. Try to find the Web folder relative to the running BPL/DLL module }
  LModuleDir := ExtractFilePath(GetModuleName(HInstance));
  LSourceDir := TPath.Combine(LModuleDir, 'Web');
  
  { 2. Try dynamic search going up 3 folder levels (development environment with manual install) }
  if not TDirectory.Exists(LSourceDir) then
  begin
    LSourceDir := TPath.GetFullPath(TPath.Combine(LModuleDir, '..\..\..\Source\UI\Web'));
  end;
  
  { 3. Fallback to the hardcoded development path if dynamic path doesn't exist }
  if not TDirectory.Exists(LSourceDir) then
  begin
    LSourceDir := 'D:\Projetos\PluginDelphiIA\Source\UI\Web';
  end;
  
  if not TDirectory.Exists(LSourceDir) then
    Exit;
    
  LFilesToCopy := TArray<string>.Create('chat.html', 'chat.css', 'chat.js', 'diff.html',
    'marked.min.js', 'prism.min.js', 'prism-pascal.min.js', 'prism-tomorrow.min.css',
    'diff2html.min.css', 'diff2html.min.js', 'diff.min.js', 'bridge.js');
  for LFile in LFilesToCopy do
  begin
    if TFile.Exists(TPath.Combine(LSourceDir, LFile)) then
    begin
      TFile.Copy(TPath.Combine(LSourceDir, LFile), TPath.Combine(FWebFilesDir, LFile), True);
    end;
  end;
end;

procedure TFrameAIChat.InitializeWebView;
begin
  EdgeBrowser.UserDataFolder := TPath.Combine(TPath.GetHomePath, 'RadIA\WebView2');
  UpdateWebViewNavigation;
end;

function TFrameAIChat.IsProviderConfigured(const AProviderId: string): Boolean;
var
  LMeta: TProviderMetadata;
begin
  if SameText(AProviderId, 'Ollama') then
    Result := not FConfig.GetOllamaBaseUrl.Trim.IsEmpty
  else if SameText(AProviderId, 'LMStudio') then
    Result := not FConfig.GetProviderBaseUrl('LMStudio').Trim.IsEmpty
  else
  begin
    if TProviderRegistry.GetProvider(AProviderId, LMeta) and LMeta.IsDynamic then
      Exit(True);

    // Provedores configurados para usar Web Login (Plus/Pro) nao exigem API Key
    if SameText(FConfig.GetProviderAuthType(AProviderId), 'web_login') then
      Exit(True);

    Result := not FConfig.GetApiKey(AProviderId).Trim.IsEmpty;
  end;
end;

procedure TFrameAIChat.LoadConfig;
var
  LProviders: TArray<TProviderMetadata>;
  LActiveProvider: string;
  LFoundIndex: Integer;
  I: Integer;
begin
  { Disable OnChange handlers to prevent premature FConfig.Save during
    programmatic combo updates — e.g. cbProvider.ItemIndex assignment
    fires cbProviderChange which calls FConfig.Save with partial data. }
  FLoadingConfig := True;
  try
    if Assigned(cbProvider) then
    begin
      for I := 0 to cbProvider.Items.Count - 1 do
      begin
        if Assigned(cbProvider.Items.Objects[I]) then
          cbProvider.Items.Objects[I].Free;
      end;
      cbProvider.Items.Clear;
    end;

    LProviders := TProviderRegistry.GetProviders;
    for I := 0 to Length(LProviders) - 1 do
    begin
      if IsProviderConfigured(LProviders[I].Id) then
        cbProvider.Items.AddObject(LProviders[I].DisplayName, TProviderObject.Create(LProviders[I].Id));
    end;

    if cbProvider.Items.Count = 0 then
    begin
      for I := 0 to Length(LProviders) - 1 do
        cbProvider.Items.AddObject(LProviders[I].DisplayName, TProviderObject.Create(LProviders[I].Id));
    end;

    LActiveProvider := FConfig.GetActiveProvider;
    LFoundIndex := -1;
    for I := 0 to cbProvider.Items.Count - 1 do
    begin
      if SameText(TProviderObject(cbProvider.Items.Objects[I]).Id, LActiveProvider) then
      begin
        LFoundIndex := I;
        Break;
      end;
    end;

    if LFoundIndex <> -1 then
      cbProvider.ItemIndex := LFoundIndex
    else if cbProvider.Items.Count > 0 then
    begin
      cbProvider.ItemIndex := 0;
      FConfig.SetActiveProvider(TProviderObject(cbProvider.Items.Objects[0]).Id);
    end;

    UpdateModelsCombo;
    UpdateWebViewNavigation;
  finally
    FLoadingConfig := False;
  end;
end;

procedure TFrameAIChat.UpdateModelsCombo;
var
  LProvider: IIAProvider;
  LGuard: ILifecycleGuard;
begin
  cbModel.Items.Clear;
  cbModel.Items.Add('Loading...');
  cbModel.ItemIndex := 0;
  cbModel.Enabled := False;
  LGuard := FLifecycleGuard as ILifecycleGuard;

  try
    LProvider := FAIService.CreateActiveProvider;
    LProvider.FetchAvailableModelsAsync(
      procedure(AModels: TArray<string>; AError: string)
      begin
        TThread.Queue(nil,
          procedure
          var
            LModel: string;
            LActiveModel: string;
            LProvId: string;
          begin
            if not LGuard.IsAlive then
              Exit;
              
            cbModel.Items.Clear;
            for LModel in AModels do
              cbModel.Items.Add(LModel);
            
            if Assigned(LProvider) then
            begin
              LProvId := LProvider.GetProviderId;
              LActiveModel := FConfig.GetActiveModel(LProvId);
              cbModel.ItemIndex := cbModel.Items.IndexOf(LActiveModel);
              if cbModel.ItemIndex = -1 then
              begin
                cbModel.ItemIndex := 0;
                if cbModel.Items.Count > 0 then
                begin
                  FConfig.SetActiveModel(LProvId, cbModel.Items[0]);
                  FConfig.Save;
                end;
              end;
            end;
              
            cbModel.Enabled := True;
            SendModelsUpdateToWeb;
          end
        );
      end);
  except
    on E: Exception do
    begin
      cbModel.Items.Clear;
      cbModel.Items.Add('Error loading models');
      cbModel.ItemIndex := 0;
      cbModel.Enabled := True;
    end;
  end;
end;

procedure TFrameAIChat.cbProviderChange(Sender: TObject);
var
  LSelectedProvider: string;
begin
  { Ignore programmatic changes during LoadConfig to prevent premature Save }
  if FLoadingConfig then
    Exit;

  if cbProvider.ItemIndex <> -1 then
  begin
    LSelectedProvider := TProviderObject(cbProvider.Items.Objects[cbProvider.ItemIndex]).Id;
    FConfig.SetActiveProvider(LSelectedProvider);
    FConfig.Save;
    UpdateModelsCombo;
    UpdateWebViewNavigation;
  end;
end;

procedure TFrameAIChat.cbModelChange(Sender: TObject);
var
  LSelectedProvider: string;
begin
  { Ignore programmatic changes during LoadConfig to prevent premature Save }
  if FLoadingConfig then
    Exit;

  if cbProvider.ItemIndex <> -1 then
  begin
    LSelectedProvider := TProviderObject(cbProvider.Items.Objects[cbProvider.ItemIndex]).Id;
    FConfig.SetActiveModel(LSelectedProvider, cbModel.Text);
    FConfig.Save;
  end;
end;

procedure TFrameAIChat.btnClearClick(Sender: TObject);
begin
  FHistory := [];
  FAccumulatedUsage := TTokenUsage.Empty;
  PostToWebView('clear_chat', '', '');
  PostToWebView('update_tokens', '', '');
  
  if Assigned(FAIService) then
    FAIService.ClearCache;
  
  if (FSessionManager <> nil) and not FSessionManager.ActiveSessionId.IsEmpty then
  begin
    try
      FSessionManager.SaveSessionHistory(FSessionManager.ActiveSessionId, []);
    except
      // Ignore write errors
    end;
  end;
end;

procedure TFrameAIChat.btnExportClick(Sender: TObject);
var
  LContent: string;
  LProviderName: string;
  LModelName: string;
begin
  if Length(FHistory) = 0 then
  begin
    ShowMessage('There is no conversation history to export.');
    Exit;
  end;

  if SaveDialog.Execute then
  begin
    LProviderName := cbProvider.Text;
    LModelName := cbModel.Text;
    
    if SameText(ExtractFileExt(SaveDialog.FileName), '.html') then
      LContent := TConversationExporter.ExportToHTML(FHistory, LProviderName, LModelName)
    else
      LContent := TConversationExporter.ExportToMarkdown(FHistory, LProviderName, LModelName);
      
    try
      TFile.WriteAllText(SaveDialog.FileName, LContent, TEncoding.UTF8);
      ShowMessage('Conversation exported successfully!');
    except
      on E: Exception do
        ShowMessage('Error exporting conversation: ' + E.Message);
    end;
  end;
end;

procedure TFrameAIChat.btnSettingsClick(Sender: TObject);
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
    
    if LForm.ShowModal = mrOk then
    begin
      { Refresh config settings }
      FConfig.Load;
      LoadConfig;
      
      { Refresh templates }
      FTemplateManager.Load;
      LoadTemplatesMenu;
    end;
  finally
    LForm.Free;
  end;
end;

procedure TFrameAIChat.PostToWebView(const AAction, ARole, AText: string; const AProvider: string; const AModel: string);
begin
  PostToWebView(AAction, ARole, AText, False, AProvider, AModel);
end;

procedure TFrameAIChat.PostToWebView(const AAction, ARole, AText: string; AIsDone: Boolean; const AProvider: string; const AModel: string);
var
  LJson: TJSONObject;
begin
  if not FBrowserInitialized then
    Exit;

  TLogger.Log(Format('PostToWebView: Action=%s, Role=%s, TextLen=%d, IsDone=%s, Provider=%s, Model=%s',
    [AAction, ARole, Length(AText), BoolToStr(AIsDone, True), AProvider, AModel]), 'UI');
    
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', AAction);
    if not ARole.IsEmpty then
      LJson.AddPair('role', ARole);
    if not AText.IsEmpty then
      LJson.AddPair('text', AText);
    LJson.AddPair('isDone', TJSONBool.Create(AIsDone));
    if not AProvider.IsEmpty then
      LJson.AddPair('provider', AProvider);
    if not AModel.IsEmpty then
      LJson.AddPair('model', AModel);
      
    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
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

    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
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

procedure TFrameAIChat.UpdateSendButtonVisual;
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

  if FRequestInProgress then
  begin
    { Estado de Parar / Cancelar }
    shpSendBg.Brush.Color := $003B3BFC; // Vermelho moderno (BGR)
    shpSendBg.Pen.Color := $003B3BFC;
    shpSendBg.Pen.Style := psSolid;
    btnSend.Caption := #9632; // quadrado ■
    btnSend.Font.Color := clWhite;
  end
  else
  begin
    { Estado de Enviar }
    if LIsDark then
    begin
      shpSendBg.Brush.Color := $00E5E5E5; // Branco/Cinza claro
      shpSendBg.Pen.Color := $00E5E5E5;
      shpSendBg.Pen.Style := psSolid;
      btnSend.Caption := #10148; // Símbolo de aviãozinho/seta moderno
      btnSend.Font.Color := $001E1E1E; // Cinza escuro
    end
    else
    begin
      shpSendBg.Brush.Color := $001F1F1F; // Preto/Cinza escuro
      shpSendBg.Pen.Color := $001F1F1F;
      shpSendBg.Pen.Style := psSolid;
      btnSend.Caption := #10148; // Símbolo de aviãozinho/seta moderno
      btnSend.Font.Color := clWhite;
    end;
  end;

  { Habilita/Desabilita os componentes de múltiplas sessões com base no progresso da requisição }
  btnNewSession.Enabled := not FRequestInProgress;
  btnRenameSession.Enabled := not FRequestInProgress;
  btnDeleteSession.Enabled := not FRequestInProgress;
  lstSessions.Enabled := not FRequestInProgress;
  PostRequestStateToWeb(FRequestInProgress);
end;

procedure TFrameAIChat.UpdateVCLColors(const AColors: TRadIAThemeColors);
begin
  { Pintamos sempre todos os nossos componentes para garantir total consistência cromática }
  Self.Color := AColors.BgBase;
  pnlToolbar.Color := AColors.BgBase;
  pnlToolbar.ParentBackground := False;
  pnlBrowser.Color := AColors.BgBase;
  pnlBrowser.ParentBackground := False;

  // Labels
  lblTitle.Font.Color := AColors.TextColor;
  if AColors.IsDark then
    lblContext.Font.Color := $009CA3AF
  else
    lblContext.Font.Color := clGrayText;

  // ComboBoxes
  cbProvider.Color := AColors.InputBgColor;
  cbProvider.Font.Color := AColors.TextColor;
  cbModel.Color := AColors.InputBgColor;
  cbModel.Font.Color := AColors.TextColor;

  // SpeedButtons da Toolbar
  btnTemplates.Font.Color := AColors.TextColor;
  btnExport.Font.Color := AColors.TextColor;
  btnClear.Font.Color := AColors.TextColor;
  btnSettings.Font.Color := AColors.TextColor;
  btnToggleSessions.Font.Color := AColors.TextColor;

  // Componentes da Barra Lateral de Sessões
  pnlSessions.Color := AColors.BgBase;
  pnlSessions.ParentBackground := False;
  pnlSessionsHeader.Color := AColors.BgBase;
  pnlSessionsHeader.ParentBackground := False;
  lstSessions.Color := AColors.InputBgColor;
  lstSessions.Font.Color := AColors.TextColor;
  btnNewSession.Font.Color := AColors.TextColor;
  btnRenameSession.Font.Color := AColors.TextColor;
  btnDeleteSession.Font.Color := AColors.TextColor;

  { Componentes da Barra de Input e Prompt }
  pnlInput.ParentBackground := False;
  pnlInput.Color := AColors.BgBase;
  pnlInput.StyleElements := pnlInput.StyleElements - [seClient, seBorder];
  
  shpInputBg.Brush.Color := AColors.InputBgColor;
  if AColors.IsDark then
    shpInputBg.Pen.Color := $003E3E42
  else
    shpInputBg.Pen.Color := $00D1D5DB;
  shpInputBg.Pen.Style := psSolid;

  memPrompt.StyleElements := [];
  memPrompt.Color := AColors.InputBgColor;
  memPrompt.Font.Color := AColors.TextColor;

  btnSend.StyleElements := btnSend.StyleElements - [seFont, seClient, seBorder];
  
  UpdateSendButtonVisual;
end;

procedure TFrameAIChat.ApplyIDETheme;
var
  LThemingServices: IOTAIDEThemingServices;
  LActiveTheme: string;
begin
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LActiveTheme := LThemingServices.ActiveTheme;
      if IsThemeDark(LActiveTheme) then
        SetTheme('dark')
      else
        SetTheme('light');
    end
    else
      SetTheme('light');
  end
  else
    SetTheme('dark');
end;

procedure TFrameAIChat.EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
var
  LSettings: ICoreWebView2Settings;
  LSettings2: ICoreWebView2Settings2_Local;
  LScriptFile: string;
  LScriptContent: string;
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
          EdgeBrowser.DefaultInterface.AddScriptToExecuteOnDocumentCreated(PWideChar(LScriptContent), nil);
        except
          on E: Exception do
            TLogger.Log('Error reading or injecting bridge script: ' + E.Message, 'UI');
        end;
      end;
    end;
    
    ApplyIDETheme;
    UpdateWebViewNavigation;
  end;
end;

procedure TFrameAIChat.ProcessWebMessage(const AMessage: string);
var
  LParsed: TJSONValue;
  LJson: TJSONObject;
  LAction: string;
  LCode: string;
  LProviderStr: string;
  LModelStr: string;
  LText: string;
begin
  LParsed := TJSONObject.ParseJSONValue(AMessage);
  if not Assigned(LParsed) then
    Exit;
  try
    if not (LParsed is TJSONObject) then
      Exit;

    LJson := LParsed as TJSONObject;
    LAction := LJson.GetValue<string>('action', '');
    if LAction = 'create_project' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        var
          LJsonFiles: TJSONArray;
          LJsonFilesStr: string;
          LErrorMsg: string;
        begin
          LJsonFiles := LJson.GetValue('files') as TJSONArray;
          if Assigned(LJsonFiles) then
          begin
            LJsonFilesStr := LJsonFiles.ToJSON;
            if not TRadIAProjectGenerator.GenerateFromJSON(LJsonFilesStr, LErrorMsg) then
            begin
              if not LErrorMsg.IsEmpty then
              begin
                Application.MessageBox(PChar(LErrorMsg), 'RadIA', MB_OK or MB_ICONWARNING);
              end;
            end;
          end
          else
          begin
            Application.MessageBox('No files data received.', 'RadIA', MB_OK or MB_ICONWARNING);
          end;
        end));
    end
    else if LAction = 'apply_code' then
    begin
      LCode := LJson.GetValue<string>('code', '');
      { Normalize line endings to CRLF (#13#10) for Windows OTA editor compatibility. }
      LCode := StringReplace(LCode, #13#10, #10, [rfReplaceAll]);
      LCode := StringReplace(LCode, #13,    #10, [rfReplaceAll]);
      LCode := StringReplace(LCode, #10,    #13#10, [rfReplaceAll]);
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          TRadIAOTAHelper.ReplaceActiveEditorText(LCode);
        end));
    end
    else if LAction = 'ready' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          FWebViewReady := True;
          LoadChatHistory;
          SendInitialConfigToWeb;
          SendSessionsUpdateToWeb;
          
          { Se a WebView carregou enquanto uma requisição de IA já estava rodando, }
          { garante o envio do indicador de digitação agora que ela está pronta. }
          if FRequestInProgress then
            PostToWebView('show_typing', '', '');
        end));
    end
    else if LAction = 'new_chat' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          btnNewSessionClick(nil);
          SendSessionsUpdateToWeb;
        end));
    end
    else if LAction = 'new_session' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          btnNewSessionClick(nil);
          SendSessionsUpdateToWeb;
        end));
    end
    else if LAction = 'toggle_history' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          btnToggleSessionsClick(nil);
        end));
    end
    else if LAction = 'open_settings' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          btnSettingsClick(nil);
        end));
    end
    else if LAction = 'change_provider' then
    begin
      LProviderStr := LJson.GetValue<string>('provider', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        var
          Idx: Integer;
        begin
          Idx := cbProvider.Items.IndexOf(LProviderStr);
          if Idx <> -1 then
          begin
            cbProvider.ItemIndex := Idx;
            cbProviderChange(nil);
          end;
        end));
    end
    else if LAction = 'change_model' then
    begin
      LModelStr := LJson.GetValue<string>('model', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        var
          Idx: Integer;
        begin
          Idx := cbModel.Items.IndexOf(LModelStr);
          if Idx <> -1 then
          begin
            cbModel.ItemIndex := Idx;
            cbModelChange(nil);
          end;
        end));
    end
    else if LAction = 'select_session' then
    begin
      LText := LJson.GetValue<string>('id', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          if FRequestInProgress then
          begin
            FCancelledByUser := True;
            FAIService.CancelCurrentRequest;
            FRequestInProgress := False;
            UpdateSendButtonVisual;
          end;
          
          if not FSessionManager.ActiveSessionId.IsEmpty and not SameText(FSessionManager.ActiveSessionId, LText) then
            SaveChatHistory;
            
          FSessionManager.ActiveSessionId := LText;
          FSessionManager.UpdateSessionActivity(LText);
          FConfig.ActiveSessionId := LText;
          FConfig.Save;
          
          UpdateSessionsList;
          
          FHistory := [];
          FAccumulatedUsage := TTokenUsage.Empty;
          PostToWebView('clear_chat', '', '');
          PostToWebView('update_tokens', '', '');
          
          LoadChatHistory;
          SendSessionsUpdateToWeb;
        end));
    end
    else if LAction = 'rename_session' then
    begin
      LProviderStr := LJson.GetValue<string>('id', '');
      LModelStr := LJson.GetValue<string>('name', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          if not LModelStr.Trim.IsEmpty then
          begin
            FSessionManager.RenameSession(LProviderStr, LModelStr);
            UpdateSessionsList;
            SendSessionsUpdateToWeb;
          end;
        end));
    end
    else if LAction = 'delete_session' then
    begin
      LText := LJson.GetValue<string>('id', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          if FRequestInProgress and SameText(FSessionManager.ActiveSessionId, LText) then
          begin
            FCancelledByUser := True;
            FAIService.CancelCurrentRequest;
            FRequestInProgress := False;
            UpdateSendButtonVisual;
          end;

          FSessionManager.DeleteSession(LText);
          
          if SameText(FSessionManager.ActiveSessionId, LText) then
          begin
            FSessionManager.ActiveSessionId := '';
            FConfig.ActiveSessionId := '';
            FConfig.Save;
          end;
          
          UpdateSessionsList;
          
          FHistory := [];
          FAccumulatedUsage := TTokenUsage.Empty;
          PostToWebView('clear_chat', '', '');
          PostToWebView('update_tokens', '', '');
          
          LoadChatHistory;
          SendSessionsUpdateToWeb;
        end));
    end
    else if LAction = 'web_login_connect' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          OnbtnWebLoginConnectClick(nil);
        end));
    end
    else if LAction = 'update_stream' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        var
          LText: string;
          LIsDone: Boolean;
          LActiveProvider: string;
          LActiveModel: string;
        begin
          LText := LJson.GetValue<string>('text', '');
          LIsDone := LJson.GetValue<Boolean>('isDone', False);
          LActiveProvider := FConfig.GetActiveProvider;
          LActiveModel := FConfig.GetActiveModel(LActiveProvider);
          
          PostToWebView('update_message', 'assistant', LText, LIsDone, LActiveProvider, LActiveModel);
          
          if LIsDone then
            TRadIAWebViewBridgeProvider.ReceiveChunk(LText, True, '');
        end));
    end
    else if LAction = 'send_prompt' then
    begin
      LText := LJson.GetValue<string>('text', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        var
          LProcessed: string;
        begin
          LProcessed := PreProcessPrompt(LText);
          PostToWebView('add_message', 'user', LText);
          SendPromptToAI(LProcessed);
        end));
    end
    else if LAction = 'generate_dto' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        var
          LInput, LInputType, LOutputType: string;
        begin
          LInput := LJson.GetValue<string>('input', '');
          LInputType := LJson.GetValue<string>('inputType', '');
          LOutputType := LJson.GetValue<string>('outputType', '');
          GenerateDTO(LInput, LInputType, LOutputType);
        end));
    end
    else if LAction = 'cancel_request' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          if FRequestInProgress then
          begin
            FCancelledByUser := True;
            TLogger.Log('ProcessWebMessage: User requested cancellation of active request.', 'UI');
            btnSend.Enabled := False;
            UpdateSendButtonVisual;
            FAIService.CancelCurrentRequest;
          end;
        end));
    end
    else if LAction = 'clear_chat' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          btnClearClick(nil);
        end));
    end
    else if LAction = 'stream_chunk' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        var
          LChunk: string;
          LIsDone: Boolean;
          LError: string;
        begin
          LChunk := LJson.GetValue<string>('text', '');
          LIsDone := LJson.GetValue<Boolean>('isDone', False);
          LError := LJson.GetValue<string>('error', '');
          
          TRadIAWebViewBridgeProvider.ReceiveChunk(LChunk, LIsDone, LError);
        end));
    end;
  finally
    LParsed.Free;
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
    // JS sends postMessage(JSON.stringify({...})), so the message is a string type.
    // TryGetWebMessageAsString returns the original string payload directly.
    // Fallback to Get_webMessageAsJson if TryGetWebMessageAsString fails.
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
procedure TFrameAIChat.EdgeBrowserWebMessageReceivedLegacy(Sender: TCustomEdgeBrowser; const AMessage: string);
begin
  ProcessWebMessage(AMessage);
end;
{$ENDIF}

procedure TFrameAIChat.btnSendClick(Sender: TObject);
var
  LText: string;
  LProcessed: string;
begin
  if FRequestInProgress then
  begin
    FCancelledByUser := True;
    TLogger.Log('btnSendClick: User requested cancellation of active request.', 'UI');
    btnSend.Enabled := False;
    UpdateSendButtonVisual;
    FAIService.CancelCurrentRequest;
    Exit;
  end;

  if not btnSend.Enabled then
    Exit;

  LText := Trim(memPrompt.Text);
  if LText.IsEmpty then
    Exit;

  { Preprocess command templates (Slash Commands) }
  LProcessed := PreProcessPrompt(LText);

  { Save to prompt history before clearing the input }
  FPromptHistoryManager.Add(memPrompt.Text);
  SavePromptHistory;

  memPrompt.Text := '';
  PostToWebView('add_message', 'user', LText);
  SendPromptToAI(LProcessed);
end;

function TFrameAIChat.PreProcessPrompt(const APromptText: string): string;
var
  LActiveCode: string;
  LTemplate: TPromptTemplate;
  LResolved: string;
  LTemplateName: string;
  LStackTrace: string;
begin
  Result := APromptText;

  if APromptText.StartsWith('/createproject', True) then
  begin
    LTemplateName := Trim(APromptText.Substring(14));
    if FTemplateManager.FindTemplate('Create Project Delphi', LTemplate) then
      Result := LTemplate.Template.Replace('{specification}', LTemplateName);
  end
  else if APromptText.StartsWith('/template', True) then
  begin
    LTemplateName := Trim(APromptText.Substring(10));
    if not LTemplateName.IsEmpty then
    begin
      if not TRadIAOTAHelper.GetActiveEditorText(LActiveCode, True) or LActiveCode.IsEmpty then
        TRadIAOTAHelper.GetActiveEditorText(LActiveCode, False);
      
      LResolved := FTemplateManager.ResolveTemplate(LTemplateName, LActiveCode);
      if not LResolved.IsEmpty then
        Result := LResolved;
    end;
  end
  else if APromptText.StartsWith('/review', True) then
  begin
    if not TRadIAOTAHelper.GetActiveEditorText(LActiveCode, True) or LActiveCode.IsEmpty then
      TRadIAOTAHelper.GetActiveEditorText(LActiveCode, False);
      
    LResolved := FTemplateManager.ResolveTemplate('Review Leaks and SOLID', LActiveCode);
    if not LResolved.IsEmpty then
      Result := LResolved;
  end
  else if APromptText.StartsWith('/stacktrace', True) then
  begin
    LStackTrace := Trim(APromptText.Substring(11));
    if not TRadIAOTAHelper.GetActiveEditorText(LActiveCode, True) or LActiveCode.IsEmpty then
      TRadIAOTAHelper.GetActiveEditorText(LActiveCode, False);
      
    if FTemplateManager.FindTemplate('Analyze Stack Trace', LTemplate) then
      Result := LTemplate.Template.Replace('{stacktrace}', LStackTrace).Replace('{code}', LActiveCode);
  end;
end;

procedure TFrameAIChat.btnTemplatesClick(Sender: TObject);
var
  LPoint: TPoint;
begin
  LPoint := btnTemplates.Parent.ClientToScreen(Point(btnTemplates.Left, btnTemplates.Top + btnTemplates.Height));
  FPopupMenuTemplates.Popup(LPoint.X, LPoint.Y);
end;

procedure TFrameAIChat.LoadTemplatesMenu;
var
  LTemplate: TPromptTemplate;
  LMenuItem: TMenuItem;
begin
  FPopupMenuTemplates.Items.Clear;
  for LTemplate in FTemplateManager.GetTemplates do
  begin
    LMenuItem := TMenuItem.Create(FPopupMenuTemplates);
    LMenuItem.Caption := LTemplate.Name;
    LMenuItem.Hint := LTemplate.Description;
    LMenuItem.OnClick := OnTemplateMenuClick;
    FPopupMenuTemplates.Items.Add(LMenuItem);
  end;
end;

procedure TFrameAIChat.OnTemplateMenuClick(Sender: TObject);
var
  LMenuItem: TMenuItem;
  LActiveCode: string;
  LResolved: string;
begin
  if not Assigned(FTemplateManager) then
    Exit;
    
  if not (Sender is TMenuItem) then
    Exit;
    
  LMenuItem := TMenuItem(Sender);
  
  if not TRadIAOTAHelper.GetActiveEditorText(LActiveCode, True) or LActiveCode.IsEmpty then
    TRadIAOTAHelper.GetActiveEditorText(LActiveCode, False);

  LResolved := FTemplateManager.ResolveTemplate(LMenuItem.Caption, LActiveCode);
  
  memPrompt.Text := LResolved;
  memPrompt.SetFocus;
end;

procedure TFrameAIChat.SendPromptToAI(const APromptText: string);
var
  LUserMsg: IChatMessage;
  LFullResponse: string;
  LGuard: ILifecycleGuard;
  LProfile: TAIRequestProfile;
  LDoneHandled: Boolean;
  LActiveProvider: string;
  LActiveModel: string;
  LSessionId: string;
begin
  if FConfig.QuotaEnabled then
  begin
    FConfig.Load;
    if FConfig.QuotaUsed >= FConfig.QuotaLimit then
    begin
      ShowMessage(Format('Não foi possível enviar a requisição: Cota mensal de tokens excedida (limite local de %s tokens atingido).',
        [FormatFloat('#,##0', FConfig.QuotaLimit, TFormatSettings.Invariant)]));
      Exit;
    end;
  end;

  LDoneHandled := False;
  FRequestInProgress := True;
  FCancelledByUser := False;
  UpdateSendButtonVisual;
  btnSend.Enabled := True;

  LActiveProvider := FConfig.GetActiveProvider;
  LActiveModel := FConfig.GetActiveModel(LActiveProvider);
  LSessionId := FSessionManager.ActiveSessionId;

  TLogger.Log(Format('SendPromptToAI started. Provider=%s, Model=%s, PromptLength=%d, Session=%s',
    [LActiveProvider, LActiveModel, Length(APromptText), LSessionId]), 'UI');

  { Infer request profile from slash commands or resolved template headers }
  LProfile := rpGeneralChat;
  if APromptText.StartsWith('/refactor', True) or APromptText.StartsWith('/optimize', True) then
    LProfile := rpRefactorCode
  else if APromptText.StartsWith('/bugs', True) or APromptText.StartsWith('Perform a comprehensive static analysis', True) then
    LProfile := rpFindBugs
  else if APromptText.StartsWith('/test', True) then
    LProfile := rpGenerateTests
  else if APromptText.StartsWith('/explain', True) or APromptText.StartsWith('/doc', True) or APromptText.StartsWith('/fix', True) or APromptText.StartsWith('Analyze the following Delphi stack trace', True) then
    LProfile := rpExplainCode;
  
  { Save user prompt to history immediately to avoid losing it on network failure or IDE exit }
  LUserMsg := TRadIAService.CreateMessage(mrUser, APromptText, LActiveProvider, LActiveModel);
  FHistory := FHistory + [LUserMsg];
  SaveChatHistory;

  LFullResponse := '';
  LGuard := FLifecycleGuard as ILifecycleGuard;
  
  PostToWebView('show_typing', '', '');
  
  try
    FAIService.SendPromptStream(APromptText, FHistory,
      procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
      var
        LChunkCopy: string;
        LIsDoneCopy: Boolean;
        LErrorCopy: string;
      begin
        LChunkCopy := AChunk;
        LIsDoneCopy := AIsDone;
        LErrorCopy := AError;
        TThread.Queue(nil,
          TThreadProcedure(
          procedure
          var
            LAssistantMsg: IChatMessage;
            LStats: string;
            LUsage: TTokenUsage;
          begin
            { Guard: discard duplicate done/error signals emitted by providers }
            if LDoneHandled then
              Exit;

            if not LGuard.IsAlive then
              Exit;

            { Session Check: if the active session changed, discard UI updates but save partial response to the origin session }
            if not SameText(FSessionManager.ActiveSessionId, LSessionId) then
            begin
              TLogger.Log(Format('SendPromptToAI: Session changed from %s to %s. Discarding UI callback.', [LSessionId, FSessionManager.ActiveSessionId]), 'UI');
              
              { Apenas salva no histórico no encerramento definitivo (LIsDoneCopy = True) }
              { para evitar que múltiplos callbacks concorrentes em andamento gravem no mesmo arquivo JSON }
              if LIsDoneCopy and (not LFullResponse.IsEmpty) then
              begin
                TThread.CreateAnonymousThread(
                  procedure
                  var
                    LOrigHistory: TArray<IChatMessage>;
                    LAssistantMsg: IChatMessage;
                  begin
                    try
                      LOrigHistory := FSessionManager.LoadSessionHistory(LSessionId);
                      LAssistantMsg := TRadIAService.CreateMessage(mrAssistant, LFullResponse, LActiveProvider, LActiveModel);
                      LOrigHistory := LOrigHistory + [LAssistantMsg];
                      FSessionManager.SaveSessionHistory(LSessionId, LOrigHistory);
                    except
                      // Mute background thread exception
                    end;
                  end).Start;
              end;
              Exit;
            end;

            if FCancelledByUser then
            begin
              LDoneHandled := True;
              FRequestInProgress := False;
              UpdateSendButtonVisual;
              btnSend.Enabled := True;
              TLogger.Log('SendPromptToAI: Handling user cancellation in UI callback.', 'UI');
              
              if not LFullResponse.IsEmpty then
              begin
                LAssistantMsg := TRadIAService.CreateMessage(mrAssistant, LFullResponse + ' [Cancelado pelo usuário]', LActiveProvider, LActiveModel);
                FHistory := FHistory + [LAssistantMsg];
                SaveChatHistory;
              end;
              
              PostToWebView('add_message', 'assistant', '*Requisicao cancelada pelo usuario.*', False, LActiveProvider, LActiveModel);
              PostToWebView('append_message', 'assistant', '', True, LActiveProvider, LActiveModel);
              Exit;
            end;

            if not LErrorCopy.IsEmpty then
            begin
              LDoneHandled := True;
              FRequestInProgress := False;
              UpdateSendButtonVisual;
              btnSend.Enabled := True;
              TLogger.Log(Format('SendPromptToAI error callback: %s', [LErrorCopy]), 'UI');
              
              if not LFullResponse.IsEmpty then
              begin
                LFullResponse := LFullResponse + #13#10#13#10 + '**Error:** ' + LErrorCopy;
                PostToWebView('append_message', 'assistant', #13#10#13#10 + '**Error:** ' + LErrorCopy, True, LActiveProvider, LActiveModel);
                
                LAssistantMsg := TRadIAService.CreateMessage(mrAssistant, LFullResponse, LActiveProvider, LActiveModel);
                FHistory := FHistory + [LAssistantMsg];
                SaveChatHistory;
              end
              else
              begin
                PostToWebView('add_message', 'assistant', '**Error:** ' + LErrorCopy, False, LActiveProvider, LActiveModel);
                PostToWebView('append_message', 'assistant', '', True, LActiveProvider, LActiveModel);
              end;
              Exit;
            end;

            if not LChunkCopy.IsEmpty then
            begin
              LFullResponse := LFullResponse + LChunkCopy;
              if not SameText(LActiveProvider, 'WebViewBridge') then
                PostToWebView('append_message', 'assistant', LChunkCopy, False, LActiveProvider, LActiveModel);
            end;

            if LIsDoneCopy then
            begin
              LDoneHandled := True;
              FRequestInProgress := False;
              UpdateSendButtonVisual;
              btnSend.Enabled := True;
              TLogger.Log(Format('SendPromptToAI completed. TotalResponseLength=%d', [Length(LFullResponse)]), 'UI');

              if LFullResponse.IsEmpty then
              begin
                TLogger.Log('SendPromptToAI: Empty response from AI provider', 'UI');
                PostToWebView('add_message', 'assistant', '**Error:** The AI provider returned an empty response. Please check your settings, API Key, and model selection.', False, LActiveProvider, LActiveModel);
                PostToWebView('append_message', 'assistant', '', True, LActiveProvider, LActiveModel);
                Exit;
              end;

              { Save assistant response to history }
              LAssistantMsg := TRadIAService.CreateMessage(mrAssistant, LFullResponse, LActiveProvider, LActiveModel);
              FHistory := FHistory + [LAssistantMsg];
              SaveChatHistory;

              { Estimate and update token usage stats }
              LUsage.PromptTokens := Length(APromptText) div 4;
              LUsage.CompletionTokens := Length(LFullResponse) div 4;
              LUsage.TotalTokens := LUsage.PromptTokens + LUsage.CompletionTokens;

              if LUsage.TotalTokens > 0 then
              begin
                FAccumulatedUsage.PromptTokens := FAccumulatedUsage.PromptTokens + LUsage.PromptTokens;
                FAccumulatedUsage.CompletionTokens := FAccumulatedUsage.CompletionTokens + LUsage.CompletionTokens;
                FAccumulatedUsage.TotalTokens := FAccumulatedUsage.TotalTokens + LUsage.TotalTokens;

                FConfig.AddToQuotaUsage(LUsage);

                LStats := FAccumulatedUsage.FormatStats;
                if FConfig.QuotaEnabled then
                begin
                  LStats := LStats + Format(' · Quota %d%%', [Round((FConfig.QuotaUsed / FConfig.QuotaLimit) * 100)]);
                end;

                PostToWebView('update_tokens', '', LStats);
              end;

              PostToWebView('append_message', 'assistant', '', True, LActiveProvider, LActiveModel);
            end;
          end));
      end, LProfile);
  except
    on E: Exception do
    begin
      FRequestInProgress := False;
      UpdateSendButtonVisual;
      btnSend.Enabled := True;
      PostToWebView('add_message', 'assistant', '**Error:** ' + E.Message, False, LActiveProvider, LActiveModel);
      PostToWebView('append_message', 'assistant', '', True, LActiveProvider, LActiveModel);
    end;
  end;
end;

procedure TFrameAIChat.GenerateDTO(const AInput, AInputType, AOutputType: string);
var
  LPromptText: string;
  LGuard: ILifecycleGuard;
  LDoneHandled: Boolean;
  LActiveProvider: string;
  LActiveModel: string;
begin
  if FConfig.QuotaEnabled then
  begin
    FConfig.Load;
    if FConfig.QuotaUsed >= FConfig.QuotaLimit then
    begin
      ShowMessage(Format('Não foi possível enviar a requisição: Cota mensal de tokens excedida (limite local de %s tokens atingido).',
        [FormatFloat('#,##0', FConfig.QuotaLimit, TFormatSettings.Invariant)]));
      Exit;
    end;
  end;

  LDoneHandled := False;
  FRequestInProgress := True;
  FCancelledByUser := False;
  UpdateSendButtonVisual;
  btnSend.Enabled := True;

  LActiveProvider := FConfig.GetActiveProvider;
  LActiveModel := FConfig.GetActiveModel(LActiveProvider);

  TLogger.Log(Format('GenerateDTO started. Provider=%s, Model=%s, InputLength=%d, InputType=%s, OutputType=%s',
    [LActiveProvider, LActiveModel, Length(AInput), AInputType, AOutputType]), 'UI');

  LPromptText := TRadIADTOBuilder.BuildPrompt(AInput, AInputType, AOutputType);
  LGuard := FLifecycleGuard as ILifecycleGuard;

  try
    FAIService.SendPromptStream(LPromptText, [],
      procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
      var
        LChunkCopy: string;
        LIsDoneCopy: Boolean;
        LErrorCopy: string;
      begin
        LChunkCopy := AChunk;
        LIsDoneCopy := AIsDone;
        LErrorCopy := AError;
        TThread.Queue(nil,
          TThreadProcedure(
          procedure
          var
            LStats: string;
            LUsage: TTokenUsage;
          begin
            if LDoneHandled then
              Exit;

            if not LGuard.IsAlive then
              Exit;

            if FCancelledByUser then
            begin
              LDoneHandled := True;
              FRequestInProgress := False;
              UpdateSendButtonVisual;
              btnSend.Enabled := True;
              PostToWebView('append_generator_code', '', ' [Cancelado pelo usuário]', True);
              Exit;
            end;

            if not LErrorCopy.IsEmpty then
            begin
              LDoneHandled := True;
              FRequestInProgress := False;
              UpdateSendButtonVisual;
              btnSend.Enabled := True;
              PostToWebView('append_generator_code', '', #13#10 + '// Error: ' + LErrorCopy, True);
              Exit;
            end;

            if not LChunkCopy.IsEmpty then
            begin
              PostToWebView('append_generator_code', '', LChunkCopy, False);
            end;

            if LIsDoneCopy then
            begin
              LDoneHandled := True;
              FRequestInProgress := False;
              UpdateSendButtonVisual;
              btnSend.Enabled := True;

              { Estimate and update token usage stats }
              LUsage.PromptTokens := Length(LPromptText) div 4;
              LUsage.CompletionTokens := 1000;
              LUsage.TotalTokens := LUsage.PromptTokens + LUsage.CompletionTokens;

              if LUsage.TotalTokens > 0 then
              begin
                FConfig.AddToQuotaUsage(LUsage);
                LStats := FAccumulatedUsage.FormatStats;
                if FConfig.QuotaEnabled then
                  LStats := LStats + Format(' · Quota %d%%', [Round((FConfig.QuotaUsed / FConfig.QuotaLimit) * 100)]);
                PostToWebView('update_tokens', '', LStats);
              end;

              PostToWebView('append_generator_code', '', '', True);
            end;
          end));
      end, rpGeneralChat);
  except
    on E: Exception do
    begin
      FRequestInProgress := False;
      UpdateSendButtonVisual;
      btnSend.Enabled := True;
      PostToWebView('append_generator_code', '', '// Error: ' + E.Message, True);
    end;
  end;
end;

procedure TFrameAIChat.OnGlobalPromptRequest(const APrompt: string; const AOpenChat: Boolean);
begin
  PostToWebView('add_message', 'user', APrompt);
  SendPromptToAI(APrompt);
end;

procedure TFrameAIChat.LoadChatHistory;
var
  LMsg: IChatMessage;
begin
  FHistory := [];
  if (FSessionManager = nil) or FSessionManager.ActiveSessionId.IsEmpty then
    Exit;

  try
    FHistory := FSessionManager.LoadSessionHistory(FSessionManager.ActiveSessionId);
    for LMsg in FHistory do
    begin
      PostToWebView('add_message', MessageRoleToString(LMsg.Role), LMsg.Content, False, LMsg.Provider, LMsg.Model);
    end;
    TLogger.Log(Format('LoadChatHistory: Loaded %d messages successfully from session %s',
      [Length(FHistory), FSessionManager.ActiveSessionId]), 'UI');
  except
    on E: Exception do
    begin
      TLogger.Log(Format('LoadChatHistory exception: %s', [E.Message]), 'UI');
      FHistory := [];
    end;
  end;
end;

procedure TFrameAIChat.SaveChatHistory;
begin
  if (FSessionManager = nil) or FSessionManager.ActiveSessionId.IsEmpty then
    Exit;

  try
    FSessionManager.SaveSessionHistory(FSessionManager.ActiveSessionId, FHistory);
    TLogger.Log('SaveChatHistory: History saved successfully for session ' + FSessionManager.ActiveSessionId, 'UI');
  except
    on E: Exception do
      TLogger.Log(Format('SaveChatHistory write exception: %s', [E.Message]), 'UI');
  end;
end;

procedure TFrameAIChat.memPromptKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  LPrompt: string;
begin
  { Send prompt with Ctrl + Enter }
  if (Key = VK_RETURN) and (Shift = [ssCtrl]) then
  begin
    btnSendClick(nil);
    Key := 0;
    Exit;
  end;

  { Navigate history with ↑ and ↓ arrows (no modifier keys) }
  if Shift <> [] then
    Exit;

  if Key = VK_UP then
  begin
    LPrompt := FPromptHistoryManager.NavigateUp;
    memPrompt.Text := LPrompt;
    { Move cursor to end of text }
    memPrompt.SelStart := Length(LPrompt);
    Key := 0; { Consume the key event }
  end
  else if Key = VK_DOWN then
  begin
    LPrompt := FPromptHistoryManager.NavigateDown;
    memPrompt.Text := LPrompt;
    memPrompt.SelStart := Length(LPrompt);
    Key := 0;
  end;
end;

procedure TFrameAIChat.LoadPromptHistory;
var
  LHistoryFile: string;
begin
  LHistoryFile := TPath.Combine(TPath.GetHomePath, 'RadIA\prompt_history.json');
  FPromptHistoryManager.LoadFromFile(LHistoryFile);
end;

procedure TFrameAIChat.SavePromptHistory;
var
  LHistoryFile: string;
begin
  LHistoryFile := TPath.Combine(TPath.GetHomePath, 'RadIA\prompt_history.json');
  FPromptHistoryManager.SaveToFile(LHistoryFile);
end;

procedure TFrameAIChat.UpdateSessionsList;
var
  LSession: TSessionInfo;
  I, LIndexToSelect: Integer;
begin
  lstSessions.OnClick := nil;
  try
    // Clean old objects to avoid memory leaks
    for I := 0 to lstSessions.Items.Count - 1 do
    begin
      if Assigned(lstSessions.Items.Objects[I]) then
        lstSessions.Items.Objects[I].Free;
    end;
    lstSessions.Items.Clear;
    
    if FSessionManager.Sessions.Count = 0 then
    begin
      FSessionManager.CreateSession('Conversa Inicial');
    end;
    
    for LSession in FSessionManager.Sessions do
    begin
      lstSessions.Items.AddObject(LSession.Name, TSessionObject.Create(LSession.Id));
    end;
    
    LIndexToSelect := -1;
    for I := 0 to lstSessions.Items.Count - 1 do
    begin
      if SameText(TSessionObject(lstSessions.Items.Objects[I]).Id, FSessionManager.ActiveSessionId) then
      begin
        LIndexToSelect := I;
        Break;
      end;
    end;
    
    if LIndexToSelect <> -1 then
      lstSessions.ItemIndex := LIndexToSelect
    else if lstSessions.Items.Count > 0 then
    begin
      lstSessions.ItemIndex := 0;
      FSessionManager.ActiveSessionId := TSessionObject(lstSessions.Items.Objects[0]).Id;
      FConfig.ActiveSessionId := FSessionManager.ActiveSessionId;
      FConfig.Save;
    end;
  finally
    lstSessions.OnClick := Self.lstSessionsClick;
  end;
end;

procedure TFrameAIChat.btnToggleSessionsClick(Sender: TObject);
begin
  pnlSessions.Visible := not pnlSessions.Visible;
  splitterSessions.Visible := pnlSessions.Visible;
end;

procedure TFrameAIChat.btnNewSessionClick(Sender: TObject);
var
  LSession: TSessionInfo;
begin
  if FRequestInProgress then
  begin
    FCancelledByUser := True;
    FAIService.CancelCurrentRequest;
    FRequestInProgress := False;
    UpdateSendButtonVisual;
  end;

  if not FSessionManager.ActiveSessionId.IsEmpty then
    SaveChatHistory;

  LSession := FSessionManager.CreateSession('Nova Conversa');
  FSessionManager.ActiveSessionId := LSession.Id;
  FConfig.ActiveSessionId := LSession.Id;
  FConfig.Save;
  
  UpdateSessionsList;
  
  FHistory := [];
  FAccumulatedUsage := TTokenUsage.Empty;
  PostToWebView('clear_chat', '', '');
  PostToWebView('update_tokens', '', '');
end;

procedure TFrameAIChat.btnRenameSessionClick(Sender: TObject);
var
  LIndex: Integer;
  LId: string;
  LName: string;
  LNewName: string;
begin
  LIndex := lstSessions.ItemIndex;
  if LIndex < 0 then
  begin
    ShowMessage('Selecione uma conversa para renomear.');
    Exit;
  end;
  
  LId := TSessionObject(lstSessions.Items.Objects[LIndex]).Id;
  LName := lstSessions.Items[LIndex];
  
  LNewName := LName;
  if InputQuery('Renomear Conversa', 'Digite o novo nome:', LNewName) then
  begin
    LNewName := Trim(LNewName);
    if not LNewName.IsEmpty then
    begin
      FSessionManager.RenameSession(LId, LNewName);
      UpdateSessionsList;
    end;
  end;
end;

procedure TFrameAIChat.btnDeleteSessionClick(Sender: TObject);
var
  LIndex: Integer;
  LId: string;
  LName: string;
begin
  LIndex := lstSessions.ItemIndex;
  if LIndex < 0 then
  begin
    ShowMessage('Selecione uma conversa para excluir.');
    Exit;
  end;
  
  LId := TSessionObject(lstSessions.Items.Objects[LIndex]).Id;
  LName := lstSessions.Items[LIndex];
  
  if MessageDlg(Format('Tem certeza que deseja excluir a conversa "%s"?', [LName]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if FRequestInProgress and SameText(FSessionManager.ActiveSessionId, LId) then
    begin
      FCancelledByUser := True;
      FAIService.CancelCurrentRequest;
      FRequestInProgress := False;
      UpdateSendButtonVisual;
    end;

    FSessionManager.DeleteSession(LId);
    
    if SameText(FSessionManager.ActiveSessionId, LId) then
    begin
      FSessionManager.ActiveSessionId := '';
      FConfig.ActiveSessionId := '';
      FConfig.Save;
    end;
    
    UpdateSessionsList;
    
    FHistory := [];
    FAccumulatedUsage := TTokenUsage.Empty;
    PostToWebView('clear_chat', '', '');
    PostToWebView('update_tokens', '', '');
    
    TThread.ForceQueue(nil,
      TThreadProcedure(
      procedure
      begin
        LoadChatHistory;
      end));
  end;
end;

procedure TFrameAIChat.lstSessionsClick(Sender: TObject);
var
  LIndex: Integer;
  LId: string;
begin
  LIndex := lstSessions.ItemIndex;
  if LIndex < 0 then
    Exit;
    
  LId := TSessionObject(lstSessions.Items.Objects[LIndex]).Id;
  
  if FRequestInProgress then
  begin
    FCancelledByUser := True;
    FAIService.CancelCurrentRequest;
    FRequestInProgress := False;
    UpdateSendButtonVisual;
  end;
  
  if not FSessionManager.ActiveSessionId.IsEmpty and not SameText(FSessionManager.ActiveSessionId, LId) then
    SaveChatHistory;
    
  FSessionManager.ActiveSessionId := LId;
  FSessionManager.UpdateSessionActivity(LId);
  
  FConfig.ActiveSessionId := LId;
  FConfig.Save;
  
  UpdateSessionsList;
  
  FHistory := [];
  FAccumulatedUsage := TTokenUsage.Empty;
  PostToWebView('clear_chat', '', '');
  PostToWebView('update_tokens', '', '');
  
  TThread.ForceQueue(nil,
    TThreadProcedure(
    procedure
    begin
      LoadChatHistory;
    end));
end;

procedure TFrameAIChat.SendInitialConfigToWeb;
var
  LJson: TJSONObject;
  LProviders: TJSONArray;
  LModels: TJSONArray;
  LProvObj: TJSONObject;
  I: Integer;
  LActiveProvider: string;
  LAuthType: string;
  LIsWebLogin: Boolean;
begin
  if not FWebViewReady then Exit;

  LActiveProvider := cbProvider.Text;
  LAuthType := FConfig.GetProviderAuthType(LActiveProvider);
  LIsWebLogin := SameText(LAuthType, 'web_login');

  LJson := TJSONObject.Create;
  LProviders := TJSONArray.Create;
  LModels := TJSONArray.Create;
  try
    for I := 0 to cbProvider.Items.Count - 1 do
    begin
      LProvObj := TJSONObject.Create;
      LProvObj.AddPair('name', cbProvider.Items[I]);
      LProvObj.AddPair('value', cbProvider.Items[I]);
      LProviders.AddElement(LProvObj);
    end;

    for I := 0 to cbModel.Items.Count - 1 do
    begin
      LModels.Add(cbModel.Items[I]);
    end;

    LJson.AddPair('action', 'initialize_config');
    LJson.AddPair('providers', LProviders);
    LJson.AddPair('models', LModels);
    LJson.AddPair('activeProvider', cbProvider.Text);
    LJson.AddPair('activeModel', cbModel.Text);
    LJson.AddPair('isWebLogin', TJSONBool.Create(LIsWebLogin));

    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
end;

procedure TFrameAIChat.SendModelsUpdateToWeb;
var
  LJson: TJSONObject;
  LModels: TJSONArray;
  I: Integer;
begin
  if not FWebViewReady then Exit;

  LJson := TJSONObject.Create;
  LModels := TJSONArray.Create;
  try
    for I := 0 to cbModel.Items.Count - 1 do
    begin
      LModels.Add(cbModel.Items[I]);
    end;

    LJson.AddPair('action', 'update_models');
    LJson.AddPair('models', LModels);
    LJson.AddPair('activeModel', cbModel.Text);

    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
end;

procedure TFrameAIChat.PostRequestStateToWeb(AInProgress: Boolean);
var
  LJson: TJSONObject;
begin
  if not FWebViewReady then Exit;

  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'set_request_state');
    LJson.AddPair('inProgress', TJSONBool.Create(AInProgress));

    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
end;

procedure TFrameAIChat.SendSessionsUpdateToWeb;
var
  LJson: TJSONObject;
  LArr: TJSONArray;
  LSessionObj: TJSONObject;
  LSession: TSessionInfo;
begin
  if not FWebViewReady then Exit;

  LJson := TJSONObject.Create;
  LArr := TJSONArray.Create;
  try
    for LSession in FSessionManager.Sessions do
    begin
      LSessionObj := TJSONObject.Create;
      LSessionObj.AddPair('id', LSession.Id);
      LSessionObj.AddPair('name', LSession.Name);
      LArr.AddElement(LSessionObj);
    end;

    LJson.AddPair('action', 'update_sessions');
    LJson.AddPair('sessions', LArr);
    LJson.AddPair('activeSessionId', FSessionManager.ActiveSessionId);

    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
end;

procedure TFrameAIChat.UpdateWebViewNavigation;
var
  LActiveProvider: string;
  LAuthType: string;
  LTargetUrl: string;
  LIsWebLogin: Boolean;
begin
  if not Assigned(EdgeBrowser) then
    Exit;

  LActiveProvider := FConfig.GetActiveProvider;
  LAuthType := FConfig.GetProviderAuthType(LActiveProvider);
  LIsWebLogin := SameText(LAuthType, 'web_login');

  // O painel nativo VCL de input e seletores permanece oculto,
  // pois a interface Web Premium (chat.html) já possui seus próprios controles integrados.
  pnlInput.Visible := False;
  cbModel.Visible := False;

  if LIsWebLogin then
  begin
    // Garante que o painel de sessões locais (histórico) seja fechado no modo Web Login
    pnlSessions.Visible := False;
    splitterSessions.Visible := False;

    // Esconde o botão de login VCL se existir (o botão 🔐 agora fica dentro do chat.html)
    if Assigned(FbtnWebLoginConnect) then
      FbtnWebLoginConnect.Visible := False;

    // Mantém o combobox de provedores invisível
    cbProvider.Visible := False;

    // Esconde a barra de ferramentas nativa VCL (o chat.html cuidará de seus próprios controles Premium)
    pnlToolbar.Visible := False;
    btnToggleSessions.Visible := False;
    btnNewSession.Visible := False;
    btnClear.Visible := False;
    btnExport.Visible := False;
    btnTemplates.Visible := False;

    if SameText(LActiveProvider, 'Gemini') then
      LTargetUrl := 'https://gemini.google.com'
    else
      LTargetUrl := 'https://chatgpt.com';

    // Garante a criação da WebView de background e inicia navegação
    CreateEdgeBrowserWeb;
    TLogger.Log('UpdateWebViewNavigation: Navigating background web to: ' + LTargetUrl, 'UI');
    FEdgeBrowserWeb.Navigate(LTargetUrl);

    // Navega a WebView principal visível sempre para o chat nativo Premium local
    LTargetUrl := 'file:///' + TPath.Combine(FWebFilesDir, 'chat.html').Replace('\', '/');
    TLogger.Log('UpdateWebViewNavigation: Navigating visible web to local chat: ' + LTargetUrl, 'UI');
    EdgeBrowser.Navigate(LTargetUrl);
  end
  else
  begin
    // Esconde o botão de login se existir
    if Assigned(FbtnWebLoginConnect) then
      FbtnWebLoginConnect.Visible := False;

    // Restaura o combo de provedores para a sua posição e parent original no painel de input nativo
    cbProvider.Parent := pnlInput;
    cbProvider.Align := alNone;
    cbProvider.Anchors := [akLeft, akTop];
    cbProvider.Left := 10;
    cbProvider.Top := 18;
    cbProvider.Width := 120;
    cbProvider.Visible := False;

    // Esconde a barra de ferramentas nativa VCL (o chat.html cuidará da exibição de seus controles Premium)
    pnlToolbar.Visible := False;
    btnToggleSessions.Visible := True;
    btnNewSession.Visible := True;
    btnClear.Visible := True;
    btnExport.Visible := True;
    btnTemplates.Visible := True;

    LTargetUrl := 'file:///' + TPath.Combine(FWebFilesDir, 'chat.html').Replace('\', '/');
    TLogger.Log('UpdateWebViewNavigation: Navigating to local chat: ' + LTargetUrl, 'UI');
    EdgeBrowser.Navigate(LTargetUrl);
  end;
end;

procedure TFrameAIChat.OnWebViewBridgeSendPrompt(const APrompt: string);
var
  LJson: TJSONObject;
begin
  CreateEdgeBrowserWeb; // Garante que a WebView de background está criada
  
  if not FBrowserWebInitialized then
  begin
    TLogger.Log('OnWebViewBridgeSendPrompt: Background browser is not initialized yet.', 'UI');
    Exit;
  end;

  TLogger.Log('OnWebViewBridgeSendPrompt: Dispatching prompt to background web view.', 'UI');
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'send_prompt');
    LJson.AddPair('text', APrompt);
    if Assigned(FEdgeBrowserWeb.DefaultInterface) then
      FEdgeBrowserWeb.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
end;

procedure TFrameAIChat.OnWebViewBridgeCancel;
var
  LJson: TJSONObject;
begin
  if not FBrowserWebInitialized then
    Exit;

  TLogger.Log('OnWebViewBridgeCancel: Dispatching cancellation to background web view.', 'UI');
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'cancel_request');
    if Assigned(FEdgeBrowserWeb.DefaultInterface) then
      FEdgeBrowserWeb.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
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
    {$IF CompilerVersion >= 35.0}
    FEdgeBrowserWeb.OnWebMessageReceived := EdgeBrowserWebWebMessageReceived;
    {$ELSE}
    FEdgeBrowserWeb.OnWebMessageReceived := EdgeBrowserWebWebMessageReceivedLegacy;
    {$ENDIF}
    
    FEdgeBrowserWeb.UserDataFolder := TPath.Combine(TPath.GetHomePath, 'RadIA\WebView2Web');
  end;
end;

procedure TFrameAIChat.OnbtnWebLoginConnectClick(Sender: TObject);
var
  LActiveProvider: string;
  LUrl: string;
begin
  LActiveProvider := FConfig.GetActiveProvider;
  if SameText(LActiveProvider, 'Gemini') then
    LUrl := 'https://gemini.google.com'
  else
    LUrl := 'https://chatgpt.com';

  TLogger.Log('OnbtnWebLoginConnectClick: Opening popup form for ' + LActiveProvider, 'UI');
  
  TFormWebLogin.ShowLogin(Self, LUrl,
    procedure
    begin
      TLogger.Log('OnbtnWebLoginConnectClick: Login completed successfully. Refreshing background browser.', 'UI');
      // Recarrega a WebView oculta para garantir que ela pegue os novos cookies de sessão
      if Assigned(FEdgeBrowserWeb) then
        FEdgeBrowserWeb.Navigate(LUrl);
    end);
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
  end;
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
procedure TFrameAIChat.EdgeBrowserWebWebMessageReceivedLegacy(Sender: TCustomEdgeBrowser; const AMessage: string);
begin
  ProcessWebMessage(AMessage);
end;
{$ENDIF}

end.
