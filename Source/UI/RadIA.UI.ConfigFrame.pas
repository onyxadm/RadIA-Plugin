unit RadIA.UI.ConfigFrame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Config;

type
  TFrameAIConfig = class(TFrame)
    pnlMain: TPanel;
    grpGemini: TGroupBox;
    lblGeminiKey: TLabel;
    edtGeminiKey: TEdit;
    grpOpenAI: TGroupBox;
    lblOpenAIKey: TLabel;
    edtOpenAIKey: TEdit;
    grpClaude: TGroupBox;
    lblClaudeKey: TLabel;
    edtClaudeKey: TEdit;
    grpOllama: TGroupBox;
    lblOllamaUrl: TLabel;
    edtOllamaUrl: TEdit;
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
  edtClaudeKey.Text := FConfig.GetApiKey(ptClaude);
  memSystemPrompt.Text := FConfig.SystemPrompt;
  edtOllamaUrl.Text := FConfig.OllamaBaseUrl;
end;

procedure TFrameAIConfig.btnSaveClick(Sender: TObject);
var
  LForm: TCustomForm;
begin
  FConfig.SetApiKey(ptGemini, Trim(edtGeminiKey.Text));
  FConfig.SetApiKey(ptOpenAI, Trim(edtOpenAIKey.Text));
  FConfig.SetApiKey(ptClaude, Trim(edtClaudeKey.Text));
  FConfig.SystemPrompt := memSystemPrompt.Text;
  FConfig.OllamaBaseUrl := Trim(edtOllamaUrl.Text);
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
