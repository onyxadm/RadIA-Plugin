unit RadIA.Provider.Base;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient, System.Threading,
  RadIA.Core.Interfaces, RadIA.Core.Types;

type
  { Base class for AI Providers implementing IIAProvider }
  TRadIAProviderBase = class(TInterfacedObject, IIAProvider)
  protected
    FConfig: IAIConfig;
    FProviderType: TAIProviderType;
    
    function GetApiKey: string;
    function GetActiveModel: string;
    function DoPostRequest(const AUrl: string; const AHeaders: TNetHeaders; 
      const ARequestBody: string): string;
  public
    constructor Create(const AConfig: IAIConfig); virtual;
    
    { IIAProvider implementation }
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TCompletionCallback); virtual; abstract;
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

end.
