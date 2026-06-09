unit RadIA.Tests.ChatPresenter;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.Sessions, RadIA.Core.TokenUsage,
  RadIA.Core.ProviderRegistry, RadIA.UI.ChatPresenter;

type
  TMockChatView = class(TInterfacedObject, IChatView)
  public
    RequestStateInProgress: Boolean;
    RequestStateSetCalled: Boolean;
    TokensStatsText: string;
    LastPostedJson: string;
    LastPostedBackgroundJson: string;
    BackgroundBrowserCreated: Boolean;
    BackgroundBrowserInitialized: Boolean;
    BackgroundBrowserNavigatedUrl: string;
    LoginWindowShown: Boolean;
    LoginWindowUrl: string;
    LoginSuccessCallback: TProc;
    
    PostedMessages: TStringList;
    
    ProvidersList: TArray<string>;
    ActiveProviderId: string;
    ModelsList: TArray<string>;
    ActiveModelName: string;
    ModelsComboEnabled: Boolean;
    SessionsList: TArray<TSessionInfo>;
    ActiveSessionId: string;
    TemplatesList: TArray<string>;
    
    PromptInputText: string;
    PromptFocused: Boolean;
    ActiveEditorText: string;
    ActiveEditorTextSelectionOnly: Boolean;
    EditorTextReplaced: Boolean;
    ReplacedEditorTextValue: string;
    
    LastMessageDialogText: string;
    SaveDialogResult: Boolean;
    SaveDialogSelectedFileName: string;
    ToggleSessionsPanelCalled: Boolean;
    OpenSettingsDialogCalled: Boolean;

    constructor Create;
    destructor Destroy; override;

    { IChatView }
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

  TMockIAProvider = class(TInterfacedObject, IIAProvider)
  private
    FId: string;
    FName: string;
    FModels: TArray<string>;
  public
    constructor Create(const AId, AName: string; const AModels: TArray<string>);
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback; const ATemperature: Double; const AMaxTokens: Integer);
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TStreamChunkCallback; const ATemperature: Double; const AMaxTokens: Integer);
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>);
    function GetAvailableModels: TArray<string>;
    function GetName: string;
    function GetProviderId: string;
    procedure CancelCurrentRequest;
  end;

  [TestFixture]
  TTestChatPresenter = class
  private
    FMockView: TMockChatView;
    FPresenter: TChatPresenter;
    FConfig: IAIConfig;
    FGeminiOriginalMeta: TProviderMetadata;
    FOpenAIOriginalMeta: TProviderMetadata;
    FHasOriginalGemini: Boolean;
    FHasOriginalOpenAI: Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestInitialization;
    [Test]
    procedure TestSendPromptUserMessageIsPosted;
    [Test]
    procedure TestClearChatResetsState;
    [Test]
    procedure TestSelectSessionLoadsHistory;
    [Test]
    procedure TestCreateNewSessionUpdatesView;
    [Test]
    procedure TestHandleTemplateSelectedLoadsInInput;
    [Test]
    procedure TestChangeProviderUpdatesModels;
  end;

implementation

uses
  RadIA.Core.Config, RadIA.Core.SettingsStorage;

{ TMockChatView }

constructor TMockChatView.Create;
begin
  inherited Create;
  RequestStateInProgress := False;
  RequestStateSetCalled := False;
  BackgroundBrowserCreated := False;
  BackgroundBrowserInitialized := True;
  LoginWindowShown := False;
  PromptFocused := False;
  EditorTextReplaced := False;
  SaveDialogResult := True;
  ToggleSessionsPanelCalled := False;
  OpenSettingsDialogCalled := False;
  ActiveEditorText := 'procedure Test; begin end;';
  PostedMessages := TStringList.Create;
end;

destructor TMockChatView.Destroy;
begin
  PostedMessages.Free;
  inherited Destroy;
end;

procedure TMockChatView.SetRequestState(const AInProgress: Boolean);
begin
  RequestStateInProgress := AInProgress;
  RequestStateSetCalled := True;
end;

procedure TMockChatView.UpdateTokensStats(const AStats: string);
begin
  TokensStatsText := AStats;
end;

procedure TMockChatView.PostMessageToWeb(const AJson: string);
begin
  LastPostedJson := AJson;
  PostedMessages.Add(AJson);
end;

procedure TMockChatView.PostMessageToBackgroundWeb(const AJson: string);
begin
  LastPostedBackgroundJson := AJson;
end;

procedure TMockChatView.CreateBackgroundBrowser;
begin
  BackgroundBrowserCreated := True;
end;

function TMockChatView.IsBackgroundBrowserInitialized: Boolean;
begin
  Result := BackgroundBrowserInitialized;
end;

procedure TMockChatView.NavigateBackgroundBrowser(const AUrl: string);
begin
  BackgroundBrowserNavigatedUrl := AUrl;
end;

procedure TMockChatView.ShowLoginWindow(const AUrl: string; AOnLoginSuccess: TProc);
begin
  LoginWindowShown := True;
  LoginWindowUrl := AUrl;
  LoginSuccessCallback := AOnLoginSuccess;
end;

procedure TMockChatView.UpdateProviders(const AProviders: TArray<string>; const AActiveProvider: string);
begin
  ProvidersList := AProviders;
  ActiveProviderId := AActiveProvider;
end;

procedure TMockChatView.UpdateModels(const AModels: TArray<string>; const AActiveModel: string; const AEnabled: Boolean);
begin
  ModelsList := AModels;
  ActiveModelName := AActiveModel;
  ModelsComboEnabled := AEnabled;
end;

procedure TMockChatView.UpdateSessions(const ASessions: TArray<TSessionInfo>; const AActiveSessionId: string);
begin
  SessionsList := ASessions;
  ActiveSessionId := AActiveSessionId;
end;

procedure TMockChatView.UpdateTemplates(const ATemplates: TArray<string>);
begin
  TemplatesList := ATemplates;
end;

function TMockChatView.GetPromptInput: string;
begin
  Result := PromptInputText;
end;

procedure TMockChatView.SetPromptInput(const APrompt: string);
begin
  PromptInputText := APrompt;
end;

procedure TMockChatView.FocusPromptInput;
begin
  PromptFocused := True;
end;

function TMockChatView.GetActiveEditorText(out ACode: string; const AOnlySelected: Boolean): Boolean;
begin
  ACode := ActiveEditorText;
  ActiveEditorTextSelectionOnly := AOnlySelected;
  Result := not ACode.IsEmpty;
end;

procedure TMockChatView.ReplaceActiveEditorText(const ACode: string);
begin
  EditorTextReplaced := True;
  ReplacedEditorTextValue := ACode;
end;

procedure TMockChatView.ShowMessageDialog(const AMessage: string);
begin
  LastMessageDialogText := AMessage;
end;

function TMockChatView.SaveDialogExecute(out AFileName: string): Boolean;
begin
  AFileName := SaveDialogSelectedFileName;
  Result := SaveDialogResult;
end;

procedure TMockChatView.ToggleSessionsPanel;
begin
  ToggleSessionsPanelCalled := True;
end;

procedure TMockChatView.OpenSettingsDialog;
begin
  OpenSettingsDialogCalled := True;
end;

{ TMockIAProvider }

constructor TMockIAProvider.Create(const AId, AName: string; const AModels: TArray<string>);
begin
  inherited Create;
  FId := AId;
  FName := AName;
  FModels := AModels;
end;

procedure TMockIAProvider.SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
  const ACallback: TCompletionCallback; const ATemperature: Double; const AMaxTokens: Integer);
begin
end;

procedure TMockIAProvider.SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
  const ACallback: TStreamChunkCallback; const ATemperature: Double; const AMaxTokens: Integer);
begin
end;

procedure TMockIAProvider.FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>);
begin
  // Keep view in 'Loading...' state deterministically
end;

function TMockIAProvider.GetAvailableModels: TArray<string>;
begin
  Result := FModels;
end;

function TMockIAProvider.GetName: string;
begin
  Result := FName;
end;

function TMockIAProvider.GetProviderId: string;
begin
  Result := FId;
end;

procedure TMockIAProvider.CancelCurrentRequest;
begin
end;

{ TTestChatPresenter }

procedure TTestChatPresenter.Setup;
var
  LMemoryStorage: ISettingsStorage;
begin
  LMemoryStorage := TMemorySettingsStorage.Create;
  TRadIAConfig.SetStorage(LMemoryStorage);
  FConfig := TRadIAConfig.GetInstance;
  FConfig.Load;
  
  FHasOriginalGemini := TProviderRegistry.GetProvider('Gemini', FGeminiOriginalMeta);
  FHasOriginalOpenAI := TProviderRegistry.GetProvider('OpenAI', FOpenAIOriginalMeta);
  
  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create('Gemini', 'Gemini Mock', '', True, False, TArray<string>.Create('gemini-1.5-flash', 'gemini-1.5-pro'),
      function(const ACfg: IAIConfig): IIAProvider
      begin
        Result := TMockIAProvider.Create('Gemini', 'Gemini Mock', TArray<string>.Create('gemini-1.5-flash', 'gemini-1.5-pro'));
      end
    )
  );

  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create('OpenAI', 'OpenAI Mock', '', True, False, TArray<string>.Create('gpt-4o-mini', 'gpt-4o'),
      function(const ACfg: IAIConfig): IIAProvider
      begin
        Result := TMockIAProvider.Create('OpenAI', 'OpenAI Mock', TArray<string>.Create('gpt-4o-mini', 'gpt-4o'));
      end
    )
  );

  FMockView := TMockChatView.Create;
  FPresenter := TChatPresenter.Create(FMockView, FConfig);
end;

procedure TTestChatPresenter.TearDown;
begin
  FPresenter.Free;
  FConfig := nil;
  TRadIAConfig.SetStorage(nil);
  
  if FHasOriginalGemini then
    TProviderRegistry.RegisterProvider(FGeminiOriginalMeta);
  if FHasOriginalOpenAI then
    TProviderRegistry.RegisterProvider(FOpenAIOriginalMeta);
end;

procedure TTestChatPresenter.TestInitialization;
begin
  FPresenter.Initialize('C:\mock\web');
  
  Assert.IsTrue(Length(FMockView.ProvidersList) > 0);
  Assert.AreEqual('Gemini', FMockView.ActiveProviderId);
  Assert.AreEqual('Loading...', FMockView.ActiveModelName);
end;

procedure TTestChatPresenter.TestSendPromptUserMessageIsPosted;
var
  LMsg: string;
  LFound: Boolean;
begin
  FPresenter.Initialize('C:\mock\web');
  FPresenter.WebViewReady := True;
  
  FMockView.PromptInputText := 'Hello Assistant';
  
  FPresenter.SendPrompt;
  
  Assert.AreEqual('', FMockView.PromptInputText);
  
  LFound := False;
  for LMsg in FMockView.PostedMessages do
  begin
    if LMsg.Contains('"action":"add_message"') and LMsg.Contains('"role":"user"') and LMsg.Contains('Hello Assistant') then
    begin
      LFound := True;
      Break;
    end;
  end;
  Assert.IsTrue(LFound);
end;

procedure TTestChatPresenter.TestClearChatResetsState;
var
  LMsg: string;
  LFound: Boolean;
begin
  FPresenter.Initialize('C:\mock\web');
  FPresenter.WebViewReady := True;
  
  FPresenter.ClearChat;
  
  LFound := False;
  for LMsg in FMockView.PostedMessages do
  begin
    if LMsg.Contains('"action":"clear_chat"') then
    begin
      LFound := True;
      Break;
    end;
  end;
  Assert.IsTrue(LFound);
end;

procedure TTestChatPresenter.TestSelectSessionLoadsHistory;
begin
  FPresenter.Initialize('C:\mock\web');
  FPresenter.WebViewReady := True;
  
  FPresenter.SelectSession('session-xyz');
  
  Assert.AreEqual('session-xyz', FPresenter.SessionManager.ActiveSessionId);
  Assert.AreEqual('session-xyz', FConfig.ActiveSessionId);
end;

procedure TTestChatPresenter.TestCreateNewSessionUpdatesView;
var
  LCountBefore: Integer;
begin
  FPresenter.Initialize('C:\mock\web');
  FPresenter.WebViewReady := True;
  
  LCountBefore := Length(FMockView.SessionsList);
  FPresenter.CreateNewSession;
  
  Assert.IsTrue(Length(FMockView.SessionsList) > LCountBefore);
end;

procedure TTestChatPresenter.TestHandleTemplateSelectedLoadsInInput;
begin
  FPresenter.Initialize('C:\mock\web');
  FPresenter.HandleTemplateSelected('Review Leaks and SOLID');
  
  Assert.IsFalse(FMockView.PromptInputText.IsEmpty);
  Assert.IsTrue(FMockView.PromptFocused);
end;

procedure TTestChatPresenter.TestChangeProviderUpdatesModels;
begin
  FPresenter.Initialize('C:\mock\web');
  FPresenter.ChangeProvider('OpenAI');
  
  Assert.AreEqual('OpenAI', FConfig.GetActiveProvider);
  Assert.AreEqual('Loading...', FMockView.ActiveModelName);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestChatPresenter);

end.
