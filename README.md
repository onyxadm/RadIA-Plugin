# RadIA - Assistente de IA para Delphi IDE

**RadIA** é um plugin assistente de IA avançado projetado especificamente para a IDE do Embarcadero Delphi (usando a Open Tools API). Ele se acopla diretamente à barra lateral da IDE, fornecendo uma interface de chat interativa e integração contextual profunda com o editor de código para acelerar o desenvolvimento, refatoração e depuração.

---

## 🇧🇷 Documentação em Português

### 1. Padrão de Linguagem
*   **Documentação (README / Docs):** Bilíngue (Inglês e Português em seções separadas).
*   **Código Fonte:** 100% escrito em **Inglês** (nomes, units, variáveis, classes, métodos e comentários de código) seguindo o clean code e os padrões Pascal.

### 2. Funcionalidades
*   **Chat Lateral Acoplável (Dockable):** Painel integrado à IDE com visual nativo do Delphi, trazendo uma janela de chat em HTML5/JS moderno (WebView2) com suporte a Markdown e realce de sintaxe Pascal.
*   **Suporte a Múltiplas IAs:** Modelo de uso de chaves próprias (BYOK) com suporte nativo ao **Google Gemini**, **OpenAI ChatGPT** e **Anthropic Claude**.
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

### 3. Como Funciona e Arquitetura
O RadIA é construído inteiramente em Object Pascal (Delphi) usando a **Open Tools API (OTA)** para interagir com o editor de código, gerenciamento de mensagens e detecção de temas da IDE.
A interface utiliza uma arquitetura híbrida:
1.  **VCL Nativa:** Gerencia o acoplamento da janela, a tela de configurações, ações de menus, gravação segura no registro e chamadas assíncronas.
2.  **Motor WebView2 (Edge):** Exibe as mensagens e respostas da IA utilizando HTML5, CSS e JS locais (Marked.js para Markdown e Prism.js para realce de sintaxe). A interface se adapta automaticamente ao tema da IDE (Light/Dark) e roda de forma fluida sem congelar a IDE.

### 4. Requisitos do Sistema
*   **IDE:** Embarcadero Delphi 10.4 Sydney, 11 Alexandria ou 12 Athens (ou superior).
*   **OS:** Windows 10 / 11 (64-bit).
*   **Web Engine:** *Microsoft Edge WebView2 Runtime* instalado no sistema Windows (pré-instalado em versões modernas do Windows).
*   **API Keys:** Chaves de desenvolvedor ativas para Google Gemini, OpenAI ou Anthropic.

### 5. Instalação
1.  Clone este repositório em sua máquina.
2.  Abra o grupo de projetos `RadIA.groupproj` no Delphi.
3.  Clique com o botão direito em `RadIA.bpl` no Project Manager e selecione **Build**.
4.  Clique novamente com o botão direito em `RadIA.bpl` e selecione **Install**.
5.  A janela de confirmação de instalação da IDE será exibida, e o painel do **RadIA** aparecerá acoplado na lateral da IDE.
6.  Acesse o menu **Tools ➔ RadIA Settings** ou clique no ícone de engrenagem no chat para inserir suas API keys e começar.

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
*   **Multi-Provider AI Support:** Bring Your Own Key (BYOK) support for **Google Gemini**, **OpenAI ChatGPT**, and **Anthropic Claude**.
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

### 3. How It Works & Architecture
RadIA is built entirely in Object Pascal (Delphi) using the **Open Tools API (OTA)** to interface with the IDE's editor services, message services, and theme services.
The user interface uses a hybrid architecture:
1.  **VCL Layout:** Handles the window docking, settings dialog, toolbars, registry storage, and integration actions.
2.  **Edge WebView2 Engine:** Displays the message history using local HTML5, CSS (incorporating glassmorphism/modern dark UI that adapts to the IDE theme), and JavaScript libraries (Prism.js and Marked.js) to render rich markdown and copyable code blocks without freezing the main IDE thread.

### 4. Prerequisites
*   **IDE:** Embarcadero Delphi 10.4 Sydney, 11 Alexandria, or 12 Athens (or newer).
*   **OS:** Windows 10 / 11 (64-bit).
*   **Web Engine:** *Microsoft Edge WebView2 Runtime* installed on the Windows system (pre-installed on modern Windows versions).
*   **API Keys:** Active developer keys for Google Gemini, OpenAI, or Anthropic.

### 5. Installation
1.  Clone this repository to your computer.
2.  Open the project group `RadIA.groupproj` in Delphi.
3.  Right-click on `RadIA.bpl` in the Project Manager and click **Build**.
4.  Right-click on `RadIA.bpl` again and click **Install**.
5.  A confirmation dialog will appear, and the **RadIA** panel will dock on the right side of your IDE.
6.  Go to **Tools ➔ RadIA Settings** or click the gear icon in the chat to insert your API keys.

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
