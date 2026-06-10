unit RadIA.Core.RequestOrchestrator;

interface

uses
  System.SysUtils, RadIA.Core.Interfaces, RadIA.Core.Types,
  RadIA.Core.TokenUsage, RadIA.Core.Service;

type
  TAIRequest = record
    UseCase: TAIRequestUseCase;
    ResponseMode: TAIResponseMode;
    Profile: TAIRequestProfile;
    Prompt: string;
    History: TArray<IChatMessage>;
    class function Create(const APrompt: string;
      const AUseCase: TAIRequestUseCase;
      const AProfile: TAIRequestProfile;
      const AHistory: TArray<IChatMessage>;
      const AResponseMode: TAIResponseMode = rmComplete): TAIRequest; static;
  end;

  TAIRequestCallback = reference to procedure(
    const AResponse: string;
    const AError: string;
    const AUsage: TTokenUsage);

  IAIRequestOrchestrator = interface
    ['{81162B4B-1D24-4D1B-8DEB-2DA064F2635E}']
    procedure ExecuteAsync(const ARequest: TAIRequest; const ACallback: TAIRequestCallback);
    procedure ExecuteStreamAsync(const ARequest: TAIRequest; const ACallback: TStreamChunkCallback);
    procedure CancelCurrentRequest;
  end;

  TRadIARequestOrchestrator = class(TInterfacedObject, IAIRequestOrchestrator)
  private
    FConfig: IAIConfig;
    FService: TRadIAService;
  public
    constructor Create(const AConfig: IAIConfig);
    destructor Destroy; override;
    procedure ExecuteAsync(const ARequest: TAIRequest; const ACallback: TAIRequestCallback);
    procedure ExecuteStreamAsync(const ARequest: TAIRequest; const ACallback: TStreamChunkCallback);
    procedure CancelCurrentRequest;
  end;

implementation

class function TAIRequest.Create(const APrompt: string;
  const AUseCase: TAIRequestUseCase; const AProfile: TAIRequestProfile;
  const AHistory: TArray<IChatMessage>;
  const AResponseMode: TAIResponseMode): TAIRequest;
begin
  Result.UseCase := AUseCase;
  Result.ResponseMode := AResponseMode;
  Result.Profile := AProfile;
  Result.Prompt := APrompt;
  Result.History := AHistory;
end;

constructor TRadIARequestOrchestrator.Create(const AConfig: IAIConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FService := TRadIAService.Create(FConfig);
end;

destructor TRadIARequestOrchestrator.Destroy;
begin
  FService.Free;
  inherited Destroy;
end;

procedure TRadIARequestOrchestrator.ExecuteAsync(const ARequest: TAIRequest;
  const ACallback: TAIRequestCallback);
begin
  FService.SendPrompt(ARequest.Prompt, ARequest.History,
    procedure(const AResponse: string; const AError: string; AFromCache: Boolean;
      const AUsage: TTokenUsage)
    begin
      if Assigned(ACallback) then
        ACallback(AResponse, AError, AUsage);
    end,
    ARequest.Profile);
end;

procedure TRadIARequestOrchestrator.ExecuteStreamAsync(const ARequest: TAIRequest;
  const ACallback: TStreamChunkCallback);
begin
  FService.SendPromptStream(ARequest.Prompt, ARequest.History, ACallback, ARequest.Profile);
end;

procedure TRadIARequestOrchestrator.CancelCurrentRequest;
begin
  FService.CancelCurrentRequest;
end;

end.
