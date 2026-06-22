unit RadIA.Provider.Qwen;

interface

uses  RadIA.Core.Interfaces, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAQwenProvider = class(TRadIAOpenAICompatibleProvider)
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

{ TRadIAQwenProvider }

constructor TRadIAQwenProvider.Create(const AConfig: IRadIAConfig);
begin
  inherited Create(AConfig);
  FProviderId := 'Qwen';
end;

function TRadIAQwenProvider.GetBaseUrl: string;
begin
  Result := 'https://dashscope.aliyuncs.com/compatible-mode/v1';
end;

function TRadIAQwenProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_QWEN_25_CODER_32B, MODEL_QWEN_25_CODER_7B, MODEL_QWEN_25_PLUS);
end;

function TRadIAQwenProvider.GetName: string;
begin
  Result := 'Alibaba Qwen';
end;

function TRadIAQwenProvider.GetModelsDiscoveryUrl: string;
begin
  Result := GetBaseUrl.TrimRight(['/']) + '/models';
end;

initialization
  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create(
      'Qwen',
      'Alibaba Qwen',
      'https://dashscope.aliyuncs.com/compatible-mode/v1',
      True, // HasApiKey
      False, // HasCustomUrl
      [MODEL_QWEN_25_CODER_32B, MODEL_QWEN_25_CODER_7B, MODEL_QWEN_25_PLUS],
      function(const ACfg: IRadIAConfig): IRadIAProvider
      begin
        Result := TRadIAQwenProvider.Create(ACfg);
      end
    )
  );

end.
