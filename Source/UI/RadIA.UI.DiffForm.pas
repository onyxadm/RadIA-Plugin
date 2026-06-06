unit RadIA.UI.DiffForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Edge, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config, RadIA.Core.Service, RadIA.Core.TokenUsage;

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
    procedure btnPrevConflictClick(Sender: TObject);
    procedure btnNextConflictClick(Sender: TObject);
  protected
    procedure CreateWnd; override;
  private
    FConfig: IAIConfig;
    FAIService: TRadIAService;
    FOriginalCode: string;
    FSuggestedCode: string;
    FUnitName: string;
    FWebFilesDir: string;
    FBrowserInitialized: Boolean;
    FLifecycleGuard: IInterface;
    
    procedure FormShow(Sender: TObject);
    procedure RequestRefactoring;
    procedure RenderDiffInBrowser;
    procedure PostToWebView(const AAction, AText: string);
  public
    procedure InitializeDiff(const AUnitName, AOriginalCode: string);
    
    property OriginalCode: string read FOriginalCode;
    property SuggestedCode: string read FSuggestedCode;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.JSON, ToolsAPI, RadIA.UI.Resources;

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
  FLifecycleGuard := TLifecycleGuard.Create;
  FConfig := TRadIAConfig.GetInstance;
  FAIService := TRadIAService.Create(FConfig);
  FWebFilesDir := TPath.Combine(TPath.GetHomePath, 'RadIA\Web');
  
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
  (FLifecycleGuard as ILifecycleGuard).Invalidate;
  FAIService.Free;
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
    EdgeBrowser.UserDataFolder := TPath.Combine(TPath.GetHomePath, 'RadIA\WebView2');
    EdgeBrowser.Navigate('file:///' + TPath.Combine(FWebFilesDir, 'diff.html').Replace('\', '/'));
  end;
end;

procedure TFormAIDiff.InitializeDiff(const AUnitName, AOriginalCode: string);
begin
  FUnitName := AUnitName;
  FOriginalCode := AOriginalCode;
end;

procedure TFormAIDiff.EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
var
  LThemingServices: IOTAIDEThemingServices;
  LThemeName: string;
begin
  if Succeeded(AResult) then
  begin
    FBrowserInitialized := True;
    
    LThemeName := 'light';
    if Supports(BorlandIDEServices, IOTAIDEThemingServices, LThemingServices) then
    begin
      if LThemingServices.IDEThemingEnabled then
      begin
        if SameText(LThemingServices.ActiveTheme, 'Dark') then
          LThemeName := 'dark';
      end;
    end;
    
    PostToWebView('set_theme', LThemeName);
    RequestRefactoring;
  end;
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
  if not FBrowserInitialized then
    Exit;
    
  LJson := TJSONObject.Create;
  try
    LJson.AddPair('action', 'render');
    LJson.AddPair('fileName', FUnitName);
    LJson.AddPair('original', FOriginalCode);
    LJson.AddPair('modified', FSuggestedCode);
    
    if Assigned(EdgeBrowser.DefaultInterface) then
      EdgeBrowser.DefaultInterface.PostWebMessageAsJson(PChar(LJson.ToJSON));
  finally
    LJson.Free;
  end;
end;

procedure TFormAIDiff.RequestRefactoring;
var
  LPrompt: string;
  LGuard: ILifecycleGuard;
begin
  LPrompt := 'Refactor and optimize the following Delphi Pascal code. ' +
             'Ensure it follows clean code principles, SOLID, and Delphi performance best practices. ' +
             'Return ONLY the raw refactored Pascal code. No explanations, no introduction, and no wrapping block tags. ' +
             'If you wrap it in markdown code blocks, use ```pascal.' +
             #13#10'Here is the code:'#13#10 + FOriginalCode;
             
  LGuard := FLifecycleGuard as ILifecycleGuard;
             
  FAIService.SendPrompt(LPrompt, [],
    procedure(const AResponse: string; const AError: string; AFromCache: Boolean; const AUsage: TTokenUsage)
    var
      LCleanedResponse: string;
    begin
      if not LGuard.IsAlive then
        Exit;

      if not AError.IsEmpty then
      begin
        FSuggestedCode := '// Error requesting refactoring: ' + AError + #13#10 + FOriginalCode;
      end
      else
      begin
        { Clean markdown block markers if IA returned them }
        LCleanedResponse := AResponse.Trim;
        if LCleanedResponse.StartsWith('```pascal') then
          LCleanedResponse := LCleanedResponse.Substring(9);
        if LCleanedResponse.StartsWith('```delphi') then
          LCleanedResponse := LCleanedResponse.Substring(9);
        if LCleanedResponse.StartsWith('```') then
          LCleanedResponse := LCleanedResponse.Substring(3);
        if LCleanedResponse.EndsWith('```') then
          LCleanedResponse := LCleanedResponse.Substring(0, LCleanedResponse.Length - 3);
          
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
