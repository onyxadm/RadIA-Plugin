unit RadIA.UI.ChatPresenter;

interface

uses
  System.SysUtils, System.Classes, System.JSON, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.Sessions, RadIA.Core.PromptTemplates,
  RadIA.Core.TokenUsage, RadIA.Core.PromptHistory, RadIA.Core.Service;

type
  IChatView = interface
    ['{8A5FC9BC-0D5C-4F7F-9ED6-9D7CC5EF5E18}']
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

  TChatPresenter = class
  private
    FView: IChatView;
    FConfig: IAIConfig;
    FAIService: TRadIAService;
    FSessionManager: TRadIASessionManager;
    FPromptHistoryManager: TPromptHistoryManager;
    FTemplateManager: TPromptTemplateManager;
    FAccumulatedUsage: TTokenUsage;
    FHistory: TArray<IChatMessage>;
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
    FModelsProvider: IIAProvider;

    procedure HandleBackgroundLoginComplete;
    procedure UpdateModelsCombo;
    procedure LoadChatHistory;
    procedure SaveChatHistory;
    procedure LoadPromptHistory;
    procedure SavePromptHistory;
    procedure UpdateSessionsList;
    function PreProcessPrompt(const APromptText: string): string;
    function IsProviderConfigured(const AProviderId: string): Boolean;
    function GetWebLoginUrl(const AProvider: string): string;

    procedure SendInitialConfigToWeb;
    procedure SendModelsUpdateToWeb(const AModels: TArray<string>; const AActiveModel: string);
    procedure SendSessionsUpdateToWeb;
    procedure PostToWebView(const AAction, ARole, AText: string; const AProvider: string = ''; const AModel: string = ''); overload;
    procedure PostToWebView(const AAction, ARole, AText: string; const AIsDone: Boolean; const AProvider: string = ''; const AModel: string = ''); overload;
    
    procedure HandleOnbtnWebLoginConnectClick;
  public
    constructor Create(const AView: IChatView; const AConfig: IAIConfig = nil; const AService: TRadIAService = nil);
    destructor Destroy; override;

    procedure Initialize(const AWebFilesDir: string);
    procedure LoadConfig;
    procedure ProcessWebMessage(const AMessage: string);
    procedure OnWebViewReady;
    
    procedure SendPrompt;
    procedure SendPromptText(const APromptText: string);
    procedure SendPromptToAI(const APromptText: string);
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

    procedure OnWebViewBridgeSendPrompt(const APrompt: string);
    procedure OnWebViewBridgeCancel;
    procedure OnBackgroundBrowserMessage(const AMessage: string);
    procedure OnBackgroundBrowserInitialized;
    procedure OnBackgroundBrowserNavigation(const AUrl: string);

    property RequestInProgress: Boolean read FRequestInProgress;
    property SessionManager: TRadIASessionManager read FSessionManager;
    property TemplateManager: TPromptTemplateManager read FTemplateManager;
    property WebViewReady: Boolean read FWebViewReady write FWebViewReady;
  end;

implementation

uses
  System.IOUtils, System.JSON.Builders, RadIA.Core.Config, RadIA.Core.Logger,
  RadIA.Core.ProviderRegistry, RadIA.Core.ConversationExporter,
  RadIA.Core.DTO.Generator, RadIA.Core.ProjectGenerator, RadIA.Provider.WebViewBridge, RadIA.OTA.Helper,
  System.SyncObjs;

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

{ TChatPresenter }

constructor TChatPresenter.Create(const AView: IChatView; const AConfig: IAIConfig; const AService: TRadIAService);
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
  else
    FConfig := TRadIAConfig.GetInstance;

  if Assigned(AService) then
  begin
    FAIService := AService;
    FOwnsService := False;
  end
  else
  begin
    FAIService := TRadIAService.Create(FConfig);
    FOwnsService := True;
  end;

  FPromptHistoryManager := TPromptHistoryManager.Create;
  FAccumulatedUsage := TTokenUsage.Empty;
  FTemplateManager := TPromptTemplateManager.Create;
  FTemplateManager.Load;
  
  FSessionManager := TRadIASessionManager.Create;
  FSessionManager.ActiveSessionId := FConfig.ActiveSessionId;
end;

destructor TChatPresenter.Destroy;
begin
  if Assigned(FModelsProvider) then
  begin
    try
      FModelsProvider.CancelCurrentRequest;
    except
      // Silencia
    end;
    FModelsProvider := nil;
  end;

  TRadIAWebViewBridgeProvider.OnSendPrompt := nil;
  TRadIAWebViewBridgeProvider.OnCancel := nil;

  if Assigned(FLifecycleGuard) then
    (FLifecycleGuard as ILifecycleGuard).Invalidate;

  if Assigned(FAIService) then
    FAIService.CancelCurrentRequest;

  FPromptHistoryManager.Free;
  FTemplateManager.Free;
  FSessionManager.Free;
  
  if FOwnsService and Assigned(FAIService) then
    FreeAndNil(FAIService);

  inherited Destroy;
end;

procedure TChatPresenter.Initialize(const AWebFilesDir: string);
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

function TChatPresenter.IsProviderConfigured(const AProviderId: string): Boolean;
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

    if SameText(FConfig.GetProviderAuthType(AProviderId), 'web_login') then
      Exit(True);

    Result := not FConfig.GetApiKey(AProviderId).Trim.IsEmpty;
  end;
end;

function TChatPresenter.GetWebLoginUrl(const AProvider: string): string;
begin
  if SameText(AProvider, 'Gemini') then
    Result := 'https://gemini.google.com'
  else if SameText(AProvider, 'OpenAI') then
    Result := 'https://chatgpt.com'
  else
    Result := '';
end;


procedure TChatPresenter.LoadConfig;
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

procedure TChatPresenter.UpdateModelsCombo;
var
  LProvider: IIAProvider;
  LGuard: ILifecycleGuard;
begin
  FView.UpdateModels(['Loading...'], 'Loading...', False);
  LGuard := FLifecycleGuard as ILifecycleGuard;
 
  try
    if Assigned(FModelsProvider) then
    begin
      try
        FModelsProvider.CancelCurrentRequest;
      except
        // Silencia
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
          var
            LActiveModel: string;
            LProvId: string;
          begin
            if not LGuard.IsAlive then
              Exit;
              
            if FModelsProvider = LProvider then
              FModelsProvider := nil;
 
            if Assigned(LProvider) then
            begin
              Self.FActiveModels := AModels;
              LProvId := LProvider.GetProviderId;
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

procedure TChatPresenter.ChangeProvider(const AProviderName: string);
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

procedure TChatPresenter.ChangeModel(const AModelName: string);
var
  LSelectedProvider: string;
begin
  if FLoadingConfig then
    Exit;

  LSelectedProvider := FConfig.GetActiveProvider;
  FConfig.SetActiveModel(LSelectedProvider, AModelName);
  FConfig.Save;
end;

procedure TChatPresenter.ClearChat;
begin
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
      // Ignore write errors
    end;
  end;
end;

procedure TChatPresenter.ToggleSessions;
begin
  FView.ToggleSessionsPanel;
end;

procedure TChatPresenter.CreateNewSession;
begin
  FSessionManager.CreateSession('Conversa Inicial');
  UpdateSessionsList;
  SendSessionsUpdateToWeb;
end;

procedure TChatPresenter.RenameSession(const ASessionId, ANewName: string);
begin
  if not ANewName.Trim.IsEmpty then
  begin
    FSessionManager.RenameSession(ASessionId, ANewName);
    UpdateSessionsList;
    SendSessionsUpdateToWeb;
  end;
end;

procedure TChatPresenter.DeleteSession(const ASessionId: string);
begin
  if FRequestInProgress and SameText(FSessionManager.ActiveSessionId, ASessionId) then
  begin
    FCancelledByUser := True;
    FAIService.CancelCurrentRequest;
    FRequestInProgress := False;
    FView.SetRequestState(False);
  end;

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

procedure TChatPresenter.SelectSession(const ASessionId: string);
begin
  if FRequestInProgress then
  begin
    FCancelledByUser := True;
    FAIService.CancelCurrentRequest;
    FRequestInProgress := False;
    FView.SetRequestState(False);
  end;
  
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

procedure TChatPresenter.ExportChat;
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

procedure TChatPresenter.OpenSettings;
begin
  FView.OpenSettingsDialog;
  FConfig.Load;
  LoadConfig;
  
  FTemplateManager.Load;
  Initialize(FWebFilesDir);
end;

procedure TChatPresenter.HandlePromptInputKeyDown(var Key: Word; const Shift: TShiftState);
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

procedure TChatPresenter.HandleTemplateSelected(const ATemplateName: string);
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

procedure TChatPresenter.HandleGlobalPromptRequest(const APrompt: string; const AOpenChat: Boolean);
begin
  PostToWebView('add_message', 'user', APrompt);
  SendPromptToAI(APrompt);
end;

procedure TChatPresenter.SendPrompt;
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

procedure TChatPresenter.SendPromptText(const APromptText: string);
var
  LProcessed: string;
begin
  LProcessed := PreProcessPrompt(APromptText);
  PostToWebView('add_message', 'user', APromptText);
  SendPromptToAI(LProcessed);
end;

procedure TChatPresenter.SendPromptToAI(const APromptText: string);
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
      FView.ShowMessageDialog(Format('Não foi possível enviar a requisição: Cota mensal de tokens excedida (limite local de %s tokens atingido).',
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
  LSessionId := FSessionManager.ActiveSessionId;

  TLogger.Log(Format('SendPromptToAI started. Provider=%s, Model=%s, PromptLength=%d, Session=%s',
    [LActiveProvider, LActiveModel, Length(APromptText), LSessionId]), 'UI');

  LProfile := rpGeneralChat;
  if APromptText.StartsWith('/refactor', True) or APromptText.StartsWith('/optimize', True) then
    LProfile := rpRefactorCode
  else if APromptText.StartsWith('/bugs', True) or APromptText.StartsWith('Perform a comprehensive static analysis', True) then
    LProfile := rpFindBugs
  else if APromptText.StartsWith('/test', True) then
    LProfile := rpGenerateTests
  else if APromptText.StartsWith('/explain', True) or APromptText.StartsWith('/doc', True) or APromptText.StartsWith('/fix', True) or APromptText.StartsWith('Analyze the following Delphi stack trace', True) then
    LProfile := rpExplainCode;
  
  LUserMsg := TRadIAService.CreateMessage(mrUser, APromptText, LActiveProvider, LActiveModel);
  FHistory := FHistory + [LUserMsg];
  SaveChatHistory;

  LFullResponse := '';
  LGuard := FLifecycleGuard as ILifecycleGuard;
  
  PostToWebView('show_typing', '', '');
  
  try
    FAIService.SendPromptStream(APromptText, FHistory,
      procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
      begin
        TThread.Queue(nil,
          TThreadProcedure(
          procedure
          var
            LAssistantMsg: IChatMessage;
            LStats: string;
            LUsage: TTokenUsage;
          begin
            if LDoneHandled then
              Exit;

            if not LGuard.IsAlive then
              Exit;

            if not SameText(Self.FSessionManager.ActiveSessionId, LSessionId) then
            begin
              TLogger.Log(Format('SendPromptToAI: Session changed from %s to %s. Discarding UI callback.', [LSessionId, Self.FSessionManager.ActiveSessionId]), 'UI');
              if AIsDone and (not LFullResponse.IsEmpty) and (not GIsShuttingDown) then
              begin
                TInterlocked.Increment(GActiveThreadCount);
                TThread.CreateAnonymousThread(
                  procedure
                  var
                    LOrigHistory: TArray<IChatMessage>;
                    LAssistantMsg: IChatMessage;
                  begin
                    try
                      try
                        LOrigHistory := Self.FSessionManager.LoadSessionHistory(LSessionId);
                        LAssistantMsg := TRadIAService.CreateMessage(mrAssistant, LFullResponse, LActiveProvider, LActiveModel);
                        LOrigHistory := LOrigHistory + [LAssistantMsg];
                        Self.FSessionManager.SaveSessionHistory(LSessionId, LOrigHistory);
                      except
                      end;
                    finally
                      TInterlocked.Decrement(GActiveThreadCount);
                    end;
                  end).Start;
              end;
              Exit;
            end;

            if Self.FCancelledByUser then
            begin
              LDoneHandled := True;
              Self.FRequestInProgress := False;
              Self.FView.SetRequestState(False);
              TLogger.Log('SendPromptToAI: Handling user cancellation in UI callback.', 'UI');
              
              if not LFullResponse.IsEmpty then
              begin
                LAssistantMsg := TRadIAService.CreateMessage(mrAssistant, LFullResponse + ' [Cancelado pelo usuário]', LActiveProvider, LActiveModel);
                Self.FHistory := Self.FHistory + [LAssistantMsg];
                Self.SaveChatHistory;
              end;
              
              Self.PostToWebView('add_message', 'assistant', '*Requisicao cancelada pelo usuario.*', False, LActiveProvider, LActiveModel);
              Self.PostToWebView('append_message', 'assistant', '', True, LActiveProvider, LActiveModel);
              Exit;
            end;

            if not AError.IsEmpty then
            begin
              LDoneHandled := True;
              Self.FRequestInProgress := False;
              Self.FView.SetRequestState(False);
              TLogger.Log(Format('SendPromptToAI error callback: %s', [AError]), 'UI');
              
              if not LFullResponse.IsEmpty then
              begin
                LFullResponse := LFullResponse + #13#10#13#10 + '**Error:** ' + AError;
                Self.PostToWebView('append_message', 'assistant', #13#10#13#10 + '**Error:** ' + AError, True, LActiveProvider, LActiveModel);
                
                LAssistantMsg := TRadIAService.CreateMessage(mrAssistant, LFullResponse, LActiveProvider, LActiveModel);
                Self.FHistory := Self.FHistory + [LAssistantMsg];
                Self.SaveChatHistory;
              end
              else
              begin
                Self.PostToWebView('add_message', 'assistant', '**Error:** ' + AError, False, LActiveProvider, LActiveModel);
                Self.PostToWebView('append_message', 'assistant', '', True, LActiveProvider, LActiveModel);
              end;

              var LIsWebError := SameText(AError, 'WebView Login session is not ready or active.') or
                                 SameText(AError, 'Input textarea not found in page.') or
                                 SameText(AError, 'Send button not found in page.');
              if LIsWebError then
              begin
                Self.HandleOnbtnWebLoginConnectClick;
              end;

              Exit;
            end;

            if not AChunk.IsEmpty then
            begin
              LFullResponse := LFullResponse + AChunk;
              if not SameText(LActiveProvider, 'WebViewBridge') and not SameText(Self.FConfig.GetProviderAuthType(LActiveProvider), 'web_login') then
                Self.PostToWebView('append_message', 'assistant', AChunk, False, LActiveProvider, LActiveModel);
            end;

            if AIsDone then
            begin
              LDoneHandled := True;
              Self.FRequestInProgress := False;
              Self.FView.SetRequestState(False);
              TLogger.Log(Format('SendPromptToAI completed. TotalResponseLength=%d', [Length(LFullResponse)]), 'UI');

              if LFullResponse.IsEmpty then
              begin
                TLogger.Log('SendPromptToAI: Empty response from AI provider', 'UI');
                Self.PostToWebView('add_message', 'assistant', '**Error:** The provider returned empty response.', False, LActiveProvider, LActiveModel);
                Self.PostToWebView('append_message', 'assistant', '', True, LActiveProvider, LActiveModel);
                Exit;
              end;

              LAssistantMsg := TRadIAService.CreateMessage(mrAssistant, LFullResponse, LActiveProvider, LActiveModel);
              Self.FHistory := Self.FHistory + [LAssistantMsg];
              Self.SaveChatHistory;

              LUsage.PromptTokens := Length(APromptText) div 4;
              LUsage.CompletionTokens := Length(LFullResponse) div 4;
              LUsage.TotalTokens := LUsage.PromptTokens + LUsage.CompletionTokens;

              if LUsage.TotalTokens > 0 then
              begin
                Self.FAccumulatedUsage.PromptTokens := Self.FAccumulatedUsage.PromptTokens + LUsage.PromptTokens;
                Self.FAccumulatedUsage.CompletionTokens := Self.FAccumulatedUsage.CompletionTokens + LUsage.CompletionTokens;
                Self.FAccumulatedUsage.TotalTokens := Self.FAccumulatedUsage.TotalTokens + LUsage.TotalTokens;

                Self.FConfig.AddToQuotaUsage(LUsage);

                LStats := Self.FAccumulatedUsage.FormatStats;
                if Self.FConfig.QuotaEnabled then
                begin
                  LStats := LStats + Format(' · Quota %d%%', [Round((Self.FConfig.QuotaUsed / Self.FConfig.QuotaLimit) * 100)]);
                end;

                Self.PostToWebView('update_tokens', '', LStats);
              end;

              Self.PostToWebView('append_message', 'assistant', '', True, LActiveProvider, LActiveModel);
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

procedure TChatPresenter.CancelRequest;
begin
  if FRequestInProgress then
  begin
    FCancelledByUser := True;
    TLogger.Log('CancelRequest: User requested cancellation.', 'UI');
    FView.SetRequestState(False);
    FAIService.CancelCurrentRequest;
  end;
end;

procedure TChatPresenter.GenerateDTO(const AInput, AInputType, AOutputType: string);
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
      FView.ShowMessageDialog(Format('Não foi possível enviar a requisição: Cota mensal de tokens excedida (limite local de %s tokens atingido).',
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

  LPromptText := TRadIADTOBuilder.BuildPrompt(AInput, AInputType, AOutputType);
  LGuard := FLifecycleGuard as ILifecycleGuard;

  try
    FAIService.SendPromptStream(LPromptText, [],
      procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
      begin
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

            if Self.FCancelledByUser then
            begin
              LDoneHandled := True;
              Self.FRequestInProgress := False;
              Self.FView.SetRequestState(False);
              Self.PostToWebView('append_generator_code', '', ' [Cancelado pelo usuário]', True);
              Exit;
            end;

            if not AError.IsEmpty then
            begin
              LDoneHandled := True;
              Self.FRequestInProgress := False;
              Self.FView.SetRequestState(False);
              Self.PostToWebView('append_generator_code', '', #13#10 + '// Error: ' + AError, True);
              Exit;
            end;

            if not AChunk.IsEmpty then
            begin
              Self.PostToWebView('append_generator_code', '', AChunk, False);
            end;

            if AIsDone then
            begin
              LDoneHandled := True;
              Self.FRequestInProgress := False;
              Self.FView.SetRequestState(False);

              LUsage.PromptTokens := Length(LPromptText) div 4;
              LUsage.CompletionTokens := 1000;
              LUsage.TotalTokens := LUsage.PromptTokens + LUsage.CompletionTokens;

              if LUsage.TotalTokens > 0 then
              begin
                Self.FConfig.AddToQuotaUsage(LUsage);
                LStats := Self.FAccumulatedUsage.FormatStats;
                if Self.FConfig.QuotaEnabled then
                  LStats := LStats + Format(' · Quota %d%%', [Round((Self.FConfig.QuotaUsed / Self.FConfig.QuotaLimit) * 100)]);
                Self.PostToWebView('update_tokens', '', LStats);
              end;

              Self.PostToWebView('append_generator_code', '', '', True);
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

procedure TChatPresenter.OnWebViewReady;
var
  LActiveProvider: string;
begin
  FWebViewReady := True;
  LoadChatHistory;
  SendInitialConfigToWeb;
  SendSessionsUpdateToWeb;
  
  if FRequestInProgress then
    PostToWebView('show_typing', '', '');

  LActiveProvider := FConfig.GetActiveProvider;
  if not GetWebLoginUrl(LActiveProvider).IsEmpty then
  begin
    TLogger.Log('OnWebViewReady: Pre-initializing background browser for Web Login provider.', 'UI');
    FView.CreateBackgroundBrowser;
  end;
end;

procedure TChatPresenter.ProcessWebMessage(const AMessage: string);
var
  LParsed: TJSONValue;
  LJson: TJSONObject;
  LAction: string;
  LText: string;
  LProviderStr: string;
  LModelStr: string;
  LJsonFiles: TJSONArray;
  LJsonFilesStr: string;
begin
  LParsed := TJSONObject.ParseJSONValue(AMessage);
  if not Assigned(LParsed) then
    Exit;

  try
    if not (LParsed is TJSONObject) then
      Exit;

    LJson := TJSONObject(LParsed);
    LAction := LJson.GetValue<string>('action', '');

    if LAction = 'insert_code' then
    begin
      LText := LJson.GetValue<string>('code', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.FView.ReplaceActiveEditorText(LText);
        end));
    end
    else if LAction = 'ready' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.OnWebViewReady;
        end));
    end
    else if (LAction = 'new_chat') or (LAction = 'new_session') then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.CreateNewSession;
        end));
    end
    else if LAction = 'toggle_history' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.ToggleSessions;
        end));
    end
    else if LAction = 'open_settings' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.OpenSettings;
        end));
    end
    else if LAction = 'change_provider' then
    begin
      LProviderStr := LJson.GetValue<string>('provider', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.ChangeProvider(LProviderStr);
        end));
    end
    else if LAction = 'change_model' then
    begin
      LModelStr := LJson.GetValue<string>('model', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.ChangeModel(LModelStr);
        end));
    end
    else if LAction = 'select_session' then
    begin
      LText := LJson.GetValue<string>('id', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.SelectSession(LText);
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
          Self.RenameSession(LProviderStr, LModelStr);
        end));
    end
    else if LAction = 'delete_session' then
    begin
      LText := LJson.GetValue<string>('id', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.DeleteSession(LText);
        end));
    end
    else if LAction = 'web_login_connect' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.HandleOnbtnWebLoginConnectClick;
        end));
    end
    else if SameText(LAction, 'login_complete') then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.FBackgroundBrowserReady := True;
          Self.HandleBackgroundLoginComplete;
        end));
    end
    else if LAction = 'error' then
    begin
      LText := LJson.GetValue<string>('text', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          TRadIAWebViewBridgeProvider.ReceiveChunk('', True, LText);
        end));
    end
    else if LAction = 'update_stream' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        var
          LChunk: string;
          LIsDone: Boolean;
          LActiveProvider: string;
          LActiveModel: string;
        begin
          LChunk := LJson.GetValue<string>('text', '');
          LIsDone := LJson.GetValue<Boolean>('isDone', False);
          LActiveProvider := Self.FConfig.GetActiveProvider;
          LActiveModel := Self.FConfig.GetActiveModel(LActiveProvider);
          
          Self.PostToWebView('update_message', 'assistant', LChunk, LIsDone, LActiveProvider, LActiveModel);
          
          if LIsDone then
            TRadIAWebViewBridgeProvider.ReceiveChunk(LChunk, True, '');
        end));
    end
    else if LAction = 'send_prompt' then
    begin
      LText := LJson.GetValue<string>('text', '');
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.SendPromptText(LText);
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
          Self.GenerateDTO(LInput, LInputType, LOutputType);
        end));
    end
    else if LAction = 'create_project' then
    begin
      LJsonFiles := LJson.GetValue('files') as TJSONArray;
      LJsonFilesStr := '';
      if Assigned(LJsonFiles) then
        LJsonFilesStr := LJsonFiles.ToJSON;

      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        var
          LErrorMsg: string;
        begin
          if not LJsonFilesStr.IsEmpty then
          begin
            if not TRadIAProjectGenerator.GenerateFromJSON(LJsonFilesStr, LErrorMsg) then
            begin
              if not LErrorMsg.IsEmpty then
              begin
                Self.FView.ShowMessageDialog(LErrorMsg);
              end;
            end;
          end
          else
          begin
            Self.FView.ShowMessageDialog('No files data received.');
          end;
        end));
    end
    else if LAction = 'cancel_request' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.CancelRequest;
        end));
    end
    else if LAction = 'clear_chat' then
    begin
      TThread.Queue(nil,
        TThreadProcedure(
        procedure
        begin
          Self.ClearChat;
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

procedure TChatPresenter.OnWebViewBridgeSendPrompt(const APrompt: string);
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
    TLogger.Log('OnWebViewBridgeSendPrompt: Background browser is not initialized yet. Queueing prompt and initializing...', 'UI');
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
      LFinalPrompt := LFinalPrompt + sLineBreak + sLineBreak + TRadIAOTAHelper.GetPreferredLanguageInstruction;
    end;
    
    LJson.AddPair('text', LFinalPrompt);
    FView.PostMessageToBackgroundWeb(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

procedure TChatPresenter.OnWebViewBridgeCancel;
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

procedure TChatPresenter.OnBackgroundBrowserMessage(const AMessage: string);
begin
  ProcessWebMessage(AMessage);
end;

procedure TChatPresenter.OnBackgroundBrowserInitialized;
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

procedure TChatPresenter.HandleBackgroundLoginComplete;
begin
  TLogger.Log('HandleBackgroundLoginComplete: Background browser is logged in and ready.', 'UI');
  if not FPendingPrompt.IsEmpty then
  begin
    TLogger.Log('HandleBackgroundLoginComplete: Dispatching pending prompt.', 'UI');
    OnWebViewBridgeSendPrompt(FPendingPrompt);
  end;
end;

procedure TChatPresenter.OnBackgroundBrowserNavigation(const AUrl: string);
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

procedure TChatPresenter.HandleOnbtnWebLoginConnectClick;
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
        TLogger.Log('HandleOnbtnWebLoginConnectClick: Login completed successfully. Refreshing background browser.', 'UI');
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

function TChatPresenter.PreProcessPrompt(const APromptText: string): string;
var
  LActiveCode: string;
  LTemplate: TPromptTemplate;
  LFound: Boolean;
  LCommand: string;
  LArgument: string;
  LFirstSpace: Integer;
  LTemplateName: string;
  LTemp: TPromptTemplate;
begin
  Result := APromptText;
  LFound := False;
  LActiveCode := '';

  LCommand := Trim(APromptText);
  LArgument := '';
  LFirstSpace := APromptText.IndexOf(' ');
  if LFirstSpace > 0 then
  begin
    LCommand := APromptText.Substring(0, LFirstSpace).Trim;
    LArgument := APromptText.Substring(LFirstSpace + 1).Trim;
  end;

  if SameText(LCommand, '/template') then
  begin
    LTemplateName := LArgument;
    if not LTemplateName.IsEmpty then
    begin
      LFound := FTemplateManager.FindTemplate(LTemplateName, LTemplate);
    end;
  end
  else if SameText(LCommand, '/review') then
  begin
    LFound := False;
    for LTemp in FTemplateManager.GetTemplates do
    begin
      if SameText(LTemp.SlashCommand, '/review') then
      begin
        LTemplate := LTemp;
        LFound := True;
        Break;
      end;
    end;
    if not LFound then
      LFound := FTemplateManager.FindTemplate('Review Leaks and SOLID', LTemplate);
  end
  else if SameText(LCommand, '/refactor') then
  begin
    LFound := False;
    for LTemp in FTemplateManager.GetTemplates do
    begin
      if SameText(LTemp.SlashCommand, '/refactor') then
      begin
        LTemplate := LTemp;
        LFound := True;
        Break;
      end;
    end;
    if not LFound then
      LFound := FTemplateManager.FindTemplate('Review Clean Code Delphi', LTemplate);
  end
  else if SameText(LCommand, '/optimize') then
  begin
    LFound := False;
    for LTemp in FTemplateManager.GetTemplates do
    begin
      if SameText(LTemp.SlashCommand, '/optimize') then
      begin
        LTemplate := LTemp;
        LFound := True;
        Break;
      end;
    end;
    if not LFound then
      LFound := FTemplateManager.FindTemplate('Analyze Performance', LTemplate);
  end
  else if LCommand.StartsWith('/') then
  begin
    for LTemp in FTemplateManager.GetTemplates do
    begin
      if SameText(LTemp.SlashCommand, LCommand) then
      begin
        LTemplate := LTemp;
        LFound := True;
        Break;
      end;
    end;
  end;

  if LFound then
  begin
    Result := LTemplate.Template;

    if Result.Contains('{code}') then
    begin
      if not FView.GetActiveEditorText(LActiveCode, True) or LActiveCode.IsEmpty then
        FView.GetActiveEditorText(LActiveCode, False);
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

procedure TChatPresenter.LoadChatHistory;
var
  LMsg: IChatMessage;
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

procedure TChatPresenter.SaveChatHistory;
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

procedure TChatPresenter.LoadPromptHistory;
var
  LHistoryFile: string;
begin
  LHistoryFile := TPath.Combine(TPath.GetHomePath, 'RadIA\prompt_history.json');
  FPromptHistoryManager.LoadFromFile(LHistoryFile);
end;

procedure TChatPresenter.SavePromptHistory;
var
  LHistoryFile: string;
begin
  LHistoryFile := TPath.Combine(TPath.GetHomePath, 'RadIA\prompt_history.json');
  FPromptHistoryManager.SaveToFile(LHistoryFile);
end;

procedure TChatPresenter.UpdateSessionsList;
var
  LSessionsArray: TArray<TSessionInfo>;
begin
  if FSessionManager.Sessions.Count = 0 then
  begin
    FSessionManager.CreateSession('Conversa Inicial');
  end;
  
  LSessionsArray := FSessionManager.Sessions.ToArray;
  
  if FSessionManager.ActiveSessionId.IsEmpty and (Length(LSessionsArray) > 0) then
  begin
    FSessionManager.ActiveSessionId := LSessionsArray[0].Id;
    FConfig.ActiveSessionId := FSessionManager.ActiveSessionId;
    FConfig.Save;
  end;
  
  FView.UpdateSessions(LSessionsArray, FSessionManager.ActiveSessionId);
end;

procedure TChatPresenter.PostToWebView(const AAction, ARole, AText: string; const AProvider: string; const AModel: string);
begin
  PostToWebView(AAction, ARole, AText, False, AProvider, AModel);
end;

procedure TChatPresenter.PostToWebView(const AAction, ARole, AText: string; const AIsDone: Boolean; const AProvider: string; const AModel: string);
var
  LJson: TJSONObject;
begin
  if not FWebViewReady then
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
      
    FView.PostMessageToWeb(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

procedure TChatPresenter.SendInitialConfigToWeb;
var
  LJson: TJSONObject;
  LProvidersJson: TJSONArray;
  LModelsJson: TJSONArray;
  LSlashCommandsJson: TJSONArray;
  LProviders: TArray<TProviderMetadata>;
  LActiveProvider: string;
  LActiveModel: string;
  LAuthType: string;
  LIsWebLogin: Boolean;
  LTemplate: TPromptTemplate;
  LSlashObj: TJSONObject;
  LProvObj: TJSONObject;
  I: Integer;
  LMeta: TProviderMetadata;
  LDefaultModels: TArray<string>;
  LModel: string;
begin
  if not FWebViewReady then Exit;

  LActiveProvider := FConfig.GetActiveProvider;
  LActiveModel := FConfig.GetActiveModel(LActiveProvider);
  LAuthType := FConfig.GetProviderAuthType(LActiveProvider);
  LIsWebLogin := SameText(LAuthType, 'web_login');

  LJson := TJSONObject.Create;
  LProvidersJson := TJSONArray.Create;
  LModelsJson := TJSONArray.Create;
  LSlashCommandsJson := TJSONArray.Create;
  try
    LProviders := TProviderRegistry.GetProviders;
    for I := 0 to Length(LProviders) - 1 do
    begin
      if IsProviderConfigured(LProviders[I].Id) then
      begin
        LProvObj := TJSONObject.Create;
        LProvObj.AddPair('name', LProviders[I].DisplayName);
        LProvObj.AddPair('value', LProviders[I].Id);
        LProvidersJson.AddElement(LProvObj);
      end;
    end;

    if LIsWebLogin then
    begin
      if TProviderRegistry.GetProvider('WebViewBridge', LMeta) then
        LDefaultModels := LMeta.DefaultModels
      else
        LDefaultModels := ['Web-Browser'];
      LActiveModel := 'Web-Browser';
    end
    else
    begin
      if Length(FActiveModels) > 0 then
        LDefaultModels := FActiveModels
      else if TProviderRegistry.GetProvider(LActiveProvider, LMeta) then
        LDefaultModels := LMeta.DefaultModels
      else
        LDefaultModels := [];
    end;
      
    for LModel in LDefaultModels do
    begin
      LModelsJson.Add(LModel);
    end;

    for LTemplate in FTemplateManager.GetTemplates do
    begin
      if not LTemplate.SlashCommand.IsEmpty then
      begin
        LSlashObj := TJSONObject.Create;
        LSlashObj.AddPair('command', LTemplate.SlashCommand);
        LSlashObj.AddPair('description', LTemplate.Description);
        LSlashObj.AddPair('name', LTemplate.Name);
        LSlashObj.AddPair('isProjectGenerator', TJSONBool.Create(LTemplate.IsProjectGenerator));
        LSlashCommandsJson.AddElement(LSlashObj);
      end;
    end;

    LJson.AddPair('action', 'initialize_config');
    LJson.AddPair('providers', LProvidersJson);
    LJson.AddPair('models', LModelsJson);
    LJson.AddPair('slashCommands', LSlashCommandsJson);
    LJson.AddPair('activeProvider', LActiveProvider);
    LJson.AddPair('activeModel', LActiveModel);
    LJson.AddPair('isWebLogin', TJSONBool.Create(LIsWebLogin));

    FView.PostMessageToWeb(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

procedure TChatPresenter.SendModelsUpdateToWeb(const AModels: TArray<string>; const AActiveModel: string);
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

procedure TChatPresenter.SendSessionsUpdateToWeb;
var
  LJson: TJSONObject;
  LArr: TJSONArray;
  LSession: TSessionInfo;
  LObj: TJSONObject;
begin
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'sessions_update');
    LArr := TJSONArray.Create;
    for LSession in FSessionManager.Sessions do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('id', LSession.Id);
      LObj.AddPair('name', LSession.Name);
      LObj.AddPair('isActive', TJSONBool.Create(SameText(LSession.Id, FSessionManager.ActiveSessionId)));
      LArr.AddElement(LObj);
    end;
    LJson.AddPair('sessions', LArr);
    FView.PostMessageToWeb(LJson.ToJSON);
  finally
    LJson.Free;
  end;
end;

end.
