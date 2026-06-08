unit RadIA.Provider.OpenAI;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAOpenAIProvider = class(TRadIAOpenAICompatibleProvider)
  protected
    function GetBaseUrl: string; override;
    function GetModelsDiscoveryUrl: string; override;
    function FilterModelId(const AId: string): Boolean; override;
  public
    constructor Create(const AConfig: IAIConfig); override;

    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading, System.Math, RadIA.Core.ProviderRegistry;

{ TRadIAOpenAIProvider }

constructor TRadIAOpenAIProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderId := 'OpenAI';
end;

function TRadIAOpenAIProvider.GetBaseUrl: string;
begin
  if not FConfig.GetOpenAICustomBaseUrl.IsEmpty then
    Result := FConfig.GetOpenAICustomBaseUrl
  else
    Result := 'https://api.openai.com/v1';
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
  Result := GetBaseUrl.TrimRight(['/']) + '/models';
end;

function TRadIAOpenAIProvider.FilterModelId(const AId: string): Boolean;
begin
  { Accept only GPT and O-series reasoning models }
  Result := not AId.IsEmpty and
    (AId.StartsWith('gpt-') or AId.StartsWith('o1-') or AId.StartsWith('o3-'));
end;

procedure TRadIAOpenAIProvider.FetchAvailableModelsAsync(
  const ACallback: TProc<TArray<string>, string>);
begin
  inherited FetchAvailableModelsAsync(ACallback);
end;

initialization
  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create(
      'OpenAI',
      'OpenAI ChatGPT',
      'https://api.openai.com/v1',
      True, // HasApiKey
      True, // HasCustomUrl
      [MODEL_OPENAI_GPT4O_MINI, MODEL_OPENAI_GPT4O],
      function(const ACfg: IAIConfig): IIAProvider
      begin
        Result := TRadIAOpenAIProvider.Create(ACfg);
      end
    )
  );

end.
