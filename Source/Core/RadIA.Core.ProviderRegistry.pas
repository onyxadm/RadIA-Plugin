unit RadIA.Core.ProviderRegistry;

interface

uses
  System.Generics.Collections, RadIA.Core.Interfaces;

type
  TProviderFactoryFunc = reference to function(const AConfig: IRadIAConfig): IRadIAProvider;

  TProviderMetadata = record
    Id: string;
    DisplayName: string;
    DefaultBaseUrl: string;
    HasApiKey: Boolean;
    HasCustomUrl: Boolean;
    DefaultModels: TArray<string>;
    FactoryFunc: TProviderFactoryFunc;
    IsDynamic: Boolean;

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
    class procedure LoadJsonProviders; static;
    class procedure RegisterProvider(const AMetadata: TProviderMetadata);
    class function GetProvider(const AId: string; out AMetadata: TProviderMetadata): Boolean;
    class function GetProviders: TArray<TProviderMetadata>;
    class function CreateProvider(const AId: string; const AConfig: IRadIAConfig): IRadIAProvider;
    class function HasProvider(const AId: string): Boolean;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON,
  System.Generics.Defaults, RadIA.Provider.Generic, RadIA.Core.Logger;

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
  Result.IsDynamic := False;
end;

{ TProviderRegistry }

class constructor TProviderRegistry.Create;
begin
  FProviders := TDictionary<string, TProviderMetadata>.Create;
  LoadJsonProviders;
end;

class procedure TProviderRegistry.LoadJsonProviders;
  function CreateFactory(const AId, ADisplayName, ABaseUrl: string;
    const AModels: TArray<string>; const AApiKey: string): TProviderFactoryFunc;
  begin
    Result :=
      function(const ACfg: IRadIAConfig): IRadIAProvider
      begin
        Result := TRadIAGenericOpenAIProvider.Create(
          ACfg, AId, ADisplayName, ABaseUrl, AModels, AApiKey
        );
      end;
  end;
var
  LProvidersFolder: string;
  LFiles: TArray<string>;
  LFile: string;
  LJsonStr: string;
  LJsonObj: TJSONObject;
  LId, LDisplayName, LDefaultBaseUrl: string;
  LApiKey: string;
  LHasApiKey, LHasCustomUrl: Boolean;
  LModelsArray: TJSONArray;
  LModelsList: TList<string>;
  LDefaultModels: TArray<string>;
  I: Integer;
  LMeta: TProviderMetadata;
  LRegApiKey: string;
begin
  LProvidersFolder := TPath.Combine(IncludeTrailingPathDelimiter(GetEnvironmentVariable('APPDATA')) + 'RadIA',
      'providers');
  if not TDirectory.Exists(LProvidersFolder) then
  begin
    try
      TDirectory.CreateDirectory(LProvidersFolder);
    except
      on E: Exception do
      begin
        TLogger.Log('Failed to create providers folder: ' + E.Message, 'Registry');
        Exit;
      end;
    end;
  end;

  try
    LFiles := TDirectory.GetFiles(LProvidersFolder, '*.json');
  except
    on E: Exception do
    begin
      TLogger.Log('Failed to list providers folder: ' + E.Message, 'Registry');
      Exit;
    end;
  end;

  for LFile in LFiles do
  begin
    try
      LJsonStr := TFile.ReadAllText(LFile, TEncoding.UTF8);
      LJsonObj := TJSONObject.ParseJSONValue(LJsonStr) as TJSONObject;
      if Assigned(LJsonObj) then
      begin
        try
          LId := LJsonObj.GetValue<string>('id', '');
          LDisplayName := LJsonObj.GetValue<string>('displayName', '');
          LDefaultBaseUrl := LJsonObj.GetValue<string>('baseUrl', '');
          LApiKey := LJsonObj.GetValue<string>('apiKey', '');
          LHasApiKey := LJsonObj.GetValue<Boolean>('hasApiKey', True);
          LHasCustomUrl := LJsonObj.GetValue<Boolean>('hasCustomUrl', False);

          if LId.IsEmpty or LDisplayName.IsEmpty or LDefaultBaseUrl.IsEmpty then
          begin
            TLogger.Log('Skipping invalid provider JSON (missing fields): ' + LFile, 'Registry');
            Continue;
          end;

          LModelsList := TList<string>.Create;
          try
            LModelsArray := LJsonObj.GetValue('defaultModels') as TJSONArray;
            if Assigned(LModelsArray) then
            begin
              for I := 0 to LModelsArray.Count - 1 do
                LModelsList.Add(LModelsArray[I].Value);
            end;
            LDefaultModels := LModelsList.ToArray;
          finally
            LModelsList.Free;
          end;

          LRegApiKey := LApiKey;
          if (not LHasApiKey) and LRegApiKey.IsEmpty then
            LRegApiKey := 'dummy';

          // Create and mark as dynamic before registration
          LMeta := TProviderMetadata.Create(
            LId,
            LDisplayName,
            LDefaultBaseUrl,
            LHasApiKey,
            LHasCustomUrl,
            LDefaultModels,
            CreateFactory(LId, LDisplayName, LDefaultBaseUrl, LDefaultModels, LRegApiKey)
          );
          LMeta.IsDynamic := True;

          RegisterProvider(LMeta);
          TLogger.Log(Format('Successfully registered JSON provider "%s" (%s)', [LDisplayName, LId]), 'Registry');
        finally
          LJsonObj.Free;
        end;
      end;
    except
      on E: Exception do
      begin
        TLogger.Log(Format('Error loading JSON provider file %s: %s', [LFile, E.Message]), 'Registry');
      end;
    end;
  end;
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
  LPair: TPair<string, TProviderMetadata>;
begin
  LList := TList<TProviderMetadata>.Create;
  try
    for LPair in FProviders do
      LList.Add(LPair.Value);

    LList.Sort(TComparer<TProviderMetadata>.Construct(
      function(const Left, Right: TProviderMetadata): Integer
      var
        LLeftIsEnd, LRightIsEnd: Boolean;
      begin
        LLeftIsEnd := SameText(Left.Id, 'Ollama') or SameText(Left.Id, 'LMStudio');
        LRightIsEnd := SameText(Right.Id, 'Ollama') or SameText(Right.Id, 'LMStudio');

        if LLeftIsEnd and not LRightIsEnd then
          Exit(1)
        else if not LLeftIsEnd and LRightIsEnd then
          Exit(-1)
        else if LLeftIsEnd and LRightIsEnd then
          Exit(CompareText(Left.DisplayName, Right.DisplayName));

        Exit(CompareText(Left.DisplayName, Right.DisplayName));
      end
    ));

    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

class function TProviderRegistry.CreateProvider(const AId: string; const AConfig: IRadIAConfig): IRadIAProvider;
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
