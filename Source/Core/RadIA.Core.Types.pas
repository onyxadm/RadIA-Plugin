unit RadIA.Core.Types;

interface

type
  { Enum representing the supported AI Providers }
  TAIProviderType = (ptGemini, ptOpenAI, ptClaude, ptOllama);

  { Enum representing the message role in chat conversations }
  TAIMessageRole = (mrUser, mrAssistant, mrSystem);

const
  { Standard models for Google Gemini }
  MODEL_GEMINI_15_FLASH = 'gemini-1.5-flash';
  MODEL_GEMINI_15_PRO   = 'gemini-1.5-pro';

  { Standard models for OpenAI }
  MODEL_OPENAI_GPT4O       = 'gpt-4o';
  MODEL_OPENAI_GPT4O_MINI  = 'gpt-4o-mini';

  { Standard models for Anthropic Claude }
  MODEL_CLAUDE_35_SONNET = 'claude-3-5-sonnet-20240620';
  MODEL_CLAUDE_3_HAIKU   = 'claude-3-haiku-20240307';

function ProviderTypeToString(const AProvider: TAIProviderType): string;
function StringToProviderType(const AString: string): TAIProviderType;
function MessageRoleToString(const ARole: TAIMessageRole): string;
function StringToMessageRole(const AString: string): TAIMessageRole;

type
  { Event types for global UI communication to avoid circular references }
  TOnRequestPromptEvent = procedure(const APrompt: string; const AOpenChat: Boolean) of object;
  TOnRequestDiffEvent = procedure(const AOriginalCode: string) of object;

var
  GlobalOnRequestPrompt: TOnRequestPromptEvent = nil;
  GlobalOnRequestDiff: TOnRequestDiffEvent = nil;

implementation

uses
  System.SysUtils;

function ProviderTypeToString(const AProvider: TAIProviderType): string;
begin
  case AProvider of
    ptGemini: Result := 'Gemini';
    ptOpenAI: Result := 'OpenAI';
    ptClaude: Result := 'Claude';
    ptOllama: Result := 'Ollama';
  else
    Result := '';
  end;
end;

function StringToProviderType(const AString: string): TAIProviderType;
begin
  if SameText(AString, 'Gemini') then
    Result := ptGemini
  else if SameText(AString, 'OpenAI') then
    Result := ptOpenAI
  else if SameText(AString, 'Claude') then
    Result := ptClaude
  else if SameText(AString, 'Ollama') then
    Result := ptOllama
  else
    raise EConvertError.CreateFmt('Invalid provider string: %s', [AString]);
end;

function MessageRoleToString(const ARole: TAIMessageRole): string;
begin
  case ARole of
    mrUser: Result := 'user';
    mrAssistant: Result := 'assistant';
    mrSystem: Result := 'system';
  else
    Result := '';
  end;
end;

function StringToMessageRole(const AString: string): TAIMessageRole;
begin
  if SameText(AString, 'user') then
    Result := mrUser
  else if SameText(AString, 'assistant') then
    Result := mrAssistant
  else if SameText(AString, 'system') then
    Result := mrSystem
  else
    raise EConvertError.CreateFmt('Invalid message role string: %s', [AString]);
end;

end.
