unit RadIA.UI.ChatFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Edge, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config,
  RadIA.Core.Service, RadIA.Core.PromptHistory, RadIA.Core.TokenUsage;

type
  TFrameAIChat = class(TFrame)
    pnlToolbar: TPanel;
    cbProvider: TComboBox;
    cbModel: TComboBox;
    btnSettings: TButton;
    btnClear: TButton;
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
    FPromptHistoryManager: TPromptHistoryManager;
    FAccumulatedUsage: TTokenUsage;
    FAccumulatedCost: TTokenCost;
    
    procedure InitializeWebView;
    procedure CopyWebFiles;
    procedure LoadConfig;
    procedure UpdateModelsCombo;
    procedure SendPromptToAI(const APromptText: string);
    procedure PostToWebView(const AAction, ARole, AText: string);
    procedure OnGlobalPromptRequest(const APrompt: string; const AOpenChat: Boolean);
    procedure LoadChatHistory;
    procedure SaveChatHistory;
    procedure LoadPromptHistory;
    procedure SavePromptHistory;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure SetTheme(const AThemeName: string);
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.JSON, RadIA.OTA.Helper, RadIA.UI.ConfigFrame, RadIA.Core.Pricing;

constructor TFrameAIChat.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBrowserInitialized := False;
  FHistory := [];
  
  FConfig := TRadIAConfig.Create;
  FAIService := TRadIAService.Create(FConfig);
  FPromptHistoryManager := TPromptHistoryManager.Create;
  FAccumulatedUsage := TTokenUsage.Empty;
  FAccumulatedCost := TTokenCost.Zero;
  
  FWebFilesDir := TPath.Combine(TPath.GetHomePath, 'RadIA\Web');
  CopyWebFiles;
  
  LoadConfig;
  InitializeWebView;
  LoadPromptHistory;

  memPrompt.OnKeyDown := Self.memPromptKeyDown;
  GlobalOnRequestPrompt := Self.OnGlobalPromptRequest;
end;

destructor TFrameAIChat.Destroy;
begin
  GlobalOnRequestPrompt := nil;
  FPromptHistoryManager.Free;
  FAIService.Free;
  inherited Destroy;
end;

procedure TFrameAIChat.CopyWebFiles;
var
  LSourceDir: string;
  LFile: string;
  LFilesToCopy: TArray<string>;
begin
  ForceDirectories(FWebFilesDir);
  
  { Copy files from development Source directory if present (or fallback to local folder) }
  LSourceDir := 'D:\Projetos\PluginDelphiIA\Source\UI\Web';
  if not TDirectory.Exists(LSourceDir) then
    Exit;
    
  LFilesToCopy := TArray<string>.Create('chat.html', 'chat.css', 'chat.js', 'diff.html');
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
begin
  cbModel.Items.Clear;
  cbModel.Items.Add('Loading...');
  cbModel.ItemIndex := 0;
  cbModel.Enabled := False;

  try
    LProvider := FAIService.CreateActiveProvider;
    LProvider.FetchAvailableModelsAsync(
      procedure(AModels: TArray<string>; AError: string)
      var
        LModel: string;
      begin
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
  FAccumulatedCost := TTokenCost.Zero;
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

procedure TFrameAIChat.btnSettingsClick(Sender: TObject);
var
  LForm: TForm;
  LConfigFrame: TFrameAIConfig;
begin
  LForm := TForm.Create(nil);
  try
    LForm.Caption := 'RadIA Configuration';
    LForm.Position := poOwnerFormCenter;
    LForm.Width := 340;
    LForm.Height := 585;
    LForm.BorderStyle := bsDialog;
    
    LConfigFrame := TFrameAIConfig.Create(LForm);
    LConfigFrame.Parent := LForm;
    LConfigFrame.Align := alClient;
    LConfigFrame.LoadConfig;
    
    LForm.ShowModal;
    
    { Refresh config settings }
    FConfig.Load;
    LoadConfig;
  finally
    LForm.Free;
  end;
end;

procedure TFrameAIChat.PostToWebView(const AAction, ARole, AText: string);
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
      
    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
end;

procedure TFrameAIChat.SetTheme(const AThemeName: string);
begin
  PostToWebView('set_theme', '', AThemeName.ToLower);
end;

procedure TFrameAIChat.EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
begin
  if Succeeded(AResult) then
  begin
    FBrowserInitialized := True;
    // Set default dark theme to match IDE
    SetTheme('dark');
    LoadChatHistory;
  end;
end;

procedure TFrameAIChat.EdgeBrowserWebMessageReceived(Sender: TCustomEdgeBrowser; const AMessage: string);
var
  LJson: TJSONObject;
  LAction: string;
  LCode: string;
  LQueueProc: TThreadProcedure;
begin
  LJson := TJSONObject.ParseJSONValue(AMessage) as TJSONObject;
  if Assigned(LJson) then
  begin
    try
      LAction := LJson.GetValue('action').Value;
      if LAction = 'apply_code' then
      begin
        LCode := LJson.GetValue('code').Value;
        LQueueProc := procedure
                      begin
                        TRadIAOTAHelper.ReplaceActiveEditorText(LCode);
                      end;
        TThread.Queue(nil, LQueueProc);
      end;
    finally
      LJson.Free;
    end;
  end;
end;

procedure TFrameAIChat.btnSendClick(Sender: TObject);
var
  LText: string;
begin
  LText := Trim(memPrompt.Text);
  if LText.IsEmpty then
    Exit;

  { Save to prompt history before clearing the input }
  FPromptHistoryManager.Add(LText);
  SavePromptHistory;

  memPrompt.Text := '';
  PostToWebView('add_message', 'user', LText);
  SendPromptToAI(LText);
end;

procedure TFrameAIChat.SendPromptToAI(const APromptText: string);
var
  LUserMsg: IChatMessage;
begin
  btnSend.Enabled := False;
  
  LUserMsg := TRadIAService.CreateMessage(mrUser, APromptText);
  
  FAIService.SendPrompt(APromptText, FHistory,
    procedure(const AResponse: string; const AError: string; AFromCache: Boolean; const AUsage: TTokenUsage)
    var
      LAssistantMsg: IChatMessage;
      LDisplayResponse: string;
      LCost: TTokenCost;
      LStats: string;
    begin
      btnSend.Enabled := True;
      if not AError.IsEmpty then
      begin
        PostToWebView('add_message', 'assistant', '**Error:** ' + AError);
        Exit;
      end;
      
      LDisplayResponse := AResponse;
      if AFromCache then
        LDisplayResponse := LDisplayResponse + sLineBreak + sLineBreak + '*[resposta obtida de cache local]*';

      PostToWebView('add_message', 'assistant', LDisplayResponse);
      
      { Accumulate and update token usage stats }
      if not AUsage.IsEmpty then
      begin
        FAccumulatedUsage.PromptTokens := FAccumulatedUsage.PromptTokens + AUsage.PromptTokens;
        FAccumulatedUsage.CompletionTokens := FAccumulatedUsage.CompletionTokens + AUsage.CompletionTokens;
        FAccumulatedUsage.TotalTokens := FAccumulatedUsage.TotalTokens + AUsage.TotalTokens;
        
        LCost := TPricingManager.Calculate(AUsage, FConfig.GetActiveProvider, FConfig.GetActiveModel(FConfig.GetActiveProvider));
        FAccumulatedCost.EstimatedCostUSD := FAccumulatedCost.EstimatedCostUSD + LCost.EstimatedCostUSD;
        
        LStats := TPricingManager.FormatTokenStats(FAccumulatedUsage, FAccumulatedCost);
        PostToWebView('update_tokens', '', LStats);
      end;
      
      { Save history }
      FHistory := FHistory + [LUserMsg];
      LAssistantMsg := TRadIAService.CreateMessage(mrAssistant, AResponse);
      FHistory := FHistory + [LAssistantMsg];
      SaveChatHistory;
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
begin
  FHistory := [];
  LHistoryFile := TPath.Combine(TPath.GetHomePath, 'RadIA\history.json');
  if not TFile.Exists(LHistoryFile) then
    Exit;

  try
    LContent := TFile.ReadAllText(LHistoryFile, TEncoding.UTF8);
    if LContent.IsEmpty then
      Exit;

    LJsonArr := TJSONObject.ParseJSONValue(LContent) as TJSONArray;
    if Assigned(LJsonArr) then
    begin
      try
        for LVal in LJsonArr do
        begin
          if LVal is TJSONObject then
          begin
            LMsgObj := LVal as TJSONObject;
            LRoleStr := LMsgObj.GetValue('role').Value;
            LContentStr := LMsgObj.GetValue('content').Value;
            
            LRole := StringToMessageRole(LRoleStr);
            LMsg := TRadIAService.CreateMessage(LRole, LContentStr);
            
            FHistory := FHistory + [LMsg];
            
            { Render message in WebView }
            PostToWebView('add_message', LRoleStr, LContentStr);
          end;
        end;
      finally
        LJsonArr.Free;
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
