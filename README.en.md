<div align="right">

[🇧🇷 Português](README.md) | [🇺🇸 English](README.en.md) | [🗺️ Roadmap](ROADMAP.en.md)

</div>

# RadIA - AI Assistant for Delphi IDE

**RadIA** is an advanced AI assistant plugin designed specifically for the Embarcadero Delphi IDE (using the Open Tools API). It docks directly into the IDE sidebar, providing an interactive chat interface and deep contextual integration with the code editor to accelerate development, refactoring, and debugging.

<p align="center">
  <img src="docs/images/radia_ui_mockup.png" alt="RadIA Chat Panel Mockup" width="100%" />
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

To check the development status, keyboard shortcuts, categories, and all integrated providers in detail, please refer to our:

👉 [**Complete Feature Checklist (docs/features.en.md)**](docs/features.en.md)

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

### 5.1 Adding a New AI Provider (Plugin Architecture)

RadIA employs a metadata-driven provider registry system (`TProviderRegistry`). This allows developers to add new AI backends in a fully dynamic and decoupled manner. For a step-by-step tutorial on how to implement your provider class and perform auto-registration, please check our:

👉 [**Guide for Adding New Providers (docs/new_provider_guide.en.md)**](docs/new_provider_guide.en.md)

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

### 8. Terms of Use and Corporate Compliance

For guidelines on corporate compliance (GDPR/LGPD), data privacy, API key encryption using Windows DPAPI, and legal disclaimers regarding AI-generated code, please refer to our:

👉 [**Terms of Use, Compliance, and Privacy Guide (docs/compliance.en.md)**](docs/compliance.en.md)
