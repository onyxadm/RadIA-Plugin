unit RadIA.Provider.DeepSeek;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIADeepSeekProvider = class(TRadIAOpenAICompatibleProvider)
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
  System.JSON, System.Threading, System.Math, RadIA.Core.ProviderRegistry;

{ TRadIADeepSeekProvider }

constructor TRadIADeepSeekProvider.Create(const AConfig: IRadIAConfig);
begin
  inherited Create(AConfig);
  FProviderId := 'DeepSeek';
end;

function TRadIADeepSeekProvider.GetBaseUrl: string;
begin
  Result := 'https://api.deepseek.com';
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
  Result := GetBaseUrl.TrimRight(['/']) + '/models';
end;



initialization
  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create(
      'DeepSeek',
      'DeepSeek',
      'https://api.deepseek.com',
      True, // HasApiKey
      False, // HasCustomUrl
      [MODEL_DEEPSEEK_CHAT, MODEL_DEEPSEEK_REASONING],
      function(const ACfg: IRadIAConfig): IRadIAProvider
      begin
        Result := TRadIADeepSeekProvider.Create(ACfg);
      end
    )
  );

end.
