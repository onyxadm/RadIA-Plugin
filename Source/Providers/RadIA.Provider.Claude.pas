unit RadIA.Provider.Claude;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAClaudeProvider = class(TRadIAProviderBase)
  private
    function BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>; const AStream: Boolean = False): string;
    function ParseResponseBody(const AResponseJson: string; out AUsage: TTokenUsage): string;
  public
    constructor Create(const AConfig: IAIConfig); override;
    
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback); override;
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TStreamChunkCallback); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
    procedure ProcessStreamBuffer(var ABuffer: string; const ACallback: TStreamChunkCallback);
  end;

implementation

uses
  System.JSON, System.Threading;

{ TRadIAClaudeProvider }

constructor TRadIAClaudeProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderType := ptClaude;
end;

function TRadIAClaudeProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_CLAUDE_3_HAIKU, MODEL_CLAUDE_35_SONNET);
end;

function TRadIAClaudeProvider.GetName: string;
begin
  Result := 'Anthropic Claude';
end;

function TRadIAClaudeProvider.BuildRequestBody(const APrompt: string; const AHistory: TArray<IChatMessage>; const AStream: Boolean): string;
var
  LRootObj: TJSONObject;
  LMessagesArr: TJSONArray;
  LMsgObj: TJSONObject;
  LMsg: IChatMessage;
  LSystemPrompt: string;
begin
  LRootObj := TJSONObject.Create;
  try
    LRootObj.AddPair('model', GetActiveModel);
    LRootObj.AddPair('max_tokens', TJSONNumber.Create(4096));
    if AStream then
      LRootObj.AddPair('stream', TJSONBool.Create(True));
    
    LMessagesArr := TJSONArray.Create;
    LRootObj.AddPair('messages', LMessagesArr);
    
    LSystemPrompt := '';

    { Add History }
    for LMsg in AHistory do
    begin
      if LMsg.Role = mrSystem then
      begin
        LSystemPrompt := LSystemPrompt + LMsg.Content + sLineBreak;
        Continue;
      end;

      LMsgObj := TJSONObject.Create;
      LMessagesArr.AddElement(LMsgObj);
      LMsgObj.AddPair('role', MessageRoleToString(LMsg.Role));
      LMsgObj.AddPair('content', LMsg.Content);
    end;
    
    { Add Current Prompt }
    LMsgObj := TJSONObject.Create;
    LMessagesArr.AddElement(LMsgObj);
    LMsgObj.AddPair('role', 'user');
    LMsgObj.AddPair('content', APrompt);

    { Add System instruction if present }
    if not LSystemPrompt.IsEmpty then
    begin
      LRootObj.AddPair('system', LSystemPrompt.Trim);
    end;
    
    Result := LRootObj.ToJSON;
  finally
    LRootObj.Free;
  end;
end;

function TRadIAClaudeProvider.ParseResponseBody(const AResponseJson: string; out AUsage: TTokenUsage): string;
var
  LJsonObj: TJSONObject;
  LContentArr: TJSONArray;
  LContentObj: TJSONObject;
  LUsageNode: TJSONObject;
begin
  Result := '';
  AUsage := TTokenUsage.Empty;
  
  LJsonObj := TJSONObject.ParseJSONValue(AResponseJson) as TJSONObject;
  if Assigned(LJsonObj) then
  begin
    try
      LContentArr := LJsonObj.GetValue('content') as TJSONArray;
      if Assigned(LContentArr) and (LContentArr.Count > 0) then
      begin
        LContentObj := LContentArr.Items[0] as TJSONObject;
        if Assigned(LContentObj) then
        begin
          Result := LContentObj.GetValue<string>('text', '');
        end;
      end;
      
      if Result.IsEmpty then
      begin
        if LJsonObj.GetValue('error') <> nil then
          raise Exception.Create(LJsonObj.GetValue('error').ToString);
      end;

      { Extract token usage }
      LUsageNode := LJsonObj.GetValue('usage') as TJSONObject;
      if Assigned(LUsageNode) then
      begin
        AUsage.PromptTokens     := LUsageNode.GetValue<Integer>('input_tokens', 0);
        AUsage.CompletionTokens := LUsageNode.GetValue<Integer>('output_tokens', 0);
        AUsage.TotalTokens      := AUsage.PromptTokens + AUsage.CompletionTokens;
      end;
    finally
      LJsonObj.Free;
    end;
  end;
end;

procedure TRadIAClaudeProvider.SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
  const ACallback: TCompletionCallback);
var
  LUrl, LApiKey, LRequestBody: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', 'API Key is missing for Anthropic Claude. Please check settings.', False, TTokenUsage.Empty);
    Exit;
  end;

  LUrl := 'https://api.anthropic.com/v1/messages';
  
  SetLength(LHeaders, 2);
  LHeaders[0] := TNetHeader.Create('x-api-key', LApiKey);
  LHeaders[1] := TNetHeader.Create('anthropic-version', '2023-06-01');

  try
    LRequestBody := BuildRequestBody(APrompt, AHistory);
  except
    on E: Exception do
    begin
      ACallback('', 'Error building request JSON: ' + E.Message, False, TTokenUsage.Empty);
      Exit;
    end;
  end;

  LTaskProc := procedure
               var
                 LResponseText: string;
                 LUsage: TTokenUsage;
               begin
                 try
                   LResponseText := DoPostRequest(LUrl, LHeaders, LRequestBody);
                   LResponseText := ParseResponseBody(LResponseText, LUsage);
                   
                   TThread.Queue(nil,
                     procedure
                     begin
                       ACallback(LResponseText, '', False, LUsage);
                     end);
                 except
                   on E: Exception do
                   begin
                     TThread.Queue(nil,
                       procedure
                       begin
                         ACallback('', E.Message, False, TTokenUsage.Empty);
                       end);
                   end;
                 end;
               end;

  TTask.Run(LTaskProc);
end;

procedure TRadIAClaudeProvider.ProcessStreamBuffer(var ABuffer: string; const ACallback: TStreamChunkCallback);
var
  LLine: string;
  LJsonLine: string;
  LJson: TJSONObject;
  LTypeStr: string;
  LDeltaObj: TJSONObject;
  LText: string;
  LIdx: Integer;
  LStartPos: Integer;
  LPtr: PChar;
  LLen: Integer;
  LLastProcessedPos: Integer;
begin
  LLen := ABuffer.Length;
  if LLen = 0 then
    Exit;

  LPtr := PChar(ABuffer);
  LStartPos := 0;
  LLastProcessedPos := 0;

  while LStartPos < LLen do
  begin
    LIdx := LStartPos;
    while (LIdx < LLen) and (LPtr[LIdx] <> #10) do
      Inc(LIdx);
      
    if LIdx >= LLen then
      Break;
      
    LLine := ABuffer.Substring(LStartPos, LIdx - LStartPos);
    LStartPos := LIdx + 1;
    LLastProcessedPos := LStartPos;

    LLine := Trim(LLine);
    if LLine.StartsWith('data:') then
    begin
      LJsonLine := Trim(LLine.Substring(5));
      if LJsonLine.IsEmpty then
        Continue;

      try
        LJson := TJSONObject.ParseJSONValue(LJsonLine) as TJSONObject;
        if Assigned(LJson) then
        begin
          try
            LTypeStr := LJson.GetValue<string>('type', '');
            if LTypeStr = 'content_block_delta' then
            begin
              LDeltaObj := LJson.GetValue('delta') as TJSONObject;
              if Assigned(LDeltaObj) then
              begin
                LText := LDeltaObj.GetValue<string>('text', '');
                if not LText.IsEmpty then
                TThread.Queue(nil,
                  procedure
                  begin
                    ACallback(LText, False, '');
                  end);
              end;
            end
            else if LTypeStr = 'message_stop' then
            begin
              TThread.Queue(nil,
                procedure
                begin
                  ACallback('', True, '');
                end);
              
              ABuffer := ABuffer.Substring(LLastProcessedPos);
              Exit;
            end;
          finally
            LJson.Free;
          end;
        end;
      except
        { Ignore parse errors }
      end;
    end;
  end;

  if LLastProcessedPos > 0 then
  begin
    ABuffer := ABuffer.Substring(LLastProcessedPos);
  end;
end;

procedure TRadIAClaudeProvider.SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
  const ACallback: TStreamChunkCallback);
var
  LUrl, LApiKey, LRequestBody: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', True, 'API Key is missing for Anthropic Claude. Please check settings.');
    Exit;
  end;

  LUrl := 'https://api.anthropic.com/v1/messages';
  
  SetLength(LHeaders, 2);
  LHeaders[0] := TNetHeader.Create('x-api-key', LApiKey);
  LHeaders[1] := TNetHeader.Create('anthropic-version', '2023-06-01');

  try
    LRequestBody := BuildRequestBody(APrompt, AHistory, True);
  except
    on E: Exception do
    begin
      ACallback('', True, 'Error building request JSON: ' + E.Message);
      Exit;
    end;
  end;

  LTaskProc :=
    procedure
    var
      LBufferText: string;
    begin
      LBufferText := '';
      try
        DoPostRequestStream(LUrl, LHeaders, LRequestBody,
          procedure(ABytes: TBytes)
          begin
            LBufferText := LBufferText + TEncoding.UTF8.GetString(ABytes);
            ProcessStreamBuffer(LBufferText, ACallback);
          end);

        TThread.Queue(nil,
          procedure
          begin
            ACallback('', True, '');
          end);
      except
        on E: Exception do
        begin
          TThread.Queue(nil,
            procedure
            begin
              ACallback('', True, E.Message);
            end);
        end;
      end;
    end;

  TTask.Run(LTaskProc);
end;

end.
