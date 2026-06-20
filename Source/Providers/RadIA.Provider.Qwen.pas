unit RadIA.Provider.Qwen;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAQwenProvider = class(TRadIAOpenAICompatibleProvider)
  protected
    function GetBaseUrl: string; override;
    function GetModelsDiscoveryUrl: string; override;
  public
    constructor Create(const AConfig: IRadIAConfig); override;

    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading, System.Math, RadIA.Core.ProviderRegistry;

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

procedure TRadIAQwenProvider.FetchAvailableModelsAsync(
  const ACallback: TProc<TArray<string>, string>);
begin
  inherited FetchAvailableModelsAsync(ACallback);
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
