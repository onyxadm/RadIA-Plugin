unit RadIA.Provider.Base;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, System.Threading,
  RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.TokenUsage;

type
  { Custom stream that intercepts HTTP write calls to process SSE chunks in real time }
  TStreamingTargetStream = class(TStream)
  private
    FOnWrite: TProc<TBytes>;
  public
    constructor Create(const AOnWrite: TProc<TBytes>);
    function Write(const Buffer; Count: Longint): Longint; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

  { Base class for AI Providers implementing IIAProvider }
  TRadIAProviderBase = class(TInterfacedObject, IIAProvider)
  protected
    FConfig: IAIConfig;
    FProviderType: TAIProviderType;
    
    function GetApiKey: string;
    function GetActiveModel: string;
    function DoPostRequest(const AUrl: string; const AHeaders: TNetHeaders; 
      const ARequestBody: string): string;
    function DoPostRequestStream(const AUrl: string; const AHeaders: TNetHeaders; 
      const ARequestBody: string; const AOnWrite: TProc<TBytes>): Boolean;
    function DoGetRequest(const AUrl: string; const AHeaders: TNetHeaders): string;
  public
    constructor Create(const AConfig: IAIConfig); virtual;
    
    { IIAProvider implementation }
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback); virtual; abstract;
    procedure SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
      const ACallback: TStreamChunkCallback); virtual;
    procedure FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>); virtual;
    function GetAvailableModels: TArray<string>; virtual; abstract;
    function GetName: string; virtual; abstract;
    function GetProviderType: TAIProviderType;
  end;

implementation

constructor TRadIAProviderBase.Create(const AConfig: IAIConfig);
begin
  inherited Create;
  FConfig := AConfig;
end;

function TRadIAProviderBase.GetApiKey: string;
begin
  Result := FConfig.GetApiKey(FProviderType);
end;

function TRadIAProviderBase.GetActiveModel: string;
begin
  Result := FConfig.GetActiveModel(FProviderType);
end;

function TRadIAProviderBase.GetProviderType: TAIProviderType;
begin
  Result := FProviderType;
end;

function TRadIAProviderBase.DoGetRequest(const AUrl: string; const AHeaders: TNetHeaders): string;
var
  LHTTPClient: THTTPClient;
  LResponse: IHTTPResponse;
begin
  LHTTPClient := THTTPClient.Create;
  try
    LHTTPClient.ConnectionTimeout := 10000;
    LHTTPClient.SendTimeout := 10000;
    LHTTPClient.ResponseTimeout := 60000;
    LHTTPClient.AcceptCharSet := 'utf-8';
    
    LResponse := LHTTPClient.Get(AUrl, nil, AHeaders);
    
    if LResponse.StatusCode <> 200 then
      raise ENetHTTPClientException.CreateFmt('HTTP error %d: %s. Response: %s', 
        [LResponse.StatusCode, LResponse.StatusText, LResponse.ContentAsString(TEncoding.UTF8)]);
        
    Result := LResponse.ContentAsString(TEncoding.UTF8);
  finally
    LHTTPClient.Free;
  end;
end;

function TRadIAProviderBase.DoPostRequest(const AUrl: string; const AHeaders: TNetHeaders; 
  const ARequestBody: string): string;
var
  LHTTPClient: THTTPClient;
  LSourceStream: TStringStream;
  LResponse: IHTTPResponse;
begin
  LHTTPClient := THTTPClient.Create;
  LSourceStream := TStringStream.Create(ARequestBody, TEncoding.UTF8);
  try
    LHTTPClient.ConnectionTimeout := 10000;
    LHTTPClient.SendTimeout := 10000;
    LHTTPClient.ResponseTimeout := 60000;
    LHTTPClient.ContentType := 'application/json';
    LHTTPClient.AcceptCharSet := 'utf-8';
    
    LResponse := LHTTPClient.Post(AUrl, LSourceStream, nil, AHeaders);
    
    if LResponse.StatusCode <> 200 then
      raise ENetHTTPClientException.CreateFmt('HTTP error %d: %s. Response: %s', 
        [LResponse.StatusCode, LResponse.StatusText, LResponse.ContentAsString(TEncoding.UTF8)]);
        
    Result := LResponse.ContentAsString(TEncoding.UTF8);
  finally
    LSourceStream.Free;
    LHTTPClient.Free;
  end;
end;

function TRadIAProviderBase.DoPostRequestStream(const AUrl: string; const AHeaders: TNetHeaders; 
  const ARequestBody: string; const AOnWrite: TProc<TBytes>): Boolean;
var
  LHTTPClient: THTTPClient;
  LSourceStream: TStringStream;
  LTargetStream: TStreamingTargetStream;
  LResponse: IHTTPResponse;
begin
  Result := False;
  LHTTPClient := THTTPClient.Create;
  LSourceStream := TStringStream.Create(ARequestBody, TEncoding.UTF8);
  LTargetStream := TStreamingTargetStream.Create(AOnWrite);
  try
    LHTTPClient.ConnectionTimeout := 10000;
    LHTTPClient.SendTimeout := 10000;
    LHTTPClient.ResponseTimeout := 60000;
    LHTTPClient.ContentType := 'application/json';
    LHTTPClient.AcceptCharSet := 'utf-8';
    
    LResponse := LHTTPClient.Post(AUrl, LSourceStream, LTargetStream, AHeaders);
    
    if LResponse.StatusCode <> 200 then
      raise ENetHTTPClientException.CreateFmt('HTTP error %d: %s. Response: %s', 
        [LResponse.StatusCode, LResponse.StatusText, LResponse.ContentAsString(TEncoding.UTF8)]);
        
    Result := True;
  finally
    LTargetStream.Free;
    LSourceStream.Free;
    LHTTPClient.Free;
  end;
end;

procedure TRadIAProviderBase.SendPromptStreamAsync(const APrompt: string; const AHistory: TArray<IChatMessage>;
  const ACallback: TStreamChunkCallback);
var
  LQueueProc: TThreadProcedure;
begin
  { Default fallback simulating streaming }
  SendPromptAsync(APrompt, AHistory,
    procedure(const AResponse: string; const AError: string; AFromCache: Boolean; const AUsage: TTokenUsage)
    begin
      LQueueProc := procedure
                    begin
                      ACallback(AResponse, True, AError);
                    end;
      TThread.Queue(nil, LQueueProc);
    end);
end;

procedure TRadIAProviderBase.FetchAvailableModelsAsync(const ACallback: TProc<TArray<string>, string>);
var
  LQueueProc: TThreadProcedure;
begin
  LQueueProc := procedure
                begin
                  ACallback(GetAvailableModels, '');
                end;
  TThread.Queue(nil, LQueueProc);
end;

{ TStreamingTargetStream }

constructor TStreamingTargetStream.Create(const AOnWrite: TProc<TBytes>);
begin
  inherited Create;
  FOnWrite := AOnWrite;
end;

function TStreamingTargetStream.Write(const Buffer; Count: Integer): Longint;
var
  LBytes: TBytes;
begin
  Result := Count;
  if (Count > 0) and Assigned(FOnWrite) then
  begin
    SetLength(LBytes, Count);
    Move(Buffer, LBytes[0], Count);
    FOnWrite(LBytes);
  end;
end;

function TStreamingTargetStream.Read(var Buffer; Count: Integer): Longint;
begin
  Result := 0;
end;

function TStreamingTargetStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := 0;
end;

end.
