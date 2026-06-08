unit RadIA.Provider.Mistral;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAMistralProvider = class(TRadIAOpenAICompatibleProvider)
  protected
    function GetBaseUrl: string; override;
    function GetModelsDiscoveryUrl: string; override;
  public
    constructor Create(const AConfig: IAIConfig); override;

    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading, System.Math, RadIA.Core.ProviderRegistry;

{ TRadIAMistralProvider }

constructor TRadIAMistralProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderId := 'Mistral';
end;

function TRadIAMistralProvider.GetBaseUrl: string;
begin
  Result := 'https://api.mistral.ai/v1';
end;

function TRadIAMistralProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_MISTRAL_CODESTRAL, MODEL_MISTRAL_LARGE, MODEL_MISTRAL_OPEN_7B);
end;

function TRadIAMistralProvider.GetName: string;
begin
  Result := 'Mistral AI';
end;

function TRadIAMistralProvider.GetModelsDiscoveryUrl: string;
begin
  Result := GetBaseUrl.TrimRight(['/']) + '/models';
end;

procedure TRadIAMistralProvider.FetchAvailableModelsAsync(
  const ACallback: TProc<TArray<string>, string>);
begin
  inherited FetchAvailableModelsAsync(ACallback);
end;

initialization
  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create(
      'Mistral',
      'Mistral AI',
      'https://api.mistral.ai/v1',
      True, // HasApiKey
      False, // HasCustomUrl
      [MODEL_MISTRAL_CODESTRAL, MODEL_MISTRAL_LARGE, MODEL_MISTRAL_OPEN_7B],
      function(const ACfg: IAIConfig): IIAProvider
      begin
        Result := TRadIAMistralProvider.Create(ACfg);
      end
    )
  );

end.
