# RadIA - Evolution Backlog

This document registers the development status, future planning, and technical implementation history of **RadIA** plugin tasks.

---

## 📊 Kanban Dashboard

The board below summarizes the current status of mapped short and medium-term features in the project:

| Feature / Task | Status | Difficulty | Priority | Target Version |
| :--- | :---: | :---: | :---: | :---: |
| **Smart SQL Optimizer in Editor** | 🔲 Planned | 🟢 Low | ⭐⭐⭐⭐ High | v0.1.0 |
| **Delphi Compiler & OS Warning Scanner** | 🔲 Planned | 🟢 Low | ⭐⭐⭐⭐ High | v0.1.0 |
| **Automatic Code Review on Save** | 🔲 Planned | 🟡 Medium | ⭐⭐⭐⭐ High | v0.1.0 |
| **Applied Refactoring History** | 🔲 Planned | 🟢 Low | ⭐⭐⭐ Medium | v0.1.0 |
| **Uses Clause Optimizer (Clean Uses)** | 🔲 Planned | 🟡 Medium | ⭐⭐⭐⭐ High | v0.2.0 |
| **Mock Generator for Unit Tests** | 🔲 Planned | 🟡 Medium | ⭐⭐⭐⭐ High | v0.2.0 |
| **Smart Multi-Unit Trace Resolver** | 🔲 Planned | 🟡 Medium | ⭐⭐⭐⭐⭐ Critical | v0.2.0 |
| **MadExcept / EurekaLog Context Extractor** | 🔲 Planned | 🟡 Medium | ⭐⭐⭐⭐⭐ Critical | v0.2.0 |
| **OpenAPI/Swagger Documentation Generator** | 🔲 Planned | 🟡 Medium | ⭐⭐⭐⭐ High | v0.2.0 |
| **Bidirectional Semantic Analysis (DFM x PAS)** | 🔲 Planned | 🟡 Medium | ⭐⭐⭐⭐ High | v0.2.0 |
| **Version Migration Assistant (Smart Migrate)** | 🔲 Planned | 🟡 Medium | ⭐⭐⭐⭐ High | v0.2.0 |
| **Cache Management Panel** | 🔲 Planned | 🟡 Medium | ⭐⭐⭐ Medium | v0.2.0 |
| **BDE/ADO/dbExpress ➔ DEXT with FireDAC Migration** | 🔲 Planned | 🔴 High | ⭐⭐⭐⭐ High | v0.3.0+ |
| **Legacy Form Decomposer (Code-Behind)** | 🔲 Planned | 🔴 High | ⭐⭐⭐⭐ High | v0.3.0+ |
| **Threads and PPL Assistant** | 🔲 Planned | 🔴 High | ⭐⭐⭐⭐ High | v0.3.0+ |
| **Automated Internationalization (i18n Wizard)** | 🔲 Planned | 🔴 High | ⭐⭐⭐⭐ High | v0.3.0+ |
| **Smart Inline Autocomplete (Ghost Text)** | 🔲 Planned | 🔴 High | ⭐⭐⭐⭐ High | v0.3.0+ |
| **IDE Debugger Auto Hook (OTA)** | 🔲 Planned | 🔴 High | ⭐⭐⭐⭐ High | v0.3.0+ |
| **Project Docs Auto Generation (API.md)** | 🔲 Planned | 🟡 Medium | ⭐⭐⭐ Medium | v0.3.0+ |
| **Native macOS/Linux Support (Lazarus)** | 🔲 Planned | 🔴 High | 🟢 Low | v0.3.0+ |

---

## ⏳ 1. Work in Progress (WIP)

*   *No active task currently in progress in this branch.*

---

## 🔲 2. Next Up (Planned Backlog)

For complete details on objectives, impacts, and technical specifications for each future feature, check the [Feature Prioritization Matrix (docs/feature_prioritization_matrix.md)](feature_prioritization_matrix.md) or the [Evolution Roadmap (ROADMAP.en.md)](../ROADMAP.en.md).

---

## ✅ 3. Completed History

Check the implementation details of each completed feature grouped by target release version:

<details>
  <summary><b>📦 v0.0.15 — Two-Layer Template Architecture (Click to expand)</b></summary>

  #### 1. Two-Layer Segregated Template Architecture (Native vs. User overlays) - Item #12c
  *   **Description**: Segregates default prompt templates hardcoded in the codebase from those customized by the user inside AppData, allowing updates without losing custom settings, using overlays and factory resets.
  *   **Details**:
      *   Two-layer loading logic merging default and custom templates at runtime inside `TPromptTemplateManager`.
      *   Automated cleanup of redundant unedited templates inside user AppData directory (`CleanRedundantUserTemplates`).
      *   Enhanced settings VCL UI featuring origin descriptors (`lblTemplateOrigin`) and contextual delete/restore buttons.
      *   Expanded unit test suite achieving 117 successful DUnitX assertions.
</details>

<details>
  <summary><b>📦 v0.0.14 — Dynamic Templates & Backup (Click to expand)</b></summary>

  #### 1. Dynamic Templates, Prompt Backups, and New Architecture - Item #12b
  *   **Description**: Total dynamic template customization for prompts and slash commands, including VCL JSON backup dialogs and Clean Architecture support.
  *   **Details**:
      *   Removed hardcoded ifs when resolving slash commands. The parser scans `TPromptTemplateManager` dynamically using `{code}`, `{specification}`, `{stacktrace}`, and `{argument}` placeholders.
      *   JSON import/export transactional dialogs with schema checks and options to *Merge* or *Overwrite* local templates.
      *   Shipped the new `'Create Project Delphi Architecture'` (`/createprojectarch`) template, incorporating Dependency Inversion, robust try..finally blocks, and Pascal naming standards.
      *   Updated test coverage in `RadIA.Tests.Templates.pas` verifying backup parsing and schema validations.
</details>

<details>
  <summary><b>📦 v0.0.13 — Prompt-Based Delphi Project Generation (Click to expand)</b></summary>

  #### 1. Full Project Generation (Prompt-Based) - Item #24b
  *   **Description**: Automated creation of full Delphi projects based on chat prompts, writing them to disk and opening them in the IDE.
  *   **Details**:
      *   Developed transactional builder class `TRadIAProjectGenerator` inside `RadIA.Core.ProjectGenerator.pas`.
      *   Requires a clean, empty folder for saving files, rolling back created files if write errors occur.
      *   Parsed and rendered files inside a glassmorphism project panel in WebView2 featuring file shortcuts and flash highlight.
</details>

<details>
  <summary><b>📦 v0.0.12 — AWS Bedrock Provider (Click to expand)</b></summary>

  #### 1. Native AWS Bedrock Provider with SigV4 Signatures and EventStream Parser - Item #33
  *   **Description**: Full native AWS Bedrock support featuring AWS Signature Version 4 (SigV4) signing and binary AWS EventStream real-time decoding.
  *   **Details**:
      *   Developed the provider client `TRadIABedrockProvider` inside `RadIA.Provider.Bedrock.pas` registered into the core registry.
      *   Developed the SigV4 cryptographic utility `TAwsSigV4Signer` inside `RadIA.Core.AwsSigner.pas` computing SHA-256 and HMAC-SHA-256 signatures for AWS request headers.
      *   Implemented `TAwsEventStreamParser` to incrementally parse and decode Bedrock's binary EventStream payload frames.
      *   Created a VCL settings page featuring DPAPI-encrypted storage for AWS credentials (Access Key, Secret Key, Region, and Session Token).
      *   Added unit tests to `RadIA.Tests.ProvidersEx.pas`, achieving **112 passing green assertions** in the test suite.
</details>

<details>
  <summary><b>📦 v0.0.11 — Azure, Qwen, and Mistral AI Providers (Click to expand)</b></summary>

  #### 1. Additional Native Providers (Azure OpenAI, Alibaba Qwen, and Mistral AI) - Items #30, #31, #32
  *   **Description**: Direct native support for Azure OpenAI, Alibaba Qwen (ModelStudio), and Mistral AI APIs, including settings panels, key acquisition shortcuts, SSE streaming, and sorted provider lists.
  *   **Details**:
      *   Developed provider classes `TRadIAAzureOpenAIProvider`, `TRadIAQwenProvider`, and `TRadIAMistralProvider` registered dynamically in `TProviderRegistry`.
      *   Saved secure API keys via Windows DPAPI and custom properties (like `AzureApiVersion`).
      *   Created VCL light/dark options tabs for each provider inside the IDE's options dialog.
      *   Implemented sorted lists inside `TProviderRegistry.GetProviders` ensuring **Ollama** and **LM Studio** sit at the bottom of all lists.
      *   Validated with tests inside `RadIA.Tests.ProvidersEx.pas` and mocked configurations inside `RadIA.Tests.Service.pas`.
</details>

<details>
  <summary><b>📦 v0.0.10 — Native GitHub Copilot Support (Click to expand)</b></summary>

  #### 1. Native GitHub Copilot Provider (Phase 2) - Item #29
  *   **Description**: Native integration with the GitHub Copilot cloud featuring PIN authentication (Device Flow) and one-click key import from VS Code, along with developer console shortcuts for other keys.
  *   **Details**:
      *   Developed unit `RadIA.Provider.GithubCopilot.pas` managing the temporary session tokens requested from `https://api.github.com/copilot_internal/v2/token`.
      *   Created UI dialog `RadIA.UI.GithubAuthForm.pas` handling the background PIN device login flow.
      *   Modified VCL settings page to display the Copilot tab with login controls and quick API Key hyperlink shortcuts.
</details>

<details>
  <summary><b>📦 v0.0.9 — Multi-IDE Build Support (Click to expand)</b></summary>

  #### 1. Multi-IDE Version Build Support - Item #27
  *   **Description**: Enhances build script stability (`build.ps1`) to support systems running multiple Delphi IDE instances, offering target version choice via shell parameters or interactive menus.
  *   **Details**:
      *   Implemented the `-DelphiVersion` compiler target flag.
      *   Scans the Windows Registry (`HKCU:\Software\Embarcadero\BDS`) to fetch physical install paths (`RootDir`) and version labels.
      *   Added an interactive console select menu when multiple IDEs are found.
      *   Replaced hardcoded C: paths with dynamic root mapping using `$rootDir`.
</details>

<details>
  <summary><b>📦 v0.0.8 — LM Studio Provider (Click to expand)</b></summary>

  #### 1. Native LM Studio Provider - Item #21c
  *   **Description**: Shipped native, optional support for local LM Studio instances featuring SSE streaming, model autodiscovery, and custom endpoints.
  *   **Details**:
      *   Created unit `RadIA.Provider.LMStudio.pas` hosting the provider and its auto-registration.
      *   Designed a dedicated VCL settings tab matching the IDE theme and persisting URL settings.
      *   Refactored the sidebar chat to load LM Studio optionally (hiding it from dropdown lists unless configured).
      *   Coded unit tests covering LM Studio JSON mapping and stream buffers inside `RadIA.Tests.ProvidersEx.pas`.
</details>

<details>
  <summary><b>📦 v0.0.6 — JSON Dynamic Providers (Click to expand)</b></summary>

  #### 1. Dynamic JSON Providers (Plugins without Recompilation) - Item #21b
  *   **Description**: Support for registering custom OpenAI-compatible providers by saving configuration `.json` files inside RadIA's AppData directory, without compiling the plugin.
  *   **Details**:
      *   Iterates the directory at `%APPDATA%\RadIA\providers\` inside `TProviderRegistry.LoadJsonProviders`.
      *   Designed a generic client wrapper `TRadIAGenericOpenAIProvider` to serve as a universal OpenAI bridge.
      *   Handled fallbacks for optional API Keys and flags to list the loaded provider inside the chat sidebar.
      *   Built a test suite inside `RadIA.Tests.JSONProviders.pas`.
</details>

<details>
  <summary><b>📦 v0.0.4 — Productivity & Static Analysis (Click to expand)</b></summary>

  #### 1. DTO and Model Converter (JSON / DDL ➔ Delphi) - Item #22
  *   **Description**: Generates Object Pascal classes and records matching JSON payloads or SQL DDL scripts, with options for DEXT ORM, Aurelius, REST.Json, and Vanilla.
  *   **Details**:
      *   Programmed DTO builder `TRadIADTOBuilder` inside `RadIA.Core.DTO.Generator.pas` using flexible conversion rules.
      *   Mapped properties for DEXT ORM using Smart properties (`IntType`, `StringType`) and Lazy relations (`ILazy<T>`, `TValueLazy<T>`).
      *   Validated with 96 unit assertions inside `RadIA.Tests.DTOGenerator.pas`.

  #### 2. Stack Trace Assistant, Static Code Analysis, and Popup Menu - Items #23, #24, #25
  *   **Description**: Shipped integrated slash commands `/stacktrace` and `/bugs`, along with a WebView2 autocomplete command popup box.
  *   **Details**:
      *   Mapped prompt templates injecting editor context (active file buffer or selection).
      *   Crafted the dynamic CSS popup menu inside WebView2 reacting to keyboard arrows (`↑`/`↓`/`Enter`/`Esc`) and mouse hover.
</details>

<details>
  <summary><b>📦 v0.0.3 — Runtime Stability (Click to expand)</b></summary>

  #### 1. Dynamic and Decoupled Providers Architecture (Plugin-like) - Item #21
  *   **Description**: Refactored AI modules to support dynamic auto-registration of backends, removing cascaded ifs and hardcoded provider enums.
  *   **Details**:
      *   Created central registry `TProviderRegistry` housing metadata (`TProviderMetadata`) and delegate factories.
      *   Implemented auto-registration of 7 native providers inside their `initialization` sections.
      *   Decoupled `TRadIAService` which now resolves providers dynamically by calling `TProviderRegistry.CreateProvider` without static case loops.
      *   Added assertions inside `RadIA.Tests.Service.pas` covering registry integrity and error handling.
</details>

<details>
  <summary><b>📦 v0.0.2 — Multiple Sessions & Token Budgeting (Click to expand)</b></summary>

  #### 1. Multiple Chat Sessions - Item #5
  *   **Description**: Organizes conversations by project or task, preserving previous context across restarts.
  *   **Details**:
      *   Persists sessions to disk at `%APPDATA%\RadIA\sessions\<guid>.json` indexed via `sessions_index.json` using `TRadIASessionManager`.
      *   Collapsible sidebar UI (`pnlSessions`) with a `ListBox` and edit tools (New Chat, Rename, Delete) and a Toggle toolbar button (☰).
      *   Tested session persistence inside `RadIA.Tests.Sessions.pas`.

  #### 2. Local Token Quota and Budgeting - Item #19
  *   **Description**: Configures monthly limits to prevent surprise faturations, accumulating usage locally and blocking network requests.
  *   **Details**:
      *   Registry integration featuring automatic monthly quota resets.
      *   Visual budget settings inside the options panel.
      *   WebView status bar displaying real-time usage percentages.
      *   Tested block routines and quota cycles inside `RadIA.Tests.Quota.pas`.

  #### 3. Native OpenRouter Provider - Item #20
  *   **Description**: Connects directly to OpenRouter with SSE streaming, DPAPI key encryption, registry storage, and dynamic models listing.
  *   **Details**:
      *   Designed `RadIA.Provider.OpenRouter.pas` inheriting from `TRadIAOpenAICompatibleProvider`.
      *   Mapped registry paths, keys, and default models (`google/gemini-2.5-pro`, `meta-llama/llama-3.3-70b-instruct`, `deepseek/deepseek-r1`).
      *   Added VCL settings tab matching the IDE theme.
      *   Tested SSE buffering and responses inside `RadIA.Tests.ProvidersEx.pas`.

  #### 4. Context Window Management (Automated Trimming) - Item #10
  *   **Description**: Prevents token limit API errors by trimming old history entries when maximum size is reached.
  *   **Details**:
      *   Added `MaxHistoryMessages` settings field (Registry, default: 20).
      *   Manager client `TRadIAService.TrimHistory` cuts the oldest messages while keeping the system prompt and new inputs.
      *   Validated with 10 unit tests in `RadIA.Tests.Service.pas`.

  #### 5. Token Consumption Tracking - Item #14
  *   **Description**: Displays input/output token counts inside the chat status bar.
  *   **Details**:
      *   Coded `TTokenUsage` record to track inputs/outputs.
      *   Synced WebView status bar elements with Delphi.
      *   Tested count mappings inside `RadIA.Tests.TokenUsage.pas`.
</details>

<details>
  <summary><b>📦 v0.0.1 — Initial Release (Click to expand)</b></summary>

  #### 1. Prompt History Navigation (↑/↓) - Item #6
  *   **Description**: Allows developers to cycle through sent inputs using keyboard arrows.
  *   **Details**:
      *   Created manager class `TPromptHistoryManager` saving up to 50 history rows inside `%APPDATA%\RadIA\prompt_history.json`.
      *   Intercepted `memPromptKeyDown` events in the memo control.
      *   Tested navigation arrays inside `RadIA.Tests.PromptHistory.pas`.

  #### 2. OpenAI Compatible Endpoints - Item #8
  *   **Description**: Connects to any OpenAI-compatible gateway by changing the Base URL parameter.
  *   **Details**:
      *   Added `Custom Base URL` settings field (`IAIConfig.OpenAICustomBaseUrl`).
      *   Tested customizations inside `RadIA.Tests.Providers.pas`.

  #### 3. Export Conversations - Item #7
  *   **Description**: Exports the active chat history to Markdown (.md) or standalone HTML.
  *   **Details**:
      *   Added "Export" toolbar buttons triggering native file saving dialogs (`TSaveDialog`).
      *   Embedded Prism.js inside standalone HTML outputs.
      *   Tested export structures inside `RadIA.Tests.Exporter.pas`.

  #### 4. Prompt Templates - Item #12
  *   **Description**: Quick template menu replacing `{code}` placeholders with active selections.
  *   **Details**:
      *   Added VCL menu buttons and `/template` slash commands.
      *   Tested parser regexes inside `RadIA.Tests.Templates.pas`.

  #### 5. Project Context (.radia file) - Item #11
  *   **Description**: Custom system prompts and workspace contexts fetched from local project files.
  *   **Details**:
      *   Developed `TProjectContextLoader` searching `.radia` files in the active project root directory using `IOTAProject`.
      *   Tested workspace loader inside `RadIA.Tests.ProjectContext.pas`.

  #### 6. SSE Stream Responses - Item #4
  *   **Description**: Token-by-token server response streaming inside the chat window.
  *   **Details**:
      *   SSE streaming integrated inside OpenAI, Gemini, Claude, and Ollama.
      *   Intercepted network downloads using `TStreamingTargetStream` wrappers.
      *   Coded WebView receiver handlers (`appendMessage`, typing triggers).
      *   Tested stream buffering inside `RadIA.Tests.Streaming.pas`.

  #### 7. Ollama Integration & Persistent Chat - Item #3
  *   **Description**: Local offline modeling without key billing, and persistent chat lists.

  #### 8. DeepSeek & Groq Providers - Item #9
  *   **Description**: Integrated DeepSeek and Groq APIs natively.
  *   **Details**:
      *   Created clients `RadIA.Provider.DeepSeek.pas` and `RadIA.Provider.Groq.pas`.
      *   DPAPI encryption mapping for API keys.
      *   Tested payloads and streams inside `RadIA.Tests.ProvidersEx.pas`.

  #### 9. Request Aborts & Prompt Capsule UI - Item #17
  *   **Description**: Cancels pending AI queries at the socket level and introduces a modern capsule text input UI.
  *   **Details**:
      *   Aborts downloads by interrupting `THTTPClient.OnReceiveData` calls.
      *   Swap send buttons dynamically to a stop icon (`■`) during network requests.
      *   Styled the memo background using transparency attributes and borders.

  #### 10. Provider Preferences Configurations - Item #18
  *   **Description**: Individual temperature and max token parameters for each provider.
  *   **Details**:
      *   Persisted settings fields inside Windows Registry using the core config class.
      *   Mapped variables to JSON request builders.

  #### 11. Hybrid Connection and Login Web (Plus/Pro) - Item #28
  *   **Description**: Automates DOM inputs and parses chat data from consumer WebView instances, allowing Plus/Pro usage.
  *   *Details*:
      *   Designed settings toggles and bridges inside the options screen.
      *   Written `bridge.js` to override official UI layouts and scan stream text.
      *   Configured chromium UA values to bypass third-party login locks.

  #### 12. VCL Third Party Options Integration - Item #2
  *   **Description**: Hosts settings frames natively under the global IDE Third Party Options registry.
  *   **Details**:
      *   Developed config frame `TFrameAIConfig` and standalone popup form wrapper `TFormAIConfig`.
      *   Registered registry bridges using `INTAAddInOptions` API under **Third Party > RadIA**.
      *   Styled options dynamically to match IDE light/dark styles.
</details>
