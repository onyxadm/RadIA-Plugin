unit RadIA.Tests.Streaming;

interface

uses
  DUnitX.TestFramework,
  RadIA.Core.Interfaces, RadIA.Provider.OpenAI, RadIA.Provider.Gemini,
  RadIA.Provider.Claude, RadIA.Provider.Ollama;

type
  [TestFixture]
  TTestRadIAStreaming = class
  private
    FConfig: IRadIAConfig;
    FOpenAI: TRadIAOpenAIProvider;
    FGemini: TRadIAGeminiProvider;
    FClaude: TRadIAClaudeProvider;
    FOllama: TRadIAOllamaProvider;

    procedure InvokeProcessStreamBuffer(AProvider: TObject; var ABuffer: string; const ACallback: TStreamChunkCallback);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestOpenAI_SingleChunk;
    [Test]
    procedure TestOpenAI_MultipleChunks;
    [Test]
    procedure TestOpenAI_DoneEvent;
    [Test]
    procedure TestClaude_SingleChunk;
    [Test]
    procedure TestClaude_StopEvent;
    [Test]
    procedure TestGemini_IncrementalObjects;
    [Test]
    procedure TestOllama_SingleChunk;
    [Test]
    procedure TestOllama_DoneEvent;
    [Test]
    procedure TestUtf8ChunkDecoderKeepsSplitMultibyteCharacter;
    [Test]
    procedure TestUtf8ChunkDecoderReturnsAsciiImmediately;
  end;

implementation


uses
  System.SysUtils, System.RTTI, RadIA.Provider.Streaming, RadIA.Core.Config, RadIA.Core.SettingsStorage;

{ TTestRadIAStreaming }

procedure TTestRadIAStreaming.Setup;
begin
  TRadIAConfig.SetBaseRegistryPath('Software\TestRadIAStreaming');
  TRadIAConfig.SetStorage(TRadIAMemorySettingsStorage.Create);
  FConfig := TRadIAConfig.Create;
  FOpenAI := TRadIAOpenAIProvider.Create(FConfig);
  FGemini := TRadIAGeminiProvider.Create(FConfig);
  FClaude := TRadIAClaudeProvider.Create(FConfig);
  FOllama := TRadIAOllamaProvider.Create(FConfig);
end;

procedure TTestRadIAStreaming.TearDown;
begin
  FOpenAI.Free;
  FGemini.Free;
  FClaude.Free;
  FOllama.Free;
  FConfig := nil;
  TRadIAConfig.SetStorage(nil);
  TRadIAConfig.SetBaseRegistryPath('');
end;

procedure TTestRadIAStreaming.InvokeProcessStreamBuffer(AProvider: TObject; var ABuffer: string;
  const ACallback: TStreamChunkCallback);
var
  LContext: TRttiContext;
  LType: TRttiInstanceType;
  LMethod: TRttiMethod;
  LParams: TArray<TValue>;
begin
  LContext := TRttiContext.Create;
  LType := LContext.GetType(AProvider.ClassType) as TRttiInstanceType;
  LMethod := LType.GetMethod('ProcessStreamBuffer');
  if not Assigned(LMethod) then
    LMethod := LType.GetMethod('ProcessOpenAICompatibleStreamBuffer');
  if Assigned(LMethod) then
  begin
    SetLength(LParams, 2);
    LParams[0] := ABuffer;
    LParams[1] := TValue.From<TStreamChunkCallback>(ACallback);
    LMethod.Invoke(AProvider, LParams);

    // Update the var parameter value back
    ABuffer := LParams[0].AsString;
  end
  else
    raise Exception.Create('ProcessStreamBuffer method not found via RTTI');
end;

procedure TTestRadIAStreaming.TestOpenAI_SingleChunk;
var
  LBuffer: string;
  LReceivedText: string;
  LCallbackCount: Integer;
begin
  LBuffer := 'data: {"choices":[{"delta":{"content":"Hello"}}]}' + #10;
  LReceivedText := '';
  LCallbackCount := 0;

  InvokeProcessStreamBuffer(FOpenAI, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      LReceivedText := LReceivedText + AChunk;
      Assert.IsFalse(AIsDone);
      Assert.IsEmpty(AError);
    end);

  Assert.AreEqual(1, LCallbackCount);
  Assert.AreEqual('Hello', LReceivedText);
  Assert.IsEmpty(LBuffer); // Buffer should be fully consumed
end;

procedure TTestRadIAStreaming.TestOpenAI_MultipleChunks;
var
  LBuffer: string;
  LReceivedText: string;
  LCallbackCount: Integer;
begin
  // First chunk has a complete line, second chunk has a partial line
  LBuffer := 'data: {"choices":[{"delta":{"content":"Hello"}}]}' + #10 + 'data: {"choices":[{"delta":{"content';
  LReceivedText := '';
  LCallbackCount := 0;

  InvokeProcessStreamBuffer(FOpenAI, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      LReceivedText := LReceivedText + AChunk;
    end);

  Assert.AreEqual(1, LCallbackCount);
  Assert.AreEqual('Hello', LReceivedText);
  // The partial line should still be in the buffer
  Assert.AreEqual('data: {"choices":[{"delta":{"content', LBuffer);

  // Now we complete the second line
  LBuffer := LBuffer + '":" world!"}}]}' + #10;
  InvokeProcessStreamBuffer(FOpenAI, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      LReceivedText := LReceivedText + AChunk;
    end);

  Assert.AreEqual(2, LCallbackCount);
  Assert.AreEqual('Hello world!', LReceivedText);
  Assert.IsEmpty(LBuffer);
end;

procedure TTestRadIAStreaming.TestOpenAI_DoneEvent;
var
  LBuffer: string;
  LIsDone: Boolean;
  LCallbackCount: Integer;
begin
  LBuffer := 'data: [DONE]' + #10;
  LIsDone := False;
  LCallbackCount := 0;

  InvokeProcessStreamBuffer(FOpenAI, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      LIsDone := AIsDone;
    end);

  Assert.AreEqual(1, LCallbackCount);
  Assert.IsTrue(LIsDone);
  Assert.IsEmpty(LBuffer);
end;

procedure TTestRadIAStreaming.TestClaude_SingleChunk;
var
  LBuffer: string;
  LReceivedText: string;
  LCallbackCount: Integer;
begin
  LBuffer := 'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Claude text"}}' + #10;
  LReceivedText := '';
  LCallbackCount := 0;

  InvokeProcessStreamBuffer(FClaude, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      LReceivedText := LReceivedText + AChunk;
      Assert.IsFalse(AIsDone);
    end);

  Assert.AreEqual(1, LCallbackCount);
  Assert.AreEqual('Claude text', LReceivedText);
  Assert.IsEmpty(LBuffer);
end;

procedure TTestRadIAStreaming.TestClaude_StopEvent;
var
  LBuffer: string;
  LIsDone: Boolean;
  LCallbackCount: Integer;
begin
  LBuffer := 'data: {"type":"message_stop"}' + #10;
  LIsDone := False;
  LCallbackCount := 0;

  InvokeProcessStreamBuffer(FClaude, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      LIsDone := AIsDone;
    end);

  Assert.AreEqual(1, LCallbackCount);
  Assert.IsTrue(LIsDone);
  Assert.IsEmpty(LBuffer);
end;

procedure TTestRadIAStreaming.TestGemini_IncrementalObjects;
var
  LBuffer: string;
  LReceivedText: string;
  LCallbackCount: Integer;
begin
  // Gemini stream is in progressive array brackets like: [\r\n{...}\r\n,\r\n{...}\r\n]
  LBuffer := '[' + #13#10 + '{"candidates": [{"content": {"parts": [{"text": "Gemini "}]}}]}' + #13#10 + ',' + #13#10 + '{"candidates": [{"content": {"parts": [{"text": "says hi"}]}}]}';
  LReceivedText := '';
  LCallbackCount := 0;

  InvokeProcessStreamBuffer(FGemini, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      LReceivedText := LReceivedText + AChunk;
    end);

  // It should parse the first and second objects even without the closing array bracket
  // Note: the second object was complete, so it is parsed as well!
  Assert.AreEqual(2, LCallbackCount);
  Assert.AreEqual('Gemini says hi', LReceivedText);
  Assert.IsEmpty(LBuffer.TrimLeft(['[', ',', #13, #10, ' ']));
end;

procedure TTestRadIAStreaming.TestOllama_SingleChunk;
var
  LBuffer: string;
  LReceivedText: string;
  LCallbackCount: Integer;
begin
  LBuffer := '{"model":"llama3","message":{"role":"assistant","content":"Ollama chunk"},"done":false}' + #10;
  LReceivedText := '';
  LCallbackCount := 0;

  InvokeProcessStreamBuffer(FOllama, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      LReceivedText := LReceivedText + AChunk;
      Assert.IsFalse(AIsDone);
    end);

  Assert.AreEqual(1, LCallbackCount);
  Assert.AreEqual('Ollama chunk', LReceivedText);
  Assert.IsEmpty(LBuffer);
end;

procedure TTestRadIAStreaming.TestOllama_DoneEvent;
var
  LBuffer: string;
  LIsDone: Boolean;
  LCallbackCount: Integer;
begin
  LBuffer := '{"model":"llama3","message":{"role":"assistant","content":""},"done":true}' + #10;
  LIsDone := False;
  LCallbackCount := 0;

  InvokeProcessStreamBuffer(FOllama, LBuffer,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      Inc(LCallbackCount);
      LIsDone := AIsDone;
    end);

  Assert.AreEqual(1, LCallbackCount);
  Assert.IsTrue(LIsDone);
  Assert.IsEmpty(LBuffer);
end;

procedure TTestRadIAStreaming.TestUtf8ChunkDecoderKeepsSplitMultibyteCharacter;
var
  LDecoder: TRadIAUtf8ChunkDecoder;
  LBytes: TBytes;
begin
  LDecoder := TRadIAUtf8ChunkDecoder.Create;
  try
    SetLength(LBytes, 2);
    LBytes[0] := Ord('O');
    LBytes[1] := $C3;
    Assert.AreEqual('O', LDecoder.Decode(LBytes));

    SetLength(LBytes, 2);
    LBytes[0] := $A1;
    LBytes[1] := Ord('!');
    Assert.AreEqual(#$00E1 + '!', LDecoder.Decode(LBytes));
  finally
    LDecoder.Free;
  end;
end;

procedure TTestRadIAStreaming.TestUtf8ChunkDecoderReturnsAsciiImmediately;
var
  LDecoder: TRadIAUtf8ChunkDecoder;
begin
  LDecoder := TRadIAUtf8ChunkDecoder.Create;
  try
    Assert.AreEqual('plain text', LDecoder.Decode(TEncoding.UTF8.GetBytes('plain text')));
  finally
    LDecoder.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAStreaming);

end.
