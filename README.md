# RadIA - Assistente de IA para Delphi IDE

**RadIA** é um plugin assistente de IA avançado projetado especificamente para a IDE do Embarcadero Delphi (usando a Open Tools API). Ele se acopla diretamente à barra lateral da IDE, fornecendo uma interface de chat interativa e integração contextual profunda com o editor de código para acelerar o desenvolvimento, refatoração e depuração.

---

## 🇧🇷 Documentação em Português

### 1. Padrão de Linguagem
*   **Documentação (README / Docs):** Bilíngue (Inglês e Português em seções separadas).
*   **Código Fonte:** 100% escrito em **Inglês** (nomes, units, variáveis, classes, métodos e comentários de código) seguindo o clean code e os padrões Pascal.

### 2. Funcionalidades
*   **Chat Lateral Acoplável (Dockable):** Painel integrado à IDE com visual nativo do Delphi, trazendo uma janela de chat em HTML5/JS moderno (WebView2) com suporte a Markdown e realce de sintaxe Pascal.
*   **Suporte a Múltiplas IAs:** Modelo de uso de chaves próprias (BYOK) com suporte nativo ao **Google Gemini**, **OpenAI ChatGPT**, **Anthropic Claude** e modelos locais/rede via **Ollama** (ex: Llama 3, Phi-3, Mistral, CodeLlama).
*   **Histórico de Chat Persistente:** O histórico de conversas é salvo automaticamente localmente em formato JSON, restaurando o contexto ao fechar e abrir a IDE.
*   **Ações de Contexto no Editor:** Clique com o botão direito em qualquer trecho de código selecionado para:
    *   *Explicar Código Selecionado:* Analisar didaticamente a lógica.
    *   *Otimizar/Refatorar:* Melhorar a performance e aplicar princípios SOLID/Clean Code.
    *   *Gerar Testes Unitários:* Gerar estruturas prontas de testes usando DUnitX.
    *   *Localizar Bugs:* Buscar memory leaks, exceptions soltas e falhas de lógica.
*   **Comparador Visual Inteligente (Smart Diff):** Visualização de refatorações lado a lado (Original vs. Sugerido) com realce vermelho/verde e botão **[Aplicar Alteração]** de um clique direto no editor.
*   **Depurador de Compilação (Smart Build):** Integração com a aba *Messages* do Delphi. Clique com o botão direito nos erros de compilação da IDE para obter explicações e correções instantâneas.
*   **Documentação XML Automática:** Geração de comentários XML estruturados (`/// <summary>`) acima do cabeçalho de métodos para alimentar o Help Insight.
*   **Comandos de Barra (Slash Commands):** Ações rápidas digitando comandos no chat (ex: `/doc`, `/explain`, `/refactor`, `/bugs`).
*   **Armazenamento Seguro de Chaves:** Credenciais criptografadas localmente via Windows DPAPI e salvas no Registro do Windows.

### 2.1 Tabela Completa de Recursos (Features)

| Recurso | Categoria | Descrição | Status |
| :--- | :--- | :--- | :--- |
| **Chat Lateral Acoplável** | Chat UX | Painel integrado à IDE rodando WebView2 com suporte a Markdown e Pascal highlight. | ✅ Concluído |
| **Streaming de Respostas** | Chat UX | Respostas incrementais token a token (SSE) nos provedores OpenAI, Gemini, Claude e Ollama. | ✅ Concluído |
| **Histórico de Chat Persistente** | Chat UX | Salvamento automático e restauração de sessões anteriores de chat em JSON. | ✅ Concluído |
| **Histórico de Prompts (↑/↓)** | Chat UX | Navegação rápida pelos prompts enviados anteriormente usando as setas do teclado. | ✅ Concluído |
| **Exportação de Conversa** | Chat UX | Botão para salvar histórico nos formatos Markdown (.md) ou HTML autônomo com Prism.js. | ✅ Concluído |
| **Templates de Prompt** | Chat UX | Biblioteca de templates (Clean Code, DUnitX, Documentação) com slash command `/template`. | ✅ Concluído |
| **Google Gemini** | Provedor | Suporte nativo aos modelos Gemini 1.5 Flash e Pro via chaves próprias (BYOK). | ✅ Concluído |
| **OpenAI ChatGPT** | Provedor | Suporte nativo aos modelos GPT-4o, GPT-4o-mini e outros. | ✅ Concluído |
| **Anthropic Claude** | Provedor | Suporte nativo aos modelos Claude 3 Haiku e Claude 3.5 Sonnet. | ✅ Concluído |
| **Ollama Local/Rede** | Provedor | Integração com modelos locais open-source sem chaves pagas e autodescoberta de tags. | ✅ Concluído |
| **Custom Base URL** | Provedor | Suporte a qualquer endpoint compatível com OpenAI (Groq, DeepSeek, LM Studio). | ✅ Concluído |
| **Contexto de Projeto** | Inteligência | Carregamento automático de instruções de sistema e arquivos de contexto via `.radia`. | ✅ Concluído |
| **Rastreamento de Tokens e Custo**| Transparência | Contador dinâmico de consumo e custo acumulado estimado em USD (locale invariant). | ✅ Concluído |
| **Ações no Editor** | Integração | Explicação de código, otimização, testes e bugs com botão direito no editor. | ✅ Concluído|
| **Smart Diff (Comparador)** | Integração | Visualização lado a lado de código sugerido vs. original com aplicação instantânea. | ✅ Concluído |
| **Smart Build Debugger** | Integração | Clique com o botão direito nos erros de compilação da IDE para correções instantâneas. | ✅ Concluído |
| **Documentação XML Automática** | Geração | Geração automática de comentários `/// <summary>` sobre os métodos da unit. | ✅ Concluído |
| **Armazenamento Seguro** | Segurança | Chaves de API salvas localmente criptografadas usando a API do Windows DPAPI. | ✅ Concluído |

### 3. Como Funciona e Arquitetura
O RadIA é construído inteiramente em Object Pascal (Delphi) usando a **Open Tools API (OTA)** para interagir com o editor de código, gerenciamento de mensagens e detecção de temas da IDE.
A interface utiliza uma arquitetura híbrida:
1.  **VCL Nativa:** Gerencia o acoplamento da janela, a tela de configurações, ações de menus, gravação segura no registro e chamadas assíncronas.
2.  **Motor WebView2 (Edge):** Exibe as mensagens e respostas da IA utilizando HTML5, CSS e JS locais (Marked.js para Markdown e Prism.js para realce de sintaxe). A interface se adapta automaticamente ao tema da IDE (Light/Dark) e roda de forma fluida sem congelar a IDE.

### 4. Requisitos do Sistema
*   **IDE:** Embarcadero Delphi 10.4 Sydney, 11 Alexandria ou 12 Athens (ou superior).
*   **OS:** Windows 10 / 11 (64-bit).
*   **Web Engine:** *Microsoft Edge WebView2 Runtime* instalado no sistema Windows (pré-instalado em versões modernas do Windows). **Importante:** A DLL `WebView2Loader.dll` correspondente à arquitetura da IDE (32-bit para Delphi 10.4, 64-bit para Delphi 11 e 12) deve estar presente na pasta `bin` da instalação do Delphi (ex: `C:\Program Files (x86)\Embarcadero\Studio\<versao>\bin`) ou no PATH do sistema.
*   **API Keys:** Chaves de desenvolvedor ativas obtidas em seus respectivos consoles: [Google AI Studio](https://aistudio.google.com/) (Gemini), [OpenAI Platform](https://platform.openai.com/) (ChatGPT) e [Anthropic Console](https://console.anthropic.com/) (Claude). Para uso local/rede com o **Ollama**, certifique-se de que a instância do servidor Ollama está ativa no endereço configurado (ex: `http://localhost:11434`).

### 5. Instalação

> [!IMPORTANT]
> **Modelo Bring Your Own Key (BYOK) & IA Local:** O RadIA exige chaves de API válidas e ativas para funcionar com nuvem (Gemini, OpenAI ou Claude) ou uma instância configurada do **Ollama** rodando na máquina ou na rede. Se você não configurar pelo menos uma API Key ou a URL do Ollama nas configurações do plugin, as funções de chat e ações de contexto não poderão ser utilizadas.

1.  Clone este repositório em sua máquina.
2.  Abra o grupo de projetos `RadIA.groupproj` no Delphi.
3.  Clique com o botão direito em `RadIA.bpl` no Project Manager e selecione **Build**.
4.  Clique novamente com o botão direito em `RadIA.bpl` e selecione **Install**.
5.  A janela de confirmação de instalação da IDE será exibida, e o painel do **RadIA** aparecerá acoplado na lateral da IDE.
6.  Acesse o menu **Tools ➔ RadIA Chat Panel** para exibir o chat, e clique no botão **Settings** no topo do painel para configurar suas chaves de API e começar.

### 5.1 Configurando o Ollama (Local ou em Rede)

O **Ollama** permite executar LLMs de código aberto (Llama 3, Mistral, Phi-3, CodeLlama etc.) diretamente na sua máquina ou em um servidor na rede local — sem dependência de APIs pagas.

**Pré-requisito:** Instale o Ollama a partir de [https://ollama.com](https://ollama.com) e baixe pelo menos um modelo com `ollama pull llama3`.

**Para uso local (mesma máquina):**
1.  Inicie o servidor Ollama (o serviço é iniciado automaticamente após a instalação no Windows).
2.  A URL padrão já está configurada como `http://localhost:11434` — **nenhuma alteração é necessária**.
3.  Nas configurações do plugin (**Settings → Ollama Local/Network Settings**), confirme que a URL está como `http://localhost:11434`.
4.  Selecione **Ollama** no combo de provedores do chat.

**Para uso em rede (servidor remoto):**
1.  Certifique-se que o Ollama está rodando no servidor remoto com escuta em todos os endereços. Defina a variável de ambiente `OLLAMA_HOST=0.0.0.0` no servidor antes de iniciar o serviço.
2.  Nas configurações do plugin (**Settings → Ollama Local/Network Settings**), defina a URL para o endereço IP ou hostname do servidor. Exemplo: `http://192.168.1.100:11434`.
3.  Certifique-se de que a porta `11434` está acessível no firewall da rede.
4.  Selecione **Ollama** no combo de provedores do chat.

> **Nota:** O plugin descobre automaticamente os modelos disponíveis no servidor Ollama via `/api/tags`. Se a conexão falhar, exibirá modelos padrão conhecidos como fallback.

### 5.2 Histórico de Conversas Persistente

O RadIA salva automaticamente o histórico do chat em:
```
%APPDATA%\RadIA\history.json
```
O histórico é restaurado integralmente ao reabrir a IDE, preservando todo o contexto da conversa anterior. Para limpar o histórico, clique no botão **Clear** no topo do painel de chat.

### 6. Estrutura do Repositório
```
PluginDelphiIA/
│
├── docs/                               # Documentação e recursos visuais
│   ├── images/
│   │   ├── radia_ui_mockup.png         # Mockup do Chat na lateral da IDE
│   │   └── radia_diff_ui_mockup.png    # Mockup da tela de comparação Diff
│   ├── implementation_plan.md          # Plano detalhado de arquitetura
│   ├── radia_design_ui.md              # Especificação de layouts e fluxos de UI
│   └── task.md                         # Lista/Checklist de tarefas de desenvolvimento
│
├── RadIA.groupproj                     # Grupo de Projetos do Delphi
├── RadIA.dpk                           # Pacote Delphi de design-time
├── RadIA.dproj                         # Configurações do projeto de pacote
│
├── Source/
│   ├── Core/                           # Units centrais (Interfaces, tipos, configurações)
│   ├── Providers/                      # Clientes de API das IAs (Gemini, OpenAI, Claude)
│   ├── Integration/                    # Integração com a Open Tools API da IDE (Wizards, Hooks)
│   └── UI/                             # Formulários e Frames VCL
│       └── Web/                        # Template Web (HTML/CSS/JS) para WebView2
│
└── Tests/                              # Testes de Integração e Unitários (DUnitX)
```

### 7. Princípios de Desenvolvimento
Este projeto adota rigidamente:
*   Princípios de design **SOLID**.
*   Práticas de **Clean Code** com total isolamento em threads (thread-safety).
*   Princípios **DRY** (Don't Repeat Yourself) e **KISS** (Keep It Simple, Stupid).
*   Uso exclusivo do idioma **Inglês** para todo código fonte do projeto.

---

## 🇺🇸 English Documentation

### 1. Language Standard
*   **Documentation (README / Docs):** Bilingual (English and Portuguese in separate sections).
*   **Source Code:** 100% written in **English** (names, units, variables, classes, methods, and code comments) following clean code and Pascal standards.

### 2. Features
*   **Dockable Sidebar Chat:** A native-looking, dockable panel integrated into the Delphi IDE featuring a high-fidelity web-rendered chat window (Edge/WebView2) with full Markdown rendering and Delphi syntax highlighting.
*   **Multi-Provider AI Support:** Bring Your Own Key (BYOK) support for **Google Gemini**, **OpenAI ChatGPT**, **Anthropic Claude**, and local/network models via **Ollama** (e.g., Llama 3, Phi-3, Mistral, CodeLlama).
*   **Persistent Chat History:** Chat conversations are automatically saved locally in JSON format, restoring previous context whenever the IDE is closed and reopened.
*   **Context-Aware Editor Actions:** Right-click on any code selection to:
    *   *Explain Selected Code:* Analyze and explain the logic.
    *   *Optimize/Refactor:* Improve performance and apply clean code practices.
    *   *Generate Unit Tests:* Automatically output a DUnitX test structure.
    *   *Analyze for Bugs:* Scan selected block for memory leaks or logic errors.
*   **Interactive Smart Diff View:** View refactored code recommendations side-by-side (Original vs. Suggested) highlighting changes in red/green with a one-click **[Apply Changes]** button directly into the editor.
*   **Smart Build Debugger:** Context integration with the Delphi *Messages View*. Right-click on compilation errors to get instant AI fixes and solutions.
*   **Auto XML Documentation:** Automatically write Delphi-compliant XML help tags (`/// <summary>`) above methods.
*   **Slash Commands:** Quick actions directly in the chat input (e.g., `/doc`, `/explain`, `/refactor`, `/bugs`).
*   **Secure API Key Registry Storage:** Keys are saved encrypted locally using the Windows Data Protection API (DPAPI) inside the Windows Registry.

### 2.1 Complete Feature Checklist

| Feature | Category | Description | Status |
| :--- | :--- | :--- | :--- |
| **Dockable Sidebar Chat** | Chat UX | IDE-integrated panel running WebView2 with Markdown and Pascal highlighting. | ✅ Completed |
| **Streaming Responses** | Chat UX | Real-time incremental token rendering (SSE) for OpenAI, Gemini, Claude, and Ollama. | ✅ Completed |
| **Persistent Chat History** | Chat UX | Automatic local JSON storage and reload of conversation history. | ✅ Completed |
| **Prompt Navigation (↑/↓)** | Chat UX | Terminal-like keyboard arrow history lookup in prompt input. | ✅ Completed |
| **Export Conversation** | Chat UX | Save current active chats to Markdown (.md) or standalone rich HTML formats. | ✅ Completed |
| **Prompt Templates** | Chat UX | Custom quick-access prompt library with `{code}` token and `/template` command. | ✅ Completed |
| **Google Gemini** | Provider | Native BYOK integration for Gemini 1.5 Pro and Gemini 1.5 Flash models. | ✅ Completed |
| **OpenAI ChatGPT** | Provider | Native BYOK integration for GPT-4o, GPT-4o-mini, and others. | ✅ Completed |
| **Anthropic Claude** | Provider | Native BYOK integration for Claude 3 Haiku and Claude 3.5 Sonnet. | ✅ Completed |
| **Ollama Local/Network** | Provider | Connects to local open-source models with no paid API keys and dynamic tags discovery. | ✅ Completed |
| **Custom Base URL** | Provider | Route OpenAI API payload to other endpoints like Groq, DeepSeek, or LM Studio. | ✅ Completed |
| **Project Context** | Intelligence | Automatic project context loading (system prompts/custom files) via `.radia`. | ✅ Completed |
| **Tokens & Cost Tracking** | Control | Status bar counter for session token usage and USD estimated cost. | ✅ Completed |
| **Editor Context Actions** | Integration | Right-click code selection to Explain, Optimize/Refactor, Test, or Scan for Bugs. | ✅ Completed |
| **Interactive Smart Diff** | Integration | Side-by-side original/suggested diff view with instant editor replacement. | ✅ Completed |
| **Smart Build Debugger** | Integration | Message tab integration to resolve compiler issues with one-click fixes. | ✅ Completed |
| **Auto XML Documentation** | Generation | Write Delphi-compliant XML help comments above methods automatically. | ✅ Completed |
| **Secure Credentials** | Security | API Keys saved securely inside the Windows Registry using DPAPI. | ✅ Completed |

### 3. How It Works & Architecture
RadIA is built entirely in Object Pascal (Delphi) using the **Open Tools API (OTA)** to interface with the IDE's editor services, message services, and theme services.
The user interface uses a hybrid architecture:
1.  **VCL Layout:** Handles the window docking, settings dialog, toolbars, registry storage, and integration actions.
2.  **Edge WebView2 Engine:** Displays the message history using local HTML5, CSS (incorporating glassmorphism/modern dark UI that adapts to the IDE theme), and JavaScript libraries (Prism.js and Marked.js) to render rich markdown and copyable code blocks without freezing the main IDE thread.

### 4. Prerequisites
*   **IDE:** Embarcadero Delphi 10.4 Sydney, 11 Alexandria, or 12 Athens (or newer).
*   **OS:** Windows 10 / 11 (64-bit).
*   **Web Engine:** *Microsoft Edge WebView2 Runtime* installed on the Windows system (pre-installed on modern Windows versions). **Important:** The `WebView2Loader.dll` matching the IDE's architecture (32-bit for Delphi 10.4, 64-bit for Delphi 11 and 12) must be present in Delphi's `bin` installation directory (e.g., `C:\Program Files (x86)\Embarcadero\Studio\<version>\bin`) or in the Windows system PATH.
*   **API Keys:** Active developer keys obtained from their respective consoles: [Google AI Studio](https://aistudio.google.com/) (Gemini), [OpenAI Platform](https://platform.openai.com/) (ChatGPT), and [Anthropic Console](https://console.anthropic.com/) (Claude). For local/network use with **Ollama**, ensure the Ollama server instance is active at the configured address (e.g., `http://localhost:11434`).

### 5. Installation

> [!IMPORTANT]
> **Bring Your Own Key (BYOK) & Local AI Model:** RadIA requires active and valid API keys to function with cloud models (Gemini, OpenAI, Claude) or a configured **Ollama** instance running on your machine or local network. If you do not configure at least one API Key or the Ollama URL in the settings, chat and context menu actions will return errors.

1.  Clone this repository to your computer.
2.  Open the project group `RadIA.groupproj` in Delphi.
3.  Right-click on `RadIA.bpl` in the Project Manager and click **Build**.
4.  Right-click on `RadIA.bpl` again and click **Install**.
5.  A confirmation dialog will appear, and the **RadIA** panel will dock on the right side of your IDE.
6.  Go to **Tools ➔ RadIA Chat Panel** to display the chat, and click the **Settings** button at the top of the panel to configure your API keys.

### 5.1 Configuring Ollama (Local or Network)

**Ollama** lets you run open-source LLMs (Llama 3, Mistral, Phi-3, CodeLlama, etc.) directly on your machine or on a server in your local network — with no paid API dependency.

**Prerequisite:** Install Ollama from [https://ollama.com](https://ollama.com) and pull at least one model with `ollama pull llama3`.

**For local use (same machine):**
1.  Start the Ollama server (on Windows, the service starts automatically after installation).
2.  The default URL `http://localhost:11434` is already pre-configured — **no changes required**.
3.  In the plugin settings (**Settings → Ollama Local/Network Settings**), confirm the URL reads `http://localhost:11434`.
4.  Select **Ollama** in the provider dropdown in the chat panel.

**For network use (remote server):**
1.  Make sure Ollama is running on the remote server and listening on all interfaces. Set the environment variable `OLLAMA_HOST=0.0.0.0` on the server before starting the service.
2.  In the plugin settings (**Settings → Ollama Local/Network Settings**), set the URL to the server's IP address or hostname. Example: `http://192.168.1.100:11434`.
3.  Make sure port `11434` is reachable through the network's firewall.
4.  Select **Ollama** in the provider dropdown in the chat panel.

> **Note:** The plugin automatically discovers available models from the Ollama server via `/api/tags`. If the connection fails, it falls back to a built-in list of well-known model names.

### 5.2 Persistent Chat History

RadIA automatically saves the full chat history to:
```
%APPDATA%\RadIA\history.json
```
The conversation is fully restored when you reopen the IDE, preserving all previous context. To clear the history, click the **Clear** button at the top of the chat panel.

### 6. Repository Structure
```
PluginDelphiIA/
│
├── docs/                               # Documentation & Visuals
│   ├── images/
│   │   ├── radia_ui_mockup.png         # IDE Chat Integration Mockup
│   │   └── radia_diff_ui_mockup.png    # Side-by-Side Diff View Mockup
│   ├── implementation_plan.md          # Architectural Planning
│   ├── radia_design_ui.md              # UI Elements & Flow Design
│   └── task.md                         # Checklist of Development Tasks
│
├── RadIA.groupproj                     # Delphi Project Group
├── RadIA.dpk                           # Design-time Package source
├── RadIA.dproj                         # Package project settings
│
├── Source/
│   ├── Core/                           # Interfaces, Core types, Configs
│   ├── Providers/                      # Google, OpenAI, Claude HTTP API clients
│   ├── Integration/                    # ToolsAPI Wizards, Hooks, Register classes
│   └── UI/                             # VCL Frames, Forms, and WebView files
│       └── Web/                        # HTML, CSS, JS template files for WebView2
│
└── Tests/                              # Unit Tests (DUnitX)
```

### 7. Architecture Principles
This project strictly enforces:
*   **SOLID** design principles.
*   **Clean Code** patterns with complete thread-safety.
*   **DRY (Don't Repeat Yourself)** & **KISS (Keep It Simple, Stupid)**.
*   Strictly using **English** for all programming artifacts.
