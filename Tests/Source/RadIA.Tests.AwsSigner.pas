unit RadIA.Tests.AwsSigner;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestAwsSigner = class
  public
    [Test]
    procedure TestGetAmzDateTimeStrings;
    [Test]
    procedure TestComputeSignatureHeaders;
    [Test]
    procedure TestComputeSignatureHeadersWithSessionToken;
  end;

implementation

uses
  System.Classes, System.SysUtils, RadIA.Core.AwsSigner;

{ TTestAwsSigner }

procedure TTestAwsSigner.TestGetAmzDateTimeStrings;
var
  LAmzDate: string;
  LDateStamp: string;
begin
  TAwsSigV4Signer.GetAmzDateTimeStrings(LAmzDate, LDateStamp);
  Assert.AreEqual(8, Length(LDateStamp), 'DateStamp format should be YYYYMMDD');
  Assert.AreEqual(16, Length(LAmzDate), 'AmzDate format should be YYYYMMDDTHHMMSSZ');
  Assert.IsTrue(LAmzDate.EndsWith('Z'), 'AmzDate must end with Z');
end;

procedure TTestAwsSigner.TestComputeSignatureHeaders;
var
  LHeaders: TStringList;
const
  ACCESS_KEY = 'TEST_ACCESS_KEY';
  SECRET_KEY = 'TEST_SECRET_KEY';
  REGION = 'us-east-1';
  SERVICE = 'bedrock';
  METHOD = 'POST';
  URI = '/model/anthropic.claude-3/invoke';
  PAYLOAD = '{"prompt":"hello"}';
  AMZ_DATE = '20260608T170000Z';
  DATE_STAMP = '20260608';
begin
  LHeaders := TAwsSigV4Signer.ComputeSignatureHeaders(
    ACCESS_KEY, SECRET_KEY, REGION, SERVICE, METHOD, URI, PAYLOAD, AMZ_DATE, DATE_STAMP
  );
  try
    Assert.IsNotNull(LHeaders);
    Assert.AreEqual('application/json', LHeaders.Values['content-type']);
    Assert.AreEqual(AMZ_DATE, LHeaders.Values['x-amz-date']);
    Assert.IsNotEmpty(LHeaders.Values['x-amz-content-sha256']);
    Assert.IsNotEmpty(LHeaders.Values['Authorization']);
    Assert.IsTrue(LHeaders.Values['Authorization'].Contains(
      'Credential=TEST_ACCESS_KEY/20260608/us-east-1/bedrock/aws4_request'));
    Assert.IsTrue(LHeaders.Values['Authorization'].Contains(
      'SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date'));
  finally
    LHeaders.Free;
  end;
end;

procedure TTestAwsSigner.TestComputeSignatureHeadersWithSessionToken;
var
  LHeaders: TStringList;
const
  ACCESS_KEY = 'TEST_ACCESS_KEY';
  SECRET_KEY = 'TEST_SECRET_KEY';
  REGION = 'us-east-1';
  SERVICE = 'bedrock';
  METHOD = 'POST';
  URI = '/model/anthropic.claude-3/invoke';
  PAYLOAD = '{"prompt":"hello"}';
  AMZ_DATE = '20260608T170000Z';
  DATE_STAMP = '20260608';
  SESSION_TOKEN = 'session_token_xyz_123';
begin
  LHeaders := TAwsSigV4Signer.ComputeSignatureHeaders(
    ACCESS_KEY, SECRET_KEY, REGION, SERVICE, METHOD, URI, PAYLOAD, AMZ_DATE, DATE_STAMP, SESSION_TOKEN
  );
  try
    Assert.IsNotNull(LHeaders);
    Assert.AreEqual(SESSION_TOKEN, LHeaders.Values['x-amz-security-token']);
    Assert.IsTrue(LHeaders.Values['Authorization'].Contains(
      'SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date;x-amz-security-token'));
  finally
    LHeaders.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAwsSigner);

end.
