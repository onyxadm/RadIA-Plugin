unit RadIA.Core.Container;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  { Generic, lightweight IoC Container for Delphi }
  TRadIAContainer = class
  private
    class var FServices: TDictionary<TGUID, IInterface>;
    class constructor Create;
    class destructor Destroy;
  public
    class procedure Register<T: IInterface>(const AInstance: T);
    class function Resolve<T: IInterface>: T;
    class function TryResolve<T: IInterface>(out AInstance: T): Boolean;
    class procedure Clear;
  end;

implementation

uses
  System.TypInfo;

{ TRadIAContainer }

class constructor TRadIAContainer.Create;
begin
  FServices := TDictionary<TGUID, IInterface>.Create;
end;

class destructor TRadIAContainer.Destroy;
begin
  FServices.Free;
end;

class procedure TRadIAContainer.Register<T>(const AInstance: T);
var
  LGuid: TGUID;
begin
  LGuid := GetTypeData(TypeInfo(T))^.Guid;
  FServices.AddOrSetValue(LGuid, AInstance);
end;

class function TRadIAContainer.Resolve<T>: T;
var
  LGuid: TGUID;
  LIntf: IInterface;
begin
  LGuid := GetTypeData(TypeInfo(T))^.Guid;
  if FServices.TryGetValue(LGuid, LIntf) then
  begin
    if Supports(LIntf, LGuid, Result) then
      Exit;
  end;
  raise Exception.CreateFmt('Service interface %s is not registered in the container.', [GetTypeName(TypeInfo(T))]);
end;

class function TRadIAContainer.TryResolve<T>(out AInstance: T): Boolean;
var
  LGuid: TGUID;
  LIntf: IInterface;
begin
  Result := False;
  LGuid := GetTypeData(TypeInfo(T))^.Guid;
  if FServices.TryGetValue(LGuid, LIntf) then
  begin
    if Supports(LIntf, LGuid, AInstance) then
      Result := True;
  end;
end;

class procedure TRadIAContainer.Clear;
begin
  FServices.Clear;
end;

end.
