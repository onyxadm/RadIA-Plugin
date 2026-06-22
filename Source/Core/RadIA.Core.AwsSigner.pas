unit RadIA.Core.AwsSigner;

interface

uses
  System.SysUtils, System.Classes;

type
  TAwsSignRequest = record
    AccessKeyId: string;
    SecretAccessKey: string;
    Region: string;
    Service: string;
    Method: string;
    Uri: string;
    Payload: string;
    AmzDate: string;
    DateStamp: string;
    SessionToken: string;
  end;

  { Utility class to compute AWS Signature Version 4 (SigV4) }
  TAwsSigV4Signer = class
  private
    class function BytesToHex(const ABytes: TBytes): string;
    class function HashSHA256Hex(const AContent: string): string;
    class function HMAC_SHA256(const AData, AKey: TBytes): TBytes; overload;
    class function HMAC_SHA256(const AData: string; const AKey: TBytes): TBytes; overload;
  public
    class procedure GetAmzDateTimeStrings(var AAmzDate, ADateStamp: string);

    class function ComputeSignatureHeaders(const AReq: TAwsSignRequest): TStringList;
  end;

implementation


uses
  System.Hash, System.DateUtils;

{ TAwsSigV4Signer }

class function TAwsSigV4Signer.BytesToHex(const ABytes: TBytes): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Length(ABytes) - 1 do
    Result := Result + Format('%.2x', [ABytes[I]]);
  Result := Result.ToLower;
end;

class function TAwsSigV4Signer.HashSHA256Hex(const AContent: string): string;
begin
  Result := THashSHA2.GetHashString(AContent).ToLower;
end;

class function TAwsSigV4Signer.HMAC_SHA256(const AData, AKey: TBytes): TBytes;
begin
  Result := THashSHA2.GetHMACAsBytes(AData, AKey);
end;

class function TAwsSigV4Signer.HMAC_SHA256(const AData: string; const AKey: TBytes): TBytes;
var
  LDataBytes: TBytes;
begin
  LDataBytes := TEncoding.UTF8.GetBytes(AData);
  Result := HMAC_SHA256(LDataBytes, AKey);
end;

class procedure TAwsSigV4Signer.GetAmzDateTimeStrings(var AAmzDate, ADateStamp: string);
var
  LUtc: TDateTime;
  LYear, LMonth, LDay, LHour, LMin, LSec, LMSec: Word;
begin
  LUtc := TTimeZone.Local.ToUniversalTime(Now);
  DecodeDate(LUtc, LYear, LMonth, LDay);
  DecodeTime(LUtc, LHour, LMin, LSec, LMSec);

  ADateStamp := Format('%.4d%.2d%.2d', [LYear, LMonth, LDay]);
  AAmzDate := Format('%sT%.2d%.2d%.2dZ', [ADateStamp, LHour, LMin, LSec]);
end;

class function TAwsSigV4Signer.ComputeSignatureHeaders(const AReq: TAwsSignRequest): TStringList;
var
  LHost: string;
  LPayloadHash: string;
  LCanonicalHeaders: string;
  LSignedHeaders: string;
  LCanonicalRequest: string;
  LCanonicalRequestHash: string;
  LScope: string;
  LStringToSign: string;

  // Signing Key intermediate keys
  LKeyDate: TBytes;
  LKeyRegion: TBytes;
  LKeyService: TBytes;
  LKeySigning: TBytes;

  LSignatureBytes: TBytes;
  LSignatureHex: string;
  LAuthorizationHeader: string;

  LSecretKeyBytes: TBytes;
begin
  Result := TStringList.Create;

  LHost := Format('%s-runtime.%s.amazonaws.com', [AReq.Service, AReq.Region]).ToLower;
  LPayloadHash := THashSHA2.GetHashString(AReq.Payload).ToLower;

  // 1. Construct Canonical Headers & Signed Headers
  if AReq.SessionToken.Trim.IsEmpty then
  begin
    LCanonicalHeaders :=
      'content-type:application/json'#10 +
      'host:' + LHost + #10 +
      'x-amz-content-sha256:' + LPayloadHash + #10 +
      'x-amz-date:' + AReq.AmzDate + #10;
    LSignedHeaders := 'content-type;host;x-amz-content-sha256;x-amz-date';
  end
  else
  begin
    LCanonicalHeaders :=
      'content-type:application/json'#10 +
      'host:' + LHost + #10 +
      'x-amz-content-sha256:' + LPayloadHash + #10 +
      'x-amz-date:' + AReq.AmzDate + #10 +
      'x-amz-security-token:' + AReq.SessionToken.Trim + #10;
    LSignedHeaders := 'content-type;host;x-amz-content-sha256;x-amz-date;x-amz-security-token';
  end;

  // 2. Canonical Request
  LCanonicalRequest :=
    AReq.Method.ToUpper + #10 +
    AReq.Uri + #10 +
    #10 + // Empty query string (query parameters)
    LCanonicalHeaders + #10 +
    LSignedHeaders + #10 +
    LPayloadHash;

  LCanonicalRequestHash := HashSHA256Hex(LCanonicalRequest);

  // 3. String to Sign
  LScope := Format('%s/%s/%s/aws4_request', [AReq.DateStamp, AReq.Region, AReq.Service]);
  LStringToSign :=
    'AWS4-HMAC-SHA256' + #10 +
    AReq.AmzDate + #10 +
    LScope + #10 +
    LCanonicalRequestHash;

  // 4. Compute Signing Key
  LSecretKeyBytes := TEncoding.UTF8.GetBytes('AWS4' + AReq.SecretAccessKey);
  LKeyDate := HMAC_SHA256(AReq.DateStamp, LSecretKeyBytes);
  LKeyRegion := HMAC_SHA256(AReq.Region, LKeyDate);
  LKeyService := HMAC_SHA256(AReq.Service, LKeyRegion);
  LKeySigning := HMAC_SHA256('aws4_request', LKeyService);

  // 5. Signature
  LSignatureBytes := HMAC_SHA256(LStringToSign, LKeySigning);
  LSignatureHex := BytesToHex(LSignatureBytes);

  // 6. Build Headers
  LAuthorizationHeader := Format(
    'AWS4-HMAC-SHA256 Credential=%s/%s, SignedHeaders=%s, Signature=%s',
    [AReq.AccessKeyId, LScope, LSignedHeaders, LSignatureHex]
  );

  Result.Values['Authorization'] := LAuthorizationHeader;
  Result.Values['x-amz-date'] := AReq.AmzDate;
  Result.Values['x-amz-content-sha256'] := LPayloadHash;
  Result.Values['content-type'] := 'application/json';
  if not AReq.SessionToken.Trim.IsEmpty then
    Result.Values['x-amz-security-token'] := AReq.SessionToken.Trim;
end;

end.
