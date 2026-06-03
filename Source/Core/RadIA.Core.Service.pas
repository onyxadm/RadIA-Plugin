unit RadIA.Core.Service;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Cache;

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
    FCacheManager: TRadIACacheManager;
  public
    constructor Create(const AConfig: IAIConfig);
    destructor Destroy; override;
    
    function CreateActiveProvider: IIAProvider;
    procedure SendPrompt(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback);
      
    class function CreateMessage(const ARole: TAIMessageRole; const AContent: string): IChatMessage;
  end;

implementation

uses
  System.IOUtils, System.JSON,
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
  FCacheManager := TRadIACacheManager.Create;
end;

destructor TRadIAService.Destroy;
begin
  FCacheManager.Free;
  inherited Destroy;
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
  LHash: string;
  LCachedResponse: string;
  LHistoryStr: string;
  LProviderName: string;
  LModelName: string;
  LSystemPrompt: string;
  LHistoryJson: TJSONArray;
  LMsg: IChatMessage;
  LMsgObj: TJSONObject;
  LHistory: TArray<IChatMessage>;
  I: Integer;
begin
  try
    LProvider := CreateActiveProvider;
    LProviderName := ProviderTypeToString(FConfig.GetActiveProvider);
    LModelName := FConfig.GetActiveModel(FConfig.GetActiveProvider);
    LSystemPrompt := FConfig.SystemPrompt;

    { Serialize history to compute Hash }
    LHistoryJson := TJSONArray.Create;
    try
      for LMsg in AHistory do
      begin
        LMsgObj := TJSONObject.Create;
        LMsgObj.AddPair('role', MessageRoleToString(LMsg.Role));
        LMsgObj.AddPair('content', LMsg.Content);
        LHistoryJson.AddElement(LMsgObj);
      end;
      LHistoryStr := LHistoryJson.ToJSON;
    finally
      LHistoryJson.Free;
    end;

    { Generate Hash }
    LHash := TRadIACacheManager.GenerateHash(LProviderName, LModelName, LSystemPrompt, APrompt, LHistoryStr);

    { Query Cache }
    if FCacheManager.Get(LHash, LCachedResponse) then
    begin
      { Return cache hit }
      ACallback(LCachedResponse, '', True);
      Exit;
    end;

    { Inject System Prompt if configured }
    if not LSystemPrompt.IsEmpty then
    begin
      SetLength(LHistory, Length(AHistory) + 1);
      LHistory[0] := TRadIAChatMessage.Create(mrSystem, LSystemPrompt);
      for I := 0 to High(AHistory) do
        LHistory[I + 1] := AHistory[I];
    end
    else
      LHistory := AHistory;

    { Perform the actual async prompt request }
    LProvider.SendPromptAsync(APrompt, LHistory,
      procedure(const AResponse: string; const AError: string; AFromCache: Boolean)
      begin
        if AError.IsEmpty then
        begin
          { Save to cache on success }
          FCacheManager.Put(LHash, AResponse);
        end;
        ACallback(AResponse, AError, False);
      end);
  except
    on E: Exception do
    begin
      ACallback('', 'Failed to initialize AI Provider: ' + E.Message, False);
    end;
  end;
end;

class function TRadIAService.CreateMessage(const ARole: TAIMessageRole; const AContent: string): IChatMessage;
begin
  Result := TRadIAChatMessage.Create(ARole, AContent);
end;

end.
