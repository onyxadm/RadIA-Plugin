unit RadIA.Provider.Generic;

interface

uses  RadIA.Core.Interfaces, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAGenericOpenAIProvider = class(TRadIAOpenAICompatibleProvider)
  private
    FDefaultBaseUrl: string;
    FDisplayName: string;
    FDefaultModels: TArray<string>;
  protected
    function GetBaseUrl: string; override;
    function GetModelsDiscoveryUrl: string; override;
  public
    constructor Create(const AConfig: IRadIAConfig; const AProviderId, ADisplayName, ADefaultBaseUrl: string; const ADefaultModels: TArray<string>; const AApiKey: string = ''); reintroduce;

    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.SysUtils, RadIA.Core.Logger;

{ TRadIAGenericOpenAIProvider }

constructor TRadIAGenericOpenAIProvider.Create(const AConfig: IRadIAConfig;
  const AProviderId, ADisplayName, ADefaultBaseUrl: string;
  const ADefaultModels: TArray<string>; const AApiKey: string);
begin
  inherited Create(AConfig);
  FProviderId := AProviderId;
  FDisplayName := ADisplayName;
  FDefaultBaseUrl := ADefaultBaseUrl;
  FDefaultModels := ADefaultModels;

  // Grava a API Key no Config para que as chamadas internas do Delphi leiam de forma nativa.
  if not AApiKey.IsEmpty and AConfig.GetApiKey(FProviderId).IsEmpty then
  begin
    AConfig.SetApiKey(FProviderId, AApiKey);
    try
      AConfig.Save;
    except
      on E: Exception do
        TLogger.Log('TRadIAGenericOpenAIProvider.Create: Failed to save config: ' + E.Message, 'Provider');
    end;
  end;
end;

function TRadIAGenericOpenAIProvider.GetBaseUrl: string;
begin
  Result := FConfig.GetProviderBaseUrl(FProviderId);
  if Result.IsEmpty then
    Result := FDefaultBaseUrl;
end;

function TRadIAGenericOpenAIProvider.GetModelsDiscoveryUrl: string;
begin
  Result := GetBaseUrl.TrimRight(['/']) + '/models';
end;

function TRadIAGenericOpenAIProvider.GetAvailableModels: TArray<string>;
begin
  Result := FDefaultModels;
end;

function TRadIAGenericOpenAIProvider.GetName: string;
begin
  Result := FDisplayName;
end;



end.
