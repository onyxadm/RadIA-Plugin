unit RadIA.UI.ChatFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Edge, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config, RadIA.Core.Service;

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
  private
    FConfig: IAIConfig;
    FAIService: TRadIAService;
    FHistory: TArray<IChatMessage>;
    FWebFilesDir: string;
    FBrowserInitialized: Boolean;
    
    procedure InitializeWebView;
    procedure CopyWebFiles;
    procedure LoadConfig;
    procedure UpdateModelsCombo;
    procedure SendPromptToAI(const APromptText: string);
    procedure PostToWebView(const AAction, ARole, AText: string);
    procedure OnGlobalPromptRequest(const APrompt: string; const AOpenChat: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure SetTheme(const AThemeName: string);
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.JSON, RadIA.OTA.Helper, RadIA.UI.ConfigFrame;

constructor TFrameAIChat.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBrowserInitialized := False;
  FHistory := [];
  
  FConfig := TRadIAConfig.Create;
  FAIService := TRadIAService.Create(FConfig);
  
  FWebFilesDir := TPath.Combine(TPath.GetHomePath, 'RadIA\Web');
  CopyWebFiles;
  
  LoadConfig;
  InitializeWebView;
  
  GlobalOnRequestPrompt := Self.OnGlobalPromptRequest;
end;

destructor TFrameAIChat.Destroy;
begin
  GlobalOnRequestPrompt := nil;
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
  LProviderType: TAIProviderType;
  LActiveModel: string;
  LModels: TArray<string>;
  LModel: string;
begin
  cbModel.Items.Clear;
  LProviderType := TAIProviderType(cbProvider.ItemIndex);
  
  case LProviderType of
    ptGemini:
      LModels := TArray<string>.Create(MODEL_GEMINI_15_FLASH, MODEL_GEMINI_15_PRO);
    ptOpenAI:
      LModels := TArray<string>.Create(MODEL_OPENAI_GPT4O_MINI, MODEL_OPENAI_GPT4O);
    ptClaude:
      LModels := TArray<string>.Create(MODEL_CLAUDE_3_HAIKU, MODEL_CLAUDE_35_SONNET);
  end;
  
  for LModel in LModels do
  begin
    cbModel.Items.Add(LModel);
  end;
  
  LActiveModel := FConfig.GetActiveModel(LProviderType);
  cbModel.ItemIndex := cbModel.Items.IndexOf(LActiveModel);
  if cbModel.ItemIndex = -1 then
    cbModel.ItemIndex := 0;
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
begin
  FHistory := [];
  PostToWebView('clear_chat', '', '');
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
    LForm.Height := 340;
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
    procedure(const AResponse: string; const AError: string)
    var
      LAssistantMsg: IChatMessage;
    begin
      btnSend.Enabled := True;
      if not AError.IsEmpty then
      begin
        PostToWebView('add_message', 'assistant', '**Error:** ' + AError);
        Exit;
      end;
      
      PostToWebView('add_message', 'assistant', AResponse);
      
      { Save history }
      FHistory := FHistory + [LUserMsg];
      LAssistantMsg := TRadIAService.CreateMessage(mrAssistant, AResponse);
      FHistory := FHistory + [LAssistantMsg];
    end);
end;

procedure TFrameAIChat.OnGlobalPromptRequest(const APrompt: string; const AOpenChat: Boolean);
begin
  PostToWebView('add_message', 'user', APrompt);
  SendPromptToAI(APrompt);
end;

end.
