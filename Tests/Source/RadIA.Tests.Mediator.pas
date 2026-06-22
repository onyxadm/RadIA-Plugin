unit RadIA.Tests.Mediator;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Mediator;

type
  [TestFixture]
  TTestRadIAMediator = class
  private
    FMediator: TRadIAMediator;
    FPromptCalled: Boolean;
    FPromptValue: string;
    FPromptOpenChat: Boolean;
    FDiffCalled: Boolean;
    FDiffValue: string;
    FDiffReplaceWhole: Boolean;

    procedure OnPrompt(const APrompt: string; const AOpenChat: Boolean);
    procedure OnDiff(const AOriginalCode: string; const AReplaceWholeBuffer: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestInstanceNotNull;
    [Test]
    procedure TestPromptRegistrationAndRequest;
    [Test]
    procedure TestDiffRegistrationAndRequest;
    [Test]
    procedure TestPromptUnregistration;
    [Test]
    procedure TestDiffUnregistration;
    [Test]
    procedure TestRequestWithoutHandlers;
  end;

implementation

{ TTestRadIAMediator }

procedure TTestRadIAMediator.Setup;
begin
  FMediator := TRadIAMediator.Instance;
  FPromptCalled := False;
  FPromptValue := '';
  FPromptOpenChat := False;
  FDiffCalled := False;
  FDiffValue := '';
  FDiffReplaceWhole := False;
end;

procedure TTestRadIAMediator.TearDown;
begin
  FMediator.UnregisterPromptHandler;
  FMediator.UnregisterDiffHandler;
  FMediator := nil;
end;

procedure TTestRadIAMediator.OnPrompt(const APrompt: string; const AOpenChat: Boolean);
begin
  FPromptCalled := True;
  FPromptValue := APrompt;
  FPromptOpenChat := AOpenChat;
end;

procedure TTestRadIAMediator.OnDiff(const AOriginalCode: string; const AReplaceWholeBuffer: Boolean);
begin
  FDiffCalled := True;
  FDiffValue := AOriginalCode;
  FDiffReplaceWhole := AReplaceWholeBuffer;
end;

procedure TTestRadIAMediator.TestInstanceNotNull;
begin
  Assert.IsNotNull(FMediator);
  Assert.AreSame(FMediator, TRadIAMediator.Instance);
end;

procedure TTestRadIAMediator.TestPromptRegistrationAndRequest;
begin
  FMediator.RegisterPromptHandler(OnPrompt);
  FMediator.RequestPrompt('Test Prompt', True);

  Assert.IsTrue(FPromptCalled);
  Assert.AreEqual('Test Prompt', FPromptValue);
  Assert.IsTrue(FPromptOpenChat);
end;

procedure TTestRadIAMediator.TestDiffRegistrationAndRequest;
begin
  FMediator.RegisterDiffHandler(OnDiff);
  FMediator.RequestDiff('Test Diff', True);

  Assert.IsTrue(FDiffCalled);
  Assert.AreEqual('Test Diff', FDiffValue);
  Assert.IsTrue(FDiffReplaceWhole);
end;

procedure TTestRadIAMediator.TestPromptUnregistration;
begin
  FMediator.RegisterPromptHandler(OnPrompt);
  FMediator.UnregisterPromptHandler;
  FMediator.RequestPrompt('Test Prompt', True);

  Assert.IsFalse(FPromptCalled);
end;

procedure TTestRadIAMediator.TestDiffUnregistration;
begin
  FMediator.RegisterDiffHandler(OnDiff);
  FMediator.UnregisterDiffHandler;
  FMediator.RequestDiff('Test Diff', True);

  Assert.IsFalse(FDiffCalled);
end;

procedure TTestRadIAMediator.TestRequestWithoutHandlers;
begin
  { Should not throw any exception when invoking requests without registered handlers }
  FMediator.RequestPrompt('No Handler', False);
  FMediator.RequestDiff('No Handler', False);
  Assert.Pass;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAMediator);

end.
