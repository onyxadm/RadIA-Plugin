unit RadIA.UI.ChatFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Edge, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config,
  RadIA.Core.Service, RadIA.Core.PromptHistory, RadIA.Core.TokenUsage, Vcl.Menus,
  RadIA.Core.PromptTemplates, Vcl.Buttons, Winapi.WebView2, Winapi.ActiveX;

type
  TFrameAIChat = class(TFrame)
    pnlToolbar: TPanel;
    cbProvider: TComboBox;
    cbModel: TComboBox;
    btnSettings: TSpeedButton;
    btnClear: TSpeedButton;
    btnExport: TSpeedButton;
    btnTemplates: TSpeedButton;
    SaveDialog: TSaveDialog;
    pnlInput: TPanel;
    memPrompt: TMemo;
    btnSend: TSpeedButton;
    lblContext: TLabel;
    pnlBrowser: TPanel;
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
  private
    FConfig: IAIConfig;
    FAIService: TRadIAService;
    FHistory: TArray<IChatMessage>;
    FWebFilesDir: string;
    FBrowserInitialized: Boolean;
    FWebViewInitialized: Boolean;
    FPromptHistoryManager: TPromptHistoryManager;
    FAccumulatedUsage: TTokenUsage;
    FTemplateManager: TPromptTemplateManager;
    FPopupMenuTemplates: TPopupMenu;
    FLifecycleGuard: IInterface;
    EdgeBrowser: TEdgeBrowser;
    
    procedure CreateEdgeBrowser;
    
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure InitializeWebView;
    procedure CopyWebFiles;
    function IsProviderConfigured(const AProvider: TAIProviderType): Boolean;
    procedure LoadConfig;
    procedure UpdateModelsCombo;
    procedure SendPromptToAI(const APromptText: string);
    procedure PostToWebView(const AAction, ARole, AText: string); overload;
    procedure PostToWebView(const AAction, ARole, AText: string; AIsDone: Boolean); overload;
    procedure OnGlobalPromptRequest(const APrompt: string; const AOpenChat: Boolean);
    procedure LoadChatHistory;
    procedure SaveChatHistory;
    procedure LoadPromptHistory;
    procedure SavePromptHistory;
    procedure LoadTemplatesMenu;
    procedure OnTemplateMenuClick(Sender: TObject);
    procedure ApplyIDETheme;
    procedure UpdateVCLColors(const AThemeName: string);
    procedure ProcessWebMessage(const AMessage: string);
  protected
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure SetTheme(const AThemeName: string);
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.JSON, ToolsAPI, RadIA.OTA.Helper, RadIA.UI.ConfigFrame,
  RadIA.Core.Mediator, RadIA.Core.ConversationExporter;



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
  FConfig := TRadIAConfig.Create;
  FAIService := TRadIAService.Create(FConfig);
  FPromptHistoryManager := TPromptHistoryManager.Create;
  FAccumulatedUsage := TTokenUsage.Empty;
  FTemplateManager := TPromptTemplateManager.Create;
  FTemplateManager.Load;
  FPopupMenuTemplates := TPopupMenu.Create(Self);
  LoadTemplatesMenu;
  
  FWebFilesDir := TPath.Combine(TPath.GetHomePath, 'RadIA\Web');
  CopyWebFiles;
  
  LoadConfig;
  LoadPromptHistory;

  { Detect current IDE theme and apply colors to VCL controls }
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
      UpdateVCLColors(LThemingServices.ActiveTheme)
    else
      UpdateVCLColors('light');
  end
  else
    UpdateVCLColors('light');

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
  
  FPromptHistoryManager.Free;
  FreeAndNil(FTemplateManager);
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
      procedure
      begin
        InitializeWebView;
      end);
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
      procedure
      begin
        InitializeWebView;
      end);
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
    LEdgeToFree.Parent := nil; // Desvincula visualmente de forma síncrona
    TThread.Queue(nil,
      procedure
      begin
        LEdgeToFree.Free; // Libera da memória de forma assíncrona (thread-safe/layout-safe)
      end);
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
    'diff2html.min.css', 'diff2html.min.js', 'diff.min.js');
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
  EdgeBrowser.Navigate('file:///' + TPath.Combine(FWebFilesDir, 'chat.html').Replace('\', '/'));
end;

function TFrameAIChat.IsProviderConfigured(const AProvider: TAIProviderType): Boolean;
begin
  if AProvider = ptOllama then
    Result := not FConfig.GetOllamaBaseUrl.Trim.IsEmpty
  else
    Result := not FConfig.GetApiKey(AProvider).Trim.IsEmpty;
end;

procedure TFrameAIChat.LoadConfig;
var
  LProv: TAIProviderType;
  LActiveProvider: TAIProviderType;
  LFoundIndex: Integer;
  I: Integer;
begin
  cbProvider.Items.Clear;
  for LProv := Low(TAIProviderType) to High(TAIProviderType) do
  begin
    if IsProviderConfigured(LProv) then
    begin
      cbProvider.Items.AddObject(ProviderTypeToString(LProv), TObject(LProv));
    end;
  end;

  if cbProvider.Items.Count = 0 then
  begin
    for LProv := Low(TAIProviderType) to High(TAIProviderType) do
    begin
      cbProvider.Items.AddObject(ProviderTypeToString(LProv), TObject(LProv));
    end;
  end;

  LActiveProvider := FConfig.GetActiveProvider;
  LFoundIndex := -1;
  for I := 0 to cbProvider.Items.Count - 1 do
  begin
    if TAIProviderType(cbProvider.Items.Objects[I]) = LActiveProvider then
    begin
      LFoundIndex := I;
      Break;
    end;
  end;

  if LFoundIndex <> -1 then
  begin
    cbProvider.ItemIndex := LFoundIndex;
  end
  else if cbProvider.Items.Count > 0 then
  begin
    cbProvider.ItemIndex := 0;
    FConfig.SetActiveProvider(TAIProviderType(cbProvider.Items.Objects[0]));
    FConfig.Save;
  end;

  UpdateModelsCombo;
end;

procedure TFrameAIChat.UpdateModelsCombo;
var
  LActiveModel: string;
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
      var
        LModel: string;
      begin
        if not LGuard.IsAlive then
          Exit;
          
        cbModel.Items.Clear;
        for LModel in AModels do
        begin
          cbModel.Items.Add(LModel);
        end;
        
        LActiveModel := FConfig.GetActiveModel(LProvider.GetProviderType);
        cbModel.ItemIndex := cbModel.Items.IndexOf(LActiveModel);
        if cbModel.ItemIndex = -1 then
          cbModel.ItemIndex := 0;
          
        cbModel.Enabled := True;
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
  LSelectedProvider: TAIProviderType;
begin
  if cbProvider.ItemIndex <> -1 then
  begin
    LSelectedProvider := TAIProviderType(cbProvider.Items.Objects[cbProvider.ItemIndex]);
    FConfig.SetActiveProvider(LSelectedProvider);
    FConfig.Save;
    UpdateModelsCombo;
  end;
end;

procedure TFrameAIChat.cbModelChange(Sender: TObject);
var
  LSelectedProvider: TAIProviderType;
begin
  if cbProvider.ItemIndex <> -1 then
  begin
    LSelectedProvider := TAIProviderType(cbProvider.Items.Objects[cbProvider.ItemIndex]);
    FConfig.SetActiveModel(LSelectedProvider, cbModel.Text);
    FConfig.Save;
  end;
end;

procedure TFrameAIChat.btnClearClick(Sender: TObject);
var
  LHistoryFile: string;
begin
  FHistory := [];
  FAccumulatedUsage := TTokenUsage.Empty;
  PostToWebView('clear_chat', '', '');
  PostToWebView('update_tokens', '', '');
  
  if Assigned(FAIService) then
    FAIService.ClearCache;
  
  { Clear physical file }
  LHistoryFile := TPath.Combine(TPath.GetHomePath, 'RadIA\history.json');
  if TFile.Exists(LHistoryFile) then
  begin
    try
      TFile.Delete(LHistoryFile);
    except
      // Ignore delete errors
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

procedure TFrameAIChat.PostToWebView(const AAction, ARole, AText: string);
begin
  PostToWebView(AAction, ARole, AText, False);
end;

procedure TFrameAIChat.PostToWebView(const AAction, ARole, AText: string; AIsDone: Boolean);
var
  LJson: TJSONObject;
begin
  if not FBrowserInitialized then
    Exit;
    
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', AAction);
    if not ARole.IsEmpty then
      LJson.AddPair('role', ARole);
    if not AText.IsEmpty then
      LJson.AddPair('text', AText);
    LJson.AddPair('isDone', TJSONBool.Create(AIsDone));
      
    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
end;

procedure TFrameAIChat.SetTheme(const AThemeName: string);
var
  LJson: TJSONObject;
begin
  UpdateVCLColors(AThemeName);

  if not FBrowserInitialized then
    Exit;
    
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'set_theme');
    LJson.AddPair('theme', AThemeName.ToLower);
    
    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
end;

procedure TFrameAIChat.UpdateVCLColors(const AThemeName: string);
var
  LThemingServices: IOTAIDEThemingServices;
  LIsDark: Boolean;
  LBgColor, LTextColor, LInputBgColor: TColor;
begin
  { Se a estilização da IDE estiver ativa, deixamos que o VCL Styles gerencie a pintura }
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
      Exit;
  end;

  LIsDark := SameText(AThemeName, 'dark');
  
  if LIsDark then
  begin
    LBgColor := $00252526;      // Cinza escuro da IDE do Delphi
    LTextColor := $00D4D4D4;    // Texto cinza claro
    LInputBgColor := $001E1E1E; // Fundo dos edits/memos
  end
  else
  begin
    LBgColor := clBtnFace;
    LTextColor := clWindowText;
    LInputBgColor := clWindow;
  end;

  Self.Color := LBgColor;
  pnlToolbar.Color := LBgColor;
  pnlToolbar.ParentBackground := False;
  pnlInput.Color := LBgColor;
  pnlInput.ParentBackground := False;
  pnlBrowser.Color := LBgColor;
  pnlBrowser.ParentBackground := False;

  // Labels
  lblContext.Font.Color := if LIsDark then $009CA3AF else clGrayText;

  // ComboBoxes
  cbProvider.Color := LInputBgColor;
  cbProvider.Font.Color := LTextColor;
  cbModel.Color := LInputBgColor;
  cbModel.Font.Color := LTextColor;

  // Input Memo
  memPrompt.Color := LInputBgColor;
  memPrompt.Font.Color := LTextColor;

  // SpeedButtons (Toolbar e Send)
  btnTemplates.Font.Color := LTextColor;
  btnExport.Font.Color := LTextColor;
  btnClear.Font.Color := LTextColor;
  btnSettings.Font.Color := LTextColor;
  btnSend.Font.Color := LTextColor;
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
      if SameText(LActiveTheme, 'Dark') then
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
    
    ApplyIDETheme;
  end;
end;

procedure TFrameAIChat.ProcessWebMessage(const AMessage: string);
var
  LParsed: TJSONValue;
  LJson: TJSONObject;
  LAction: string;
  LCode: string;
begin
  LParsed := TJSONObject.ParseJSONValue(AMessage);
  if not Assigned(LParsed) then
    Exit;
  try
    if not (LParsed is TJSONObject) then
      Exit;

    LJson := LParsed as TJSONObject;
    LAction := LJson.GetValue<string>('action', '');
    if LAction = 'apply_code' then
    begin
      LCode := LJson.GetValue<string>('code', '');
      { Normalize line endings to CRLF (#13#10) for Windows OTA editor compatibility. }
      LCode := StringReplace(LCode, #13#10, #10, [rfReplaceAll]);
      LCode := StringReplace(LCode, #13,    #10, [rfReplaceAll]);
      LCode := StringReplace(LCode, #10,    #13#10, [rfReplaceAll]);
      TThread.Queue(nil,
        procedure
        begin
          TRadIAOTAHelper.ReplaceActiveEditorText(LCode);
        end);
    end
    else if LAction = 'ready' then
    begin
      TThread.Queue(nil,
        procedure
        begin
          LoadChatHistory;
        end);
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
  LActiveCode: string;
  LTemplateName: string;
  LResolved: string;
begin
  LText := Trim(memPrompt.Text);
  if LText.IsEmpty then
    Exit;

  { Check for Slash Command /template }
  if LText.StartsWith('/template', True) then
  begin
    LTemplateName := Trim(LText.Substring(10));
    if LTemplateName.IsEmpty then
    begin
      ShowMessage('Please specify the template name. Example: /template Review Clean Code Delphi');
      Exit;
    end;
    
    if not TRadIAOTAHelper.GetActiveEditorText(LActiveCode, True) or LActiveCode.IsEmpty then
      TRadIAOTAHelper.GetActiveEditorText(LActiveCode, False);

    LResolved := FTemplateManager.ResolveTemplate(LTemplateName, LActiveCode);
    if LResolved.IsEmpty then
    begin
      ShowMessage(Format('Template "%s" not found.', [LTemplateName]));
      Exit;
    end;
    
    LText := LResolved;
  end;

  { Save to prompt history before clearing the input }
  FPromptHistoryManager.Add(memPrompt.Text);
  SavePromptHistory;

  memPrompt.Text := '';
  PostToWebView('add_message', 'user', LText);
  SendPromptToAI(LText);
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
begin
  btnSend.Enabled := False;

  { Infer request profile from slash commands }
  LProfile := rpGeneralChat;
  if APromptText.StartsWith('/refactor', True) or APromptText.StartsWith('/optimize', True) then
    LProfile := rpRefactorCode
  else if APromptText.StartsWith('/bugs', True) then
    LProfile := rpFindBugs
  else if APromptText.StartsWith('/test', True) then
    LProfile := rpGenerateTests
  else if APromptText.StartsWith('/explain', True) or APromptText.StartsWith('/doc', True) or APromptText.StartsWith('/fix', True) then
    LProfile := rpExplainCode;
  
  LUserMsg := TRadIAService.CreateMessage(mrUser, APromptText);
  LFullResponse := '';
  LGuard := FLifecycleGuard as ILifecycleGuard;
  
  PostToWebView('show_typing', '', '');
  
  FAIService.SendPromptStream(APromptText, FHistory,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      TThread.Queue(nil,
        procedure
        var
          LAssistantMsg: IChatMessage;
          LStats: string;
          LUsage: TTokenUsage;
        begin
          if not LGuard.IsAlive then
            Exit;
            
          if not AError.IsEmpty then
          begin
            btnSend.Enabled := True;
            PostToWebView('add_message', 'assistant', '**Error:** ' + AError);
            Exit;
          end;
          
          if not AIsDone then
          begin
            LFullResponse := LFullResponse + AChunk;
            PostToWebView('append_message', 'assistant', AChunk, False);
          end
          else
          begin
            btnSend.Enabled := True;
            if not AChunk.IsEmpty then
            begin
              LFullResponse := LFullResponse + AChunk;
              PostToWebView('append_message', 'assistant', AChunk, False);
            end;
            
            if LFullResponse.IsEmpty and AError.IsEmpty then
            begin
              PostToWebView('add_message', 'assistant', '**Error:** The AI provider returned an empty response. Please check your settings, API Key, and model selection.');
              PostToWebView('append_message', 'assistant', '', True);
              Exit;
            end;
            
            PostToWebView('append_message', 'assistant', '', True);
            
            { Save history }
            FHistory := FHistory + [LUserMsg];
            LAssistantMsg := TRadIAService.CreateMessage(mrAssistant, LFullResponse);
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
              
              LStats := FAccumulatedUsage.FormatStats;
              PostToWebView('update_tokens', '', LStats);
            end;
          end;
        end);
    end, LProfile);
end;

procedure TFrameAIChat.OnGlobalPromptRequest(const APrompt: string; const AOpenChat: Boolean);
begin
  PostToWebView('add_message', 'user', APrompt);
  SendPromptToAI(APrompt);
end;

procedure TFrameAIChat.LoadChatHistory;
var
  LHistoryFile: string;
  LContent: string;
  LJsonArr: TJSONArray;
  LVal: TJSONValue;
  LMsgObj: TJSONObject;
  LMsg: IChatMessage;
  LRoleStr, LContentStr: string;
  LRole: TAIMessageRole;
  LParsedVal: TJSONValue;
begin
  FHistory := [];
  LHistoryFile := TPath.Combine(TPath.GetHomePath, 'RadIA\history.json');
  if not TFile.Exists(LHistoryFile) then
    Exit;

  try
    LContent := TFile.ReadAllText(LHistoryFile, TEncoding.UTF8);
    if LContent.IsEmpty then
      Exit;

    LParsedVal := TJSONObject.ParseJSONValue(LContent);
    if Assigned(LParsedVal) then
    begin
      if LParsedVal is TJSONArray then
      begin
        LJsonArr := LParsedVal as TJSONArray;
        try
          for LVal in LJsonArr do
          begin
            if LVal is TJSONObject then
            begin
              LMsgObj := LVal as TJSONObject;
              LRoleStr := LMsgObj.GetValue<string>('role', '');
              LContentStr := LMsgObj.GetValue<string>('content', '');
              
              if not LContentStr.IsEmpty then
              begin
                LRole := StringToMessageRole(LRoleStr);
                LMsg := TRadIAService.CreateMessage(LRole, LContentStr);
                
                FHistory := FHistory + [LMsg];
                
                { Render message in WebView }
                PostToWebView('add_message', LRoleStr, LContentStr);
              end;
            end;
          end;
        finally
          LJsonArr.Free;
        end;
      end
      else
      begin
        LParsedVal.Free;
      end;
    end;
  except
    FHistory := [];
  end;
end;

procedure TFrameAIChat.SaveChatHistory;
var
  LHistoryFile: string;
  LJsonArr: TJSONArray;
  LMsgObj: TJSONObject;
  LMsg: IChatMessage;
begin
  LHistoryFile := TPath.Combine(TPath.GetHomePath, 'RadIA\history.json');
  ForceDirectories(TPath.GetDirectoryName(LHistoryFile));

  LJsonArr := TJSONArray.Create;
  try
    for LMsg in FHistory do
    begin
      if LMsg.Role = mrSystem then
        Continue;

      LMsgObj := TJSONObject.Create;
      LMsgObj.AddPair('role', MessageRoleToString(LMsg.Role));
      LMsgObj.AddPair('content', LMsg.Content);
      LJsonArr.AddElement(LMsgObj);
    end;
    
    TFile.WriteAllText(LHistoryFile, LJsonArr.ToJSON, TEncoding.UTF8);
  finally
    LJsonArr.Free;
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

end.
