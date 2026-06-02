unit RadIA.Core.Service;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Interfaces, RadIA.Core.Types;

type
  { Simple concrete class implementing IChatMessage }
  TRadIAChatMessage = class(TInterfacedObject, IChatMessage)
  private
    FRole: TAIMessageRole;
    FContent: string;
    
    function GetRole: TAIMessageRole;
    function GetContent: string;
    procedure SetContent(const AValue: string);
  public
    constructor Create(const ARole: TAIMessageRole; const AContent: string);
    
    property Role: TAIMessageRole read GetRole;
    property Content: string read GetContent write SetContent;
  end;

  { Orchestrator service to manage active provider instantiation }
  TRadIAService = class
  private
    FConfig: IAIConfig;
    function CreateActiveProvider: IIAProvider;
  public
    constructor Create(const AConfig: IAIConfig);
    
    procedure SendPrompt(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback);
      
    class function CreateMessage(const ARole: TAIMessageRole; const AContent: string): IChatMessage;
  end;

implementation

uses
  RadIA.Provider.Gemini, RadIA.Provider.OpenAI, RadIA.Provider.Claude;

{ TRadIAChatMessage }

constructor TRadIAChatMessage.Create(const ARole: TAIMessageRole; const AContent: string);
begin
  inherited Create;
  FRole := ARole;
  FContent := AContent;
end;

function TRadIAChatMessage.GetContent: string;
begin
  Result := FContent;
end;

function TRadIAChatMessage.GetRole: TAIMessageRole;
begin
  Result := FRole;
end;

procedure TRadIAChatMessage.SetContent(const AValue: string);
begin
  FContent := AValue;
end;

{ TRadIAService }

constructor TRadIAService.Create(const AConfig: IAIConfig);
begin
  inherited Create;
  FConfig := AConfig;
end;

function TRadIAService.CreateActiveProvider: IIAProvider;
var
  LProviderType: TAIProviderType;
begin
  LProviderType := FConfig.GetActiveProvider;
  case LProviderType of
    ptGemini: Result := TRadIAGeminiProvider.Create(FConfig);
    ptOpenAI: Result := TRadIAOpenAIProvider.Create(FConfig);
    ptClaude: Result := TRadIAClaudeProvider.Create(FConfig);
  else
    raise Exception.Create('Invalid active provider type selected.');
  end;
end;

procedure TRadIAService.SendPrompt(const APrompt: string; const AHistory: TArray<IChatMessage>; 
  const ACallback: TCompletionCallback);
var
  LProvider: IIAProvider;
begin
  try
    LProvider := CreateActiveProvider;
    LProvider.SendPromptAsync(APrompt, AHistory, ACallback);
  except
    on E: Exception do
    begin
      ACallback('', 'Failed to initialize AI Provider: ' + E.Message);
    end;
  end;
end;

class function TRadIAService.CreateMessage(const ARole: TAIMessageRole; const AContent: string): IChatMessage;
begin
  Result := TRadIAChatMessage.Create(ARole, AContent);
end;

end.
