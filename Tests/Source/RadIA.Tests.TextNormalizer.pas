unit RadIA.Tests.TextNormalizer;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces;

type
  [TestFixture]
  TTestTextNormalizer = class
  private
    FNormalizer: IRadIATextNormalizer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNormalizeLF;
    [Test]
    procedure TestNormalizeCR;
    [Test]
    procedure TestNormalizeCRLF;
    [Test]
    procedure TestNormalizeEmpty;
    [Test]
    procedure TestNormalizeMixed;
  end;

implementation

uses
  RadIA.Core.TextNormalizer;

{ TTestTextNormalizer }

procedure TTestTextNormalizer.Setup;
begin
  FNormalizer := TRadIATextNormalizer.Create;
end;

procedure TTestTextNormalizer.TearDown;
begin
  FNormalizer := nil;
end;

procedure TTestTextNormalizer.TestNormalizeLF;
begin
  Assert.AreEqual('Line1' + #13#10 + 'Line2', FNormalizer.NormalizeLineBreaks('Line1' + #10 + 'Line2'));
end;

procedure TTestTextNormalizer.TestNormalizeCR;
begin
  Assert.AreEqual('Line1' + #13#10 + 'Line2', FNormalizer.NormalizeLineBreaks('Line1' + #13 + 'Line2'));
end;

procedure TTestTextNormalizer.TestNormalizeCRLF;
begin
  Assert.AreEqual('Line1' + #13#10 + 'Line2', FNormalizer.NormalizeLineBreaks('Line1' + #13#10 + 'Line2'));
end;

procedure TTestTextNormalizer.TestNormalizeEmpty;
begin
  Assert.AreEqual('', FNormalizer.NormalizeLineBreaks(''));
end;

procedure TTestTextNormalizer.TestNormalizeMixed;
begin
  Assert.AreEqual('Line1' + #13#10 + 'Line2' + #13#10 + 'Line3',
    FNormalizer.NormalizeLineBreaks('Line1' + #10 + 'Line2' + #13 + 'Line3'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTextNormalizer);

end.
