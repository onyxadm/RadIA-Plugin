unit RadIA.Tests.Exporter;

interface

uses
  DUnitX.TestFramework, RadIA.Core.Interfaces, RadIA.Core.Types, RadIA.Core.Service, 
  RadIA.Core.ConversationExporter;

type
  [TestFixture]
  TTestRadIAExporter = class
  private
    FHistory: TArray<IRadIAChatMessage>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestExportMarkdown_ContainsAllMessages;
    [Test]
    procedure TestExportMarkdown_ContainsHeader;
    [Test]
    procedure TestExportMarkdown_EmptyHistory;
    [Test]
    procedure TestExportHTML_ContainsStylesAndContent;
  end;

implementation

uses
  System.SysUtils, RadIA.Core.ChatMessage;

{ TTestRadIAExporter }

procedure TTestRadIAExporter.Setup;
begin
  FHistory := TArray<IRadIAChatMessage>.Create(
    TRadIAChatMessage.CreateMessage(mrUser, 'Como criar uma classe em Delphi?'),
    TRadIAChatMessage.CreateMessage(mrAssistant, 'Use a sintaxe `type TMyClass = class`.')
  );
end;

procedure TTestRadIAExporter.TearDown;
begin
  FHistory := nil;
end;

procedure TTestRadIAExporter.TestExportMarkdown_ContainsAllMessages;
var
  LMarkdown: string;
begin
  LMarkdown := TConversationExporter.ExportToMarkdown(FHistory, 'OpenAI', 'gpt-4o');
  
  Assert.IsNotEmpty(LMarkdown);
  Assert.IsTrue(LMarkdown.Contains('Como criar uma classe em Delphi?'));
  Assert.IsTrue(LMarkdown.Contains('Use a sintaxe `type TMyClass = class`.'));
  Assert.IsTrue(LMarkdown.Contains('👤 Usuário'));
  Assert.IsTrue(LMarkdown.Contains('🤖 Assistente (Rad IA)'));
end;

procedure TTestRadIAExporter.TestExportMarkdown_ContainsHeader;
var
  LMarkdown: string;
begin
  LMarkdown := TConversationExporter.ExportToMarkdown(FHistory, 'Google Gemini', 'gemini-1.5-flash');
  
  Assert.IsTrue(LMarkdown.Contains('# Histórico de Conversa - Rad IA'));
  Assert.IsTrue(LMarkdown.Contains('**Provedor**: Google Gemini'));
  Assert.IsTrue(LMarkdown.Contains('**Modelo**: gemini-1.5-flash'));
end;

procedure TTestRadIAExporter.TestExportMarkdown_EmptyHistory;
var
  LMarkdown: string;
  LEmptyHistory: TArray<IRadIAChatMessage>;
begin
  LEmptyHistory := [];
  LMarkdown := TConversationExporter.ExportToMarkdown(LEmptyHistory, 'OpenAI', 'gpt-4o');
  
  Assert.IsTrue(LMarkdown.Contains('# Histórico de Conversa - Rad IA'));
  Assert.IsFalse(LMarkdown.Contains('👤 Usuário'));
end;

procedure TTestRadIAExporter.TestExportHTML_ContainsStylesAndContent;
var
  LHtml: string;
begin
  LHtml := TConversationExporter.ExportToHTML(FHistory, 'Anthropic Claude', 'claude-3-5-sonnet');
  
  Assert.IsNotEmpty(LHtml);
  Assert.IsTrue(LHtml.Contains('<!DOCTYPE html>'));
  Assert.IsTrue(LHtml.Contains('<html>'));
  Assert.IsTrue(LHtml.Contains('<head>'));
  Assert.IsTrue(LHtml.Contains('background-color: #1e1e1e;'));
  Assert.IsTrue(LHtml.Contains('Como criar uma classe em Delphi?'));
  Assert.IsTrue(LHtml.Contains('Use a sintaxe `type TMyClass = class`.'));
  Assert.IsTrue(LHtml.Contains('class="message user"'));
  Assert.IsTrue(LHtml.Contains('class="message assistant"'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadIAExporter);

end.

