unit RadIA.Provider.OpenAI;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAOpenAIProvider = class(TRadIAProviderBase)
  private
    function GetChatCompletionsUrl: string;
  protected
    function GetModelsDiscoveryUrl: string; override;
    function FilterModelId(const AId: string): Boolean; override;
  public
    constructor Create(const AConfig: IAIConfig); override;

    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TCompletionCallback); override;
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TStreamChunkCallback); override;
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading;

{ TRadIAOpenAIProvider }

constructor TRadIAOpenAIProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderType := ptOpenAI;
end;

function TRadIAOpenAIProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_OPENAI_GPT4O_MINI, MODEL_OPENAI_GPT4O);
end;

function TRadIAOpenAIProvider.GetName: string;
begin
  Result := 'OpenAI ChatGPT';
end;

function TRadIAOpenAIProvider.GetModelsDiscoveryUrl: string;
begin
  if not FConfig.GetOpenAICustomBaseUrl.IsEmpty then
    Result := FConfig.GetOpenAICustomBaseUrl.TrimRight(['/']) + '/models'
  else
    Result := 'https://api.openai.com/v1/models';
end;

function TRadIAOpenAIProvider.FilterModelId(const AId: string): Boolean;
begin
  { Accept only GPT and O-series reasoning models }
  Result := not AId.IsEmpty and
    (AId.StartsWith('gpt-') or AId.StartsWith('o1-') or AId.StartsWith('o3-'));
end;

function TRadIAOpenAIProvider.GetChatCompletionsUrl: string;
begin
  if not FConfig.GetOpenAICustomBaseUrl.IsEmpty then
    Result := FConfig.GetOpenAICustomBaseUrl.TrimRight(['/']) + '/chat/completions'
  else
    Result := 'https://api.openai.com/v1/chat/completions';
end;

procedure TRadIAOpenAIProvider.SendPromptAsync(const APrompt: string;
  const AHistory: TArray<IChatMessage>; const ACallback: TCompletionCallback);
var
  LUrl, LApiKey, LRequestBody: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', 'API Key is missing for OpenAI. Please check settings.', False, TTokenUsage.Empty);
    Exit;
  end;

  LUrl := GetChatCompletionsUrl;
  SetLength(LHeaders, 1);
  LHeaders[0] := TNetHeader.Create('Authorization', 'Bearer ' + LApiKey);

  try
    LRequestBody := BuildOpenAICompatibleRequestBody(APrompt, AHistory, False);
  except
    on E: Exception do
    begin
      ACallback('', 'Error building request JSON: ' + E.Message, False, TTokenUsage.Empty);
      Exit;
    end;
  end;

  LTaskProc :=
    procedure
    var
      LResponseText: string;
      LUsage: TTokenUsage;
    begin
      try
        LResponseText := DoPostRequest(LUrl, LHeaders, LRequestBody);
        LResponseText := ParseOpenAICompatibleResponse(LResponseText, LUsage);

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

procedure TRadIAOpenAIProvider.FetchAvailableModelsAsync(
  const ACallback: TProc<TArray<string>, string>);
begin
  { Delegates to the base implementation which uses GetModelsDiscoveryUrl and FilterModelId }
  inherited FetchAvailableModelsAsync(ACallback);
end;

procedure TRadIAOpenAIProvider.SendPromptStreamAsync(const APrompt: string;
  const AHistory: TArray<IChatMessage>; const ACallback: TStreamChunkCallback);
var
  LUrl, LApiKey, LRequestBody: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', True, 'API Key is missing for OpenAI. Please check settings.');
    Exit;
  end;

  LUrl := GetChatCompletionsUrl;
  SetLength(LHeaders, 1);
  LHeaders[0] := TNetHeader.Create('Authorization', 'Bearer ' + LApiKey);

  try
    LRequestBody := BuildOpenAICompatibleRequestBody(APrompt, AHistory, True);
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
            ProcessOpenAICompatibleStreamBuffer(LBufferText, ACallback);
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
