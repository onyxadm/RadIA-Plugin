unit RadIA.Core.ErrorDecoder;

interface

uses  RadIA.Core.Interfaces;

type
  TRadIAErrorDecoder = class(TInterfacedObject, IRadIAErrorDecoder)
  private
    function ExtractErrorMessageFromJson(const AJsonStr: string): string;
  public
    function DecodeError(const AStatusCode: Integer; const AResponseContent: string): string;
  end;

implementation

uses
  System.JSON, RadIA.Core.Logger, System.SysUtils;

{ TRadIAErrorDecoder }

function TRadIAErrorDecoder.ExtractErrorMessageFromJson(const AJsonStr: string): string;
var
  LJson: TJSONObject;
  LError: TJSONObject;
begin
  Result := '';
  try
    LJson := TJSONObject.ParseJSONValue(AJsonStr) as TJSONObject;
    if Assigned(LJson) then
    begin
      try
        // Caso 1: {"error": {"message": "..."}}
        if LJson.GetValue('error') is TJSONObject then
        begin
          LError := LJson.GetValue('error') as TJSONObject;
          if Assigned(LError) then
          begin
            Result := LError.GetValue<string>('message', '');
            if Result.IsEmpty then
              Result := LError.GetValue<string>('msg', '');
          end;
        end;

        // Caso 2: {"error": "..."}
        if Result.IsEmpty then
          Result := LJson.GetValue<string>('error', '');

        // Caso 3: {"message": "..."}
        if Result.IsEmpty then
          Result := LJson.GetValue<string>('message', '');
      finally
        LJson.Free;
      end;
    end;
  except
    on E: Exception do
      TLogger.Log('Failed to parse error JSON: ' + E.Message, 'ErrorDecoder');
  end;
end;

function TRadIAErrorDecoder.DecodeError(const AStatusCode: Integer; const AResponseContent: string): string;
var
  LExtractedMsg: string;
begin
  Result := '';
  LExtractedMsg := ExtractErrorMessageFromJson(AResponseContent);
  if not LExtractedMsg.IsEmpty then
  begin
    Result := Format('API Error (Status %d): %s', [AStatusCode, LExtractedMsg]);
  end;

  if Result.IsEmpty then
  begin
    case AStatusCode of
      401: Result := 'API Error: Unauthorized (Status 401). Please check your API key or login credentials.';
      403: Result := 'API Error: Forbidden (Status 403). You might not have access to this resource or model.';
      404: Result := 'API Error: Not Found (Status 404). The requested resource or model was not found.';
      429: Result := 'API Error: Rate Limit Exceeded (Status 429). Please wait a moment before sending more requests.';
      500, 502, 503, 504: Result := Format('API Error: Server Error (Status %d). The AI provider is ' +
          'temporarily unavailable.', [AStatusCode]);
    else
      Result := Format('API HTTP Error %d. Response: %s', [AStatusCode, AResponseContent]);
    end;
  end;
end;

end.
