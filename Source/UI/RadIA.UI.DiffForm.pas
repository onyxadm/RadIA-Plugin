unit RadIA.UI.DiffForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Edge, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config, RadIA.Core.Service, RadIA.Core.TokenUsage, Winapi.WebView2, Winapi.ActiveX;

type
  { Form to compare code changes side-by-side before applying them to the editor }
  TFormAIDiff = class(TForm)
    pnlFooter: TPanel;
    lblSeparator: TLabel;
    btnPrevConflict: TButton;
    btnNextConflict: TButton;
    btnApply: TButton;
    btnCancel: TButton;
    pnlBrowser: TPanel;
    EdgeBrowser: TEdgeBrowser;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
    procedure EdgeBrowserNavigationCompleted(Sender: TCustomEdgeBrowser; IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
    procedure btnPrevConflictClick(Sender: TObject);
    procedure btnNextConflictClick(Sender: TObject);
  protected
    procedure CreateWnd; override;
  private
    FConfig: IAIConfig;
    FAIService: IRadIAService;
    FOriginalCode: string;
    FSuggestedCode: string;
    FUnitName: string;
    FWebFilesDir: string;
    FBrowserInitialized: Boolean;
    FPageReady: Boolean;
    FRequestStarted: Boolean;
    FRequestFinished: Boolean;
    FPendingRender: Boolean;
    FCanApply: Boolean;
    FRequestTimeoutTimer: TTimer;
    FLifecycleGuard: IInterface;
    
    procedure FormShow(Sender: TObject);
    procedure LoadWindowPlacement;
    procedure RequestRefactoring;
    procedure RequestTimeoutElapsed(Sender: TObject);
    procedure RenderDiffInBrowser;
    procedure SaveWindowPlacement;
    procedure TryStartRefactoring;
    function CleanSuggestedCode(const AResponse: string): string;
    procedure PostToWebView(const AAction, AText: string);
  public
    procedure InitializeDiff(const AUnitName, AOriginalCode: string);
    
    property OriginalCode: string read FOriginalCode;
    property SuggestedCode: string read FSuggestedCode;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.JSON, System.Math, System.Win.Registry, ToolsAPI, RadIA.UI.Resources;

const
  CDiffDefaultTimeoutMs = 60000;
  CDiffWebLoginTimeoutMs = 300000;

procedure TFormAIDiff.CreateWnd;
var
  LThemingServices: IOTAIDEThemingServices;
  LActiveTheme: string;
begin
  inherited CreateWnd;
  
  LActiveTheme := 'light';
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LActiveTheme := LThemingServices.ActiveTheme;
    end;
  end;
  
  if SameText(LActiveTheme, 'dark') then
  begin
    TUIHelper.ApplyDarkTitleBar(Self, True);
  end;
end;

procedure TFormAIDiff.FormCreate(Sender: TObject);
var
  LThemingServices: IOTAIDEThemingServices;
begin
  FBrowserInitialized := False;
  FPageReady := False;
  FRequestStarted := False;
  FRequestFinished := False;
  FPendingRender := False;
  FCanApply := False;
  FLifecycleGuard := TLifecycleGuard.Create;
  FConfig := TRadIAConfig.GetInstance;
  FAIService := TRadIAService.Create(FConfig);
  FWebFilesDir := TPath.Combine(TPath.GetHomePath, 'RadIA\Web');
  FRequestTimeoutTimer := TTimer.Create(Self);
  FRequestTimeoutTimer.Enabled := False;
  if FConfig.IsWebLoginProvider(FConfig.GetActiveProvider) then
    FRequestTimeoutTimer.Interval := CDiffWebLoginTimeoutMs
  else
    FRequestTimeoutTimer.Interval := CDiffDefaultTimeoutMs;
  FRequestTimeoutTimer.OnTimer := RequestTimeoutElapsed;
  btnApply.Enabled := False;
  LoadWindowPlacement;
  
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LThemingServices.ApplyTheme(Self);
    end;
  end;
  
  OnShow := FormShow;
end;

procedure TFormAIDiff.FormDestroy(Sender: TObject);
begin
  SaveWindowPlacement;
  (FLifecycleGuard as ILifecycleGuard).Invalidate;
  FAIService := nil;
end;

procedure TFormAIDiff.LoadWindowPlacement;
var
  LReg: TRegistry;
  LRegPath: string;
  LLeft: Integer;
  LTop: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LBounds: TRect;
  LDesktop: TRect;
begin
  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    LRegPath := TRadIAConfig.GetRegistryPath;
    if not LReg.OpenKeyReadOnly(LRegPath) then
      Exit;

    if not (LReg.ValueExists('DiffWindowWidth') and
            LReg.ValueExists('DiffWindowHeight') and
            LReg.ValueExists('DiffWindowLeft') and
            LReg.ValueExists('DiffWindowTop')) then
      Exit;

    LWidth := LReg.ReadInteger('DiffWindowWidth');
    LHeight := LReg.ReadInteger('DiffWindowHeight');
    LLeft := LReg.ReadInteger('DiffWindowLeft');
    LTop := LReg.ReadInteger('DiffWindowTop');

    LWidth := Max(640, LWidth);
    LHeight := Max(480, LHeight);
    LBounds := Rect(LLeft, LTop, LLeft + LWidth, LTop + LHeight);
    LDesktop := Screen.DesktopRect;

    if (LBounds.Right < LDesktop.Left) or (LBounds.Left > LDesktop.Right) or
       (LBounds.Bottom < LDesktop.Top) or (LBounds.Top > LDesktop.Bottom) then
      Exit;

    Position := poDesigned;
    SetBounds(LLeft, LTop, LWidth, LHeight);
  finally
    LReg.Free;
  end;
end;

procedure TFormAIDiff.SaveWindowPlacement;
var
  LReg: TRegistry;
  LRegPath: string;
begin
  if WindowState <> wsNormal then
    Exit;

  LReg := TRegistry.Create;
  try
    LReg.RootKey := HKEY_CURRENT_USER;
    LRegPath := TRadIAConfig.GetRegistryPath;
    if LReg.OpenKey(LRegPath, True) then
    begin
      LReg.WriteInteger('DiffWindowWidth', Width);
      LReg.WriteInteger('DiffWindowHeight', Height);
      LReg.WriteInteger('DiffWindowLeft', Left);
      LReg.WriteInteger('DiffWindowTop', Top);
      LReg.CloseKey;
    end;
  finally
    LReg.Free;
  end;
end;

procedure TFormAIDiff.FormShow(Sender: TObject);
var
  LThemingServices: IOTAIDEThemingServices;
begin
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled then
    begin
      LThemingServices.ApplyTheme(Self);
    end;
  end;

  if not FBrowserInitialized then
  begin
    EdgeBrowser.UserDataFolder := TPath.Combine(TPath.GetHomePath, 'RadIA\WebView2Diff');
    EdgeBrowser.Navigate('file:///' + TPath.Combine(FWebFilesDir, 'diff.html').Replace('\', '/'));
  end;
end;

procedure TFormAIDiff.InitializeDiff(const AUnitName, AOriginalCode: string);
begin
  FUnitName := AUnitName;
  FOriginalCode := AOriginalCode;
end;

procedure TFormAIDiff.EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
begin
  if Succeeded(AResult) then
    FBrowserInitialized := True;
end;

procedure TFormAIDiff.EdgeBrowserNavigationCompleted(Sender: TCustomEdgeBrowser;
  IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
var
  LThemingServices: IOTAIDEThemingServices;
  LThemeName: string;
begin
  if not IsSuccess then
  begin
    FSuggestedCode := '// Error loading diff view. WebView2 status: ' + IntToStr(Ord(WebErrorStatus)) +
      #13#10 + FOriginalCode;
    FPendingRender := True;
    Exit;
  end;

  FPageReady := True;

  LThemeName := 'light';
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
  begin
    if LThemingServices.IDEThemingEnabled and SameText(LThemingServices.ActiveTheme, 'Dark') then
      LThemeName := 'dark';
  end;

  PostToWebView('set_theme', LThemeName);

  if FPendingRender and (not FSuggestedCode.Trim.IsEmpty) then
    RenderDiffInBrowser
  else
    TryStartRefactoring;
end;

procedure TFormAIDiff.PostToWebView(const AAction, AText: string);
var
  LJson: TJSONObject;
begin
  if not FBrowserInitialized then
    Exit;
    
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', AAction);
    if not AText.IsEmpty then
      LJson.AddPair('theme', AText);
      
    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
end;

procedure TFormAIDiff.RenderDiffInBrowser;
var
  LJson: TJSONObject;
begin
  if not FBrowserInitialized or not FPageReady then
  begin
    FPendingRender := True;
    Exit;
  end;
    
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'render');
    LJson.AddPair('fileName', FUnitName);
    LJson.AddPair('original', FOriginalCode);
    LJson.AddPair('modified', FSuggestedCode);
    
    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
    FPendingRender := False;
    btnApply.Enabled := FCanApply and (not FSuggestedCode.Trim.IsEmpty);
  finally
    LJson.Free;
  end;
end;

procedure TFormAIDiff.TryStartRefactoring;
begin
  if FRequestStarted or not FBrowserInitialized or not FPageReady then
    Exit;

  FRequestStarted := True;
  FRequestFinished := False;
  RequestRefactoring;
end;

procedure TFormAIDiff.RequestTimeoutElapsed(Sender: TObject);
begin
  FRequestTimeoutTimer.Enabled := False;

  if FRequestFinished then
    Exit;

  FRequestFinished := True;
  FCanApply := False;
  FAIService.CancelCurrentRequest;
  FSuggestedCode := '// Error requesting refactoring: provider response timed out.' +
    #13#10 + FOriginalCode;
  RenderDiffInBrowser;
end;

function TFormAIDiff.CleanSuggestedCode(const AResponse: string): string;
var
  LLines: TStringList;
  I: Integer;
  LLine: string;
begin
  Result := AResponse.Trim;

  LLines := TStringList.Create;
  try
    LLines.Text := Result;

    I := LLines.Count - 1;
    while I >= 0 do
    begin
      LLine := LLines[I].Trim;
      if LLine.StartsWith('```') or SameText(LLine, 'Delphi') or SameText(LLine, 'Pascal') then
        LLines.Delete(I);
      Dec(I);
    end;

    while (LLines.Count > 0) and LLines[0].Trim.IsEmpty do
      LLines.Delete(0);

    while (LLines.Count > 0) and LLines[LLines.Count - 1].Trim.IsEmpty do
      LLines.Delete(LLines.Count - 1);

    Result := LLines.Text.Trim;
  finally
    LLines.Free;
  end;
end;

procedure TFormAIDiff.RequestRefactoring;
var
  LPrompt: string;
  LGuard: ILifecycleGuard;
  LActiveProvider: string;
begin
  LActiveProvider := FConfig.GetActiveProvider;
  if (not FConfig.IsWebLoginProvider(LActiveProvider)) and
     (SameText(LActiveProvider, 'Gemini') or SameText(LActiveProvider, 'OpenAI')) and
     FConfig.GetApiKey(LActiveProvider).Trim.IsEmpty then
  begin
    FRequestFinished := True;
    FCanApply := False;
    FSuggestedCode := '// Error requesting refactoring: ' +
      'Provider is configured for API key authentication, but no API key is saved. ' +
      'Open Rad IA settings, select Web Login for ' + LActiveProvider +
      ', complete login, and save settings.' + #13#10 + FOriginalCode;
    RenderDiffInBrowser;
    Exit;
  end;

  LPrompt := 'Refactor and optimize the following Delphi Pascal code. ' +
             'Ensure it follows clean code principles, SOLID, and Delphi performance best practices. ' +
             'Preserve valid Delphi formatting and indentation using two spaces per indentation level. ' +
             'Return the complete refactored source in exactly one fenced code block using pascal as ' +
             'the language. Do not place any text before or after the fenced code block. ' +
             'Do not split the source into multiple code blocks or explanations.' +
             #13#10'Here is the code:'#13#10 + FOriginalCode;
             
  LGuard := FLifecycleGuard as ILifecycleGuard;

  FRequestTimeoutTimer.Enabled := True;
             
  FAIService.SendPrompt(LPrompt, [],
    procedure(const AResponse: string; const AError: string; AFromCache: Boolean; const AUsage: TTokenUsage)
    var
      LCleanedResponse: string;
    begin
      if not LGuard.IsAlive then
        Exit;

      if FRequestFinished then
        Exit;

      FRequestFinished := True;
      FRequestTimeoutTimer.Enabled := False;

      if not AError.IsEmpty then
      begin
        FCanApply := False;
        FSuggestedCode := '// Error requesting refactoring: ' + AError + #13#10 + FOriginalCode;
      end
      else
      begin
        LCleanedResponse := CleanSuggestedCode(AResponse);
          
        FCanApply := not LCleanedResponse.Trim.IsEmpty;
        FSuggestedCode := LCleanedResponse.Trim;
      end;
      
      TThread.Queue(nil,
        procedure
        begin
          if LGuard.IsAlive then
            RenderDiffInBrowser;
        end);
    end, rpRefactorCode);
end;

procedure TFormAIDiff.btnPrevConflictClick(Sender: TObject);
var
  LJson: TJSONObject;
begin
  if not FBrowserInitialized then Exit;
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'navigate');
    LJson.AddPair('direction', 'prev');
    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
end;

procedure TFormAIDiff.btnNextConflictClick(Sender: TObject);
var
  LJson: TJSONObject;
begin
  if not FBrowserInitialized then Exit;
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'navigate');
    LJson.AddPair('direction', 'next');
    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
end;

end.
