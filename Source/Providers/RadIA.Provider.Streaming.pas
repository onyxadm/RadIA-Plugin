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
    function CombineWithPending(const ABytes: TBytes): TBytes;
    function DeterminePendingCount(const ACombined: TBytes): Integer;
    procedure UpdatePending(const ACombined: TBytes; AKeepCount: Integer);
    function GetNeededContinuations(ABobyte: Byte): Integer;
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

function TRadIAUtf8ChunkDecoder.CombineWithPending(const ABytes: TBytes): TBytes;
var
  LNewLen, LPendLen, LByteLen: Integer;
begin
  LPendLen := Length(FPendingBytes);
  LByteLen := Length(ABytes);
  if LPendLen = 0 then
    Exit(ABytes);

  LNewLen := LPendLen + LByteLen;
  SetLength(Result, LNewLen);
  Move(FPendingBytes[0], Result[0], LPendLen);
  Move(ABytes[0], Result[LPendLen], LByteLen);
end;

function TRadIAUtf8ChunkDecoder.GetNeededContinuations(ABobyte: Byte): Integer;
begin
  if (ABobyte >= $C0) and (ABobyte <= $DF) then
    Exit(1);
  if (ABobyte >= $E0) and (ABobyte <= $EF) then
    Exit(2);
  if (ABobyte >= $F0) and (ABobyte <= $F7) then
    Exit(3);
  Result := 0;
end;

function TRadIAUtf8ChunkDecoder.DeterminePendingCount(const ACombined: TBytes): Integer;
var
  LLenCombined, I, LContinuations: Integer;
  LStartByte: Byte;
begin
  Result := 0;
  LLenCombined := Length(ACombined);
  if LLenCombined = 0 then Exit;

  I := LLenCombined - 1;
  LContinuations := 0;

  while (I >= 0) and (I >= LLenCombined - 4) do
  begin
    LStartByte := ACombined[I];
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
      if LContinuations < GetNeededContinuations(LStartByte) then
        Result := LLenCombined - I;
      Break;
    end;

    Dec(I);
  end;
end;

procedure TRadIAUtf8ChunkDecoder.UpdatePending(const ACombined: TBytes; AKeepCount: Integer);
var
  LDecodableLen: Integer;
begin
  if AKeepCount > 0 then
  begin
    LDecodableLen := Length(ACombined) - AKeepCount;
    SetLength(FPendingBytes, AKeepCount);
    Move(ACombined[LDecodableLen], FPendingBytes[0], AKeepCount);
  end
  else
  begin
    FPendingBytes := nil;
  end;
end;

function TRadIAUtf8ChunkDecoder.Decode(const ABytes: TBytes): string;
var
  LCombined: TBytes;
  LKeepCount, LDecodableLen: Integer;
begin
  Result := '';
  if Length(ABytes) = 0 then
    Exit;

  LCombined := CombineWithPending(ABytes);
  LKeepCount := DeterminePendingCount(LCombined);
  LDecodableLen := Length(LCombined) - LKeepCount;

  UpdatePending(LCombined, LKeepCount);

  if LDecodableLen > 0 then
    Result := TEncoding.UTF8.GetString(LCombined, 0, LDecodableLen);
end;

end.
