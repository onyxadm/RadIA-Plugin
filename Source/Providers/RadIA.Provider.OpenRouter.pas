unit RadIA.Provider.OpenRouter;

interface

uses  RadIA.Core.Interfaces, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAOpenRouterProvider = class(TRadIAOpenAICompatibleProvider)
  protected
    function GetBaseUrl: string; override;
    function GetModelsDiscoveryUrl: string; override;
  public
    constructor Create(const AConfig: IRadIAConfig); override;

    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.SysUtils, RadIA.Core.ProviderRegistry, RadIA.Core.Types;

{ TRadIAOpenRouterProvider }

constructor TRadIAOpenRouterProvider.Create(const AConfig: IRadIAConfig);
begin
  inherited Create(AConfig);
  FProviderId := 'OpenRouter';
end;

function TRadIAOpenRouterProvider.GetBaseUrl: string;
begin
  Result := 'https://openrouter.ai/api/v1';
end;

function TRadIAOpenRouterProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_OPENROUTER_GEMINI25_PRO, MODEL_OPENROUTER_LLAMA33,
      MODEL_OPENROUTER_DEEPSEEK_R1);
end;

function TRadIAOpenRouterProvider.GetName: string;
begin
  Result := 'OpenRouter';
end;

function TRadIAOpenRouterProvider.GetModelsDiscoveryUrl: string;
begin
  Result := GetBaseUrl.TrimRight(['/']) + '/models';
end;



initialization
  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create(
      'OpenRouter',
      'OpenRouter',
      'https://openrouter.ai/api/v1',
      True, // HasApiKey
      False, // HasCustomUrl
      [MODEL_OPENROUTER_GEMINI25_PRO, MODEL_OPENROUTER_LLAMA33, MODEL_OPENROUTER_DEEPSEEK_R1],
      function(const ACfg: IRadIAConfig): IRadIAProvider
      begin
        Result := TRadIAOpenRouterProvider.Create(ACfg);
      end
    )
  );

end.
