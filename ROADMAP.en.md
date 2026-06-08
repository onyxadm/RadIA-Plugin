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
- **Native GitHub Copilot / GitLab Duo Integration (Phase 2):** Integrated OAuth login flow and automated token refresh mechanics (Complexity: High).
- **Native macOS/Linux support** via FPC/Lazarus (feasibility analysis).

---

## 🤝 How to Contribute

Contributions are very welcome! If you want to implement any of the items in this roadmap:

1. **Fork** the repository.
2. Create a descriptive branch: `feature/multiple-chat-sessions`.
3. Implement the changes following the **SOLID, Clean Code, and DRY** principles adopted in the project.
4. Make sure the command `powershell -ExecutionPolicy Bypass -File .\build.ps1` passes with **all tests green**.
5. Open a **Pull Request** describing your contribution.

> [!IMPORTANT]
> All project source code must be written **exclusively in English** (variable names, methods, classes, and comments). Documentation can be written in Portuguese or English.
