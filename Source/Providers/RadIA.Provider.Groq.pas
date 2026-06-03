unit RadIA.Provider.Groq;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAGroqProvider = class(TRadIAProviderBase)
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

{ TRadIAGroqProvider }

constructor TRadIAGroqProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderType := ptGroq;
end;

function TRadIAGroqProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_GROQ_LLAMA33, MODEL_GROQ_MIXTRAL, MODEL_GROQ_GEMMA2);
end;

function TRadIAGroqProvider.GetName: string;
begin
  Result := 'Groq';
end;

function TRadIAGroqProvider.GetModelsDiscoveryUrl: string;
begin
  Result := 'https://api.groq.com/openai/v1/models';
end;

function TRadIAGroqProvider.FilterModelId(const AId: string): Boolean;
begin
  { Accept only the model families supported by Groq }
  Result := not AId.IsEmpty and
    (AId.Contains('llama') or AId.Contains('mixtral') or AId.Contains('gemma'));
end;

procedure TRadIAGroqProvider.SendPromptAsync(const APrompt: string;
  const AHistory: TArray<IChatMessage>; const ACallback: TCompletionCallback);
var
  LUrl, LApiKey, LRequestBody: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', 'API Key is missing for Groq. Please check settings.', False, TTokenUsage.Empty);
    Exit;
  end;

  LUrl := 'https://api.groq.com/openai/v1/chat/completions';
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

procedure TRadIAGroqProvider.FetchAvailableModelsAsync(
  const ACallback: TProc<TArray<string>, string>);
begin
  { Delegates to the base implementation which uses GetModelsDiscoveryUrl and FilterModelId }
  inherited FetchAvailableModelsAsync(ACallback);
end;

procedure TRadIAGroqProvider.SendPromptStreamAsync(const APrompt: string;
  const AHistory: TArray<IChatMessage>; const ACallback: TStreamChunkCallback);
var
  LUrl, LApiKey, LRequestBody: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
begin
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', True, 'API Key is missing for Groq. Please check settings.');
    Exit;
  end;

  LUrl := 'https://api.groq.com/openai/v1/chat/completions';
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
