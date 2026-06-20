unit RadIA.Tests.Container;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Container;

type
  IMockServiceA = interface
    ['{84B0F83C-1F0A-4E16-95D9-052C876FA63B}']
    function GetValue: string;
  end;

  TMockServiceA = class(TInterfacedObject, IMockServiceA)
  public
    function GetValue: string;
  end;

  IMockServiceB = interface
    ['{C0EFA938-1E74-4C7D-89EA-FA5F20807B41}']
    function GetValue: string;
  end;

  TMockServiceB = class(TInterfacedObject, IMockServiceB)
  public
    function GetValue: string;
  end;

  [TestFixture]
  TTestRadIAContainer = class
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestRegisterAndResolve;
    [Test]
    procedure TestTryResolve_ReturnsFalseWhenNotRegistered;
    [Test]
    procedure TestResolve_ThrowsExceptionWhenNotRegistered;
    [Test]
    procedure TestConcurrentAccess_IsThreadSafe;
  end;

implementation

uses
  System.Classes, System.SysUtils, System.SyncObjs, System.Threading;

{ TMockServiceA }

function TMockServiceA.GetValue: string;
begin
  Result := 'ServiceA';
end;

{ TMockServiceB }

function TMockServiceB.GetValue: string;
begin
  Result := 'ServiceB';
end;

{ TTestRadIAContainer }

procedure TTestRadIAContainer.Setup;
begin
  TRadIAContainer.Clear;
end;

procedure TTestRadIAContainer.TearDown;
begin
  TRadIAContainer.Clear;
end;

procedure TTestRadIAContainer.TestRegisterAndResolve;
var
  LServiceA: IMockServiceA;
  LResolved: IMockServiceA;
begin
  LServiceA := TMockServiceA.Create;
  TRadIAContainer.Register<IMockServiceA>(LServiceA);

  LResolved := TRadIAContainer.Resolve<IMockServiceA>;
  Assert.IsNotNull(LResolved);
  Assert.AreEqual('ServiceA', LResolved.GetValue);
end;

procedure TTestRadIAContainer.TestTryResolve_ReturnsFalseWhenNotRegistered;
var
  LResolved: IMockServiceA;
  LFound: Boolean;
begin
  LFound := TRadIAContainer.TryResolve<IMockServiceA>(LResolved);
  Assert.IsFalse(LFound);
  Assert.IsNull(LResolved);
end;

procedure TTestRadIAContainer.TestResolve_ThrowsExceptionWhenNotRegistered;
begin
  Assert.WillRaise(
    procedure
    begin
      TRadIAContainer.Resolve<IMockServiceA>;
    end,
    Exception
  );
end;

procedure TTestRadIAContainer.TestConcurrentAccess_IsThreadSafe;
const
  NUM_THREADS = 10;
  ITERATIONS = 100;
var
  LTasks: TArray<ITask>;
  LServiceA: IMockServiceA;
  LServiceB: IMockServiceB;
  I: Integer;
begin
  LServiceA := TMockServiceA.Create;
  LServiceB := TMockServiceB.Create;
  
  TRadIAContainer.Register<IMockServiceA>(LServiceA);
  TRadIAContainer.Register<IMockServiceB>(LServiceB);

  SetLength(LTasks, NUM_THREADS);

  for I := 0 to NUM_THREADS - 1 do
  begin
    LTasks[I] := TTask.Create(
      procedure
      var
        LTaskIdx: Integer;
        LResolvedA: IMockServiceA;
        LResolvedB: IMockServiceB;
        LInstanceA: IMockServiceA;
      begin
        for LTaskIdx := 1 to ITERATIONS do
        begin
          // Test simultaneous read/write
          if LTaskIdx mod 5 = 0 then
          begin
            LInstanceA := TMockServiceA.Create;
            TRadIAContainer.Register<IMockServiceA>(LInstanceA);
          end;
          
          TRadIAContainer.Resolve<IMockServiceA>;
          TRadIAContainer.Resolve<IMockServiceB>;
          
          TRadIAContainer.TryResolve<IMockServiceA>(LResolvedA);
          TRadIAContainer.TryResolve<IMockServiceB>(LResolvedB);
        end;
      end
    );
    LTasks[I].Start;
  end;

  // Wait for all tasks to complete
  TTask.WaitForAll(LTasks);
  
  // Re-verify that container is still valid and responsive
  Assert.IsNotNull(TRadIAContainer.Resolve<IMockServiceB>);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAContainer);

end.
