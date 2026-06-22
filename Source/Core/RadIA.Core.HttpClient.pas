unit RadIA.Core.HttpClient;

interface

uses
  System.SysUtils, System.Net.HttpClient, System.Net.URLClient,
  RadIA.Core.Interfaces;

type
  TRadIAConcreteHttpClient = class(TInterfacedObject, IRadIAHttpClient)
  private
    FHTTPClient: THTTPClient;
    FCancelled: Boolean;
    procedure HTTPClientReceiveData(const Sender: TObject; AContentLength, AReadCount: Int64; var AAbort: Boolean);
  public
    constructor Create;
    destructor Destroy; override;

    { IRadIAHttpClient implementation }
    function Get(const AUrl: string; const AHeaders: TNetHeaders; const ATimeoutMs: Integer = 0): string;
    function Post(const AUrl: string; const AHeaders: TNetHeaders; const ARequestBody: string;
        const ATimeoutMs: Integer = 0): string;
    procedure PostStream(const AUrl: string; const AHeaders: TNetHeaders; const ARequestBody: string;
      const AOnWrite: TProc<TBytes>; const ATimeoutMs: Integer = 0);
    procedure Cancel;
  end;

implementation

uses
  RadIA.Core.Types, RadIA.Provider.Streaming, System.Classes;

{ TRadIAConcreteHttpClient }

constructor TRadIAConcreteHttpClient.Create;
begin
  inherited Create;
  FHTTPClient := THTTPClient.Create;
  FHTTPClient.OnReceiveData := HTTPClientReceiveData;
  FCancelled := False;
end;

destructor TRadIAConcreteHttpClient.Destroy;
begin
  FHTTPClient.Free;
  inherited Destroy;
end;

procedure TRadIAConcreteHttpClient.HTTPClientReceiveData(const Sender: TObject;
  AContentLength, AReadCount: Int64; var AAbort: Boolean);
begin
  if FCancelled or GIsShuttingDown then
    AAbort := True;
end;

procedure TRadIAConcreteHttpClient.Cancel;
begin
  FCancelled := True;
end;

function TRadIAConcreteHttpClient.Get(const AUrl: string; const AHeaders: TNetHeaders;
  const ATimeoutMs: Integer): string;
var
  LResponse: IHTTPResponse;
begin
  FCancelled := False;
  if ATimeoutMs > 0 then
  begin
    FHTTPClient.ConnectionTimeout := ATimeoutMs;
    FHTTPClient.SendTimeout := ATimeoutMs;
    FHTTPClient.ResponseTimeout := ATimeoutMs;
  end;
  FHTTPClient.AcceptCharSet := 'utf-8';
  FHTTPClient.ProtocolVersion := THTTPProtocolVersion.HTTP_1_1;

  LResponse := FHTTPClient.Get(AUrl, nil, AHeaders);

  if LResponse.StatusCode <> 200 then
  begin
    raise ERadIAHttpException.Create(
      Format('HTTP error %d: %s', [LResponse.StatusCode, LResponse.StatusText]),
      LResponse.StatusCode,
      LResponse.ContentAsString(TEncoding.UTF8)
    );
  end;

  Result := LResponse.ContentAsString(TEncoding.UTF8);
end;

function TRadIAConcreteHttpClient.Post(const AUrl: string; const AHeaders: TNetHeaders;
  const ARequestBody: string; const ATimeoutMs: Integer): string;
var
  LSourceStream: TStringStream;
  LResponse: IHTTPResponse;
begin
  FCancelled := False;
  if ATimeoutMs > 0 then
  begin
    FHTTPClient.ConnectionTimeout := ATimeoutMs;
    FHTTPClient.SendTimeout := ATimeoutMs;
    FHTTPClient.ResponseTimeout := ATimeoutMs;
  end;
  FHTTPClient.ContentType := 'application/json';
  FHTTPClient.AcceptCharSet := 'utf-8';
  FHTTPClient.ProtocolVersion := THTTPProtocolVersion.HTTP_1_1;

  LSourceStream := TStringStream.Create(ARequestBody, TEncoding.UTF8);
  try
    LResponse := FHTTPClient.Post(AUrl, LSourceStream, nil, AHeaders);

    if LResponse.StatusCode <> 200 then
    begin
      raise ERadIAHttpException.Create(
        Format('HTTP error %d: %s', [LResponse.StatusCode, LResponse.StatusText]),
        LResponse.StatusCode,
        LResponse.ContentAsString(TEncoding.UTF8)
      );
    end;

    Result := LResponse.ContentAsString(TEncoding.UTF8);
  finally
    LSourceStream.Free;
  end;
end;

procedure TRadIAConcreteHttpClient.PostStream(const AUrl: string; const AHeaders: TNetHeaders;
  const ARequestBody: string; const AOnWrite: TProc<TBytes>; const ATimeoutMs: Integer);
var
  LSourceStream: TStringStream;
  LTargetStream: TRadIAStreamingTargetStream;
  LResponse: IHTTPResponse;
begin
  FCancelled := False;
  if ATimeoutMs > 0 then
  begin
    FHTTPClient.ConnectionTimeout := ATimeoutMs;
    FHTTPClient.SendTimeout := ATimeoutMs;
    FHTTPClient.ResponseTimeout := ATimeoutMs;
  end;
  FHTTPClient.ContentType := 'application/json';
  FHTTPClient.AcceptCharSet := 'utf-8';
  FHTTPClient.ProtocolVersion := THTTPProtocolVersion.HTTP_1_1;

  LSourceStream := TStringStream.Create(ARequestBody, TEncoding.UTF8);
  LTargetStream := TRadIAStreamingTargetStream.Create(AOnWrite);
  try
    LResponse := FHTTPClient.Post(AUrl, LSourceStream, LTargetStream, AHeaders);

    if LResponse.StatusCode <> 200 then
    begin
      raise ERadIAHttpException.Create(
        Format('HTTP error %d: %s', [LResponse.StatusCode, LResponse.StatusText]),
        LResponse.StatusCode,
        ''
      );
    end;
  finally
    LTargetStream.Free;
    LSourceStream.Free;
  end;
end;

end.
