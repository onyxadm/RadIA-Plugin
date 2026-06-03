unit RadIA.UI.DiffForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Edge, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config, RadIA.Core.Service;

type
  { Form to compare code changes side-by-side before applying them to the editor }
  TFormAIDiff = class(TForm)
    pnlFooter: TPanel;
    btnApply: TButton;
    btnCancel: TButton;
    pnlBrowser: TPanel;
    EdgeBrowser: TEdgeBrowser;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
  private
    FConfig: IAIConfig;
    FAIService: TRadIAService;
    FOriginalCode: string;
    FSuggestedCode: string;
    FUnitName: string;
    FWebFilesDir: string;
    FBrowserInitialized: Boolean;
    
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
  System.IOUtils, System.JSON;

procedure TFormAIDiff.FormCreate(Sender: TObject);
begin
  FBrowserInitialized := False;
  FConfig := TRadIAConfig.Create;
  FAIService := TRadIAService.Create(FConfig);
  FWebFilesDir := TPath.Combine(TPath.GetHomePath, 'RadIA\Web');
  
  EdgeBrowser.Navigate('file:///' + TPath.Combine(FWebFilesDir, 'diff.html').Replace('\', '/'));
end;

procedure TFormAIDiff.FormDestroy(Sender: TObject);
begin
  FAIService.Free;
end;

procedure TFormAIDiff.InitializeDiff(const AUnitName, AOriginalCode: string);
begin
  FUnitName := AUnitName;
  FOriginalCode := AOriginalCode;
end;

procedure TFormAIDiff.EdgeBrowserCreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HRESULT);
begin
  if Succeeded(AResult) then
  begin
    FBrowserInitialized := True;
    PostToWebView('set_theme', 'dark');
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
begin
  LPrompt := 'Refactor and optimize the following Delphi Pascal code. ' +
             'Ensure it follows clean code principles, SOLID, and Delphi performance best practices. ' +
             'Return ONLY the raw refactored Pascal code. No explanations, no introduction, and no wrapping block tags. ' +
             'If you wrap it in markdown code blocks, use ```pascal.' +
             #13#10'Here is the code:'#13#10 + FOriginalCode;
             
  FAIService.SendPrompt(LPrompt, [],
    procedure(const AResponse: string; const AError: string; AFromCache: Boolean)
    var
      LCleanedResponse: string;
    begin
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
      
      TThread.Queue(nil, RenderDiffInBrowser);
    end);
end;

end.
