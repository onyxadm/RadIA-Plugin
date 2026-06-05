unit RadIA.Provider.DeepSeek;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIADeepSeekProvider = class(TRadIAProviderBase)
  protected
    function GetModelsDiscoveryUrl: string; override;
  public
    constructor Create(const AConfig: IAIConfig); override;

    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TCompletionCallback; const ATemperature: Double; const AMaxTokens: Integer); override;
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TStreamChunkCallback; const ATemperature: Double; const AMaxTokens: Integer); override;
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading, System.Math;

{ TRadIADeepSeekProvider }

constructor TRadIADeepSeekProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderType := ptDeepSeek;
end;

function TRadIADeepSeekProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_DEEPSEEK_CHAT, MODEL_DEEPSEEK_REASONING);
end;

function TRadIADeepSeekProvider.GetName: string;
begin
  Result := 'DeepSeek';
end;

function TRadIADeepSeekProvider.GetModelsDiscoveryUrl: string;
begin
  Result := 'https://api.deepseek.com/models';
end;

{ FilterModelId uses the default base implementation (accept all non-empty IDs) }

procedure TRadIADeepSeekProvider.SendPromptAsync(const APrompt: string;
  const AHistory: TArray<IChatMessage>; const ACallback: TCompletionCallback;
  const ATemperature: Double; const AMaxTokens: Integer);
var
  LUrl, LApiKey, LRequestBody: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
  LProviderRef: IIAProvider;
begin
  LProviderRef := Self;
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', 'API Key is missing for DeepSeek. Please check settings.', False, TTokenUsage.Empty);
    Exit;
  end;

  LUrl := 'https://api.deepseek.com/chat/completions';
  SetLength(LHeaders, 1);
  LHeaders[0] := TNetHeader.Create('Authorization', 'Bearer ' + LApiKey);

  try
    LRequestBody := BuildOpenAICompatibleRequestBody(APrompt, AHistory, False, ATemperature, AMaxTokens);
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
      LErrorMsg: string;
    begin
      System.Math.SetExceptionMask(System.Math.exAllArithmeticExceptions);
      LProviderRef.GetProviderType;
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
          LErrorMsg := E.ClassName + ': ' + E.Message;
          TThread.Queue(nil,
            procedure
            begin
              ACallback('', LErrorMsg, False, TTokenUsage.Empty);
            end);
        end;
      end;
    end;

  TTask.Run(LTaskProc);
end;

procedure TRadIADeepSeekProvider.FetchAvailableModelsAsync(
  const ACallback: TProc<TArray<string>, string>);
begin
  { Delegates to the base implementation which uses GetModelsDiscoveryUrl }
  inherited FetchAvailableModelsAsync(ACallback);
end;

procedure TRadIADeepSeekProvider.SendPromptStreamAsync(const APrompt: string;
  const AHistory: TArray<IChatMessage>; const ACallback: TStreamChunkCallback;
  const ATemperature: Double; const AMaxTokens: Integer);
var
  LUrl, LApiKey, LRequestBody: string;
  LHeaders: TNetHeaders;
  LTaskProc: TProc;
  LProviderRef: IIAProvider;
begin
  LProviderRef := Self;
  LApiKey := GetApiKey;
  if LApiKey.IsEmpty then
  begin
    ACallback('', True, 'API Key is missing for DeepSeek. Please check settings.');
    Exit;
  end;

  LUrl := 'https://api.deepseek.com/chat/completions';
  SetLength(LHeaders, 1);
  LHeaders[0] := TNetHeader.Create('Authorization', 'Bearer ' + LApiKey);

  try
    LRequestBody := BuildOpenAICompatibleRequestBody(APrompt, AHistory, True, ATemperature, AMaxTokens);
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
      LErrorMsg: string;
    begin
      System.Math.SetExceptionMask(System.Math.exAllArithmeticExceptions);
      LProviderRef.GetProviderType;
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
          LErrorMsg := E.ClassName + ': ' + E.Message;
          TThread.Queue(nil,
            procedure
            begin
              ACallback('', True, LErrorMsg);
            end);
        end;
      end;
    end;

  TTask.Run(LTaskProc);
end;

end.
