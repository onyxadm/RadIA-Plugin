unit RadIA.UI.ChatFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Edge, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config,
  RadIA.Core.Service, RadIA.Core.PromptHistory, RadIA.Core.TokenUsage, Vcl.Menus,
  RadIA.Core.PromptTemplates;

type
  TFrameAIChat = class(TFrame)
    pnlToolbar: TPanel;
    cbProvider: TComboBox;
    cbModel: TComboBox;
    btnSettings: TButton;
    btnClear: TButton;
    btnExport: TButton;
    btnTemplates: TButton;
    SaveDialog: TSaveDialog;
    pnlInput: TPanel;
    memPrompt: TMemo;
    btnSend: TButton;
    lblContext: TLabel;
    pnlBrowser: TPanel;
    EdgeBrowser: TEdgeBrowser;
    procedure btnSendClick(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure cbModelChange(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnTemplatesClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    procedure EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser; const AMessage: string);
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
    
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure InitializeWebView;
    procedure CopyWebFiles;
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
begin
  if Assigned(FLifecycleGuard) then
    (FLifecycleGuard as ILifecycleGuard).Invalidate;
  TRadIAMediator.Instance.UnregisterPromptHandler;
  FPromptHistoryManager.Free;
  FTemplateManager.Free;
  FAIService.Free;
  inherited Destroy;
end;

procedure TFrameAIChat.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  if Showing and not FWebViewInitialized then
  begin
    FWebViewInitialized := True;
    InitializeWebView;
  end;
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

procedure TFrameAIChat.LoadConfig;
var
  LProv: TAIProviderType;
begin
  cbProvider.Items.Clear;
  for LProv := Low(TAIProviderType) to High(TAIProviderType) do
  begin
    cbProvider.Items.Add(ProviderTypeToString(LProv));
  end;
  
  cbProvider.ItemIndex := Integer(FConfig.GetActiveProvider);
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
begin
  FConfig.SetActiveProvider(TAIProviderType(cbProvider.ItemIndex));
  FConfig.Save;
  UpdateModelsCombo;
end;

procedure TFrameAIChat.cbModelChange(Sender: TObject);
begin
  FConfig.SetActiveModel(TAIProviderType(cbProvider.ItemIndex), cbModel.Text);
  FConfig.Save;
end;

procedure TFrameAIChat.btnClearClick(Sender: TObject);
var
  LHistoryFile: string;
begin
  FHistory := [];
  FAccumulatedUsage := TTokenUsage.Empty;
  PostToWebView('clear_chat', '', '');
  PostToWebView('update_tokens', '', '');
  
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
    
    LForm.ShowModal;
    
    { Refresh config settings }
    FConfig.Load;
    LoadConfig;
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
  LIsDark: Boolean;
  LBgColor, LTextColor, LInputBgColor: TColor;
begin
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

  // Botão Send
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
begin
  if Succeeded(AResult) then
  begin
    FBrowserInitialized := True;
    ApplyIDETheme;
    LoadChatHistory;
  end;
end;

procedure TFrameAIChat.EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser; const AMessage: string);
var
  LJson: TJSONObject;
  LAction: string;
  LCode: string;
begin
  LJson := TJSONObject.ParseJSONValue(AMessage) as TJSONObject;
  if Assigned(LJson) then
  begin
    try
      LAction := LJson.GetValue<string>('action', '');
      if LAction = 'apply_code' then
      begin
        LCode := LJson.GetValue<string>('code', '');
        TThread.Queue(nil,
          procedure
          begin
            TRadIAOTAHelper.ReplaceActiveEditorText(LCode);
          end);
      end;
    finally
      LJson.Free;
    end;
  end;
end;

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
begin
  btnSend.Enabled := False;
  
  LUserMsg := TRadIAService.CreateMessage(mrUser, APromptText);
  LFullResponse := '';
  LGuard := FLifecycleGuard as ILifecycleGuard;
  
  PostToWebView('show_typing', '', '');
  
  FAIService.SendPromptStream(APromptText, FHistory,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
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
