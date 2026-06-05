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
*   **Web Engine:** *Microsoft Edge WebView2 Runtime* installed on the Windows system (pre-installed on modern Windows versions). **Important:** The `WebView2Loader.dll` matching the IDE's architecture (32-bit for Delphi 10.4, 64-bit for Delphi 11 and 12) must be present in Delphi's `bin` installation directory (e.g., `C:\Program Files (x86)\Embarcadero\Studio\<version>\bin`) or in the Windows system PATH.
*   **API Keys:** Active developer keys obtained from their respective consoles: [Google AI Studio](https://aistudio.google.com/) (Gemini), [OpenAI Platform](https://platform.openai.com/) (ChatGPT), [Anthropic Console](https://console.anthropic.com/) (Claude), [DeepSeek Console](https://platform.deepseek.com/), and [Groq Console](https://console.groq.com/). For local/network use with **Ollama**, ensure the Ollama server instance is active at the configured address (e.g., `http://localhost:11434`).

### 5. Installation

> [!IMPORTANT]
> **Bring Your Own Key (BYOK) & Local AI Model:** RadIA requires active and valid API keys to function with cloud models (Gemini, OpenAI, Claude) or a configured **Ollama** instance running on your machine or local network. If you do not configure at least one API Key or the Ollama URL in the settings, chat and context menu actions will return errors.

RadIA can be installed in two ways: **Automated (Recommended)** via PowerShell, or **Manual** through the Delphi IDE.

#### Option A: Automated Installation (PowerShell) - Recommended

This option automatically compiles the plugin, runs unit tests, copies the binaries to the official public Delphi directories, and registers the plugin in the Windows Registry.

1. Open the Windows PowerShell console.
2. Make sure the Delphi installation `bin` folder containing `dcc32` is present in your system PATH.
3. Run the command in the project root directory according to your IDE's architecture:
   * **For the default 32-bit IDE (Recommended)**:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\build.ps1 -Install
     ```
   * **For the 64-bit IDE (Delphi 13 Florence)**:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\build.ps1 -Install -IDE64
     ```
4. Done! The plugin will be installed and active on the next startup of the IDE.

#### Option B: Manual Installation via IDE

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

### 5.3 Automated Compilation and Installation (PowerShell)

To compile the main package, run the unit tests in an automated way, perform direct installation, or perform uninstallation from the Delphi IDE, you can use the integrated build script in the project root. It supports the following parameters/switches:

*   `-Install`: Compiles the plugin, runs the unit tests, copies the BPL/DCP to the Delphi public documents directory, and registers the package in the Windows Registry (`Known Packages`) for the detected IDE version.
*   `-Uninstall`: Removes the BPLs, DCPs, and the Web resources folder previously copied to the Delphi public folders, and removes the package from the Windows Registry (`Known Packages`), clean uninstalling the plugin.
*   `-Release`: Compiles the plugin and unit tests in Release (Production) configuration, disabling debug symbols and debug information (generating a significantly smaller and faster BPL) and enabling Delphi compiler optimizations.
*   `-IDE64`: Compiles and installs the plugin specifically for the 64-bit Delphi IDE (available from Delphi 13 Florence), generating the Win64 binary and registering it in the corresponding 64-bit `Known Packages` Registry key (`BDS\<version>_x64`). If omitted, compiles for the default 32-bit IDE (Win32).

Example commands:

1. Open the Windows PowerShell console.
2. Make sure the Delphi installation `bin` folder containing `dcc32` is present in your system PATH.
3. Run the following command in the project root directory to only build and test in Debug mode:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\build.ps1
   ```
4. To compile, test, and install in the IDE in **Release** mode (recommended for production):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\build.ps1 -Install -Release
   ```
5. To cleanly uninstall the plugin from the Delphi IDE:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\build.ps1 -Uninstall
   ```
6. The script will automatically detect the active compiler version, create the version-isolated output directories (e.g., `Output\23.0\bpl`, `Output\23.0\dcp`, `Output\23.0\dcu`, etc.), clean up temporary DCU files from source folders, compile the main package, compile the unit tests, and automatically run the validation test suite.
7. If the `-Install` switch is provided, the script will also copy the output files (`RadIA.bpl` and `RadIA.dcp`) to the official Delphi folders (`C:\Users\Public\Documents\Embarcadero\Studio\<version>\Bpl` and `Dcp`) and register the plugin under the `Known Packages` Registry key for the detected Delphi version.

### 5.4 API Key Acquisition & Configuration Guide

To configure and use RadIA with its supported AI providers, you need to generate and enter the API keys in the settings dialog (**Settings** at the top of the chat panel). Below are the instructions and direct links for each provider:

1. **Google Gemini (Recommended)**
   * **How to obtain:** Access the [Google AI Studio Console](https://aistudio.google.com/).
   * **Step-by-step:** Log in with a Google account, click the **Create API Key** button on the left sidebar menu, select your project, and copy the generated key.
   * **Suggested Models:** `gemini-1.5-flash` or `gemini-1.5-pro` (or newer).

2. **OpenAI ChatGPT**
   * **How to obtain:** Access the [OpenAI Platform](https://platform.openai.com/).
   * **Step-by-step:** Log in, navigate to the **API Keys** section in the side menu, click **Create new secret key**, give it an optional name, and copy the generated token (starts with `sk-`). *Note: Requires active pre-paid credits on the OpenAI platform.*
   * **Suggested Models:** `gpt-4o-mini`, `gpt-4o`.

3. **Anthropic Claude**
   * **How to obtain:** Access the [Anthropic Console](https://console.anthropic.com/).
   * **Step-by-step:** Log in, go to the **API Keys** tab, click **Create Key**, and copy the token (starts with `sk-ant-`). *Note: Requires a pre-paid balance on the Anthropic account.*
   * **Suggested Models:** `claude-3-5-sonnet-latest`, `claude-3-haiku`.

4. **DeepSeek**
   * **How to obtain:** Access the [DeepSeek Platform Console](https://platform.deepseek.com/).
   * **Step-by-step:** Create an account or log in, go to the **API Keys** section, click **Create API Key**, and copy it.
   * **Suggested Models:** `deepseek-chat` (for general coding/chat) or `deepseek-reasoning` (for deep logical thinking).

5. **Groq Cloud (High-Speed Inference)**
   * **How to obtain:** Access the [Groq Console](https://console.groq.com/).
   * **Step-by-step:** Sign up, navigate to **API Keys**, click **Create API Key**, and copy it (starts with `gsk_`).
   * **Suggested Models:** `llama-3.3-70b-versatile`, `mixtral-8x7b-32768`.

6. **Ollama (Free Local Models)**
   * **How to obtain:** No API key required! Simply download and install [Ollama](https://ollama.com).
   * **Configuration:** The plugin connects automatically to the default loopback address `http://localhost:11434`. Pull the model you want to run by executing in CMD or PowerShell: `ollama pull llama3` (or any model of your choice).
   * **Network Use:** If Ollama runs on a remote machine in your network, configure the `OLLAMA_HOST=0.0.0.0` environment variable on the server to listen on all interfaces, and enter the remote URL (e.g., `http://192.168.1.100:11434`) in the RadIA settings panel.

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

### 8. Trademark Disclaimer
All trademarks, logos, service marks, and trade names mentioned in this project (including, but not limited to: *Embarcadero Delphi*, *Microsoft Windows*, *Microsoft Edge*, *WebView2*, *Google Gemini*, *OpenAI ChatGPT*, *Anthropic Claude*, *DeepSeek*, *Groq*, and *Ollama*) are the property of their respective owners.

The use of these names and trademarks is solely for compatibility, configuration, and technology integration description purposes. **RadIA** is an independent, open-source project and has no official affiliation, sponsorship, endorsement, or association with the owners of these trademarks.

### 8.1 AI Assistant & Safety Disclaimer
*   **Mandatory Code Review**: RadIA is a productivity assistant that generates code suggestions leveraging third-party AI models. Any generated suggestions (including refactorings, bug fixes, and unit tests) may contain inaccuracies, logic errors, or vulnerabilities. The user is **solely responsible** for reviewing, validating, testing, and approving any code suggested by the AI before integrating it into production environments.
*   **Limitation of Liabilities**: The creators and contributors of RadIA shall not be held liable for any damages, data loss, loss of profits, security breaches, or service interruptions resulting from the use of AI-suggested code or the execution of this plugin within the IDE.
*   **API Key Security (BYOK)**: RadIA stores API Keys locally and encrypted using the Windows Data Protection API (DPAPI) inside the Windows Registry. Keys are sent directly and securely to the official servers of each respective provider (Google, OpenAI, Anthropic, DeepSeek, Groq, or Ollama). The project authors do not collect, remotely store, or share your API keys. Billing, quotas, and budget control of the keys are the user's sole responsibility.

### 8.2 Data Privacy & Corporate Compliance
When using cloud providers (Google Gemini, OpenAI, Anthropic, DeepSeek, or Groq), snippets of your selected source code and project context will be sent to their respective remote servers for processing.

*   **Confidential Corporate Use**: If you work on projects with restricted proprietary code or under strict corporate compliance regulations (such as GDPR or LGPD), **we strongly recommend using Ollama** configured locally. By running local models offline, RadIA processes your prompts entirely within your machine or internal network, ensuring that no proprietary source code ever leaves your company's secure environment.
