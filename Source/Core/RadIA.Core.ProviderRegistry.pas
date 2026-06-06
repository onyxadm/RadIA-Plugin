unit RadIA.Core.ProviderRegistry;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, RadIA.Core.Interfaces, RadIA.Core.Types;

type
  TProviderFactoryFunc = reference to function(const AConfig: IAIConfig): IIAProvider;

  TProviderMetadata = record
    Id: string;
    DisplayName: string;
    DefaultBaseUrl: string;
    HasApiKey: Boolean;
    HasCustomUrl: Boolean;
    DefaultModels: TArray<string>;
    FactoryFunc: TProviderFactoryFunc;
    
    class function Create(const AId, ADisplayName, ADefaultBaseUrl: string;
      AHasApiKey, AHasCustomUrl: Boolean; const ADefaultModels: TArray<string>;
      const AFactory: TProviderFactoryFunc): TProviderMetadata; static;
  end;

  TProviderRegistry = class
  private
    class var FProviders: TDictionary<string, TProviderMetadata>;
    class constructor Create;
    class destructor Destroy;
  public
    class procedure RegisterProvider(const AMetadata: TProviderMetadata);
    class function GetProvider(const AId: string; out AMetadata: TProviderMetadata): Boolean;
    class function GetProviders: TArray<TProviderMetadata>;
    class function CreateProvider(const AId: string; const AConfig: IAIConfig): IIAProvider;
    class function HasProvider(const AId: string): Boolean;
  end;

implementation

{ TProviderMetadata }

class function TProviderMetadata.Create(const AId, ADisplayName, ADefaultBaseUrl: string;
  AHasApiKey, AHasCustomUrl: Boolean; const ADefaultModels: TArray<string>;
  const AFactory: TProviderFactoryFunc): TProviderMetadata;
begin
  Result.Id := AId;
  Result.DisplayName := ADisplayName;
  Result.DefaultBaseUrl := ADefaultBaseUrl;
  Result.HasApiKey := AHasApiKey;
  Result.HasCustomUrl := AHasCustomUrl;
  Result.DefaultModels := ADefaultModels;
  Result.FactoryFunc := AFactory;
end;

{ TProviderRegistry }

class constructor TProviderRegistry.Create;
begin
  FProviders := TDictionary<string, TProviderMetadata>.Create;
end;

class destructor TProviderRegistry.Destroy;
begin
  FProviders.Free;
end;

class procedure TProviderRegistry.RegisterProvider(const AMetadata: TProviderMetadata);
begin
  FProviders.AddOrSetValue(AMetadata.Id.ToLower, AMetadata);
end;

class function TProviderRegistry.GetProvider(const AId: string; out AMetadata: TProviderMetadata): Boolean;
begin
  Result := FProviders.TryGetValue(AId.ToLower, AMetadata);
end;

class function TProviderRegistry.GetProviders: TArray<TProviderMetadata>;
var
  LList: TList<TProviderMetadata>;
  LMeta: TProviderMetadata;
begin
  LList := TList<TProviderMetadata>.Create;
  try
    for LMeta in FProviders.Values do
      LList.Add(LMeta);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

class function TProviderRegistry.CreateProvider(const AId: string; const AConfig: IAIConfig): IIAProvider;
var
  LMeta: TProviderMetadata;
begin
  if GetProvider(AId, LMeta) then
  begin
    if Assigned(LMeta.FactoryFunc) then
      Exit(LMeta.FactoryFunc(AConfig));
  end;
  raise Exception.CreateFmt('Provider "%s" is not registered or has no factory.', [AId]);
end;

class function TProviderRegistry.HasProvider(const AId: string): Boolean;
begin
  Result := FProviders.ContainsKey(AId.ToLower);
end;

end.
