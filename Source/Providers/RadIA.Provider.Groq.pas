unit RadIA.Provider.Groq;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAGroqProvider = class(TRadIAOpenAICompatibleProvider)
  protected
    function GetBaseUrl: string; override;
    function GetModelsDiscoveryUrl: string; override;
    function FilterModelId(const AId: string): Boolean; override;
  public
    constructor Create(const AConfig: IAIConfig); override;

    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading, System.Math;

{ TRadIAGroqProvider }

constructor TRadIAGroqProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderType := ptGroq;
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

procedure TRadIAGroqProvider.FetchAvailableModelsAsync(
  const ACallback: TProc<TArray<string>, string>);
begin
  inherited FetchAvailableModelsAsync(ACallback);
end;

end.
