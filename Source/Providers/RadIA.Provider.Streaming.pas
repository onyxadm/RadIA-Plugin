unit RadIA.Provider.Streaming;

interface

uses
  System.SysUtils, System.Classes;

type
  TRadIAStreamingTargetStream = class(TStream)
  private
    FOnWrite: TProc<TBytes>;
  public
    constructor Create(const AOnWrite: TProc<TBytes>);
    function Write(const Buffer; Count: LongInt): LongInt; override;
    function Read(var Buffer; Count: LongInt): LongInt; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

  TRadIAUtf8ChunkDecoder = class
  private
    FPendingBytes: TBytes;
  public
    function Decode(const ABytes: TBytes): string;
  end;

implementation

{ TRadIAStreamingTargetStream }

constructor TRadIAStreamingTargetStream.Create(const AOnWrite: TProc<TBytes>);
begin
  inherited Create;
  FOnWrite := AOnWrite;
end;

function TRadIAStreamingTargetStream.Write(const Buffer; Count: LongInt): LongInt;
var
  LBytes: TBytes;
begin
  Result := Count;
  if Count <= 0 then
    Exit;

  SetLength(LBytes, Count);
  Move(Buffer, LBytes[0], Count);

  if Assigned(FOnWrite) then
    FOnWrite(LBytes);
end;

function TRadIAStreamingTargetStream.Read(var Buffer; Count: LongInt): LongInt;
begin
  Result := 0;
end;

function TRadIAStreamingTargetStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := 0;
end;

{ TRadIAUtf8ChunkDecoder }

function TRadIAUtf8ChunkDecoder.Decode(const ABytes: TBytes): string;
var
  LCombined: TBytes;
  LLenCombined: Integer;
  LLenChunk: Integer;
  LKeepCount: Integer;
  LDecodableLen: Integer;
  I: Integer;
  LContinuations: Integer;
  LStartByte: Byte;
  LNeeded: Integer;
begin
  Result := '';
  LLenChunk := Length(ABytes);
  if LLenChunk = 0 then
    Exit;

  if Length(FPendingBytes) > 0 then
  begin
    SetLength(LCombined, Length(FPendingBytes) + LLenChunk);
    Move(FPendingBytes[0], LCombined[0], Length(FPendingBytes));
    Move(ABytes[0], LCombined[Length(FPendingBytes)], LLenChunk);
  end
  else
  begin
    LCombined := ABytes;
  end;

  LLenCombined := Length(LCombined);
  LDecodableLen := LLenCombined;
  LKeepCount := 0;

  I := LLenCombined - 1;
  LContinuations := 0;
  while (I >= 0) and (I >= LLenCombined - 4) do
  begin
    LStartByte := LCombined[I];
    if LStartByte < $80 then
      Break;

    if (LStartByte >= $80) and (LStartByte <= $BF) then
    begin
      Inc(LContinuations);
      Dec(I);
      Continue;
    end;

    if LStartByte >= $C0 then
    begin
      LNeeded := 0;
      if (LStartByte >= $C0) and (LStartByte <= $DF) then
        LNeeded := 1
      else if (LStartByte >= $E0) and (LStartByte <= $EF) then
        LNeeded := 2
      else if (LStartByte >= $F0) and (LStartByte <= $F7) then
        LNeeded := 3;

      if LContinuations < LNeeded then
      begin
        LKeepCount := LLenCombined - I;
        LDecodableLen := I;
      end;
      Break;
    end;

    Dec(I);
  end;

  if LKeepCount > 0 then
  begin
    SetLength(FPendingBytes, LKeepCount);
    Move(LCombined[LDecodableLen], FPendingBytes[0], LKeepCount);
  end
  else
  begin
    FPendingBytes := nil;
  end;

  if LDecodableLen > 0 then
    Result := TEncoding.UTF8.GetString(LCombined, 0, LDecodableLen);
end;

end.
