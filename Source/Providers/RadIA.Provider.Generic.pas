unit RadIA.Provider.Generic;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Interfaces, RadIA.Core.Types, 
  RadIA.Core.TokenUsage, RadIA.Provider.Base;

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
    constructor Create(const AConfig: IAIConfig; const AProviderId, ADisplayName, ADefaultBaseUrl: string; const ADefaultModels: TArray<string>); reintroduce;

    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading, System.Math;

{ TRadIAGenericOpenAIProvider }

constructor TRadIAGenericOpenAIProvider.Create(const AConfig: IAIConfig;
  const AProviderId, ADisplayName, ADefaultBaseUrl: string;
  const ADefaultModels: TArray<string>);
begin
  inherited Create(AConfig);
  FProviderId := AProviderId;
  FDisplayName := ADisplayName;
  FDefaultBaseUrl := ADefaultBaseUrl;
  FDefaultModels := ADefaultModels;
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

procedure TRadIAGenericOpenAIProvider.FetchAvailableModelsAsync(
  const ACallback: TProc<TArray<string>, string>);
begin
  inherited FetchAvailableModelsAsync(ACallback);
end;

end.
