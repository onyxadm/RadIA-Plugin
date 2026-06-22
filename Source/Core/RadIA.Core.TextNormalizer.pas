unit RadIA.Core.TextNormalizer;

interface

uses  RadIA.Core.Interfaces;

type
  TRadIATextNormalizer = class(TInterfacedObject, IRadIATextNormalizer)
  public
    function NormalizeLineBreaks(const AText: string): string;
  end;

implementation


uses
  System.SysUtils;

{ TRadIATextNormalizer }

function TRadIATextNormalizer.NormalizeLineBreaks(const AText: string): string;
begin
  Result := AText.Replace(#13#10, #10).Replace(#13, #10).Replace(#10, #13#10);
end;

end.
