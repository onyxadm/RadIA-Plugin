<div align="right">

[🇧🇷 Português](ROADMAP.md) | [🇺🇸 English](ROADMAP.en.md)

</div>

# RadIA - Evolution Roadmap

This document describes the evolution roadmap of the RadIA plugin, organized by versions and delivery priorities. Items are grouped by milestone and reflect the long-term vision of the project.

> [!NOTE]
> RadIA follows a **community-driven open source development model**. Pull Requests are welcome for any item listed below. See the contribution section for more details.

---

## ✅ v0.0.1 — Initial Release (Completed)

Version v0.0.1 implemented all core plugin features, including:

- Dockable sidebar chat with WebView2 (HTML5/JS/CSS)
- Support for 6 AI providers: Gemini, OpenAI, Claude, DeepSeek, Groq, and Ollama
- SSE token-by-token streaming responses
- Persistent chat history in local JSON
- Prompt history with ↑/↓ arrow key navigation
- Conversation export to Markdown and HTML
- Prompt templates with `/template`
- Project context via `.radia` file
- Context-aware editor actions (right-click menu)
- Smart Diff (side-by-side visual code comparison)
- Smart Build Debugger (compilation error integration)
- Automatic XML documentation generation
- Secure API key storage via Windows DPAPI
- Offline-first distribution of Web dependencies
- Automated build script (`build.ps1`) with `-Install` and `-Release` flags
- Apache 2.0 License, `NOTICE` file, and complete liability disclaimers

---

## ✅ v0.0.2 — Multiple Sessions & Token Budget Control (Completed)

Version v0.0.2 focused on context management, local governance over token usage, and new AI backends:

- **Multiple Chat Sessions (Advanced History):**
  * Local conversation persistence saved inside `%APPDATA%\RadIA\sessions\<guid>.json`.
  * Collapsible sidebar built with high-fidelity HTML/CSS/JS premium styling inside WebView2 for listing, selecting, creating, renaming (inline double-click), and deleting active conversations.
  * Thread-safe event integration and sync handlers in Delphi-WebView channel.
- **Local Token Budget & Quota Control:**
  * Configurable monthly budget limit inside settings.
  * Local persistency accumulator with real-time percentage consumption status inside WebView status bar.
  * Dynamic network request block whenever usage exceeds 100% of the set quota.
- **OpenRouter Support:**
  * Integrates OpenRouter provider as a unified gateway to access hundreds of AI models via a single API Key.

---

## ✅ v0.0.3 — Dynamic Provider Architecture & Teardown Stability (Completed)

Version v0.0.3 introduced critical architectural enhancements for extensibility and memory stability:

- **Dynamic Provider Architecture:**
  * Implemented a central, metadata-driven registry (`TProviderRegistry`) allowing dynamic registration and loading of new AI backends without compiler coupling.
- **Robust Configuration Lifecycle:**
  * Replaced `TDictionary` with `TStringList` internally and moved `TRadIAConfig` to a Singleton pattern with manual lifetime management (disabled ARC). This prevents package teardown Access Violations and double-free exceptions in the IDE.
- **WebView2 & Async Request Safety:**
  * Protected async callbacks using `TThread.Queue` and lifecycle verification wrappers (`ILifecycleGuard`) to prevent crashes when active frames or panels are destroyed during pending HTTP requests.

---

## ✅ v0.0.4 — Advanced Productivity & Static Analysis (Completed)

Version v0.0.4 introduced advanced code analysis tools, test automation support, and panel usability shortcuts:

- **DTO and Model Converter (JSON / DDL ➔ Delphi):**
  * Convert JSON payloads or SQL DDL statements into matching Delphi classes and records, supporting Vanilla, DEXT, Aurelius, and REST.Json.
- **Stack Trace Assistant:**
  * Intelligent analysis of exception and error reports (MadExcept, EurekaLog) with root cause mapping within the active IDE source file.
- **Memory Leak & Anti-pattern Analyzer (Static Analysis):**
  * Static analysis of the active unit focusing on locating missing try..finally blocks and SOLID violations.
- **Slash Commands Popup Shortcut Menu (/):**
  * Interactive prompt menu displaying quick slash command shortcuts (such as `/explain`, `/refactor`, `/bugs`, `/doc`, `/review`, `/stacktrace`) when typing `/`.

---

## ✅ v0.0.5 — Provider Decoupling & UI Optimizations (Completed)

Version v0.0.5 focused on deep structural refactoring and options screen improvements:

- **Dynamic Architecture without Enums:**
  * Removed the static global enum `TAIProviderType`. The plugin now utilizes 100% dynamic strings (`FProviderId`) to identify, save settings, and manage the lifecycle of AI providers.
- **Visual Fixes in Settings UI:**
  * Fixed the top "Templates" tab showing up unintentionally on all option panels in Delphi's Options.
  * Omitted and cleaned up the experimental "Inline Autocomplete" settings UI in this branch to keep it focused and isolated from the branch dedicated to the feature.
- **Extensibility Documentation:**
  * New provider guides (`new_provider_guide.md` and its English translation) fully updated to reflect the new string-based API.

---

## ✅ v0.0.6 — Dynamic JSON Providers & Copilot Support (Completed)

Version v0.0.6 drastically expanded plugin extensibility by allowing ad-hoc additions of new models without recompilation and support for enterprise AIs:

- **Dynamic JSON Providers (Plugins without Recompilation):**
  * Support for adding any OpenAI-compatible provider by creating `.json` files in the `%APPDATA%\RadIA\providers\` directory.
- **GitHub Copilot Support (Local Proxy - Phase 1):**
  * Step-by-step documented integration to connect enterprise/personal Copilot subscriptions using local proxy tools (such as `copilot-gpt4-service`), enabling compliance and cost savings.

---

## ✅ v0.0.7 — Default System Prompt & Configuration Fine-tuning (Completed)

Version v0.0.7 introduced usability improvements in the assistant's initial out-of-the-box configuration:

- **Optimized Default System Prompt:**
  * Integration of a structured default fallback instruction that guides the AI to always reply in the same language as the user's prompt and output only clean, specific Pascal code snippets, preventing verbose answers containing full Delphi units.
- **Developer Choices Respected:**
  * The new prompt acts non-intrusively as an out-of-the-box default fallback value and will not override or modify system prompt customizations already saved by the developer in the Windows Registry.

---

## ✅ v0.0.8 — Local LM Studio Provider & Test Suite Stability (Completed)

Version v0.0.8 added native and optional support for LM Studio as a local AI provider and refined the robustness of the unit test suite:

- **Native LM Studio Provider:**
  * Direct integration of `TRadIALMStudioProvider` class inheriting from `TRadIAOpenAICompatibleProvider`.
  * Default local URL set to `http://localhost:1234/v1`.
  * 100% optional behavior (just like Ollama): the provider is only listed in the chat dropdown if a valid URL is saved in options, keeping the list clean for users who don't need it.
- **IDE Options Screen:**
  * Dedicated settings tab for LM Studio (`Tools -> Options -> Third Party -> RadIA`) with native support for IDE Light and Dark themes.
- **Automated Test Suite:**
  * Created unit tests inside `RadIA.Tests.ProvidersEx.pas` covering LM Studio payloads, responses, and SSE streaming (totaling 103 successful DUnitX tests in the suite).


---

## ✅ v0.0.9 — Multi-IDE Support and Console Compatibility (Completed)

Version v0.0.9 refined the build infrastructure and support for environments running multiple Delphi IDE installations simultaneously:

- **Dynamic Multi-IDE Installer:**
  * The `build.ps1` script now dynamically scans for all installed Delphi versions under `HKCU:\Software\Embarcadero\BDS` in the Windows Registry.
  * Added the `-DelphiVersion` parameter to target a specific Delphi IDE.
  * Interactive PowerShell console menu displays version options if multiple IDEs are found (including a safe Cancel option).
  * Automatically sets temporary PATH variable using the selected version's compiler (`dcc32`) and maps IDE folders dynamically using `$rootDir`.
- **Console Compatibility:**
  * Replaced all accented characters inside PowerShell output strings with standard ASCII characters to prevent encoding distortion across different Windows system locales (UTF-8/CP1252/CP850).

---

## ✅ v0.0.10 — Native GitHub Copilot Support (Completed)

Version v0.0.10 introduced native and official support for direct remote connections to GitHub Copilot cloud servers and settings UI shortcuts for API key acquisition:

- **Native GitHub Copilot Provider (Phase 2):**
  * Integrated `TRadIAGithubCopilotProvider` class inheriting from `TRadIAOpenAICompatibleProvider` to communicate directly with the GitHub Copilot cloud (`https://api.githubcopilot.com`) without local proxies.
  * Automated session token acquisition and refresh via `https://api.github.com/copilot_internal/v2/token` using the persistent user token.
- **Enhanced Authentication UX:**
  * Integrated PIN-based device login directly inside options (OAuth Device Flow) with automated system browser redirection.
  * One-click credential importer to parse and extract active Copilot tokens from local VS Code configurations (`hosts.json`).
- **API Key Shortcut Links:**
  * Hyperlink shortcuts next to key input fields (Gemini, OpenAI, Claude, DeepSeek, Groq, OpenRouter) pointing directly to developer dashboards.

---

## ✅ v0.0.11 — Additional Native Providers (Completed)

Version v0.0.11 expanded the plugin's direct BYOK integrations by introducing native and optimized support for three key AI providers:

- **Native Azure OpenAI:**
  * Implemented the `TRadIAAzureOpenAIProvider` class with `AzureApiVersion` mapping, dynamic endpoint URLs, and DPAPI-encrypted credential management.
- **Native Alibaba Qwen (ModelStudio):**
  * Direct communication with the official Alibaba Cloud ModelStudio API to consume the **Qwen 2.5** model family (including *Qwen 2.5 Coder*).
- **Native Mistral AI:**
  * Native integration with Mistral AI's official endpoints and model listings.
- **Settings Tab & UI Enhancements:**
  * Created custom light/dark VCL settings tabs for all three providers, along with direct hyperlink shortcuts to obtain official API Keys.
- **Custom Provider Sorting:**
  * Implemented custom sorting in the chat sidebar and WebView dropdown listings, ensuring local providers (**Ollama** and **LM Studio**) are strictly positioned at the end of all menus.
- **Unit Test Suite Coverage:**
  * Expanded tests to cover payload schemas and SSE streaming for the new APIs, achieving 109 successful unit tests (DUnitX).

---

## ✅ v0.0.12 — AWS Bedrock Provider & Stabilization (Completed)

Version v0.0.12 introduced official support for the AWS Bedrock provider, featuring secure AWS SigV4 cryptographic request signing and incremental EventStream binary streaming decoding:

- **Native AWS Bedrock Provider:**
  * Implemented the `TRadIABedrockProvider` class inside `RadIA.Provider.Bedrock.pas` integrated into the central registry.
  * Created the `TAwsSigV4Signer` utility class inside `RadIA.Core.AwsSigner.pas` to compute and sign request headers following the AWS Signature Version 4 specification.
  * Implemented the `TAwsEventStreamParser` binary parser to incrementally process streaming frames in the binary AWS EventStream format, translating them into real-time SSE text streams.
- **Settings Tab & Persistence:**
  * Built a custom VCL options page tab for AWS Bedrock under `Tools -> Options`, securing access keys, secret keys, region, and session tokens via Windows DPAPI.
- **Bug Fixes & Test Suite:**
  * Fixed an infinite loop condition in the EventStream parser when the buffer matched the frame size boundary.
  * Fixed an RTTI resolution conflict and literal float parameter coercion inside unit test mock helpers.
  * Extended unit tests inside `RadIA.Tests.ProvidersEx.pas`, achieving **112 successful DUnitX tests** in the test suite.

---

## ✅ v0.0.13 — Prompt-Based Delphi Project Generation (Completed)

Version v0.0.13 introduced support for automatically generating entire Delphi projects from a chat prompt, with physical file persistence and immediate loading inside the IDE:

- **Complete Project Generation:**
  * Implemented a new `TRadIAProjectGenerator` specialist service (in `RadIA.Core.ProjectGenerator.pas`) to parse multiple files via JSON.
  * Added a directory selection dialog that restricts saving unless the folder is completely empty.
  * Integrated a transactional file saver that rolls back and deletes all created files in case of write errors.
  * Automated project detection (.dproj and .dpr) and native loading in the Delphi IDE via Open Tools API.
- **Prompt Template and Slash Command `/createproject`:**
  * Centralized all prompt directives in the template manager (`TPromptTemplateManager` in `RadIA.Core.PromptTemplates.pas`), keeping UI code clean and respecting the Single Responsibility Principle.
  * Instructed the AI to strictly format output files with the comment tag `// filepath: relative/path`.
- **Premium Project UI Panel:**
  * Rendered a consolidated, high-fidelity project panel (modern glassmorphism design) listing all generated files with file type icons.
  * Added smooth chat container scroll-to-view and a temporary flash highlight border animation to visually locate file code blocks when inspecting the file list.

---

## ✅ v0.0.14 — Dynamic Templates, Backup, and New Project Architecture (Completed)

Version v0.0.14 brings total flexibility to prompt management and project templates in the IDE, alongside support for importable backups and an optimized project generator:

- **Dynamic Slash Commands Customization:**
  * Complete removal of hardcoded static ifs during command preprocessing. RadIA now dynamically iterates through active templates to match slash commands and replace their placeholders.
  * Automated synchronization of slash commands with the web frontend (WebView2) for dynamic autocomplete in the chat view.
- **Template Backup & Restore Mechanism:**
  * Dedicated buttons and native Windows dialogs integrated into the VCL settings frame (`Tools -> Options -> RadIA -> Templates`).
  * Structural import/export using JSON files with strict validation of mandatory attributes (`name` and `template`).
  * Transactional support to merge imported files with existing templates or completely overwrite them.
- **Clean Architecture Delphi Project Template (`/createprojectarch`):**
  * Created the new native template `'Create Project Delphi Architecture'` incorporating robust architectural guidelines (SOLID, interface-driven dependency inversion, business logic isolation, and systematic try..finally blocks to guarantee zero memory leaks).
- **Test Suite & Refinement:**
  * Sychronized unit tests to cover import validation, merge vs. overwrite behaviors, schema assertions, and export functions. **All 112 DUnitX tests passed successfully**.

---

## ✅ v0.0.15 — Two-Layer Template Architecture and Overlays (Completed)

Version v0.0.15 introduced the complete segregation of default prompt templates defined in the code from those created or modified by the user (saved to disk), ensuring that default prompt updates propagate automatically:

- **Physical-Logical Template Segregation:**
  * Clean, delta storage in local `templates.json` file (contains only new user templates or customization overlays).
  * Dynamic runtime merging (`BuildActiveTemplates`) between hardcoded system templates and user overrides.
- **Redundant Data Higienization (Auto-Migration):**
  * Automatic cleaning (`CleanRedundantUserTemplates`) of redundant items in the local JSON that match the updated plugin source code exactly.
- **Premium Origin Management UX:**
  * Dynamic origin label (`Origin: Default System (Read-Only)`, `Origin: Default System (Customized)`, and `Origin: User Custom`) programmatically created in the options frame.
  * Smart VCL buttons control logic (Delete button changes to **"Restore Default"** for overlays, clearing the override and re-enabling the original system properties).
- **Unit Testing:**
  * Added unit tests covering default template detection, overlay creation, and restoring defaults. **All 116 DUnitX unit tests passed successfully**.

---

## 🔲 v0.1.0 — Automation & Auditing (Next Version)

### 1. Automatic Code Review on Save
*   **Goal**: Silently analyze the active unit on save and signal in the RadIA panel if the AI found points of attention (e.g., potential bugs, duplicated code, or missing exception handling).
*   **Impact**: ⭐⭐⭐⭐ High
*   **Complexity**: Medium

### 2. Applied Refactoring History
*   **Goal**: Maintain an auditable log of every time the **[Apply Changes]** button was clicked, recording the original snippet, the applied snippet, the date, and the file, allowing future manual review.
*   **Impact**: ⭐⭐⭐ Medium
*   **Complexity**: Low

---

## 🔲 v0.2.0 — Administration & Diagnostics

### 6. Version Migration Assistant (Smart Migrate)
*   **Goal**: Contextual menu or sidebar action to rewrite legacy/procedural code blocks utilizing modern Delphi features (Unicode, PPL, FireDAC).
*   **Impact**: ⭐⭐⭐⭐ High
*   **Complexity**: Medium

### 7. Cache Management Panel
*   **Goal**: Display an internal administration screen for the response cache, allowing users to view cached entries, delete specific ones, and see the total cache file size without manually editing JSON.
*   **Impact**: ⭐⭐⭐ Medium
*   **Complexity**: Medium

---

## 💡 Future Ideas (v0.3.0+)

The items below are still in the conceptual stage and are being evaluated for technical feasibility with the Open Tools API:

- **Smart Inline Autocomplete (Ghost Text):** Real-time gray text code suggestions inside the editor similar to Copilot (Complexity: High).
- **IDE Debugger Auto Hook:** Dynamic capture and automatic explanation of active exceptions raised during debug sessions (Complexity: High).
- **Automatic project documentation generation** (scan units and generate a complete `docs/API.md`).
- **Native macOS/Linux support** via FPC/Lazarus (feasibility analysis).

---

## 🤝 How to Contribute

Contributions are very welcome! If you want to implement any of the items in this roadmap:

1. **Fork** the repository.
2. Create a descriptive branch: `feature/multiple-chat-sessions`.
3. Implement the changes following the **SOLID, Clean Code, and DRY** principles adopted in the project.
4. Make sure the command `powershell -ExecutionPolicy Bypass -File .\build.ps1 -Test` passes with **all tests green**.
5. Open a **Pull Request** describing your contribution.

> [!IMPORTANT]
> All project source code must be written **exclusively in English** (variable names, methods, classes, and comments). Documentation can be written in Portuguese or English.
