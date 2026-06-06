unit RadIA.Provider.OpenRouter;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAOpenRouterProvider = class(TRadIAOpenAICompatibleProvider)
  protected
    function GetBaseUrl: string; override;
    function GetModelsDiscoveryUrl: string; override;
  public
    constructor Create(const AConfig: IAIConfig); override;

    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;

implementation

uses
  System.JSON, System.Threading, System.Math;

{ TRadIAOpenRouterProvider }

constructor TRadIAOpenRouterProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderType := ptOpenRouter;
end;

function TRadIAOpenRouterProvider.GetBaseUrl: string;
begin
  Result := 'https://openrouter.ai/api/v1';
end;

function TRadIAOpenRouterProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create(MODEL_OPENROUTER_GEMINI25_PRO, MODEL_OPENROUTER_LLAMA33, MODEL_OPENROUTER_DEEPSEEK_R1);
end;

function TRadIAOpenRouterProvider.GetName: string;
begin
  Result := 'OpenRouter';
end;

function TRadIAOpenRouterProvider.GetModelsDiscoveryUrl: string;
begin
  Result := GetBaseUrl.TrimRight(['/']) + '/models';
end;

procedure TRadIAOpenRouterProvider.FetchAvailableModelsAsync(
  const ACallback: TProc<TArray<string>, string>);
begin
  inherited FetchAvailableModelsAsync(ACallback);
end;

end.
