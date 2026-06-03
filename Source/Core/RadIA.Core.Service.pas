unit RadIA.Core.Service;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Cache, RadIA.Core.TokenUsage;

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
    function GetEffectiveSystemPrompt: string;
    function BuildEffectiveHistory(const ASystemPrompt: string; const ATrimmedHistory: TArray<IChatMessage>): TArray<IChatMessage>;
  public
    constructor Create(const AConfig: IAIConfig);
    destructor Destroy; override;
    
    function CreateActiveProvider: IIAProvider;
    function TrimHistory(const AHistory: TArray<IChatMessage>): TArray<IChatMessage>;
    procedure SendPrompt(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback);
    procedure SendPromptStream(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TStreamChunkCallback);
      
    class function CreateMessage(const ARole: TAIMessageRole; const AContent: string): IChatMessage;
  end;

implementation

uses
  System.IOUtils, System.JSON, RadIA.OTA.Helper, RadIA.Core.ProjectContext,
  RadIA.Provider.Gemini, RadIA.Provider.OpenAI, RadIA.Provider.Claude, RadIA.Provider.Ollama,
  RadIA.Provider.DeepSeek, RadIA.Provider.Groq;

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

function TRadIAService.TrimHistory(const AHistory: TArray<IChatMessage>): TArray<IChatMessage>;
var
  LMaxMessages: Integer;
  LMaxPairs: Integer;
  LStartIndex: Integer;
  LCount: Integer;
  LNonSystemHistory: TArray<IChatMessage>;
  LMsg: IChatMessage;
  I: Integer;
begin
  LMaxMessages := FConfig.GetMaxHistoryMessages;

  { Separate system messages (handled externally) from user/assistant pairs }
  SetLength(LNonSystemHistory, 0);
  for LMsg in AHistory do
  begin
    if LMsg.Role <> mrSystem then
    begin
      SetLength(LNonSystemHistory, Length(LNonSystemHistory) + 1);
      LNonSystemHistory[High(LNonSystemHistory)] := LMsg;
    end;
  end;

  { LMaxMessages pairs = LMaxMessages * 2 messages (user + assistant) }
  LMaxPairs := LMaxMessages * 2;
  LCount := Length(LNonSystemHistory);

  if LCount <= LMaxPairs then
  begin
    Result := LNonSystemHistory;
    Exit;
  end;

  { Keep only the most recent LMaxPairs messages }
  LStartIndex := LCount - LMaxPairs;
  SetLength(Result, LMaxPairs);
  for I := 0 to LMaxPairs - 1 do
    Result[I] := LNonSystemHistory[LStartIndex + I];
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
    ptOllama: Result := TRadIAOllamaProvider.Create(FConfig);
    ptDeepSeek: Result := TRadIADeepSeekProvider.Create(FConfig);
    ptGroq: Result := TRadIAGroqProvider.Create(FConfig);
  else
    raise Exception.Create('Invalid active provider type selected.');
  end;
end;

function TRadIAService.GetEffectiveSystemPrompt: string;
var
  LSystemPrompt: string;
  LProjectFolder: string;
  LProjectContext: string;
begin
  LSystemPrompt := FConfig.SystemPrompt;
  LProjectFolder := TRadIAOTAHelper.GetActiveProjectFolder;
  if not LProjectFolder.IsEmpty then
  begin
    if TProjectContextLoader.LoadContext(LProjectFolder, LProjectContext) and not LProjectContext.IsEmpty then
    begin
      if LSystemPrompt.IsEmpty then
        LSystemPrompt := LProjectContext
      else
        LSystemPrompt := LProjectContext + sLineBreak + sLineBreak + LSystemPrompt;
    end;
  end;
  Result := LSystemPrompt;
end;

function TRadIAService.BuildEffectiveHistory(const ASystemPrompt: string;
  const ATrimmedHistory: TArray<IChatMessage>): TArray<IChatMessage>;
var
  I: Integer;
begin
  if not ASystemPrompt.IsEmpty then
  begin
    SetLength(Result, Length(ATrimmedHistory) + 1);
    Result[0] := TRadIAChatMessage.Create(mrSystem, ASystemPrompt);
    for I := 0 to High(ATrimmedHistory) do
      Result[I + 1] := ATrimmedHistory[I];
  end
  else
    Result := ATrimmedHistory;
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
  LTrimmedHistory: TArray<IChatMessage>;
begin
  try
    LProvider := CreateActiveProvider;
    LProviderName := ProviderTypeToString(FConfig.GetActiveProvider);
    LModelName := FConfig.GetActiveModel(FConfig.GetActiveProvider);
    
    LSystemPrompt := GetEffectiveSystemPrompt;
    LTrimmedHistory := TrimHistory(AHistory);

    { Serialize trimmed history to compute Hash }
    LHistoryJson := TJSONArray.Create;
    try
      for LMsg in LTrimmedHistory do
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
      ACallback(LCachedResponse, '', True, TTokenUsage.Empty);
      Exit;
    end;

    { Build effective history with system instructions }
    LHistory := BuildEffectiveHistory(LSystemPrompt, LTrimmedHistory);

    { Perform the actual async prompt request }
    LProvider.SendPromptAsync(APrompt, LHistory,
      procedure(const AResponse: string; const AError: string; AFromCache: Boolean; const AUsage: TTokenUsage)
      begin
        if AError.IsEmpty then
        begin
          FCacheManager.Put(LHash, AResponse);
        end;
        ACallback(AResponse, AError, False, AUsage);
      end);
  except
    on E: Exception do
    begin
      ACallback('', 'Failed to initialize AI Provider: ' + E.Message, False, TTokenUsage.Empty);
    end;
  end;
end;

procedure TRadIAService.SendPromptStream(const APrompt: string; const AHistory: TArray<IChatMessage>;
  const ACallback: TStreamChunkCallback);
var
  LProvider: IIAProvider;
  LSystemPrompt: string;
  LHistory: TArray<IChatMessage>;
  LTrimmedHistory: TArray<IChatMessage>;
begin
  try
    LProvider := CreateActiveProvider;
    LSystemPrompt := GetEffectiveSystemPrompt;
    LTrimmedHistory := TrimHistory(AHistory);
    LHistory := BuildEffectiveHistory(LSystemPrompt, LTrimmedHistory);

    { Perform the stream request }
    LProvider.SendPromptStreamAsync(APrompt, LHistory, ACallback);
  except
    on E: Exception do
    begin
      ACallback('', True, 'Failed to initialize AI Provider: ' + E.Message);
    end;
  end;
end;

class function TRadIAService.CreateMessage(const ARole: TAIMessageRole; const AContent: string): IChatMessage;
begin
  Result := TRadIAChatMessage.Create(ARole, AContent);
end;

end.
