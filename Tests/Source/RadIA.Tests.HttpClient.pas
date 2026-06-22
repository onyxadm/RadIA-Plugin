unit RadIA.Tests.HttpClient;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces;

type
  [TestFixture]
  TTestRadIAHttpClient = class
  private
    FClient: IRadIAHttpClient;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestGetVersionFromSonarQube;
    [Test]
    procedure TestGetNonExistentUrlThrowsException;
    [Test]
    procedure TestPostNonExistentUrlThrowsException;
    [Test]
    procedure TestCancelRequest;
  end;

implementation

uses
  RadIA.Core.HttpClient, System.SysUtils, System.Net.URLClient;

{ TTestRadIAHttpClient }

procedure TTestRadIAHttpClient.Setup;
begin
  FClient := TRadIAConcreteHttpClient.Create;
end;

procedure TTestRadIAHttpClient.TearDown;
begin
  FClient := nil;
end;

procedure TTestRadIAHttpClient.TestGetVersionFromSonarQube;
var
  LUrl: string;
  LHeaders: TNetHeaders;
  LResponse: string;
begin
  LUrl := 'http://localhost:9000/api/server/version';
  SetLength(LHeaders, 0);
  try
    LResponse := FClient.Get(LUrl, LHeaders, 5000);
    Assert.IsNotEmpty(LResponse, 'Should receive version response from SonarQube');
  except
    on E: Exception do
      Assert.Fail('GET request to SonarQube version endpoint failed: ' + E.Message);
  end;
end;

procedure TTestRadIAHttpClient.TestGetNonExistentUrlThrowsException;
var
  LUrl: string;
  LHeaders: TNetHeaders;
begin
  LUrl := 'http://localhost:9000/api/nonexistent_endpoint_for_test';
  SetLength(LHeaders, 0);

  Assert.WillRaise(
    procedure
    begin
      FClient.Get(LUrl, LHeaders, 2000);
    end,
    ERadIAHttpException,
    'GET to non-existent endpoint should raise ERadIAHttpException'
  );
end;

procedure TTestRadIAHttpClient.TestPostNonExistentUrlThrowsException;
var
  LUrl: string;
  LHeaders: TNetHeaders;
  LBody: string;
begin
  LUrl := 'http://localhost:9000/api/nonexistent_endpoint_for_test';
  SetLength(LHeaders, 0);
  LBody := '{"test": true}';

  Assert.WillRaise(
    procedure
    begin
      FClient.Post(LUrl, LHeaders, LBody, 2000);
    end,
    ERadIAHttpException,
    'POST to non-existent endpoint should raise ERadIAHttpException'
  );
end;

procedure TTestRadIAHttpClient.TestCancelRequest;
var
  LUrl: string;
  LHeaders: TNetHeaders;
begin
  LUrl := 'http://localhost:9000/api/server/version';
  SetLength(LHeaders, 0);

  FClient.Cancel;

  try
    FClient.Get(LUrl, LHeaders, 2000);
  except
  end;
  Assert.Pass;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAHttpClient);

end.
