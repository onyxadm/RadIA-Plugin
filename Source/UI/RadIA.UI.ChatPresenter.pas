unit RadIA.UI.ChatPresenter;

interface

uses
  System.SysUtils, System.Classes, System.JSON, RadIA.Core.Interfaces,
  RadIA.Core.Sessions, RadIA.Core.PromptTemplates,
  RadIA.Core.TokenUsage, RadIA.Core.PromptHistory;

type
  IRadIAChatView = interface
    ['{8A5FC9BC-0D5C-4F7F-9ED6-9D7CC5EF5E18}']
    procedure SetRequestState(const AInProgress: Boolean);
    procedure UpdateTokensStats(const AStats: string);
    procedure PostMessageToWeb(const AJson: string);
    procedure PostMessageToBackgroundWeb(const AJson: string);
    procedure ApplyCurrentTheme;

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

  TRadIAChatPresenter = class
  private
    FView: IRadIAChatView;
    FConfig: IRadIAConfig;
    FAIService: IRadIAService;
    FSessionManager: TRadIASessionManager;
    FPromptHistoryManager: TPromptHistoryManager;
    FTemplateManager: TPromptTemplateManager;
    FAccumulatedUsage: TTokenUsage;
    FHistory: TArray<IRadIAChatMessage>;
    FRequestInProgress: Boolean;
    FCancelledByUser: Boolean;
    FLoadingConfig: Boolean;
    FWebViewReady: Boolean;
    FWebFilesDir: string;
    FLifecycleGuard: IInterface;
    FActiveModels: TArray<string>;
    FPendingPrompt: string;
    FBackgroundBrowserReady: Boolean;
    FCurrentBackgroundUrl: string;
    FLoginPopupOpen: Boolean;
    FOwnsService: Boolean;
    FModelsProvider: IRadIAProvider;
    FDataDir: string;
    FDTOBuilder: IRadIADTOBuilder;
    FProjectGenerator: IRadIAProjectGenerator;

    procedure HandleBackgroundLoginComplete;
    procedure UpdateModelsCombo;

    procedure HandleUpdateModelsComboResult(AModels: TArray<string>; AProvider: IRadIAProvider);
    function BuildProvidersJsonArray: TJSONArray;
    function BuildModelsJsonArray(
  const AActiveProvider: string;
   LIsWebLogin: Boolean;
   out AActiveModel: string): TJSONArray;
  
    function BuildSlashCommandsJsonArray: TJSONArray;

    procedure LoadChatHistory;
    procedure SaveChatHistory;
    procedure LoadPromptHistory;
    procedure SavePromptHistory;
    function GetVisibleSessions: TArray<TSessionInfo>;
    procedure UpdateSessionsList;
    function PreProcessPrompt(const APromptText: string): string;

    function ExtractCodeArgument(const AArgument: string): string;
    function FindTemplateForCommand(const ACommand, AArgument: string; out ATemplate: TPromptTemplate): Boolean;

    function IsProviderConfigured(const AProviderId: string): Boolean;
    function GetWebLoginUrl(const AProvider: string): string;
    function CanChangeSession: Boolean;

    procedure SendInitialConfigToWeb;
    procedure SendModelsUpdateToWeb(const AModels: TArray<string>; const AActiveModel: string);
    procedure SendSessionsUpdateToWeb;
    procedure PostToWebView(const AAction, ARole, AText: string; const AProvider: string = '';
        const AModel: string = ''); overload;
    procedure PostToWebView(const AAction, ARole, AText: string; const AIsDone: Boolean;
        const AProvider: string = ''; const AModel: string = ''); overload;

    procedure HandleOnbtnWebLoginConnectClick;
    procedure QueueOnUI(const AProcedure: TProc);
    procedure DispatchWebMessage(const AAction: string; const AJson: TJSONObject);
    procedure HandleInsertCodeMessage(const ACode: string);
    procedure HandleReadyMessage;
    procedure HandleNewChatMessage;
    procedure HandleLoadHistoryMessage;
    procedure HandleToggleHistoryMessage;
    procedure HandleOpenSettingsMessage;
    procedure HandleChangeProviderMessage(const AProvider: string);
    procedure HandleChangeModelMessage(const AModel: string);
    procedure HandleSelectSessionMessage(const ASessionId: string);
    procedure HandleRenameSessionMessage(const ASessionId, AName: string);
    procedure HandleDeleteSessionMessage(const ASessionId: string);
    procedure HandleWebLoginConnectMessage;
    procedure HandleLoginCompleteMessage;
    procedure HandleErrorMessage(const AText: string);
    procedure HandleUpdateStreamMessage(const AText: string; const AIsDone: Boolean);
    procedure HandleSendPromptMessage(const AText: string);
    procedure HandleGenerateDTOMessage(const AInput, AInputType, AOutputType: string);
    procedure HandleCreateProjectMessage(const AFilesJson: string);
    procedure HandleCancelRequestMessage;
    procedure HandleClearChatMessage;
    procedure HandleStreamChunkMessage(const AText: string; const AIsDone: Boolean; const AError: string);
  public
    constructor Create(const AView: IRadIAChatView; const AConfig: IRadIAConfig;
        const AService: IRadIAService = nil; const ADataDir: string = '');
    destructor Destroy; override;

    procedure Initialize(const AWebFilesDir: string);
    procedure LoadConfig;
    procedure ProcessWebMessage(const AMessage: string);
    procedure OnWebViewReady;

    procedure SendPrompt;
    procedure SendPromptText(const APromptText: string);
    procedure SendPromptToAI(const APromptText: string);

    procedure HandleStreamSessionChange(
  AIsDone: Boolean;
  
  const ASessionId, AFullResponse, AActiveProvider, AActiveModel: string);
  
    procedure HandleStreamCancel(const AActiveProvider, AActiveModel: string; var AFullResponse: string);
    procedure HandleStreamError(const AError, AActiveProvider, AActiveModel: string; var AFullResponse: string);
    procedure HandleStreamDone(const APromptText, AActiveProvider, AActiveModel, AFullResponse: string);

    procedure CancelRequest;
    procedure ClearChat;

    procedure ChangeProvider(const AProviderName: string);
    procedure ChangeModel(const AModelName: string);

    procedure ToggleSessions;
    procedure CreateNewSession;
    procedure RenameSession(const ASessionId, ANewName: string);
    procedure DeleteSession(const ASessionId: string);
    procedure SelectSession(const ASessionId: string);

    procedure ExportChat;
    procedure OpenSettings;

    procedure HandlePromptInputKeyDown(var Key: Word; const Shift: TShiftState);
    procedure HandleTemplateSelected(const ATemplateName: string);
    procedure HandleGlobalPromptRequest(const APrompt: string; const AOpenChat: Boolean);

    procedure GenerateDTO(const AInput, AInputType, AOutputType: string);

    procedure HandleGenerateDTOCancel;
    procedure HandleGenerateDTOError(const AError: string);
    procedure HandleGenerateDTODone(const APromptText, AActiveProvider: string);


    procedure OnWebViewBridgeSendPrompt(const APrompt: string);
    procedure OnWebViewBridgeCancel;
    procedure OnBackgroundBrowserMessage(const AMessage: string);
    procedure OnBackgroundBrowserInitialized;
    procedure OnBackgroundBrowserNavigation(const AUrl: string);

    {$IFDEF TESTS}
    function TestPreProcessPrompt(const APromptText: string): string;
    {$ENDIF}

    property SessionManager: TRadIASessionManager read FSessionManager;
    property WebViewReady: Boolean read FWebViewReady write FWebViewReady;
  end;

implementation

uses
  System.IOUtils, System.StrUtils, RadIA.Core.Types, RadIA.Core.Config, RadIA.Core.Logger,
  RadIA.Core.ProviderRegistry, RadIA.Core.ConversationExporter,
  RadIA.Core.DTO.Generator, RadIA.Core.ProjectGenerator, RadIA.Provider.WebViewBridge,
  System.SyncObjs, RadIA.Core.Container, RadIA.Core.ChatMessage, RadIA.Core.Service;

{ Helper Functions }

function IndexOfString(const AArray: TArray<string>; const AValue: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := Low(AArray) to High(AArray) do
  begin
    if SameText(AArray[I], AValue) then
      Exit(I);
  end;
end;

{ TRadIAChatPresenter }

constructor TRadIAChatPresenter.Create(const AView: IRadIAChatView; const AConfig: IRadIAConfig;
    const AService: IRadIAService; const ADataDir: string);
begin
  inherited Create;
  FView := AView;
  FHistory := [];
  FRequestInProgress := False;
  FCancelledByUser := False;
  FLoadingConfig := False;
  FWebViewReady := False;
  FLifecycleGuard := TLifecycleGuard.Create;
  FActiveModels := [];
  FPendingPrompt := '';
  FBackgroundBrowserReady := False;
  FCurrentBackgroundUrl := '';
  FLoginPopupOpen := False;

  TRadIAWebViewBridgeProvider.OnSendPrompt := OnWebViewBridgeSendPrompt;
  TRadIAWebViewBridgeProvider.OnCancel := OnWebViewBridgeCancel;

  if Assigned(AConfig) then
    FConfig := AConfig
  else if not TRadIAContainer.TryResolve<IRadIAConfig>(FConfig) then
    FConfig := TRadIAConfig.GetInstance;

  if Assigned(AService) then
  begin
    FAIService := AService;
    FOwnsService := False;
  end
  else if TRadIAContainer.TryResolve<IRadIAService>(FAIService) then
  begin
    FOwnsService := False;
  end
  else
  begin
    FAIService := TRadIAService.Create(FConfig);
    FOwnsService := True;
  end;

  if not TRadIAContainer.TryResolve<IRadIADTOBuilder>(FDTOBuilder) then
    FDTOBuilder := TRadIADTOBuilder.Create;
  if not TRadIAContainer.TryResolve<IRadIAProjectGenerator>(FProjectGenerator) then
    FProjectGenerator := TRadIAProjectGenerator.Create;

  if ADataDir.IsEmpty then
    FDataDir := TPath.Combine(TPath.GetHomePath, 'RadIA')
  else
    FDataDir := ADataDir;

  FPromptHistoryManager := TPromptHistoryManager.Create;
  FAccumulatedUsage := TTokenUsage.Empty;

  FTemplateManager := TPromptTemplateManager.Create(FDataDir);
  FTemplateManager.Load;

  FSessionManager := TRadIASessionManager.Create(TPath.Combine(FDataDir, 'sessions'));
  FSessionManager.ActiveSessionId := FConfig.ActiveSessionId;
end;

destructor TRadIAChatPresenter.Destroy;
begin
  if Assigned(FModelsProvider) then
  begin
    try
      FModelsProvider.CancelCurrentRequest;
    except
      on E: Exception do
        TLogger.Log('Destroy: Error cancelling model provider: ' + E.Message, 'UI');
    end;
    FModelsProvider := nil;
  end;

  TRadIAWebViewBridgeProvider.OnSendPrompt := nil;
  TRadIAWebViewBridgeProvider.OnCancel := nil;

  if Assigned(FLifecycleGuard) then
    (FLifecycleGuard as IRadIALifecycleGuard).Invalidate;

  if Assigned(FAIService) then
    FAIService.CancelCurrentRequest;

  FPromptHistoryManager.Free;
  FTemplateManager.Free;
  FSessionManager.Free;

  if FOwnsService and Assigned(FAIService) then
    FAIService := nil;

  inherited Destroy;
end;

procedure TRadIAChatPresenter.Initialize(const AWebFilesDir: string);
var
  LTemplate: TPromptTemplate;
  LTemplateNames: TArray<string>;
begin
  FWebFilesDir := AWebFilesDir;

  LTemplateNames := [];
  for LTemplate in FTemplateManager.GetTemplates do
  begin
    LTemplateNames := LTemplateNames + [LTemplate.Name];
  end;
  FView.UpdateTemplates(LTemplateNames);

  LoadConfig;
  UpdateSessionsList;
  LoadPromptHistory;
end;

function TRadIAChatPresenter.IsProviderConfigured(const AProviderId: string): Boolean;
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

    if FConfig.IsWebLoginProvider(AProviderId) then
      Exit(True);

    Result := not FConfig.GetApiKey(AProviderId).Trim.IsEmpty;
  end;
end;

function TRadIAChatPresenter.GetWebLoginUrl(const AProvider: string): string;
begin
  if SameText(AProvider, 'Gemini') then
    Result := 'https://gemini.google.com'
  else if SameText(AProvider, 'OpenAI') then
    Result := 'https://chatgpt.com'
  else
    Result := '';
end;

function TRadIAChatPresenter.CanChangeSession: Boolean;
begin
  Result := not FRequestInProgress;
  if not Result then
    FView.ShowMessageDialog('Wait for the current response to finish, or cancel it before switching chats.');
end;

procedure TRadIAChatPresenter.LoadConfig;
var
  LProviders: TArray<TProviderMetadata>;
  LActiveProvider: string;
  LConfiguredProviders: TArray<string>;
  I: Integer;
begin
  FLoadingConfig := True;
  try
    LConfiguredProviders := [];
    LProviders := TProviderRegistry.GetProviders;
    for I := 0 to Length(LProviders) - 1 do
    begin
      if IsProviderConfigured(LProviders[I].Id) then
        LConfiguredProviders := LConfiguredProviders + [LProviders[I].Id];
    end;

    if Length(LConfiguredProviders) = 0 then
    begin
      for I := 0 to Length(LProviders) - 1 do
        LConfiguredProviders := LConfiguredProviders + [LProviders[I].Id];
    end;

    LActiveProvider := FConfig.GetActiveProvider;
    FView.UpdateProviders(LConfiguredProviders, LActiveProvider);

    UpdateModelsCombo;
  finally
    FLoadingConfig := False;
  end;
end;


procedure TRadIAChatPresenter.HandleUpdateModelsComboResult(AModels: TArray<string>; AProvider: IRadIAProvider);
var
  LActiveModel: string;
  LProvId: string;
begin
  if FModelsProvider = AProvider then
    FModelsProvider := nil;

  if Assigned(AProvider) then
  begin
    Self.FActiveModels := AModels;
    LProvId := AProvider.GetProviderId;
    LActiveModel := Self.FConfig.GetActiveModel(LProvId);

    if (Length(AModels) > 0) and (LActiveModel.IsEmpty or (IndexOfString(AModels, LActiveModel) = -1)) then
    begin
      LActiveModel := AModels[0];
      Self.FConfig.SetActiveModel(LProvId, LActiveModel);
      Self.FConfig.Save;
    end;

    Self.FView.UpdateModels(AModels, LActiveModel, True);
    Self.SendModelsUpdateToWeb(AModels, LActiveModel);
  end;
end;

function TRadIAChatPresenter.BuildProvidersJsonArray: TJSONArray;
var
  LProviders: TArray<TProviderMetadata>;
  LProvObj: TJSONObject;
  I: Integer;
begin
  Result := TJSONArray.Create;
  LProviders := TProviderRegistry.GetProviders;
  for I := 0 to Length(LProviders) - 1 do
  begin
    if IsProviderConfigured(LProviders[I].Id) then
    begin
      LProvObj := TJSONObject.Create;
      LProvObj.AddPair('name', LProviders[I].DisplayName);
      LProvObj.AddPair('value', LProviders[I].Id);
      Result.AddElement(LProvObj);
    end;
  end;
end;

function TRadIAChatPresenter.BuildModelsJsonArray(
  const AActiveProvider: string;
   LIsWebLogin: Boolean;
   out AActiveModel: string): TJSONArray;
  
var
  LMeta: TProviderMetadata;
  LDefaultModels: TArray<string>;
  LModel: string;
begin
  Result := TJSONArray.Create;
  AActiveModel := FConfig.GetActiveModel(AActiveProvider);

  if LIsWebLogin then
  begin
    if TProviderRegistry.GetProvider('WebViewBridge', LMeta) then
      LDefaultModels := LMeta.DefaultModels
    else
      LDefaultModels := ['Web-Browser'];
    AActiveModel := 'Web-Browser';
  end
  else
  begin
    if Length(FActiveModels) > 0 then
      LDefaultModels := FActiveModels
    else if TProviderRegistry.GetProvider(AActiveProvider, LMeta) then
      LDefaultModels := LMeta.DefaultModels
    else
      LDefaultModels := [];
  end;

  for LModel in LDefaultModels do
  begin
    Result.Add(LModel);
  end;
end;

function TRadIAChatPresenter.BuildSlashCommandsJsonArray: TJSONArray;
var
  LTemplate: TPromptTemplate;
  LSlashObj: TJSONObject;
begin
  Result := TJSONArray.Create;
  for LTemplate in FTemplateManager.GetTemplates do
  begin
    if not LTemplate.SlashCommand.IsEmpty then
    begin
      LSlashObj := TJSONObject.Create;
      LSlashObj.AddPair('command', LTemplate.SlashCommand);
      LSlashObj.AddPair('description', LTemplate.Description);
      LSlashObj.AddPair('name', LTemplate.Name);
      LSlashObj.AddPair('isProjectGenerator', TJSONBool.Create(LTemplate.IsProjectGenerator));
      Result.AddElement(LSlashObj);
    end;
  end;
end;
procedure TRadIAChatPresenter.UpdateModelsCombo;
var
  LProvider: IRadIAProvider;
  LGuard: IRadIALifecycleGuard;
begin
  FView.UpdateModels(['Loading...'], 'Loading...', False);
  LGuard := FLifecycleGuard as IRadIALifecycleGuard;

  try
    if Assigned(FModelsProvider) then
    begin
      try
        FModelsProvider.CancelCurrentRequest;
      except
        on E: Exception do
          TLogger.Log('UpdateModelsCombo: Error cancelling previous model provider: ' + E.Message, 'UI');
      end;
      FModelsProvider := nil;
    end;

    FModelsProvider := FAIService.CreateActiveProvider;
    LProvider := FModelsProvider;
    LProvider.FetchAvailableModelsAsync(
      procedure(AModels: TArray<string>; AError: string)
      begin
        TThread.Queue(nil,
          procedure
          begin
            if not LGuard.IsAlive then
              Exit;
            Self.HandleUpdateModelsComboResult(AModels, LProvider);
          end
        );
      end);
  except
    on E: Exception do
    begin
      FView.UpdateModels(['Error loading models'], 'Error loading models', True);
    end;
  end;
end;

procedure TRadIAChatPresenter.ChangeProvider(const AProviderName: string);
var
  LUrl: string;
begin
  if FLoadingConfig then
    Exit;

  FActiveModels := [];
  FConfig.SetActiveProvider(AProviderName);
  FConfig.Save;
  UpdateModelsCombo;

  LUrl := GetWebLoginUrl(AProviderName);
  if not LUrl.IsEmpty then
  begin
    if not FView.IsBackgroundBrowserInitialized then
    begin
      TLogger.Log('ChangeProvider: Initializing background browser for newly selected Web Login provider.', 'UI');
      FBackgroundBrowserReady := False;
      FView.CreateBackgroundBrowser;
    end
    else if not SameText(FCurrentBackgroundUrl, LUrl) then
    begin
      TLogger.Log(Format('ChangeProvider: Preventive navigation of background browser to %s', [LUrl]), 'UI');
      FBackgroundBrowserReady := False;
      FCurrentBackgroundUrl := LUrl;
      FView.NavigateBackgroundBrowser(LUrl);
    end;
  end;
end;

procedure TRadIAChatPresenter.ChangeModel(const AModelName: string);
var
  LSelectedProvider: string;
begin
  if FLoadingConfig then
    Exit;

  LSelectedProvider := FConfig.GetActiveProvider;
  FConfig.SetActiveModel(LSelectedProvider, AModelName);
  FConfig.Save;
end;

procedure TRadIAChatPresenter.ClearChat;
begin
  if not CanChangeSession then
    Exit;

  FHistory := [];
  FAccumulatedUsage := TTokenUsage.Empty;
  PostToWebView('clear_chat', '', '');
  PostToWebView('update_tokens', '', '');

  if Assigned(FAIService) then
    FAIService.ClearCache;

  if not FSessionManager.ActiveSessionId.IsEmpty then
  begin
    try
      FSessionManager.SaveSessionHistory(FSessionManager.ActiveSessionId, []);
    except
      on E: Exception do
        TLogger.Log('ClearChat: Error saving cleared session: ' + E.Message, 'UI');
    end;
  end;
end;

procedure TRadIAChatPresenter.ToggleSessions;
begin
  if not CanChangeSession then
    Exit;

  FView.ToggleSessionsPanel;
end;

procedure TRadIAChatPresenter.CreateNewSession;
var
  LSession: TSessionInfo;
begin
  if not CanChangeSession then
    Exit;

  SaveChatHistory;
  LSession := FSessionManager.CreateSession('Initial Chat');
  FSessionManager.ActiveSessionId := LSession.Id;
  FConfig.ActiveSessionId := LSession.Id;
  FConfig.Save;

  FHistory := [];
  FAccumulatedUsage := TTokenUsage.Empty;
  PostToWebView('clear_chat', '', '');
  PostToWebView('update_tokens', '', '');

  UpdateSessionsList;
  SendSessionsUpdateToWeb;
end;

procedure TRadIAChatPresenter.RenameSession(const ASessionId, ANewName: string);
begin
  if not CanChangeSession then
    Exit;

  if not ANewName.Trim.IsEmpty then
  begin
    FSessionManager.RenameSession(ASessionId, ANewName);
    UpdateSessionsList;
    SendSessionsUpdateToWeb;
  end;
end;

procedure TRadIAChatPresenter.DeleteSession(const ASessionId: string);
begin
  if not CanChangeSession then
    Exit;

  FSessionManager.DeleteSession(ASessionId);

  if SameText(FSessionManager.ActiveSessionId, ASessionId) then
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
end;

procedure TRadIAChatPresenter.SelectSession(const ASessionId: string);
begin
  if not CanChangeSession then
    Exit;

  if not FSessionManager.ActiveSessionId.IsEmpty and not SameText(FSessionManager.ActiveSessionId, ASessionId) then
    SaveChatHistory;

  FSessionManager.ActiveSessionId := ASessionId;
  FSessionManager.UpdateSessionActivity(ASessionId);
  FConfig.ActiveSessionId := ASessionId;
  FConfig.Save;

  UpdateSessionsList;

  FHistory := [];
  FAccumulatedUsage := TTokenUsage.Empty;
  PostToWebView('clear_chat', '', '');
  PostToWebView('update_tokens', '', '');

  LoadChatHistory;
  SendSessionsUpdateToWeb;
end;

procedure TRadIAChatPresenter.ExportChat;
var
  LContent: string;
  LProviderName: string;
  LModelName: string;
  LFileName: string;
begin
  if Length(FHistory) = 0 then
  begin
    FView.ShowMessageDialog('There is no conversation history to export.');
    Exit;
  end;

  if FView.SaveDialogExecute(LFileName) then
  begin
    LProviderName := FConfig.GetActiveProvider;
    LModelName := FConfig.GetActiveModel(LProviderName);

    if SameText(ExtractFileExt(LFileName), '.html') then
      LContent := TConversationExporter.ExportToHTML(FHistory, LProviderName, LModelName)
    else
      LContent := TConversationExporter.ExportToMarkdown(FHistory, LProviderName, LModelName);

    try
      TFile.WriteAllText(LFileName, LContent, TEncoding.UTF8);
      FView.ShowMessageDialog('Conversation exported successfully!');
    except
      on E: Exception do
        FView.ShowMessageDialog('Error exporting conversation: ' + E.Message);
    end;
  end;
end;

procedure TRadIAChatPresenter.OpenSettings;
begin
  FView.OpenSettingsDialog;
  FConfig.Load;
  LoadConfig;

  FTemplateManager.Load;
  Initialize(FWebFilesDir);
end;

procedure TRadIAChatPresenter.HandlePromptInputKeyDown(var Key: Word; const Shift: TShiftState);
var
  LPrompt: string;
begin
  if (Key = 13) and (Shift = [ssCtrl]) then
  begin
    SendPrompt;
    Key := 0;
    Exit;
  end;

  if Shift <> [] then
    Exit;

  if Key = 38 then
  begin
    LPrompt := FPromptHistoryManager.NavigateUp;
    FView.SetPromptInput(LPrompt);
    Key := 0;
  end
  else if Key = 40 then
  begin
    LPrompt := FPromptHistoryManager.NavigateDown;
    FView.SetPromptInput(LPrompt);
    Key := 0;
  end;
end;

procedure TRadIAChatPresenter.HandleTemplateSelected(const ATemplateName: string);
var
  LActiveCode: string;
  LResolved: string;
begin
  if not Assigned(FTemplateManager) then
    Exit;

  if not FView.GetActiveEditorText(LActiveCode, True) or LActiveCode.IsEmpty then
    FView.GetActiveEditorText(LActiveCode, False);

  LResolved := FTemplateManager.ResolveTemplate(ATemplateName, LActiveCode);

  FView.SetPromptInput(LResolved);
  FView.FocusPromptInput;
end;

procedure TRadIAChatPresenter.HandleGlobalPromptRequest(const APrompt: string; const AOpenChat: Boolean);
var
  LProcessed: string;
begin
  LProcessed := PreProcessPrompt(APrompt);
  PostToWebView('add_message', 'user', APrompt);
  SendPromptToAI(LProcessed);
end;

procedure TRadIAChatPresenter.SendPrompt;
var
  LText: string;
  LProcessed: string;
begin
  if FRequestInProgress then
  begin
    FCancelledByUser := True;
    TLogger.Log('SendPrompt: User requested cancellation of active request.', 'UI');
    FView.SetRequestState(False);
    FAIService.CancelCurrentRequest;
    Exit;
  end;

  LText := Trim(FView.GetPromptInput);
  if LText.IsEmpty then
    Exit;

  LProcessed := PreProcessPrompt(LText);
  FPromptHistoryManager.Add(FView.GetPromptInput);
  SavePromptHistory;

  FView.SetPromptInput('');
  PostToWebView('add_message', 'user', LText);
  SendPromptToAI(LProcessed);
end;

procedure TRadIAChatPresenter.SendPromptText(const APromptText: string);
var
  LProcessed: string;
begin
  LProcessed := PreProcessPrompt(APromptText);
  PostToWebView('add_message', 'user', APromptText);
  SendPromptToAI(LProcessed);
end;


procedure TRadIAChatPresenter.HandleStreamSessionChange(
  AIsDone: Boolean;
  
  const ASessionId, AFullResponse, AActiveProvider, AActiveModel: string);
  
begin
  TLogger.Log(Format('SendPromptToAI: Session changed from %s to %s. Discarding UI callback.',
      [ASessionId, Self.FSessionManager.ActiveSessionId]), 'UI');
  if AIsDone and (not AFullResponse.IsEmpty) and (not GIsShuttingDown) then
  begin
    TInterlocked.Increment(GActiveThreadCount);
    TThread.CreateAnonymousThread(
      procedure
      var
        LOrigHistory: TArray<IRadIAChatMessage>;
        LAssistantMsg: IRadIAChatMessage;
      begin
        try
          try
            LOrigHistory := Self.FSessionManager.LoadSessionHistory(ASessionId);
            LAssistantMsg := TRadIAChatMessage.CreateMessage(mrAssistant, AFullResponse,
                AActiveProvider, AActiveModel);
            LOrigHistory := LOrigHistory + [LAssistantMsg];
            Self.FSessionManager.SaveSessionHistory(ASessionId, LOrigHistory);
          except
            on E: Exception do
              TLogger.Log('SendPromptToAI background thread: Error saving history: ' + E.Message, 'UI');
          end;
        finally
          TInterlocked.Decrement(GActiveThreadCount);
        end;
      end).Start;
  end;
end;

procedure TRadIAChatPresenter.HandleStreamCancel(
  const AActiveProvider, AActiveModel: string;
   var AFullResponse: string);
  
var
  LAssistantMsg: IRadIAChatMessage;
begin
  Self.FRequestInProgress := False;
  Self.FView.SetRequestState(False);
  TLogger.Log('SendPromptToAI: Handling user cancellation in UI callback.', 'UI');

  if not AFullResponse.IsEmpty then
  begin
    LAssistantMsg := TRadIAChatMessage.CreateMessage(mrAssistant, AFullResponse + ' [Cancelled ' +
        'by user]', AActiveProvider, AActiveModel);
    Self.FHistory := Self.FHistory + [LAssistantMsg];
    Self.SaveChatHistory;
  end;

  Self.PostToWebView('add_message', 'assistant', '*Requisicao cancelada pelo usuario.*',
      False, AActiveProvider, AActiveModel);
  Self.PostToWebView('append_message', 'assistant', '', True, AActiveProvider, AActiveModel);
end;

procedure TRadIAChatPresenter.HandleStreamError(
  const AError, AActiveProvider, AActiveModel: string;
   var AFullResponse: string);
  
var
  LAssistantMsg: IRadIAChatMessage;
  LIsWebError: Boolean;
begin
  Self.FRequestInProgress := False;
  Self.FView.SetRequestState(False);
  TLogger.Log(Format('SendPromptToAI error callback: %s', [AError]), 'UI');

  if not AFullResponse.IsEmpty then
  begin
    AFullResponse := AFullResponse + #13#10#13#10 + '**Error:** ' + AError;
    Self.PostToWebView('append_message', 'assistant', #13#10#13#10 + '**Error:** ' + AError,
        True, AActiveProvider, AActiveModel);

    LAssistantMsg := TRadIAChatMessage.CreateMessage(mrAssistant, AFullResponse, AActiveProvider,
        AActiveModel);
    Self.FHistory := Self.FHistory + [LAssistantMsg];
    Self.SaveChatHistory;
  end
  else
  begin
    Self.PostToWebView('add_message', 'assistant', '**Error:** ' + AError, False, AActiveProvider,
        AActiveModel);
    Self.PostToWebView('append_message', 'assistant', '', True, AActiveProvider, AActiveModel);
  end;

  LIsWebError := SameText(AError, 'WebView Login session is not ready or active.') or
                     SameText(AError, 'Input textarea not found in page.') or
                     SameText(AError, 'Send button not found in page.');
  if LIsWebError then
  begin
    Self.HandleOnbtnWebLoginConnectClick;
  end;
end;

procedure TRadIAChatPresenter.HandleStreamDone(const APromptText, AActiveProvider, AActiveModel, AFullResponse: string);
var
  LAssistantMsg: IRadIAChatMessage;
  LUsage: TTokenUsage;
  LStats: string;
begin
  Self.FRequestInProgress := False;
  Self.FView.SetRequestState(False);
  TLogger.Log(Format('SendPromptToAI completed. TotalResponseLength=%d', [Length(AFullResponse)]), 'UI');

  if AFullResponse.IsEmpty then
  begin
    TLogger.Log('SendPromptToAI: Empty response from AI provider', 'UI');
    Self.PostToWebView('add_message', 'assistant', '**Error:** The provider returned empty ' +
        'response.', False, AActiveProvider, AActiveModel);
    Self.PostToWebView('append_message', 'assistant', '', True, AActiveProvider, AActiveModel);
    Exit;
  end;

  LAssistantMsg := TRadIAChatMessage.CreateMessage(mrAssistant, AFullResponse, AActiveProvider,
      AActiveModel);
  Self.FHistory := Self.FHistory + [LAssistantMsg];
  Self.SaveChatHistory;

  LUsage.PromptTokens := Length(APromptText) div 4;
  LUsage.CompletionTokens := Length(AFullResponse) div 4;
  LUsage.TotalTokens := LUsage.PromptTokens + LUsage.CompletionTokens;

  if LUsage.TotalTokens > 0 then
  begin
    Self.FAccumulatedUsage.PromptTokens := Self.FAccumulatedUsage.PromptTokens + LUsage.PromptTokens;
    Self.FAccumulatedUsage.CompletionTokens :=
      Self.FAccumulatedUsage.CompletionTokens + LUsage.CompletionTokens;

    Self.FAccumulatedUsage.TotalTokens := Self.FAccumulatedUsage.TotalTokens + LUsage.TotalTokens;

    if not Self.FConfig.IsWebLoginProvider(AActiveProvider) then
      Self.FConfig.AddToQuotaUsage(LUsage);

    LStats := Self.FAccumulatedUsage.FormatStats;
    if Self.FConfig.QuotaEnabled and (not Self.FConfig.IsWebLoginProvider(AActiveProvider)) then
    begin
      LStats := LStats + Format(' Â· Quota %d%%',
        [Round((Self.FConfig.QuotaUsed / Self.FConfig.QuotaLimit) * 100)]);
    end;

    Self.PostToWebView('update_tokens', '', LStats);
  end;

  Self.PostToWebView('append_message', 'assistant', '', True, AActiveProvider, AActiveModel);
end;

procedure TRadIAChatPresenter.SendPromptToAI(const APromptText: string);
var
  LUserMsg: IRadIAChatMessage;
  LFullResponse: string;
  LGuard: IRadIALifecycleGuard;
  LProfile: TAIRequestProfile;
  LDoneHandled: Boolean;
  LActiveProvider: string;
  LActiveModel: string;
  LSessionId: string;
begin
  if FConfig.QuotaEnabled and (not FConfig.IsWebLoginProvider(FConfig.GetActiveProvider)) then
  begin
    FConfig.Load;
    if FConfig.QuotaUsed >= FConfig.QuotaLimit then
    begin
      FView.ShowMessageDialog(Format('Could not send the request: monthly token quota exceeded (local ' +
          'limit of %s tokens reached).',
        [FormatFloat('#,##0', FConfig.QuotaLimit, TFormatSettings.Invariant)]));
      Exit;
    end;
  end;

  LDoneHandled := False;
  FRequestInProgress := True;
  FCancelledByUser := False;
  FView.SetRequestState(True);

  LActiveProvider := FConfig.GetActiveProvider;
  LActiveModel := FConfig.GetActiveModel(LActiveProvider);
  if FConfig.IsWebLoginProvider(LActiveProvider) then
    LActiveModel := 'Web Login';
  LSessionId := FSessionManager.ActiveSessionId;

  TLogger.Log(Format('SendPromptToAI started. Provider=%s, Model=%s, PromptLength=%d, Session=%s',
    [LActiveProvider, LActiveModel, Length(APromptText), LSessionId]), 'UI');

  LProfile := rpGeneralChat;
  if APromptText.StartsWith('/refactor', True) or APromptText.StartsWith('/optimize', True) then
    LProfile := rpRefactorCode
  else if APromptText.StartsWith('/bugs', True) or APromptText.StartsWith('Perform a comprehensive static ' +
      'analysis', True) then
    LProfile := rpFindBugs
  else if APromptText.StartsWith('/test', True) then
    LProfile := rpGenerateTests
  else if APromptText.StartsWith('/explain', True) or APromptText.StartsWith('/doc',
      True) or APromptText.StartsWith('/fix',
      True) or APromptText.StartsWith('Analyze the following Delphi stack trace', True) then
    LProfile := rpExplainCode;

  LUserMsg := TRadIAChatMessage.CreateMessage(mrUser, APromptText, LActiveProvider, LActiveModel);
  FHistory := FHistory + [LUserMsg];
  SaveChatHistory;

  LFullResponse := '';
  LGuard := FLifecycleGuard as IRadIALifecycleGuard;

  PostToWebView('show_typing', '', '');

  try
    FAIService.SendPromptStream(APromptText, FHistory,
      procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
      begin
        TThread.Queue(nil,
          TThreadProcedure(
          procedure
          begin
            if LDoneHandled then
              Exit;

            if not LGuard.IsAlive then
              Exit;

            if not SameText(Self.FSessionManager.ActiveSessionId, LSessionId) then
            begin
              Self.HandleStreamSessionChange(AIsDone, LSessionId, LFullResponse, LActiveProvider, LActiveModel);
              Exit;
            end;

            if Self.FCancelledByUser then
            begin
              LDoneHandled := True;
              Self.HandleStreamCancel(LActiveProvider, LActiveModel, LFullResponse);
              Exit;
            end;

            if not AError.IsEmpty then
            begin
              LDoneHandled := True;
              Self.HandleStreamError(AError, LActiveProvider, LActiveModel, LFullResponse);
              Exit;
            end;

            if not AChunk.IsEmpty then
            begin
              LFullResponse := LFullResponse + AChunk;
              if not Self.FConfig.IsWebLoginProvider(LActiveProvider) then
                Self.PostToWebView('append_message', 'assistant', AChunk, False, LActiveProvider, LActiveModel);
            end;

            if AIsDone then
            begin
              LDoneHandled := True;
              Self.HandleStreamDone(APromptText, LActiveProvider, LActiveModel, LFullResponse);
            end;
          end));
      end, LProfile);
  except
    on E: Exception do
    begin
      FRequestInProgress := False;
      FView.SetRequestState(False);
      PostToWebView('add_message', 'assistant', '**Error:** ' + E.Message, False, LActiveProvider, LActiveModel);
      PostToWebView('append_message', 'assistant', '', True, LActiveProvider, LActiveModel);
    end;
  end;
end;

procedure TRadIAChatPresenter.CancelRequest;
begin
  if FRequestInProgress then
  begin
    FCancelledByUser := True;
    TLogger.Log('CancelRequest: User requested cancellation.', 'UI');
    FView.SetRequestState(False);
    FAIService.CancelCurrentRequest;
  end;
end;


procedure TRadIAChatPresenter.HandleGenerateDTOCancel;
begin
  Self.FRequestInProgress := False;
  Self.FView.SetRequestState(False);
  Self.PostToWebView('append_generator_code', '', ' [Cancelled by user]', True);
end;

procedure TRadIAChatPresenter.HandleGenerateDTOError(const AError: string);
begin
  Self.FRequestInProgress := False;
  Self.FView.SetRequestState(False);
  Self.PostToWebView('append_generator_code', '', #13#10 + '// Error: ' + AError, True);
end;

procedure TRadIAChatPresenter.HandleGenerateDTODone(const APromptText, AActiveProvider: string);
var
  LUsage: TTokenUsage;
  LStats: string;
begin
  Self.FRequestInProgress := False;
  Self.FView.SetRequestState(False);

  LUsage.PromptTokens := Length(APromptText) div 4;
  LUsage.CompletionTokens := 1000;
  LUsage.TotalTokens := LUsage.PromptTokens + LUsage.CompletionTokens;

  if LUsage.TotalTokens > 0 then
  begin
    if not Self.FConfig.IsWebLoginProvider(AActiveProvider) then
      Self.FConfig.AddToQuotaUsage(LUsage);
    LStats := Self.FAccumulatedUsage.FormatStats;
    if Self.FConfig.QuotaEnabled and (not Self.FConfig.IsWebLoginProvider(AActiveProvider)) then
      LStats := LStats + Format(' Â· Quota %d%%',
        [Round((Self.FConfig.QuotaUsed / Self.FConfig.QuotaLimit) * 100)]);
    Self.PostToWebView('update_tokens', '', LStats);
  end;

  Self.PostToWebView('append_generator_code', '', '', True);
end;

procedure TRadIAChatPresenter.GenerateDTO(const AInput, AInputType, AOutputType: string);
var
  LPromptText: string;
  LGuard: IRadIALifecycleGuard;
  LDoneHandled: Boolean;
  LActiveProvider: string;
  LActiveModel: string;
begin
  if FConfig.QuotaEnabled and (not FConfig.IsWebLoginProvider(FConfig.GetActiveProvider)) then
  begin
    FConfig.Load;
    if FConfig.QuotaUsed >= FConfig.QuotaLimit then
    begin
      FView.ShowMessageDialog(Format('Could not send the request: monthly token quota exceeded (local ' +
          'limit of %s tokens reached).',
        [FormatFloat('#,##0', FConfig.QuotaLimit, TFormatSettings.Invariant)]));
      Exit;
    end;
  end;

  LDoneHandled := False;
  FRequestInProgress := True;
  FCancelledByUser := False;
  FView.SetRequestState(True);

  LActiveProvider := FConfig.GetActiveProvider;
  LActiveModel := FConfig.GetActiveModel(LActiveProvider);

  TLogger.Log(Format('GenerateDTO started. Provider=%s, Model=%s, InputLength=%d, InputType=%s, OutputType=%s',
    [LActiveProvider, LActiveModel, Length(AInput), AInputType, AOutputType]), 'UI');

  LPromptText := FDTOBuilder.BuildPrompt(AInput, AInputType, AOutputType);
  LGuard := FLifecycleGuard as IRadIALifecycleGuard;

  try
    FAIService.SendPromptStream(LPromptText, [],
      procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
      begin
        TThread.Queue(nil,
          TThreadProcedure(
          procedure
          begin
            if LDoneHandled then
              Exit;

            if not LGuard.IsAlive then
              Exit;

            if Self.FCancelledByUser then
            begin
              LDoneHandled := True;
              Self.HandleGenerateDTOCancel;
              Exit;
            end;

            if not AError.IsEmpty then
            begin
              LDoneHandled := True;
              Self.HandleGenerateDTOError(AError);
              Exit;
            end;

            if not AChunk.IsEmpty then
            begin
              Self.PostToWebView('append_generator_code', '', AChunk, False);
            end;

            if AIsDone then
            begin
              LDoneHandled := True;
              Self.HandleGenerateDTODone(LPromptText, LActiveProvider);
            end;
          end));
      end, rpGeneralChat);
  except
    on E: Exception do
    begin
      FRequestInProgress := False;
      FView.SetRequestState(False);
      PostToWebView('append_generator_code', '', '// Error: ' + E.Message, True);
    end;
  end;
end;


procedure TRadIAChatPresenter.OnWebViewReady;
var
  LActiveProvider: string;
begin
  FWebViewReady := True;
  FView.ApplyCurrentTheme;
  SendInitialConfigToWeb;

  if FRequestInProgress then
  begin
    FView.SetRequestState(True);
    PostToWebView('show_typing', '', '');
  end;

  LActiveProvider := FConfig.GetActiveProvider;
  if not GetWebLoginUrl(LActiveProvider).IsEmpty then
  begin
    TLogger.Log('OnWebViewReady: Pre-initializing background browser for Web Login provider.', 'UI');
    FView.CreateBackgroundBrowser;
  end;
end;

procedure TRadIAChatPresenter.QueueOnUI(const AProcedure: TProc);
begin
  if not Assigned(AProcedure) then
    Exit;

  TThread.ForceQueue(nil,
    TThreadProcedure(
    procedure
    begin
      AProcedure;
    end));
end;

procedure TRadIAChatPresenter.HandleInsertCodeMessage(const ACode: string);
begin
  QueueOnUI(
    procedure
    begin
      FView.ReplaceActiveEditorText(ACode);
    end);
end;

procedure TRadIAChatPresenter.HandleReadyMessage;
begin
  QueueOnUI(
    procedure
    begin
      OnWebViewReady;
    end);
end;

procedure TRadIAChatPresenter.HandleNewChatMessage;
begin
  QueueOnUI(
    procedure
    begin
      CreateNewSession;
    end);
end;

procedure TRadIAChatPresenter.HandleLoadHistoryMessage;
begin
  QueueOnUI(
    procedure
    begin
      PostToWebView('clear_chat', '', '');
      LoadChatHistory;
      SendSessionsUpdateToWeb;
    end);
end;

procedure TRadIAChatPresenter.HandleToggleHistoryMessage;
begin
  QueueOnUI(
    procedure
    begin
      ToggleSessions;
    end);
end;

procedure TRadIAChatPresenter.HandleOpenSettingsMessage;
begin
  QueueOnUI(
    procedure
    begin
      OpenSettings;
    end);
end;

procedure TRadIAChatPresenter.HandleChangeProviderMessage(const AProvider: string);
begin
  QueueOnUI(
    procedure
    begin
      ChangeProvider(AProvider);
    end);
end;

procedure TRadIAChatPresenter.HandleChangeModelMessage(const AModel: string);
begin
  QueueOnUI(
    procedure
    begin
      ChangeModel(AModel);
    end);
end;

procedure TRadIAChatPresenter.HandleSelectSessionMessage(const ASessionId: string);
begin
  QueueOnUI(
    procedure
    begin
      SelectSession(ASessionId);
    end);
end;

procedure TRadIAChatPresenter.HandleRenameSessionMessage(const ASessionId, AName: string);
begin
  QueueOnUI(
    procedure
    begin
      RenameSession(ASessionId, AName);
    end);
end;

procedure TRadIAChatPresenter.HandleDeleteSessionMessage(const ASessionId: string);
begin
  QueueOnUI(
    procedure
    begin
      DeleteSession(ASessionId);
    end);
end;

procedure TRadIAChatPresenter.HandleWebLoginConnectMessage;
begin
  QueueOnUI(
    procedure
    begin
      HandleOnbtnWebLoginConnectClick;
    end);
end;

procedure TRadIAChatPresenter.HandleLoginCompleteMessage;
begin
  QueueOnUI(
    procedure
    begin
      FBackgroundBrowserReady := True;
      HandleBackgroundLoginComplete;
    end);
end;

procedure TRadIAChatPresenter.HandleErrorMessage(const AText: string);
begin
  QueueOnUI(
    procedure
    begin
      TRadIAWebViewBridgeProvider.ReceiveChunk('', True, AText);
    end);
end;

procedure TRadIAChatPresenter.HandleUpdateStreamMessage(const AText: string; const AIsDone: Boolean);
begin
  QueueOnUI(
    procedure
    var
      LActiveProvider: string;
      LActiveModel: string;
    begin
      LActiveProvider := FConfig.GetActiveProvider;
      LActiveModel := FConfig.GetActiveModel(LActiveProvider);
      if FConfig.IsWebLoginProvider(LActiveProvider) then
        LActiveModel := 'Web Login';

      PostToWebView('update_message', 'assistant', AText, AIsDone, LActiveProvider, LActiveModel);

      if AIsDone then
        TRadIAWebViewBridgeProvider.ReceiveChunk(AText, True, '');
    end);
end;

procedure TRadIAChatPresenter.HandleSendPromptMessage(const AText: string);
begin
  QueueOnUI(
    procedure
    begin
      SendPromptText(AText);
    end);
end;

procedure TRadIAChatPresenter.HandleGenerateDTOMessage(const AInput, AInputType, AOutputType: string);
begin
  QueueOnUI(
    procedure
    begin
      GenerateDTO(AInput, AInputType, AOutputType);
    end);
end;

procedure TRadIAChatPresenter.HandleCreateProjectMessage(const AFilesJson: string);
begin
  QueueOnUI(
    procedure
    var
      LErrorMsg: string;
    begin
      if not AFilesJson.IsEmpty then
      begin
        if not FProjectGenerator.GenerateFromJSON(AFilesJson, LErrorMsg) then
        begin
          if not LErrorMsg.IsEmpty then
            FView.ShowMessageDialog(LErrorMsg);
        end;
      end
      else
      begin
        FView.ShowMessageDialog('No files data received.');
      end;
    end);
end;

procedure TRadIAChatPresenter.HandleCancelRequestMessage;
begin
  QueueOnUI(
    procedure
    begin
      CancelRequest;
    end);
end;

procedure TRadIAChatPresenter.HandleClearChatMessage;
begin
  QueueOnUI(
    procedure
    begin
      ClearChat;
    end);
end;

procedure TRadIAChatPresenter.HandleStreamChunkMessage(const AText: string; const AIsDone: Boolean;
    const AError: string);
begin
  QueueOnUI(
    procedure
    begin
      TRadIAWebViewBridgeProvider.ReceiveChunk(AText, AIsDone, AError);
    end);
end;

procedure TRadIAChatPresenter.DispatchWebMessage(const AAction: string; const AJson: TJSONObject);
var
  LFiles: TJSONArray;
begin
  if SameText(AAction, 'insert_code') or SameText(AAction, 'apply_code') then
    HandleInsertCodeMessage(AJson.GetValue<string>('code', ''))
  else if AAction = 'log' then
    TLogger.Log('JS Console: ' + AJson.GetValue<string>('text', ''), 'WebView')
  else if AAction = 'ready' then
    HandleReadyMessage
  else if (AAction = 'new_chat') or (AAction = 'new_session') then
    HandleNewChatMessage
  else if AAction = 'load_history' then
    HandleLoadHistoryMessage
  else if AAction = 'toggle_history' then
    HandleToggleHistoryMessage
  else if AAction = 'open_settings' then
    HandleOpenSettingsMessage
  else if AAction = 'change_provider' then
    HandleChangeProviderMessage(AJson.GetValue<string>('provider', ''))
  else if AAction = 'change_model' then
    HandleChangeModelMessage(AJson.GetValue<string>('model', ''))
  else if AAction = 'select_session' then
    HandleSelectSessionMessage(AJson.GetValue<string>('id', ''))
  else if AAction = 'rename_session' then
    HandleRenameSessionMessage(AJson.GetValue<string>('id', ''), AJson.GetValue<string>('name', ''))
  else if AAction = 'delete_session' then
    HandleDeleteSessionMessage(AJson.GetValue<string>('id', ''))
  else if AAction = 'web_login_connect' then
    HandleWebLoginConnectMessage
  else if SameText(AAction, 'login_complete') then
    HandleLoginCompleteMessage
  else if AAction = 'error' then
    HandleErrorMessage(AJson.GetValue<string>('text', ''))
  else if AAction = 'update_stream' then
    HandleUpdateStreamMessage(
      AJson.GetValue<string>('text', ''),
      AJson.GetValue<Boolean>('isDone', False))
  else if AAction = 'send_prompt' then
    HandleSendPromptMessage(AJson.GetValue<string>('text', ''))
  else if AAction = 'generate_dto' then
    HandleGenerateDTOMessage(
      AJson.GetValue<string>('input', ''),
      AJson.GetValue<string>('inputType', ''),
      AJson.GetValue<string>('outputType', ''))
  else if AAction = 'create_project' then
  begin
    LFiles := AJson.GetValue('files') as TJSONArray;
    if Assigned(LFiles) then
      HandleCreateProjectMessage(LFiles.ToJSON)
    else
      HandleCreateProjectMessage('');
  end
  else if AAction = 'cancel_request' then
    HandleCancelRequestMessage
  else if AAction = 'clear_chat' then
    HandleClearChatMessage
  else if AAction = 'stream_chunk' then
    HandleStreamChunkMessage(
      AJson.GetValue<string>('text', ''),
      AJson.GetValue<Boolean>('isDone', False),
      AJson.GetValue<string>('error', ''));
end;

procedure TRadIAChatPresenter.ProcessWebMessage(const AMessage: string);
var
  LParsed: TJSONValue;
  LNestedParsed: TJSONValue;
  LJson: TJSONObject;
  LAction: string;
  LMessage: string;
begin
  TLogger.Log('ProcessWebMessage raw: ' + AMessage, 'UI');
  LMessage := AMessage.Trim;
  LParsed := TJSONObject.ParseJSONValue(LMessage);
  if not Assigned(LParsed) then
    Exit;

  try
    if LParsed is TJSONString then
    begin
      LNestedParsed := TJSONObject.ParseJSONValue(TJSONString(LParsed).Value);
      if Assigned(LNestedParsed) then
      begin
        LParsed.Free;
        LParsed := LNestedParsed;
      end;
    end;

    if not (LParsed is TJSONObject) then
      Exit;

    LJson := TJSONObject(LParsed);
    LAction := LJson.GetValue<string>('action', '');
    DispatchWebMessage(LAction, LJson);
  finally
    LParsed.Free;
  end;
end;

procedure TRadIAChatPresenter.OnWebViewBridgeSendPrompt(const APrompt: string);
var
  LJson: TJSONObject;
  LActiveProvider: string;
  LUrl: string;
begin
  LActiveProvider := FConfig.GetActiveProvider;
  LUrl := GetWebLoginUrl(LActiveProvider);
  if LUrl.IsEmpty then
  begin
    TLogger.Log('OnWebViewBridgeSendPrompt: Active provider ' + LActiveProvider + ' does not support Web Login.', 'UI');
    Exit;
  end;

  if not FView.IsBackgroundBrowserInitialized then
  begin
    TLogger.Log('OnWebViewBridgeSendPrompt: Background browser is not initialized yet. Queueing prompt ' +
        'and initializing...', 'UI');
    FPendingPrompt := APrompt;
    FBackgroundBrowserReady := False;
    FView.CreateBackgroundBrowser;
    Exit;
  end;

  if not SameText(FCurrentBackgroundUrl, LUrl) then
  begin
    TLogger.Log(Format('OnWebViewBridgeSendPrompt: Navigating background browser to %s', [LUrl]), 'UI');
    FPendingPrompt := APrompt;
    FBackgroundBrowserReady := False;
    FCurrentBackgroundUrl := LUrl;
    FView.NavigateBackgroundBrowser(LUrl);
    Exit;
  end;

  if not FBackgroundBrowserReady then
  begin
    TLogger.Log('OnWebViewBridgeSendPrompt: Background browser is navigating/loading. Queueing prompt.', 'UI');
    FPendingPrompt := APrompt;
    Exit;
  end;

  TLogger.Log('OnWebViewBridgeSendPrompt: Dispatching prompt to background web view.', 'UI');
  FPendingPrompt := '';
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'send_prompt');

    var LFinalPrompt := APrompt;
    if not LFinalPrompt.Trim.IsEmpty then
    begin
      var LAdapter: IRadIAIDEAdapter;
      var LInstruction: string := '';
      if TRadIAContainer.TryResolve<IRadIAIDEAdapter>(LAdapter) then
        LInstruction := LAdapter.GetPreferredLanguageInstruction;
      if not LInstruction.IsEmpty then
        LFinalPrompt := LFinalPrompt + sLineBreak + sLineBreak + LInstruction;
    end;

    LJson.AddPair('text', LFinalPrompt);
    FView.PostMessageToBackgroundWeb(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

procedure TRadIAChatPresenter.OnWebViewBridgeCancel;
var
  LJson: TJSONObject;
begin
  if not FView.IsBackgroundBrowserInitialized then
    Exit;

  TLogger.Log('OnWebViewBridgeCancel: Dispatching cancellation to background web view.', 'UI');
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'cancel_request');
    FView.PostMessageToBackgroundWeb(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

procedure TRadIAChatPresenter.OnBackgroundBrowserMessage(const AMessage: string);
begin
  ProcessWebMessage(AMessage);
end;

procedure TRadIAChatPresenter.OnBackgroundBrowserInitialized;
var
  LActiveProvider: string;
  LUrl: string;
begin
  LActiveProvider := FConfig.GetActiveProvider;
  LUrl := GetWebLoginUrl(LActiveProvider);
  if LUrl.IsEmpty then
    Exit;

  TLogger.Log(Format('OnBackgroundBrowserInitialized: Background browser created. Navigating to %s', [LUrl]), 'UI');
  FBackgroundBrowserReady := False;
  FCurrentBackgroundUrl := LUrl;
  FView.NavigateBackgroundBrowser(LUrl);
end;

procedure TRadIAChatPresenter.HandleBackgroundLoginComplete;
begin
  TLogger.Log('HandleBackgroundLoginComplete: Background browser is logged in and ready.', 'UI');
  if not FPendingPrompt.IsEmpty then
  begin
    TLogger.Log('HandleBackgroundLoginComplete: Dispatching pending prompt.', 'UI');
    OnWebViewBridgeSendPrompt(FPendingPrompt);
  end;
end;

procedure TRadIAChatPresenter.OnBackgroundBrowserNavigation(const AUrl: string);
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
    TLogger.Log('OnBackgroundBrowserNavigation: Auth page redirect detected. URL: ' + AUrl, 'UI');
    TThread.Queue(nil,
      procedure
      begin
        HandleOnbtnWebLoginConnectClick;
      end);
  end;
end;

procedure TRadIAChatPresenter.HandleOnbtnWebLoginConnectClick;
var
  LActiveProvider: string;
  LUrl: string;
begin
  if FLoginPopupOpen then
  begin
    TLogger.Log('HandleOnbtnWebLoginConnectClick: Login popup is already open. Ignoring request.', 'UI');
    Exit;
  end;

  LActiveProvider := FConfig.GetActiveProvider;
  LUrl := GetWebLoginUrl(LActiveProvider);
  if LUrl.IsEmpty then
    Exit;

  TLogger.Log('HandleOnbtnWebLoginConnectClick: Opening popup form for ' + LActiveProvider, 'UI');

  FLoginPopupOpen := True;
  try
    FView.ShowLoginWindow(LUrl,
      procedure
      begin
        FLoginPopupOpen := False;
        TLogger.Log('HandleOnbtnWebLoginConnectClick: Login completed successfully. Refreshing background ' +
            'browser.', 'UI');
        FConfig.SetProviderAuthType(LActiveProvider, 'web_login');
        FConfig.Save;
        FView.NavigateBackgroundBrowser(LUrl);
      end);
  except
    on E: Exception do
    begin
      FLoginPopupOpen := False;
      TLogger.Log('HandleOnbtnWebLoginConnectClick: Error showing login window: ' + E.Message, 'UI');
    end;
  end;
end;


function TRadIAChatPresenter.ExtractCodeArgument(const AArgument: string): string;
var
  LText: string;
  LFenceStart: Integer;
  LCodeStart: Integer;
  LFenceEnd: Integer;
begin
  Result := AArgument.Trim;
  LText := AArgument.Replace(#13#10, #10).Replace(#13, #10);
  LFenceStart := Pos('```', LText);
  if LFenceStart <= 0 then
    Exit;

  LCodeStart := PosEx(#10, LText, LFenceStart + 3);
  if LCodeStart <= 0 then
    Exit;

  Inc(LCodeStart);
  LFenceEnd := PosEx('```', LText, LCodeStart);
  if LFenceEnd > 0 then
    Result := Copy(LText, LCodeStart, LFenceEnd - LCodeStart).TrimRight
  else
    Result := Copy(LText, LCodeStart, MaxInt).TrimRight;
end;

function TRadIAChatPresenter.FindTemplateForCommand(const ACommand, AArgument: string; out ATemplate: TPromptTemplate): Boolean;
var
  LTemp: TPromptTemplate;
  LFallbackNames: TArray<string>;
  LFallbackCommands: TArray<string>;
  I: Integer;
begin
  if not ACommand.StartsWith('/') then
    Exit(False);

  if SameText(ACommand, '/template') then
  begin
    if not AArgument.IsEmpty then
      Exit(FTemplateManager.FindTemplate(AArgument, ATemplate));
    Exit(False);
  end;

  for LTemp in FTemplateManager.GetTemplates do
  begin
    if SameText(LTemp.SlashCommand, ACommand) then
    begin
      ATemplate := LTemp;
      Exit(True);
    end;
  end;

  LFallbackCommands := ['/review', '/explain', '/refactor', '/optimize'];
  LFallbackNames := ['Review Leaks and SOLID', 'Explain Code', 'Review Clean Code Delphi', 'Analyze Performance'];

  for I := Low(LFallbackCommands) to High(LFallbackCommands) do
  begin
    if SameText(ACommand, LFallbackCommands[I]) then
      Exit(FTemplateManager.FindTemplate(LFallbackNames[I], ATemplate));
  end;

  Result := False;
end;

function TRadIAChatPresenter.PreProcessPrompt(const APromptText: string): string;
var
  LActiveCode: string;
  LTemplate: TPromptTemplate;
  LFound: Boolean;
  LCommand: string;
  LArgument: string;
  LFirstSeparator: Integer;
  I: Integer;
begin
  Result := APromptText;
  LActiveCode := '';

  LCommand := Trim(APromptText);
  LArgument := '';
  LFirstSeparator := -1;
  for I := Low(APromptText) to High(APromptText) do
  begin
    if CharInSet(APromptText[I], [#9, #10, #13, ' ']) then
    begin
      LFirstSeparator := I - 1;
      Break;
    end;
  end;

  if LFirstSeparator > 0 then
  begin
    LCommand := APromptText.Substring(0, LFirstSeparator).Trim;
    LArgument := APromptText.Substring(LFirstSeparator + 1).Trim;
  end;

  LFound := FindTemplateForCommand(LCommand, LArgument, LTemplate);

  if LFound then
  begin
    Result := LTemplate.Template;

    if Result.Contains('{code}') then
    begin
      if not LArgument.IsEmpty then
        LActiveCode := ExtractCodeArgument(LArgument);

      if LActiveCode.IsEmpty then
      begin
        if not FView.GetActiveEditorText(LActiveCode, True) or LActiveCode.IsEmpty then
          FView.GetActiveEditorText(LActiveCode, False);
      end;

      Result := Result.Replace('{code}', LActiveCode);
    end;

    if Result.Contains('{specification}') then
      Result := Result.Replace('{specification}', LArgument)
    else if Result.Contains('{stacktrace}') then
      Result := Result.Replace('{stacktrace}', LArgument)
    else if Result.Contains('{argument}') then
      Result := Result.Replace('{argument}', LArgument);
  end;
end;

{$IFDEF TESTS}
function TRadIAChatPresenter.TestPreProcessPrompt(const APromptText: string): string;
begin
  Result := PreProcessPrompt(APromptText);
end;
{$ENDIF}

procedure TRadIAChatPresenter.LoadChatHistory;
var
  LMsg: IRadIAChatMessage;
begin
  FHistory := [];
  if FSessionManager.ActiveSessionId.IsEmpty then
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

procedure TRadIAChatPresenter.SaveChatHistory;
begin
  if FSessionManager.ActiveSessionId.IsEmpty then
    Exit;

  try
    FSessionManager.SaveSessionHistory(FSessionManager.ActiveSessionId, FHistory);
    TLogger.Log('SaveChatHistory: History saved successfully for session ' + FSessionManager.ActiveSessionId, 'UI');
  except
    on E: Exception do
      TLogger.Log(Format('SaveChatHistory write exception: %s', [E.Message]), 'UI');
  end;
end;

procedure TRadIAChatPresenter.LoadPromptHistory;
var
  LHistoryFile: string;
begin
  LHistoryFile := TPath.Combine(FDataDir, 'prompt_history.json');
  FPromptHistoryManager.LoadFromFile(LHistoryFile);
end;

procedure TRadIAChatPresenter.SavePromptHistory;
var
  LHistoryFile: string;
begin
  LHistoryFile := TPath.Combine(FDataDir, 'prompt_history.json');
  FPromptHistoryManager.SaveToFile(LHistoryFile);
end;

procedure TRadIAChatPresenter.UpdateSessionsList;
var
  LSessionsArray: TArray<TSessionInfo>;
begin
  if FSessionManager.Sessions.Count = 0 then
  begin
    FSessionManager.CreateSession('Initial Chat');
  end;

  LSessionsArray := FSessionManager.Sessions.ToArray;

  if FSessionManager.ActiveSessionId.IsEmpty and (Length(LSessionsArray) > 0) then
  begin
    FSessionManager.ActiveSessionId := LSessionsArray[0].Id;
    FConfig.ActiveSessionId := FSessionManager.ActiveSessionId;
    FConfig.Save;
  end;

  FView.UpdateSessions(GetVisibleSessions, FSessionManager.ActiveSessionId);
end;

function TRadIAChatPresenter.GetVisibleSessions: TArray<TSessionInfo>;
var
  LSession: TSessionInfo;
begin
  Result := [];
  for LSession in FSessionManager.Sessions do
  begin
    if SameText(LSession.Id, FSessionManager.ActiveSessionId) or
       FSessionManager.SessionHasHistory(LSession.Id) then
      Result := Result + [LSession];
  end;
end;

procedure TRadIAChatPresenter.PostToWebView(const AAction, ARole, AText: string;
    const AProvider: string; const AModel: string);
begin
  PostToWebView(AAction, ARole, AText, False, AProvider, AModel);
end;

procedure TRadIAChatPresenter.PostToWebView(const AAction, ARole, AText: string;
    const AIsDone: Boolean; const AProvider: string; const AModel: string);
var
  LJson: TJSONObject;
  LDisplayModel: string;
begin
  if not FWebViewReady then
    Exit;

  LDisplayModel := AModel;
  if (not AProvider.IsEmpty) and FConfig.IsWebLoginProvider(AProvider) then
    LDisplayModel := 'Web Login';

  TLogger.Log(Format('PostToWebView: Action=%s, Role=%s, TextLen=%d, IsDone=%s, Provider=%s, Model=%s',
    [AAction, ARole, Length(AText), BoolToStr(AIsDone, True), AProvider, LDisplayModel]), 'UI');

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
    if not LDisplayModel.IsEmpty then
      LJson.AddPair('model', LDisplayModel);

    FView.PostMessageToWeb(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

procedure TRadIAChatPresenter.SendInitialConfigToWeb;
var
  LJson: TJSONObject;
  LActiveProvider: string;
  LActiveModel: string;
  LIsWebLogin: Boolean;
begin
  if not FWebViewReady then Exit;

  LActiveProvider := FConfig.GetActiveProvider;
  LIsWebLogin := FConfig.IsWebLoginProvider(LActiveProvider);

  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'initialize_config');
    LJson.AddPair('providers', BuildProvidersJsonArray);
    LJson.AddPair('models', BuildModelsJsonArray(LActiveProvider, LIsWebLogin, LActiveModel));
    LJson.AddPair('slashCommands', BuildSlashCommandsJsonArray);
    LJson.AddPair('activeProvider', LActiveProvider);
    LJson.AddPair('activeModel', LActiveModel);
    LJson.AddPair('isWebLogin', TJSONBool.Create(LIsWebLogin));

    FView.PostMessageToWeb(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

procedure TRadIAChatPresenter.SendModelsUpdateToWeb(const AModels: TArray<string>; const AActiveModel: string);
var
  LJson: TJSONObject;
  LModels: TJSONArray;
  LModel: string;
begin
  if not FWebViewReady then Exit;

  LJson := TJSONObject.Create;
  LModels := TJSONArray.Create;
  try
    for LModel in AModels do
    begin
      LModels.Add(LModel);
    end;

    LJson.AddPair('action', 'update_models');
    LJson.AddPair('models', LModels);
    LJson.AddPair('activeModel', AActiveModel);

    FView.PostMessageToWeb(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

procedure TRadIAChatPresenter.SendSessionsUpdateToWeb;
var
  LJson: TJSONObject;
  LArr: TJSONArray;
  LSession: TSessionInfo;
  LObj: TJSONObject;
begin
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'update_sessions');
    LArr := TJSONArray.Create;
    for LSession in GetVisibleSessions do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('id', LSession.Id);
      LObj.AddPair('name', LSession.Name);
      LObj.AddPair('isActive', TJSONBool.Create(SameText(LSession.Id, FSessionManager.ActiveSessionId)));
      LArr.AddElement(LObj);
    end;
    LJson.AddPair('sessions', LArr);
    LJson.AddPair('activeSessionId', FSessionManager.ActiveSessionId);
    FView.PostMessageToWeb(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

end.
