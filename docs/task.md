# Lista de Tarefas: Desenvolvimento do RadIA

Esta é a checklist de desenvolvimento consolidada do plugin **RadIA**, refletindo todas as fases entregues até o momento.

---

## Fase 1: Estrutura do Projeto & Configurações ✅
- [x] **Configuração da Solução Delphi**
  - [x] Criar a árvore de pastas física (`Source/Core`, `Source/Providers`, `Source/Integration`, `Source/UI`, `Source/UI/Web`, `Tests/Source`)
  - [x] Criar `RadIA.groupproj`, `RadIA.dpk` e `RadIA.dproj` para Delphi 10.4+
- [x] **Interfaces e Tipos do Core**
  - [x] `RadIA.Core.Types.pas`: enum `TAIProviderType` (Gemini, OpenAI, Claude, **Ollama**), `TAIMessageRole`, modelos padrão, conversão string/enum
  - [x] `RadIA.Core.Interfaces.pas`: `IIAProvider`, `IAIConfig` (incl. `OllamaBaseUrl`, `SystemPrompt`), `IChatMessage`, `TCompletionCallback`
- [x] **Gerenciador de Configurações**
  - [x] `RadIA.Core.Config.pas`: leitura/escrita no Registro `HKEY_CURRENT_USER\Software\RadIA`
  - [x] Criptografia de API Keys via DPAPI (`CryptProtectData`/`CryptUnprotectData`)
  - [x] Persistência de `OllamaBaseUrl` (padrão `http://localhost:11434`)
  - [x] Persistência de `SystemPrompt`

---

## Fase 2: Integração com as APIs de IA (Providers) ✅
- [x] **Provedor Base**
  - [x] `RadIA.Provider.Base.pas`: `TRadIAProviderBase` com `DoPostRequest`, `DoGetRequest` (via `THTTPClient`), `FetchAvailableModelsAsync` padrão
- [x] **Provedores de Nuvem**
  - [x] `RadIA.Provider.Gemini.pas`: `POST /v1beta/models/{model}:generateContent`, header `x-goog-api-key`, descoberta via API
  - [x] `RadIA.Provider.OpenAI.pas`: `POST /v1/chat/completions`, header `Authorization: Bearer`, descoberta via API
  - [x] `RadIA.Provider.Claude.pas`: `POST /v1/messages`, headers `x-api-key` + `anthropic-version`
- [x] **Provedor Local/Rede (Ollama)**
  - [x] `RadIA.Provider.Ollama.pas`: `POST /api/chat` (`stream: false`), `GET /api/tags` para descoberta de modelos, fallback estático
- [x] **Orquestrador de IA**
  - [x] `RadIA.Core.Service.pas`: `TRadIAService` seleciona o provedor ativo via factory, executa em `TTask.Run`, callback retorna via `TThread.Queue`

---

## Fase 3: Integração com a IDE Delphi (Open Tools API) ✅
- [x] `RadIA.OTA.Helper.pas`: `ReplaceActiveEditorText` via `IOTAEditBlock`
- [x] `RadIA.OTA.ContextParser.pas`: extrai cláusula `interface` e contexto da classe ativa
- [x] `RadIA.OTA.MessageViewHook.pas`: monitora Messages View e extrai erros de compilação
- [x] `RadIA.OTA.EditorHook.pas`: atalhos de teclado e menus de contexto do editor
- [x] `RadIA.OTA.Register.pas`: registra Wizard na IDE, cria itens no menu `Tools` e menu de contexto
- [x] `RadIA.OTA.DockableForm.pas`: `INTADockableForm`, encapsula `TFrameAIChat`, ajusta tema via `IOTAThemeServices`

---

## Fase 4: Interface do Usuário (VCL + Edge/WebView2) ✅
- [x] **Páginas Web do Chat**
  - [x] `chat.html`: estrutura de mensagens, listener de `webview.message`
  - [x] `chat.css`: temas Dark/Light, design moderno
  - [x] `chat.js`: Marked.js (Markdown), Prism.js (syntax highlighting Pascal), botão "Apply Code"
  - [x] `diff.html`: visualização Smart Diff com `diff2html`
- [x] **Chat Frame** (`RadIA.UI.ChatFrame`)
  - [x] Combo de provedores e modelos (carregamento assíncrono via `FetchAvailableModelsAsync`)
  - [x] `TEdgeBrowser` com comunicação bidirecional JSON
  - [x] **Histórico persistente:** `LoadChatHistory` / `SaveChatHistory` em `%APPDATA%\RadIA\history.json`
  - [x] Botão Clear apaga histórico na tela e o arquivo físico
- [x] **Config Frame** (`RadIA.UI.ConfigFrame`)
  - [x] Campos de API Key para Gemini, OpenAI e Claude (mascarados)
  - [x] **Campo `edtOllamaUrl`:** URL do servidor Ollama (local ou rede)
  - [x] Campo de System Prompt customizado (`memSystemPrompt`)
- [x] **Diff Form** (`RadIA.UI.DiffForm`): modal lado a lado com botão [Aplicar Alteração]

---

## Fase 5: Testes Unitários (DUnitX) ✅
- [x] `RadIA.Tests.Config.pas`: 5 testes — persistência de provider, API key (DPAPI), model, system prompt, **OllamaBaseUrl**
- [x] `RadIA.Tests.Providers.pas`: 8 testes — parse de JSON (Gemini/OpenAI/Claude), payloads, erros HTTP
- [x] `RadIA.Tests.Cache.pas`: 2 testes — Put/Get, expiração LRU
- [x] `RadIA.Tests.Ollama.pas`: 2 testes — `BuildRequestBody` (RTTI), `ParseResponseBody` (RTTI)
- [x] **Resultado: 17/17 testes passando** ✅

---

## Fase 6: Cache, System Prompts e Descoberta Dinâmica de Modelos ✅
- [x] **Cache LRU local** (`RadIA.Core.Cache.pas`)
  - [x] 500 entradas, expiração de 24h, descarte LRU (Least Recently Used)
  - [x] Hash SHA-1 por `provider+model+systemPrompt+prompt+history`
  - [x] Persistência em `%APPDATA%\RadIA\cache.json` (JSON, formato ISO 8601)
  - [x] Resposta de cache indicada com nota no chat
- [x] **System Prompt customizado**
  - [x] Campo na tela de configurações
  - [x] Injetado como `mrSystem` no início de cada requisição
  - [x] Persistido no Registro do Windows
- [x] **Descoberta dinâmica de modelos** (Gemini, OpenAI, Ollama)
  - [x] Chamada assíncrona em `FetchAvailableModelsAsync` ao trocar o provedor
  - [x] Exibe `Loading...` durante carregamento
  - [x] Fallback para lista estática em caso de falha

---

## Fase 7: Suporte ao Ollama e Histórico Persistente ✅
- [x] `ptOllama` adicionado ao enum `TAIProviderType`
- [x] `OllamaBaseUrl` na interface `IAIConfig` e implementação em `TRadIAConfig`
- [x] `TRadIAOllamaProvider` implementado e registrado na factory
- [x] Campo `edtOllamaUrl` adicionado ao ConfigFrame (DFM e PAS)
- [x] Modal de configurações redimensionada (altura 585 px)
- [x] `LoadChatHistory` / `SaveChatHistory` no ChatFrame
- [x] Botão Clear apaga arquivo físico `history.json`
- [x] Testes unitários do Ollama criados e passando
- [x] README.md atualizado com seções 5.1 (Ollama) e 5.2 (Histórico)
- [x] `docs/backlog.md` atualizado — item concluído

---

## Critérios de Aceitação ✅

- [x] Compilação do pacote principal `RadIA.dpk` — **sucesso**
- [x] Compilação do projeto de testes `RadIATests.dpr` — **sucesso** (apenas hints)
- [x] 100% dos testes unitários passando — **17/17** ✅
- [x] Documentação (`README.md`, `docs/`) refletindo o estado real da implementação ✅
