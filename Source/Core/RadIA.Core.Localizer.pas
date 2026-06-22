unit RadIA.Core.Localizer;

interface

uses  System.Generics.Collections, RadIA.Core.Interfaces;

type
  TRadIALocalizer = class(TInterfacedObject, IRadIALocalizer)
  private
    FLanguage: string;
    FDictionary: TDictionary<string, string>;
    procedure PopulateTranslations;
  public
    constructor Create;
    destructor Destroy; override;

    { IRadIALocalizer implementation }
    function GetText(const AKey: string; const ADefault: string = ''): string;
    function GetLanguage: string;
    procedure SetLanguage(const ALang: string);
  end;

implementation


uses
  System.SysUtils;

{ TRadIALocalizer }

constructor TRadIALocalizer.Create;
begin
  inherited Create;
  FDictionary := TDictionary<string, string>.Create;
  FLanguage := 'pt-BR'; // default local language
  PopulateTranslations;
end;

destructor TRadIALocalizer.Destroy;
begin
  FDictionary.Free;
  inherited Destroy;
end;

function TRadIALocalizer.GetLanguage: string;
begin
  Result := FLanguage;
end;

procedure TRadIALocalizer.SetLanguage(const ALang: string);
begin
  if not SameText(FLanguage, ALang) then
  begin
    FLanguage := ALang;
    PopulateTranslations;
  end;
end;

function TRadIALocalizer.GetText(const AKey: string; const ADefault: string): string;
begin
  if not FDictionary.TryGetValue(AKey.ToLower, Result) then
  begin
    if not ADefault.IsEmpty then
      Result := ADefault
    else
      Result := AKey;
  end;
end;

procedure TRadIALocalizer.PopulateTranslations;
begin
  FDictionary.Clear;
  if SameText(FLanguage, 'pt-BR') then
  begin
    FDictionary.Add('session_locked_message', 'Aguarde a resposta atual terminar ou cancele antes de trocar de chat.');
    FDictionary.Add('unauthorized_error', 'Erro de API: Não autorizado. Verifique sua chave de API.');
    FDictionary.Add('rate_limit_error', 'Erro de API: Limite de requisições excedido. Por favor, aguarde.');
    FDictionary.Add('server_error', 'Erro de API: Servidor temporariamente indisponível.');
    FDictionary.Add('not_found_error', 'Erro de API: Recurso não encontrado.');
  end
  else // default to English ('en')
  begin
    FDictionary.Add('session_locked_message', 'Wait for the current response to finish, or cancel it ' +
        'before switching chats.');
    FDictionary.Add('unauthorized_error', 'API Error: Unauthorized. Please check your API key.');
    FDictionary.Add('rate_limit_error', 'API Error: Rate Limit Exceeded. Please wait a moment.');
    FDictionary.Add('server_error', 'API Error: Server temporarily unavailable.');
    FDictionary.Add('not_found_error', 'API Error: Resource not found.');
  end;
end;

end.
