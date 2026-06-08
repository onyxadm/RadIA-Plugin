<div align="right">

[🇧🇷 Português](README.md) | [🇺🇸 English](README.en.md) | [🗺️ Roadmap](ROADMAP.en.md)

</div>

<p align="center">
  <img src="docs/images/radia_owl_mascot.png" alt="RadIA Mascot" width="160" />
</p>

# RadIA - AI Assistant for Delphi IDE

**RadIA** is an advanced AI assistant plugin designed specifically for the Embarcadero Delphi IDE (using the Open Tools API). It docks directly into the IDE sidebar, providing an interactive chat interface and deep contextual integration with the code editor to accelerate development, refactoring, and debugging.

<p align="center">
  <img src="docs/images/radia_ui_mockup.png" alt="RadIA Chat Panel Mockup" width="100%" />
</p>

---

### 1. Development Guidelines and Language Standard

This project adopts clear language rules and design standards for both human developers and AI assistants (LLMs/Co-pilots) working on the codebase:

*   **AI & Human Interactions:**
    *   All chat interactions, commit messages, pull request descriptions, task updates, and design discussions must be conducted in **Brazilian Portuguese (pt-BR)**.
*   **Source Code & Architecture:**
    *   The source code is **100% written in English (en-US)**.
    *   All identifiers (unit names, variables, classes, methods, records, enums), parameters, data structures (JSON/XML), and inline comments must be written exclusively in English, following object-oriented Pascal naming conventions.
    *   Strict adherence to **Clean Code**, **SOLID**, **DRY**, and **KISS** with complete thread-safety.
*   **Official Documentation:**
    *   Available primarily in Portuguese ([README.md](README.md)) with an English translation ([README.en.md](README.en.md)).

### 2. Features
*   **Dockable Sidebar Chat:** A native-looking, dockable panel integrated into the Delphi IDE featuring a high-fidelity web-rendered chat window (Edge/WebView2) with full Markdown rendering and Delphi syntax highlighting.
*   **Multi-Provider AI Support & Hybrid Connection:** Flexible hybrid connection model. Allows using your own API keys (BYOK) for **Google Gemini**, **OpenAI ChatGPT**, **Anthropic Claude**, **DeepSeek**, **Groq**, **OpenRouter**, **LM Studio**, and local **Ollama**, OR connecting directly to consumer personal/corporate accounts (**ChatGPT Plus/Pro** and **Gemini Advanced**) via official login inside WebView2, bypassing network blocks using smart DOM/CSS injection and JS-Delphi bridge.
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
*   **DTO and Model Converter:** Instantly generate Object Pascal classes (DTOs) or records from JSON payloads or SQL DDL scripts, with smart support for DEXT ORM, TMS Aurelius, REST.Json, and Vanilla Delphi.
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

RadIA can be installed in two ways: **Automated via PowerShell** (recommended, supporting autodetect of multiple installed Delphi environments and interactive selection menu) or **manually through the IDE**. For detailed compilation, registry registration, and API key acquisition instructions for all providers or local Ollama usage, please refer to our:

👉 [**Complete Installation and Configuration Guide (docs/install_config.en.md)**](docs/install_config.en.md)

### 5.1 Adding a New AI Provider (Plugin Architecture)

RadIA employs a metadata-driven provider registry system (`TProviderRegistry`). This allows developers to add new AI backends in a fully dynamic and decoupled manner. For a step-by-step tutorial on how to implement your provider class and perform auto-registration, please check our:

👉 [**Guide for Adding New Providers (docs/new_provider_guide.en.md)**](docs/new_provider_guide.en.md)

### 5.2 Using GitHub Copilot via Local Proxy (Phase 1)

RadIA supports integrating GitHub Copilot (and other enterprise assistants) through local proxies compatible with the OpenAI API. To learn how to configure the local proxy, acquire your token securely, and register your dynamic JSON provider, please refer to our:

👉 [**GitHub Copilot Configuration Guide (docs/copilot_proxy_guide.en.md)**](docs/copilot_proxy_guide.en.md)

---

### 6. Repository Structure
```
PluginDelphiIA/
│
├── docs/                               # Documentation & Visuals
│   ├── images/
│   │   ├── radia_ui_mockup.png         # IDE Chat Integration Mockup
│   │   ├── radia_options_mockup.png    # IDE Settings Panel Mockup (Tools -> Options)
│   │   └── radia_diff_ui_mockup.png    # Side-by-Side Diff View Mockup
│   ├── install_config.en.md            # Detailed installation and API keys guide
│   ├── implementation_plan.md          # Architectural Planning
│   ├── radia_design_ui.md              # UI Elements & Flow Design
│   ├── new_provider_guide.en.md        # Guide for adding new AI Providers
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

### 7. Terms of Use and Corporate Compliance

For guidelines on corporate compliance (GDPR/LGPD), data privacy, API key encryption using Windows DPAPI, and legal disclaimers regarding AI-generated code, please refer to our:

👉 [**Terms of Use, Compliance, and Privacy Guide (docs/compliance.en.md)**](docs/compliance.en.md)
