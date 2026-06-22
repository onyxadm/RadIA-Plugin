unit RadIA.Tests.Infrastructure;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces;

type
  [TestFixture]
  TTestRadIAInfrastructure = class
  private
    FDecoder: IRadIAErrorDecoder;
    FLocalizer: IRadIALocalizer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestErrorDecoder_OpenAICompatibleError;
    [Test]
    procedure TestErrorDecoder_GoogleGeminiError;
    [Test]
    procedure TestErrorDecoder_HTTPStatusCodes;
    [Test]
    procedure TestErrorDecoder_Exception;
    [Test]
    procedure TestLocalizer_PtBrTranslations;
    [Test]
    procedure TestLocalizer_EnTranslations;
  end;

implementation

uses
  System.SysUtils, RadIA.Core.ErrorDecoder, RadIA.Core.Localizer;

{ TTestRadIAInfrastructure }

procedure TTestRadIAInfrastructure.Setup;
begin
  FDecoder := TRadIAErrorDecoder.Create;
  FLocalizer := TRadIALocalizer.Create;
end;

procedure TTestRadIAInfrastructure.TearDown;
begin
  FDecoder := nil;
  FLocalizer := nil;
end;

procedure TTestRadIAInfrastructure.TestErrorDecoder_OpenAICompatibleError;
var
  LMockJson: string;
  LErrorMsg: string;
begin
  LMockJson := '{"error": {"message": "Invalid API key provided", "type": "invalid_request_error", "code": ' +
      '"invalid_api_key"}}';
  LErrorMsg := FDecoder.DecodeError(401, LMockJson);
  Assert.AreEqual('API Error (Status 401): Invalid API key provided', LErrorMsg);
end;

procedure TTestRadIAInfrastructure.TestErrorDecoder_GoogleGeminiError;
var
  LMockJson: string;
  LErrorMsg: string;
begin
  // Gemini/Google format example: {"error": {"message": "API key not valid. Please pass a valid API key.",
  //    "status": "INVALID_ARGUMENT"}}
  LMockJson := '{"error": {"message": "API key not valid. Please pass a valid API ' +
      'key.", "status": "INVALID_ARGUMENT"}}';
  LErrorMsg := FDecoder.DecodeError(400, LMockJson);
  Assert.AreEqual('API Error (Status 400): API key not valid. Please pass a valid API key.', LErrorMsg);
end;

procedure TTestRadIAInfrastructure.TestErrorDecoder_HTTPStatusCodes;
begin
  // Fallbacks
  Assert.AreEqual('API Error: Unauthorized (Status 401). Please check your API key or login credentials.',
      FDecoder.DecodeError(401, ''));
  Assert.AreEqual('API Error: Rate Limit Exceeded (Status 429). Please wait a moment before sending ' +
      'more requests.', FDecoder.DecodeError(429, ''));
  Assert.AreEqual('API Error: Server Error (Status 500). The AI provider is temporarily unavailable.',
      FDecoder.DecodeError(500, ''));
  Assert.AreEqual('API HTTP Error 418. Response: Teapot', FDecoder.DecodeError(418, 'Teapot'));
end;

procedure TTestRadIAInfrastructure.TestErrorDecoder_Exception;
var
  LErrorMsg: string;
begin
  LErrorMsg := FDecoder.DecodeError(500, '[1, 2, 3]');
  Assert.AreEqual('API Error: Server Error (Status 500). The AI provider is temporarily unavailable.', LErrorMsg);
end;

procedure TTestRadIAInfrastructure.TestLocalizer_PtBrTranslations;
var
  LText: string;
begin
  FLocalizer.SetLanguage('pt-BR');
  Assert.AreEqual('pt-BR', FLocalizer.GetLanguage);
  LText := FLocalizer.GetText('unauthorized_error');
  Assert.IsTrue(LText.Contains('autorizado') and LText.Contains('chave de API'));
  Assert.AreEqual('Aguarde a resposta atual terminar ou cancele antes de trocar ' +
      'de chat.', FLocalizer.GetText('session_locked_message'));
  Assert.AreEqual('Default Value', FLocalizer.GetText('non_existent_key', 'Default Value'));
end;

procedure TTestRadIAInfrastructure.TestLocalizer_EnTranslations;
begin
  FLocalizer.SetLanguage('en');
  Assert.AreEqual('en', FLocalizer.GetLanguage);
  Assert.AreEqual('API Error: Unauthorized. Please check your API key.', FLocalizer.GetText('unauthorized_error'));
  Assert.AreEqual('Wait for the current response to finish, or cancel it before ' +
      'switching chats.', FLocalizer.GetText('session_locked_message'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAInfrastructure);

end.
