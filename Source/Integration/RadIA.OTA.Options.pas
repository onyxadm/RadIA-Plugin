unit RadIA.OTA.Options;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, ToolsAPI,
  RadIA.Core.Types, RadIA.UI.ConfigFrame;

type
  { Provider page configuration tag }
  TRadIAPageTag = (ptNone, ptGemini, ptOpenAI, ptClaude, ptDeepSeek, ptGroq, ptOpenRouter, ptOllama, ptLMStudio, ptSystem, ptTemplates);

  { INTAAddInOptions implementation for RadIA Options }
  TRadIAAddInOptions = class(TInterfacedObject, INTAAddInOptions)
  private
    FTag: TRadIAPageTag;
    FTitle: string;
    FFrame: TFrameAIConfig;
  public
    constructor Create(const ATitle: string; ATag: TRadIAPageTag);
    
    { INTAAddInOptions }
    function GetArea: string;
    function GetCaption: string;
    function GetFrameClass: TCustomFrameClass;
    procedure FrameCreated(AFrame: TCustomFrame);
    procedure DialogClosed(Accepted: Boolean);
    function ValidateContents: Boolean;
    function GetHelpContext: Integer;
    function IncludeInIDEInsight: Boolean;
  end;

implementation

uses
  Vcl.ComCtrls;

{ TRadIAAddInOptions }

constructor TRadIAAddInOptions.Create(const ATitle: string; ATag: TRadIAPageTag);
begin
  inherited Create;
  FTitle := ATitle;
  FTag := ATag;
  FFrame := nil;
end;

function TRadIAAddInOptions.GetArea: string;
begin
  // Retornando vazio coloca a página sob a categoria principal "Third Party"
  Result := '';
end;

function TRadIAAddInOptions.GetCaption: string;
begin
  case FTag of
    ptNone: Result := 'RadIA.General';
    ptSystem: Result := 'RadIA.System Prompt';
    ptTemplates: Result := 'RadIA.Templates';
    ptGemini, ptOpenAI, ptClaude, ptDeepSeek, ptGroq, ptOpenRouter, ptOllama, ptLMStudio: 
      Result := 'RadIA.AI Providers.' + FTitle;
  else
    Result := 'RadIA.' + FTitle;
  end;
end;

function TRadIAAddInOptions.GetFrameClass: TCustomFrameClass;
begin
  Result := TFrameAIConfig;
end;

procedure TRadIAAddInOptions.FrameCreated(AFrame: TCustomFrame);
begin
  if AFrame is TFrameAIConfig then
  begin
    FFrame := TFrameAIConfig(AFrame);
    FFrame.LoadConfig;
    
    // Selecionar a aba adequada
    case FTag of
      ptNone: FFrame.SelectCategoryByName('General / Logs');
      ptSystem: FFrame.SelectCategoryByName('System Prompt');
      ptTemplates: FFrame.SelectCategoryByName('Templates');
      ptGemini: FFrame.SelectCategoryByName('Gemini');
      ptOpenAI: FFrame.SelectCategoryByName('OpenAI');
      ptClaude: FFrame.SelectCategoryByName('Claude');
      ptDeepSeek: FFrame.SelectCategoryByName('DeepSeek');
      ptGroq: FFrame.SelectCategoryByName('Groq');
      ptOpenRouter: FFrame.SelectCategoryByName('OpenRouter');
      ptOllama: FFrame.SelectCategoryByName('Ollama');
      ptLMStudio: FFrame.SelectCategoryByName('LM Studio');

    end;
  end;
end;

procedure TRadIAAddInOptions.DialogClosed(Accepted: Boolean);
begin
  if Assigned(FFrame) then
  begin
    if Accepted then
      FFrame.btnSaveClick(nil)
    else
      FFrame.btnCancelClick(nil);
    FFrame := nil;
  end;
end;

function TRadIAAddInOptions.ValidateContents: Boolean;
begin
  Result := True;
end;

function TRadIAAddInOptions.GetHelpContext: Integer;
begin
  Result := 0;
end;

function TRadIAAddInOptions.IncludeInIDEInsight: Boolean;
begin
  Result := True;
end;

end.
