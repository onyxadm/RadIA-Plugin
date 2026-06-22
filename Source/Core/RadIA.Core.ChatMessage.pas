unit RadIA.Core.ChatMessage;

interface

uses  RadIA.Core.Interfaces, RadIA.Core.Types;

type
  { Simple concrete class implementing IRadIAChatMessage }
  TRadIAChatMessage = class(TInterfacedObject, IRadIAChatMessage)
  private
    FRole: TAIMessageRole;
    FContent: string;
    FProvider: string;
    FModel: string;

    function GetRole: TAIMessageRole;
    function GetContent: string;
    procedure SetContent(const AValue: string);
    function GetProvider: string;
    procedure SetProvider(const AValue: string);
    function GetModel: string;
    procedure SetModel(const AValue: string);
  public
    constructor Create(const ARole: TAIMessageRole; const AContent: string;
      const AProvider: string = ''; const AModel: string = '');

    class function CreateMessage(const ARole: TAIMessageRole; const AContent: string;
      const AProvider: string = ''; const AModel: string = ''): IRadIAChatMessage; static;

  end;

implementation

{ TRadIAChatMessage }

constructor TRadIAChatMessage.Create(const ARole: TAIMessageRole; const AContent: string;
  const AProvider: string; const AModel: string);
begin
  inherited Create;
  FRole := ARole;
  FContent := AContent;
  FProvider := AProvider;
  FModel := AModel;
end;

class function TRadIAChatMessage.CreateMessage(const ARole: TAIMessageRole; const AContent: string;
  const AProvider: string; const AModel: string): IRadIAChatMessage;
begin
  Result := TRadIAChatMessage.Create(ARole, AContent, AProvider, AModel);
end;

function TRadIAChatMessage.GetContent: string;
begin
  Result := FContent;
end;

function TRadIAChatMessage.GetRole: TAIMessageRole;
begin
  Result := FRole;
end;

procedure TRadIAChatMessage.SetContent(const AValue: string);
begin
  FContent := AValue;
end;

function TRadIAChatMessage.GetProvider: string;
begin
  Result := FProvider;
end;

procedure TRadIAChatMessage.SetProvider(const AValue: string);
begin
  FProvider := AValue;
end;

function TRadIAChatMessage.GetModel: string;
begin
  Result := FModel;
end;

procedure TRadIAChatMessage.SetModel(const AValue: string);
begin
  FModel := AValue;
end;

end.
