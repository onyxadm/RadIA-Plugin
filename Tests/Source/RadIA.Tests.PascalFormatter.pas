unit RadIA.Tests.PascalFormatter;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestRadIAPascalFormatter = class
  public
    [Test]
    procedure TestNormalizeIndentation_ReindentsClassSections;
    [Test]
    procedure TestNormalizeIndentation_ReindentsMethodBody;
  end;

implementation

uses
  System.SysUtils, RadIA.Core.PascalFormatter;

{ TTestRadIAPascalFormatter }

procedure TTestRadIAPascalFormatter.TestNormalizeIndentation_ReindentsClassSections;
var
  LInput: string;
  LOutput: string;
begin
  LInput :=
    'unit uSample;' + sLineBreak +
    'interface' + sLineBreak +
    'type' + sLineBreak +
    'TSample = class(TObject)' + sLineBreak +
    'private' + sLineBreak +
    'FQuery: TFDQuery;' + sLineBreak +
    'public' + sLineBreak +
    'constructor Create(AQuery: TFDQuery);' + sLineBreak +
    'end;';

  LOutput := TRadIAPascalFormatter.NormalizeIndentation(LInput);

  Assert.IsTrue(LOutput.Contains('  TSample = class(TObject)'));
  Assert.IsTrue(LOutput.Contains('  private'));
  Assert.IsTrue(LOutput.Contains('    FQuery: TFDQuery;'));
  Assert.IsTrue(LOutput.Contains('  public'));
  Assert.IsTrue(LOutput.Contains('    constructor Create(AQuery: TFDQuery);'));
end;

procedure TTestRadIAPascalFormatter.TestNormalizeIndentation_ReindentsMethodBody;
var
  LInput: string;
  LOutput: string;
begin
  LInput :=
    'implementation' + sLineBreak +
    'function TSample.GetNextID: Integer;' + sLineBreak +
    'var' + sLineBreak +
    'LQuery: TFDQuery;' + sLineBreak +
    'begin' + sLineBreak +
    'try' + sLineBreak +
    'Result := 1;' + sLineBreak +
    'finally' + sLineBreak +
    'LQuery.Free;' + sLineBreak +
    'end;' + sLineBreak +
    'end;';

  LOutput := TRadIAPascalFormatter.NormalizeIndentation(LInput);

  Assert.IsTrue(LOutput.Contains('function TSample.GetNextID: Integer;'));
  Assert.IsTrue(LOutput.Contains('var' + sLineBreak + '  LQuery: TFDQuery;'));
  Assert.IsTrue(LOutput.Contains('begin' + sLineBreak + '  try'));
  Assert.IsTrue(LOutput.Contains('    Result := 1;'));
  Assert.IsTrue(LOutput.Contains('  finally' + sLineBreak + '    LQuery.Free;'));
  Assert.IsTrue(LOutput.EndsWith('end;'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAPascalFormatter);

end.
