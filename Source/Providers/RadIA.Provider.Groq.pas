unit RadIA.Provider.Groq;

interface

uses  RadIA.Core.Interfaces, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAGroqProvider = class(TRadIAOpenAICompatibleProvider)
  protected
    function GetBaseUrl: string; override;
    function GetModelsDiscoveryUrl: string; override;
    function FilterModelId(const AId: string): Boolean; override;
  public
    constructor Create(const AConfig: IRadIAConfig); override;

    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.SysUtils, RadIA.Core.ProviderRegistry, RadIA.Core.Types;

{ TRadIAGroqProvider }

constructor TRadIAGroqProvider.Create(const AConfig: IRadIAConfig);
begin
  inherited Create(AConfig);
  FProviderId := 'Groq';
end;

function TRadIAGroqProvider.GetBaseUrl: string;
begin
  Result := 'https://api.groq.com/openai/v1';
end;

function TRadIAGroqProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_GROQ_LLAMA33, MODEL_GROQ_MIXTRAL, MODEL_GROQ_GEMMA2);
end;

function TRadIAGroqProvider.GetName: string;
begin
  Result := 'Groq';
end;

function TRadIAGroqProvider.GetModelsDiscoveryUrl: string;
begin
  Result := GetBaseUrl.TrimRight(['/']) + '/models';
end;

function TRadIAGroqProvider.FilterModelId(const AId: string): Boolean;
begin
  { Accept only the model families supported by Groq }
  Result := not AId.IsEmpty and
    (AId.Contains('llama') or AId.Contains('mixtral') or AId.Contains('gemma'));
end;



initialization
  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create(
      'Groq',
      'Groq',
      'https://api.groq.com/openai/v1',
      True, // HasApiKey
      False, // HasCustomUrl
      [MODEL_GROQ_LLAMA33, MODEL_GROQ_MIXTRAL, MODEL_GROQ_GEMMA2],
      function(const ACfg: IRadIAConfig): IRadIAProvider
      begin
        Result := TRadIAGroqProvider.Create(ACfg);
      end
    )
  );

end.
