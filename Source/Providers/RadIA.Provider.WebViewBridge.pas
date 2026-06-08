unit RadIA.Provider.WebViewBridge;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Interfaces, RadIA.Core.Types,
  RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  TWebViewBridgeSendPromptEvent = procedure(const APrompt: string) of object;
  TWebViewBridgeCancelEvent = procedure of object;

  {$RTTI EXPLICIT METHODS([vcPrivate, vcProtected, vcPublic, vcPublished])}
  TRadIAWebViewBridgeProvider = class(TRadIAProviderBase)
  private
    class var FActiveCallback: TStreamChunkCallback;
    class var FOnSendPrompt: TWebViewBridgeSendPromptEvent;
    class var FOnCancel: TWebViewBridgeCancelEvent;
  public
    constructor Create(const AConfig: IAIConfig); override;
    
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TCompletionCallback; const ATemperature: Double; const AMaxTokens: Integer); override;
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TStreamChunkCallback; const ATemperature: Double; const AMaxTokens: Integer); override;
      
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
    procedure CancelCurrentRequest; override;

    class property OnSendPrompt: TWebViewBridgeSendPromptEvent read FOnSendPrompt write FOnSendPrompt;
    class property OnCancel: TWebViewBridgeCancelEvent read FOnCancel write FOnCancel;
    
    class procedure ReceiveChunk(const AChunk: string; const AIsDone: Boolean; const AError: string);
  end;

implementation

uses
  System.Threading, RadIA.Core.ProviderRegistry, RadIA.Core.Logger;

{ TRadIAWebViewBridgeProvider }

constructor TRadIAWebViewBridgeProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  FProviderId := 'WebViewBridge';
end;

procedure TRadIAWebViewBridgeProvider.SendPromptAsync(const APrompt: string;
  const AHistory: TArray<IChatMessage>; const ACallback: TCompletionCallback;
  const ATemperature: Double; const AMaxTokens: Integer);
var
  LAccumulator: TStringBuilder;
begin
  TLogger.Log('WebViewBridge.SendPromptAsync started.', 'Provider');
  LAccumulator := TStringBuilder.Create;
  SendPromptStreamAsync(APrompt, AHistory,
    procedure(const AChunk: string; const AIsDone: Boolean; const AError: string)
    begin
      if not AError.IsEmpty then
      begin
        LAccumulator.Free;
        if Assigned(ACallback) then
          ACallback('', AError, False, TTokenUsage.Empty);
        Exit;
      end;
      
      if not AChunk.IsEmpty then
        LAccumulator.Append(AChunk);
        
      if AIsDone then
      begin
        var LFullText := LAccumulator.ToString;
        LAccumulator.Free;
        if Assigned(ACallback) then
          ACallback(LFullText, '', False, TTokenUsage.Empty);
      end;
    end, ATemperature, AMaxTokens);
end;

procedure TRadIAWebViewBridgeProvider.SendPromptStreamAsync(const APrompt: string;
  const AHistory: TArray<IChatMessage>; const ACallback: TStreamChunkCallback;
  const ATemperature: Double; const AMaxTokens: Integer);
begin
  TLogger.Log('WebViewBridge.SendPromptStreamAsync started.', 'Provider');
  FCancelled := False;
  FActiveCallback := ACallback;
  
  if Assigned(FOnSendPrompt) then
  begin
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(FOnSendPrompt) then
          FOnSendPrompt(APrompt);
      end);
  end
  else
  begin
    TLogger.Log('WebViewBridge Error: FOnSendPrompt event not assigned by ChatFrame.', 'Provider');
    if Assigned(ACallback) then
      ACallback('', True, 'WebView Login session is not ready or active.');
  end;
end;

function TRadIAWebViewBridgeProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create('Web-Browser');
end;

function TRadIAWebViewBridgeProvider.GetName: string;
begin
  Result := 'WebView Bridge';
end;

procedure TRadIAWebViewBridgeProvider.CancelCurrentRequest;
begin
  TLogger.Log('WebViewBridge.CancelCurrentRequest invoked.', 'Provider');
  inherited CancelCurrentRequest;
  if Assigned(FOnCancel) then
  begin
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(FOnCancel) then
          FOnCancel();
      end);
  end;
end;

class procedure TRadIAWebViewBridgeProvider.ReceiveChunk(const AChunk: string;
  const AIsDone: Boolean; const AError: string);
begin
  TLogger.Log(Format('WebViewBridge.ReceiveChunk: ChunkLen=%d, IsDone=%s, HasError=%s', 
    [Length(AChunk), BoolToStr(AIsDone, True), BoolToStr(not AError.IsEmpty, True)]), 'Provider');
    
  if Assigned(FActiveCallback) then
  begin
    var LCallback := FActiveCallback;
    if AIsDone or not AError.IsEmpty then
      FActiveCallback := nil;
      
    LCallback(AChunk, AIsDone, AError);
  end
  else
  begin
    TLogger.Log('WebViewBridge.ReceiveChunk Warning: No active callback found to process chunk.', 'Provider');
  end;
end;

initialization
  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create(
      'WebViewBridge',
      'WebView Bridge',
      '',
      False, // HasApiKey
      False, // HasCustomUrl
      ['Web-Browser'],
      function(const ACfg: IAIConfig): IIAProvider
      begin
        Result := TRadIAWebViewBridgeProvider.Create(ACfg);
      end
    )
  );

end.
