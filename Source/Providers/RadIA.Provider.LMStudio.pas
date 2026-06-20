unit RadIA.Provider.LMStudio;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIALMStudioProvider = class(TRadIAOpenAICompatibleProvider)
  protected
    function GetBaseUrl: string; override;
    function GetModelsDiscoveryUrl: string; override;
  public
    constructor Create(const AConfig: IRadIAConfig); override;

    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IRadIAChatMessage>;
      const ACallback: TCompletionCallback; const ATemperature: Double; const AMaxTokens: Integer); override;
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IRadIAChatMessage>;
      const ACallback: TStreamChunkCallback; const ATemperature: Double; const AMaxTokens: Integer); override;
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading, System.Math, RadIA.Core.ProviderRegistry;

{ TRadIALMStudioProvider }

constructor TRadIALMStudioProvider.Create(const AConfig: IRadIAConfig);
begin
  inherited Create(AConfig);
  FProviderId := 'LMStudio';
end;

function TRadIALMStudioProvider.GetBaseUrl: string;
begin
  Result := FConfig.GetProviderBaseUrl(FProviderId);
  if Result.IsEmpty then
    Result := 'http://localhost:1234/v1';
end;

function TRadIALMStudioProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create('lms-default');
end;

function TRadIALMStudioProvider.GetName: string;
begin
  Result := 'LM Studio';
end;

function TRadIALMStudioProvider.GetModelsDiscoveryUrl: string;
begin
  Result := GetBaseUrl.TrimRight(['/']) + '/models';
end;

procedure TRadIALMStudioProvider.FetchAvailableModelsAsync(
  const ACallback: TProc<TArray<string>, string>);
begin
  inherited FetchAvailableModelsAsync(ACallback);
end;

procedure TRadIALMStudioProvider.SendPromptAsync(const APrompt: string;
  const AHistory: TArray<IRadIAChatMessage>; const ACallback: TCompletionCallback;
  const ATemperature: Double; const AMaxTokens: Integer);
var
  LUrl, LRequestBody: string;
  LHeaders: TNetHeaders;
  LApiKey: string;
begin
  LUrl := GetBaseUrl.TrimRight(['/']) + '/chat/completions';
  
  LApiKey := FConfig.GetApiKey(FProviderId);
  if LApiKey.IsEmpty then
    LApiKey := 'lm-studio'; { Dummy API Key since LM Studio is local and doesn't require auth }

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

  ExecuteRequestAsync(LUrl, LHeaders, LRequestBody,
    function(const AResponseJson: string; out AUsage: TTokenUsage): string
    begin
      Result := ParseOpenAICompatibleResponse(AResponseJson, AUsage);
    end, ACallback);
end;

procedure TRadIALMStudioProvider.SendPromptStreamAsync(const APrompt: string;
  const AHistory: TArray<IRadIAChatMessage>; const ACallback: TStreamChunkCallback;
  const ATemperature: Double; const AMaxTokens: Integer);
var
  LUrl, LRequestBody: string;
  LHeaders: TNetHeaders;
  LApiKey: string;
begin
  LUrl := GetBaseUrl.TrimRight(['/']) + '/chat/completions';
  
  LApiKey := FConfig.GetApiKey(FProviderId);
  if LApiKey.IsEmpty then
    LApiKey := 'lm-studio'; { Dummy API Key }

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

  ExecuteRequestStreamAsync(LUrl, LHeaders, LRequestBody,
    function(const ABuffer: string): string
    var
      LTemp: string;
    begin
      LTemp := ABuffer;
      ProcessOpenAICompatibleStreamBuffer(LTemp, ACallback);
      Result := LTemp;
    end, ACallback);
end;

initialization
  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create(
      'LMStudio',
      'LM Studio',
      'http://localhost:1234/v1',
      False, { HasApiKey }
      True,  { HasCustomUrl }
      ['lms-default'],
      function(const ACfg: IRadIAConfig): IRadIAProvider
      begin
        Result := TRadIALMStudioProvider.Create(ACfg);
      end
    )
  );

end.
