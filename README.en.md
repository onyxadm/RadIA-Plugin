<div align="right">

[🇧🇷 Português](README.md) | [🇺🇸 English](README.en.md) | [🗺️ Roadmap](ROADMAP.en.md)

</div>

# RadIA - AI Assistant for Delphi IDE

**RadIA** is an advanced AI assistant plugin designed specifically for the Embarcadero Delphi IDE (using the Open Tools API). It docks directly into the IDE sidebar, providing an interactive chat interface and deep contextual integration with the code editor to accelerate development, refactoring, and debugging.

<p align="center">
  <img src="docs/images/radia_ui_mockup.png" alt="RadIA Chat Panel Mockup" width="45%" />
  &nbsp;&nbsp;
  <img src="docs/images/radia_diff_ui_mockup.png" alt="RadIA Diff View Mockup" width="45%" />
</p>

---

### 1. Language Standard
*   **Documentation (README / Docs):** Available in Portuguese (default) and English (alternative).
*   **Source Code:** 100% written in **English** (names, units, variables, classes, methods, and code comments) following clean code and Pascal standards.

### 2. Features
*   **Dockable Sidebar Chat:** A native-looking, dockable panel integrated into the Delphi IDE featuring a high-fidelity web-rendered chat window (Edge/WebView2) with full Markdown rendering and Delphi syntax highlighting.
*   **Multi-Provider AI Support:** Bring Your Own Key (BYOK) support for **Google Gemini**, **OpenAI ChatGPT**, **Anthropic Claude**, **DeepSeek**, **Groq**, and local/network models via **Ollama** (e.g., Llama 3, Phi-3, Mistral, CodeLlama).
*   **Persistent Chat History:** Chat conversations are automatically saved locally in JSON format, restoring previous context whenever the IDE is closed and reopened.
*   **Shortcuts and Prompt History:** Integrated productivity shortcuts: use `Ctrl + Enter` to send prompts, `Enter` for line breaks, and keyboard arrows `↑` (up) and `↓` (down) inside the text input area to quickly cycle through previously typed and sent prompts.
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
*   **Request Cancellation:** A dynamic circular stop button integrated inside the prompt input to abort active requests instantly and safely.

### 2.1 Complete Feature Checklist

| Feature | Category | Description | Status |
| :--- | :--- | :--- | :--- |
| **Dockable Sidebar Chat** | Chat UX | IDE-integrated panel running WebView2 with Markdown and Pascal highlighting. | ✅ Completed |
| **Keyboard Shortcuts** | Chat UX | Shortcut `Ctrl + Enter` to send prompts and simple `Enter` for line breaks. | ✅ Completed |
| **Layout Persistence** | Chat UX | Automatic saving and restoration of floating window size/position and visibility at startup. | ✅ Completed |
| **Streaming Responses** | Chat UX | Real-time incremental token rendering (SSE) for OpenAI, Gemini, Claude, and Ollama. | ✅ Completed |
| **Multiple Chat Sessions** | Chat UX | Create, rename, delete, and isolate conversations in a collapsible sidebar. | ✅ Completed |
| **Persistent Chat History** | Chat UX | Automatic local JSON storage and reload of conversation history. | ✅ Completed |
| **Prompt Navigation (↑/↓)** | Chat UX | Terminal-like keyboard arrow history lookup in prompt input. | ✅ Completed |
| **Request Cancellation** | Chat UX | Abort active AI HTTP requests asynchronously using a dynamic stop button interface. | ✅ Completed |
| **Export Conversation** | Chat UX | Save current active chats to Markdown (.md) or standalone rich HTML formats. | ✅ Completed |
| **Prompt Templates** | Chat UX | Custom quick-access prompt library with `{code}` token and `/template` command. | ✅ Completed |
| **Google Gemini** | Provider | Native BYOK integration for Gemini 1.5 Pro and Gemini 1.5 Flash models. | ✅ Completed |
| **OpenAI ChatGPT** | Provider | Native BYOK integration for GPT-4o, GPT-4o-mini, and others. | ✅ Completed |
| **Anthropic Claude** | Provider | Native BYOK integration for Claude 3 Haiku and Claude 3.5 Sonnet. | ✅ Completed |
| **DeepSeek** | Provider | Native BYOK integration for DeepSeek Chat and Reasoning models. | ✅ Completed |
| **Groq** | Provider | Native BYOK integration for Llama, Mixtral, and Gemma models via Groq's high-speed cloud. | ✅ Completed |
| **Ollama Local/Network** | Provider | Connects to local open-source models with no paid API keys and dynamic tags discovery. | ✅ Completed |
| **Custom Base URL** | Provider | Route OpenAI API payload to other endpoints like Groq, DeepSeek, or LM Studio. | ✅ Completed |
| **Project Context** | Intelligence | Automatic project context loading (system prompts/custom files) via `.radia`. | ✅ Completed |
| **Tokens & Cost Tracking** | Control | Status bar counter for session token usage and USD estimated cost. | ✅ Completed |
| **Local Quota Control** | Control | Define a monthly token limit with request blocking and a manual reset button. | ✅ Completed |
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
*   **IDE:** Embarcadero Delphi 10.4 Sydney, 11 Alexandria, 12 Athens, or 13 Florence (or newer).
*   **OS:** Windows 10 / 11 (64-bit).
*   **Web Engine:** *Microsoft Edge WebView2 Runtime* installed on the Windows system.
*   **API Keys:** Active developer keys or a local Ollama instance.

### 5. Installation and Configuration

RadIA can be installed in two ways: **Automated via PowerShell** (recommended) or **manually through the IDE**. For detailed compilation, registry registration, and API key acquisition instructions for all providers or local Ollama usage, please refer to our:

👉 [**Complete Installation and Configuration Guide (docs/install_config.en.md)**](docs/install_config.en.md)

---

### 6. Repository Structure
```
PluginDelphiIA/
│
├── docs/                               # Documentation & Visuals
│   ├── images/
│   │   ├── radia_ui_mockup.png         # IDE Chat Integration Mockup
│   │   └── radia_diff_ui_mockup.png    # Side-by-Side Diff View Mockup
│   ├── install_config.en.md            # Detailed installation and API keys guide
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

*   **Mandatory Code Review**: RadIA is a productivity assistant that generates code suggestions leveraging third-party AI models. Any generated suggestions (including refactorings, bug fixes, and unit tests) may contain inaccuracies, logic errors, or vulnerabilities. The user is **solely responsible** for reviewing, validating, testing, and approving any code suggested by the AI before integrating it into production environments.
*   **Limitation of Liabilities**: The creators and contributors of RadIA shall not be held liable for any damages, data loss, loss of profits, security breaches, or service interruptions resulting from the use of AI-suggested code or the execution of this plugin within the IDE.
*   **API Key Security (BYOK)**: RadIA stores API Keys locally and encrypted using the Windows Data Protection API (DPAPI) inside the Windows Registry. Keys are sent directly and securely to the official servers of each respective provider (Google, OpenAI, Anthropic, DeepSeek, Groq, or Ollama). The project authors do not collect, remotely store, or share your API keys. Billing, quotas, and budget control of the keys are the user's sole responsibility.

### 8.2 Data Privacy & Corporate Compliance
When using cloud providers (Google Gemini, OpenAI, Anthropic, DeepSeek, or Groq), snippets of your selected source code and project context will be sent to their respective remote servers for processing.

*   **Confidential Corporate Use**: If you work on projects with restricted proprietary code or under strict corporate compliance regulations (such as GDPR or LGPD), **we strongly recommend using Ollama** configured locally. By running local models offline, RadIA processes your prompts entirely within your machine or internal network, ensuring that no proprietary source code ever leaves your company's secure environment.
