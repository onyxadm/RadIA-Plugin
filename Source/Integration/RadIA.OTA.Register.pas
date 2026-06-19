unit RadIA.OTA.Register;

interface

uses
  System.SysUtils, System.Classes, ToolsAPI, Vcl.ExtCtrls;

type
  { Wizard implementing IOTAWizard to register RadIA into Delphi IDE }
  TRadIAWizard = class(TInterfacedObject, IOTAWizard)
  private
    FEditorHook: TObject;
    FTimer: TTimer;
    FOptionsPages: TInterfaceList;
    procedure RegisterMenus;
    procedure UnregisterMenus;
    procedure RegisterOptions;
    procedure UnregisterOptions;
    procedure OnRequestDiff(const AOriginalCode: string; const AReplaceWholeBuffer: Boolean);
    procedure OnTimerEvent(Sender: TObject);
    procedure RestoreWindowVisibility;
  public
    constructor Create;
    destructor Destroy; override;
    
    { IOTANotifier implementation }
    procedure AfterSave;
    procedure BeforeSave;
    procedure Destroyed;
    procedure Modified;
    
    { IOTAWizard implementation }
    function GetName: string;
    function GetIDString: string;
    function GetState: TWizardState;
    procedure Execute;
  end;

procedure Register;

implementation

uses
  Vcl.Menus, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Dialogs, System.Win.Registry, Winapi.Windows, RadIA.OTA.EditorHook, RadIA.UI.DiffForm, 
  RadIA.UI.ConfigForm, RadIA.OTA.Helper, RadIA.Core.Types, RadIA.Core.Mediator, RadIA.Core.Config, RadIA.OTA.DockableForm,
  RadIA.Core.Interfaces, RadIA.Core.Logger, RadIA.OTA.Options, RadIA.Providers.Link;

const
  GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS = $00000004;

function GetModuleHandleEx(dwFlags: DWORD; lpModuleName: PChar; var phModule: HMODULE): BOOL; stdcall;
  external 'kernel32.dll' name 'GetModuleHandleExW';

var
  GWizardIndex: Integer = -1;
  GAboutBoxIndex: Integer = -1;
  LAboutServices: IOTAAboutBoxServices;
  GModuleHandle: HMODULE = 0;

procedure LogDebug(const AMsg: string);
begin
  TLogger.Log(AMsg, 'Register');
end;

procedure RegisterSplashAndAbout;
var
  LBitmap: Vcl.Graphics.TBitmap;
begin
  LBitmap := Vcl.Graphics.TBitmap.Create;
  try
    LBitmap.PixelFormat := pf24bit;
    LBitmap.Width := 24;
    LBitmap.Height := 24;
    
    // Fundo azul escuro (#0F172A -> BGR $002A170F)
    LBitmap.Canvas.Brush.Color := $002A170F;
    LBitmap.Canvas.FillRect(Rect(0, 0, 24, 24));
    
    // Cabeça do robô cinza claro (#D1D5DB -> BGR $00DBD5D1)
    LBitmap.Canvas.Pen.Color := $00DBD5D1;
    LBitmap.Canvas.Brush.Color := $00DBD5D1;
    LBitmap.Canvas.RoundRect(4, 6, 20, 18, 4, 4);
    
    // Antena
    LBitmap.Canvas.Pen.Color := $00DBD5D1;
    LBitmap.Canvas.MoveTo(12, 6);
    LBitmap.Canvas.LineTo(12, 3);
    LBitmap.Canvas.Brush.Color := $00CC7A00; // Azul RadIA (#007ACC -> BGR $00CC7A00)
    LBitmap.Canvas.Ellipse(10, 1, 14, 5);
    
    // Olhos azuis brilhantes (#3B82F6 -> BGR $00F6823B)
    LBitmap.Canvas.Brush.Color := $00F6823B;
    LBitmap.Canvas.Pen.Color := $00F6823B;
    LBitmap.Canvas.Ellipse(7, 10, 10, 13);
    LBitmap.Canvas.Ellipse(14, 10, 17, 13);
    
    // Boca
    LBitmap.Canvas.Pen.Color := $009CA3AF;
    LBitmap.Canvas.MoveTo(9, 15);
    LBitmap.Canvas.LineTo(15, 15);

    { 1. Registrar na Splash Screen se disponível }
    if Assigned(SplashScreenServices) then
    begin
      SplashScreenServices.AddPluginBitmap(
        'Rad IA AI Assistant',
        LBitmap.Handle,
        False,
        'Open Source (BYOK)'
      );
    end;

    { 2. Registrar no About Box se disponível }
    if Supports(BorlandIDEServices, IOTAAboutBoxServices, LAboutServices) then
    begin
      GAboutBoxIndex := LAboutServices.AddPluginInfo(
        'Rad IA AI Assistant',
        'Rad IA - AI Assistant for Delphi IDE' + sLineBreak +
        'Provides sidebar chat, code refactoring, context parsing, and smart diff.' + sLineBreak +
        'Copyright (c) 2026 Rad IA Open Source Project',
        LBitmap.Handle,
        False,
        'Apache 2.0 License',
        'v0.0.25'
      );
    end;
  finally
    LBitmap.Free;
  end;
end;

procedure Register;
var
  LOTAInstance: IOTAWizard;
  LWizardServices: IOTAWizardServices;
  LOTAServices: IOTAServices;
begin
  LogDebug('Register called');
  if not Assigned(BorlandIDEServices) then
  begin
    LogDebug('Error: BorlandIDEServices is nil');
    Exit;
  end;

  if Supports(BorlandIDEServices, IOTAServices, LOTAServices) then
  begin
    TRadIAConfig.SetBaseRegistryPath(LOTAServices.GetBaseRegistryKey + '\RadIA');
  end;

  if Supports(BorlandIDEServices, IOTAWizardServices, LWizardServices) then
  begin
    LogDebug('IOTAWizardServices supported');
    try
      LOTAInstance := TRadIAWizard.Create;
      GWizardIndex := LWizardServices.AddWizard(LOTAInstance);
      LogDebug(Format('Wizard added successfully with index: %d', [GWizardIndex]));
    except
      on E: Exception do
        LogDebug('Exception during Wizard creation: ' + E.Message);
    end;
  end
  else
  begin
    LogDebug('Error: IOTAWizardServices NOT supported');
  end;
  RegisterSplashAndAbout;
end;

{ TRadIAWizard }

constructor TRadIAWizard.Create;
var
  LThemingServices: IOTAIDEThemingServices;
begin
  LogDebug('TRadIAWizard.Create called');
  GIsShuttingDown := False;
  
  // Incrementar a contagem de referencias da BPL para mante-la mapeada em memoria se a IDE fechar
  GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS, PChar(@Register), GModuleHandle);
  
  inherited Create;
  
  FOptionsPages := TInterfaceList.Create;
  
  { Register custom forms in IDE Theming Services }
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    LThemingServices.RegisterFormClass(TFormAIDiff);
    LThemingServices.RegisterFormClass(TFormAIConfig);
    LThemingServices.RegisterFormClass(TFormRadIADockable);
  end;
  
  FEditorHook := TRadIAEditorHook.Create(nil);
  TRadIAEditorHook(FEditorHook).Install;
  RegisterMenus;
  RegisterOptions;
  
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 1000;
  FTimer.OnTimer := OnTimerEvent;
  FTimer.Enabled := True;
  
  TRadIAMediator.Instance.RegisterDiffHandler(OnRequestDiff);
end;

destructor TRadIAWizard.Destroy;
begin
  GIsShuttingDown := True;
  
  {$IFNDEF TESTS}
  RadIA.OTA.DockableForm.UnregisterDockableForm;
  {$ENDIF}

  TRadIAMediator.Instance.UnregisterDiffHandler;
  if Assigned(FTimer) then
  begin
    FTimer.Enabled := False;
    FTimer.Free;
  end;
  UnregisterOptions;
  UnregisterMenus;
  TRadIAEditorHook(FEditorHook).Uninstall;
  FEditorHook.Free;
  FOptionsPages.Free;
  
  // Se nao for shutdown geral da IDE (ou seja, desinstalacao normal do pacote), libere a referencia de modulo
  if (not GIsShuttingDown) and (GModuleHandle <> 0) then
  begin
    FreeLibrary(GModuleHandle);
    GModuleHandle := 0;
  end;
  
  GWizardIndex := -1;
  inherited Destroy;
end;

procedure TRadIAWizard.RegisterOptions;
var
  LOptionsServices: INTAEnvironmentOptionsServices;
  
  procedure AddPage(const ATitle: string; ATag: TRadIAPageTag);
  var
    LOptions: INTAAddInOptions;
  begin
    LOptions := TRadIAAddInOptions.Create(ATitle, ATag);
    FOptionsPages.Add(LOptions);
    LOptionsServices.RegisterAddInOptions(LOptions);
  end;

begin
  if Supports(BorlandIDEServices, INTAEnvironmentOptionsServices, LOptionsServices) then
  begin
    AddPage('General', ptNone);
    AddPage('System Prompt', ptSystem);
    AddPage('Templates', ptTemplates);
    AddPage('Gemini', ptGemini);
    AddPage('OpenAI', ptOpenAI);
    AddPage('Azure OpenAI', ptAzureOpenAI);
    AddPage('Claude', ptClaude);
    AddPage('DeepSeek', ptDeepSeek);
    AddPage('Groq', ptGroq);
    AddPage('Alibaba Qwen', ptQwen);
    AddPage('Mistral AI', ptMistral);
    AddPage('OpenRouter', ptOpenRouter);
    AddPage('GitHub Copilot', ptGithubCopilot);
    AddPage('AWS Bedrock', ptBedrock);
    AddPage('Ollama', ptOllama);
    AddPage('LM Studio', ptLMStudio);
  end;
end;

procedure TRadIAWizard.UnregisterOptions;
var
  LOptionsServices: INTAEnvironmentOptionsServices;
  I: Integer;
begin
  try
    if Supports(BorlandIDEServices, INTAEnvironmentOptionsServices, LOptionsServices) then
    begin
      for I := FOptionsPages.Count - 1 downto 0 do
      begin
        try
          LOptionsServices.UnregisterAddInOptions(FOptionsPages[I] as INTAAddInOptions);
        except
          // Silenciosamente ignora qualquer erro de desregistro no encerramento da IDE
        end;
      end;
      FOptionsPages.Clear;
    end;
  except
    // Protege contra exceções de acesso a BorlandIDEServices/LOptionsServices
  end;
end;

procedure TRadIAWizard.AfterSave;
begin
end;

procedure TRadIAWizard.BeforeSave;
begin
end;

procedure TRadIAWizard.Destroyed;
begin
end;

procedure TRadIAWizard.Modified;
begin
end;

function TRadIAWizard.GetIDString: string;
begin
  Result := 'RadIA.Wizard.Main';
end;

function TRadIAWizard.GetName: string;
begin
  Result := 'Rad IA';
end;

function TRadIAWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

procedure TRadIAWizard.Execute;
begin
  // Handled on menu and context clicks, nothing to execute on start
end;

procedure TRadIAWizard.OnRequestDiff(const AOriginalCode: string; const AReplaceWholeBuffer: Boolean);
var
  LForm: TFormAIDiff;
  LActiveFile: string;
  LEditBuffer: IOTAEditBuffer;
  LConfig: IAIConfig;
  LActiveProvider: string;
begin
  LConfig := TRadIAConfig.GetInstance;
  LConfig.Load;
  LActiveProvider := LConfig.GetActiveProvider;
  if SameText(LConfig.GetProviderAuthType(LActiveProvider), 'web_login') then
  begin
    LogDebug('OnRequestDiff: Active provider uses Web Login. Opening the chat bridge.');
    ShowRadIAChat;
  end;

  LForm := TFormAIDiff.Create(nil);
  try
    LEditBuffer := TRadIAOTAHelper.GetCurrentEditBuffer;
    if Assigned(LEditBuffer) then
      LActiveFile := LEditBuffer.FileName
    else
      LActiveFile := 'ActiveUnit.pas';
      
    LForm.InitializeDiff(ExtractFileName(LActiveFile), AOriginalCode);
    if LForm.ShowModal = mrOk then
    begin
      if not TRadIAOTAHelper.ReplaceActiveEditorText(LForm.SuggestedCode, AReplaceWholeBuffer, AOriginalCode) then
        ShowMessage('Could not apply the diff because the original code block was not found in the active editor.');
    end;
  finally
    LForm.Free;
  end;
end;

function FindToolsMenu(const AMainMenu: TMainMenu): TMenuItem;
var
  I: Integer;
  LCaption: string;
begin
  Result := nil;
  if not Assigned(AMainMenu) then
    Exit;

  // 1. Busca pelo nome do componente (independe de tradução)
  for I := 0 to AMainMenu.Items.Count - 1 do
  begin
    if SameText(AMainMenu.Items[I].Name, 'ToolsMenu') or 
       SameText(AMainMenu.Items[I].Name, 'Tools') then
    begin
      Result := AMainMenu.Items[I];
      Exit;
    end;
  end;

  // 2. Fallbacks de Caption usando buscas exatas limpas de atalhos (&)
  for I := 0 to AMainMenu.Items.Count - 1 do
  begin
    LCaption := StringReplace(AMainMenu.Items[I].Caption, '&', '', [rfReplaceAll]);
    if SameText(LCaption, 'Tools') or 
       SameText(LCaption, 'Ferramentas') or 
       SameText(LCaption, 'ToolsMenu') then
    begin
      Result := AMainMenu.Items[I];
      Exit;
    end;
  end;

  // 3. Fallback clássico da Open Tools API
  Result := AMainMenu.Items.Find('Tools');
end;

procedure TRadIAWizard.RegisterMenus;
var
  LNTAServices: INTAServices;
  LToolsMenu: TMenuItem;
  I: Integer;
  LToolsAlreadyPopulated: Boolean;
  LHook: TRadIAEditorHook;
begin
  LogDebug('RegisterMenus called');
  LToolsAlreadyPopulated := False;
  LHook := TRadIAEditorHook(FEditorHook);

  if Supports(BorlandIDEServices, INTAServices, LNTAServices) then
  begin
    LogDebug('INTAServices supported');
    
    { Register tools actions }
    LToolsMenu := FindToolsMenu(LNTAServices.MainMenu);
    if Assigned(LToolsMenu) then
    begin
      for I := 0 to LToolsMenu.Count - 1 do
      begin
        if SameText(LToolsMenu.Items[I].Caption, 'RadIA Chat Panel') or
           SameText(LToolsMenu.Items[I].Caption, 'Rad IA Chat Panel') or 
           SameText(LToolsMenu.Items[I].Caption, 'Fix Last Compiler Error') then
        begin
          LToolsAlreadyPopulated := True;
          Break;
        end;
      end;

      if not LToolsAlreadyPopulated then
      begin
        LogDebug('Tools/Ferramentas menu found');
        LHook.PopulateToolsMenu(LToolsMenu);
        LogDebug('Tools menu populated');
      end;
    end
    else
    begin
      LogDebug('Error: Tools/Ferramentas menu NOT found');
    end;
  end;
end;

procedure TRadIAWizard.OnTimerEvent(Sender: TObject);
var
  LNTAServices: INTAServices;
  LToolsMenu: TMenuItem;
  LToolsPopulated: Boolean;
  I: Integer;
  LHook: TRadIAEditorHook;
begin
  LToolsPopulated := False;
  LHook := TRadIAEditorHook(FEditorHook);

  if Supports(BorlandIDEServices, INTAServices, LNTAServices) then
  begin
    // 1. Verificar e popular o menu Tools
    LToolsMenu := FindToolsMenu(LNTAServices.MainMenu);
    if Assigned(LToolsMenu) then
    begin
      for I := 0 to LToolsMenu.Count - 1 do
      begin
        if SameText(LToolsMenu.Items[I].Caption, 'RadIA Chat Panel') or
           SameText(LToolsMenu.Items[I].Caption, 'Rad IA Chat Panel') or 
           SameText(LToolsMenu.Items[I].Caption, 'Fix Last Compiler Error') then
        begin
          LToolsPopulated := True;
          Break;
        end;
      end;

      if not LToolsPopulated then
      begin
        LogDebug('Tools menu not populated or reset. Populating now...');
        LHook.PopulateToolsMenu(LToolsMenu);
        LToolsPopulated := True;
        LogDebug('Tools menu populated successfully');
      end;
    end;
  end;

  // Desliga o timer assim que o menu Tools estiver populado
  if LToolsPopulated then
  begin
    LogDebug('Tools menu populated. Disabling timer.');
    FTimer.Enabled := False;
    RestoreWindowVisibility;
  end;
end;

procedure TRadIAWizard.UnregisterMenus;
var
  LNTAServices: INTAServices;
  LToolsMenu: TMenuItem;
  I: Integer;
begin
  LogDebug('UnregisterMenus called');
  if not Assigned(FEditorHook) then
    Exit;
    
  try
    if Supports(BorlandIDEServices, INTAServices, LNTAServices) then
    begin
      LToolsMenu := FindToolsMenu(LNTAServices.MainMenu);
      if Assigned(LToolsMenu) then
      begin
        for I := LToolsMenu.Count - 1 downto 0 do
        begin
          try
            if SameText(LToolsMenu.Items[I].Caption, 'RadIA Chat Panel') or
               SameText(LToolsMenu.Items[I].Caption, 'Rad IA Chat Panel') or
               SameText(LToolsMenu.Items[I].Caption, 'Fix Last Compiler Error') then
            begin
              LToolsMenu.Items[I].Free;
            end;
          except
            // Ignora erro ao liberar item individual
          end;
        end;
      end;
    end;
  except
    // Protege contra exceções ao acessar serviços de menu
  end;
end;

procedure TRadIAWizard.RestoreWindowVisibility;
var
  LReg: TRegistry;
  LRegPath: string;
  LVisible: Boolean;
begin
  LVisible := False;
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    LRegPath := TRadIAConfig.GetRegistryPath;
    if LReg.OpenKeyReadOnly(LRegPath) then
    begin
      if LReg.ValueExists('WindowVisible') then
        LVisible := LReg.ReadBool('WindowVisible');
      LReg.CloseKey;
    end;
  finally
    LReg.Free;
  end;

  if LVisible then
  begin
    LogDebug('Restoring window visibility from registry');
    ShowRadIAChat;
  end;
end;

initialization



end.
