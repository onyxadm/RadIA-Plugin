unit RadIA.Tests.Cache;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Cache;

type
  [TestFixture]
  TTestRadIACache = class
  private
    FCacheDir: string;
    FCacheFile: string;
    FCache: TRadIACacheManager;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestHashGeneration;
    [Test]
    procedure TestPutAndGet;
    [Test]
    procedure TestExpiration;
    [Test]
    procedure TestLRUEviction;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.JSON, System.DateUtils;

procedure TTestRadIACache.Setup;
begin
  FCacheDir := TPath.Combine(TPath.GetTempPath, 'RadIATests');
  ForceDirectories(FCacheDir);
  FCacheFile := TPath.Combine(FCacheDir, 'cache_test.json');
  if TFile.Exists(FCacheFile) then
    TFile.Delete(FCacheFile);

  FCache := TRadIACacheManager.Create(FCacheFile, 5); { Limit of 5 for easier testing }
end;

procedure TTestRadIACache.TearDown;
begin
  FCache.Free;
  if TFile.Exists(FCacheFile) then
    TFile.Delete(FCacheFile);
end;

procedure TTestRadIACache.TestHashGeneration;
var
  LHash1, LHash2, LHash3: string;
begin
  LHash1 := TRadIACacheManager.GenerateHash('Gemini', 'gemini-1.5-flash', 'system', 'hello', '[]');
  LHash2 := TRadIACacheManager.GenerateHash('Gemini', 'gemini-1.5-flash', 'system', 'hello', '[]');
  LHash3 := TRadIACacheManager.GenerateHash('Gemini', 'gemini-1.5-pro', 'system', 'hello', '[]');

  Assert.AreEqual(LHash1, LHash2, 'Same inputs must produce the same hash!');
  Assert.AreNotEqual(LHash1, LHash3, 'Different models must produce different hashes!');
end;

procedure TTestRadIACache.TestPutAndGet;
var
  LHash, LResponse: string;
begin
  LHash := 'test-hash-1';
  FCache.Put(LHash, 'IA Response Content');

  Assert.IsTrue(FCache.Get(LHash, LResponse));
  Assert.AreEqual('IA Response Content', LResponse);

  Assert.IsFalse(FCache.Get('non-existent-hash', LResponse));
end;

procedure TTestRadIACache.TestExpiration;
var
  LJsonArr: TJSONArray;
  LEntry: TJSONObject;
  LResponse: string;
begin
  { Create a manual expired entry }
  LJsonArr := TJSONArray.Create;
  try
    LEntry := TJSONObject.Create;
    LEntry.AddPair('hash', 'expired-hash');
    LEntry.AddPair('response', 'Old content');

    { Set timestamp to 25 hours ago }
    LEntry.AddPair('timestamp', DateToISO8601(IncHour(Now, -25)));
    LEntry.AddPair('last_accessed', DateToISO8601(IncHour(Now, -25)));
    LJsonArr.AddElement(LEntry);

    TFile.WriteAllText(FCacheFile, LJsonArr.ToJSON, TEncoding.UTF8);
  finally
    LJsonArr.Free;
  end;

  { Reload cache }
  FCache.Free;
  FCache := TRadIACacheManager.Create(FCacheFile, 5);

  { Attempt get - should miss and delete because it is expired }
  Assert.IsFalse(FCache.Get('expired-hash', LResponse));
end;

procedure TTestRadIACache.TestLRUEviction;
var
  LResponse: string;
begin
  { Limit is 5 entries (from Setup) }
  FCache.Put('hash-1', 'resp-1');
  Sleep(5); // Ensure time differences
  FCache.Put('hash-2', 'resp-2');
  Sleep(5);
  FCache.Put('hash-3', 'resp-3');
  Sleep(5);
  FCache.Put('hash-4', 'resp-4');
  Sleep(5);
  FCache.Put('hash-5', 'resp-5');

  { Access hash-1 to refresh its last_accessed time }
  Assert.IsTrue(FCache.Get('hash-1', LResponse));
  Sleep(5);

  { Now, put hash-6. The LRU entry (which is hash-2, since hash-1 was accessed recently and hash-3,4,5 are newer than hash-2) should be evicted.
    Since FLimit is 5, 5 div 10 = 0, so LEvictCount defaults to 1. Thus, only 1 item (hash-2) is evicted. }
  FCache.Put('hash-6', 'resp-6');

  Assert.IsTrue(FCache.Get('hash-1', LResponse), 'hash-1 should still be present since it was recently accessed');
  Assert.IsFalse(FCache.Get('hash-2', LResponse), 'hash-2 should have been evicted (LRU)');
  Assert.IsTrue(FCache.Get('hash-6', LResponse), 'hash-6 should be present');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIACache);

end.
