unit RadIA.UI.ConfigFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config;

type
  TFrameAIConfig = class(TFrame)
    pgcSettings: TPageControl;
    tsGemini: TTabSheet;
    tsOpenAI: TTabSheet;
    tsClaude: TTabSheet;
    tsDeepSeek: TTabSheet;
    tsGroq: TTabSheet;
    tsOllama: TTabSheet;
    tsSystemPrompt: TTabSheet;
    grpGemini: TGroupBox;
    lblGeminiKey: TLabel;
    edtGeminiKey: TEdit;
    grpOpenAI: TGroupBox;
    lblOpenAIKey: TLabel;
    edtOpenAIKey: TEdit;
    lblOpenAICustomUrl: TLabel;
    edtOpenAICustomUrl: TEdit;
    grpClaude: TGroupBox;
    lblClaudeKey: TLabel;
    edtClaudeKey: TEdit;
    grpOllama: TGroupBox;
    lblOllamaUrl: TLabel;
    edtOllamaUrl: TEdit;
    grpDeepSeek: TGroupBox;
    lblDeepSeekKey: TLabel;
    edtDeepSeekKey: TEdit;
    grpGroq: TGroupBox;
    lblGroqKey: TLabel;
    edtGroqKey: TEdit;
    grpSystemPrompt: TGroupBox;
    memSystemPrompt: TMemo;
    pnlFooter: TPanel;
    btnSave: TButton;
    btnCancel: TButton;
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FConfig: IAIConfig;
    FOnClose: TNotifyEvent;
  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadConfig;
    
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
  end;

implementation

{$R *.dfm}

constructor TFrameAIConfig.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FConfig := TRadIAConfig.Create;
  LoadConfig;
end;

procedure TFrameAIConfig.LoadConfig;
begin
  edtGeminiKey.Text := FConfig.GetApiKey(ptGemini);
  edtOpenAIKey.Text := FConfig.GetApiKey(ptOpenAI);
  edtOpenAICustomUrl.Text := FConfig.OpenAICustomBaseUrl;
  edtClaudeKey.Text := FConfig.GetApiKey(ptClaude);
  edtDeepSeekKey.Text := FConfig.GetApiKey(ptDeepSeek);
  edtGroqKey.Text := FConfig.GetApiKey(ptGroq);
  memSystemPrompt.Text := FConfig.SystemPrompt;
  edtOllamaUrl.Text := FConfig.OllamaBaseUrl;
end;

procedure TFrameAIConfig.btnSaveClick(Sender: TObject);
var
  LForm: TCustomForm;
  LOllamaUrl: string;
  LOpenAIUrl: string;
begin
  LOllamaUrl := Trim(edtOllamaUrl.Text);
  LOpenAIUrl := Trim(edtOpenAICustomUrl.Text);

  if not LOllamaUrl.IsEmpty and not (LOllamaUrl.StartsWith('http://', True) or LOllamaUrl.StartsWith('https://', True)) then
  begin
    ShowMessage('A URL do Ollama deve iniciar com http:// ou https://');
    Exit;
  end;

  if not LOpenAIUrl.IsEmpty and not (LOpenAIUrl.StartsWith('http://', True) or LOpenAIUrl.StartsWith('https://', True)) then
  begin
    ShowMessage('A Custom Base URL da OpenAI deve iniciar com http:// ou https://');
    Exit;
  end;

  FConfig.SetApiKey(ptGemini, Trim(edtGeminiKey.Text));
  FConfig.SetApiKey(ptOpenAI, Trim(edtOpenAIKey.Text));
  FConfig.OpenAICustomBaseUrl := LOpenAIUrl;
  FConfig.SetApiKey(ptClaude, Trim(edtClaudeKey.Text));
  FConfig.SetApiKey(ptDeepSeek, Trim(edtDeepSeekKey.Text));
  FConfig.SetApiKey(ptGroq, Trim(edtGroqKey.Text));
  FConfig.SystemPrompt := memSystemPrompt.Text;
  FConfig.OllamaBaseUrl := LOllamaUrl;
  FConfig.Save;

  ShowMessage('Settings saved successfully.');

  LForm := GetParentForm(Self);
  if LForm <> nil then
    LForm.ModalResult := mrOk;
end;

procedure TFrameAIConfig.btnCancelClick(Sender: TObject);
var
  LForm: TCustomForm;
begin
  LoadConfig;
  LForm := GetParentForm(Self);
  if LForm <> nil then
    LForm.ModalResult := mrCancel;
end;

end.
