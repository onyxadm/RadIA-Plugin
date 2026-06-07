<div align="right">

[🇧🇷 Português](backlog.md) | [🇺🇸 English](backlog.en.md)

</div>

# RadIA Future Evolution Backlog

This document tracks tasks and ideas for the evolution of the RadIA plugin, detailing the status of each feature.

---

## ✅ Completed Items

### 1. Context Window Management (Automatic Trimming) - Item #10
*   **Description**: Prevents silent token limit errors from the API by trimming older messages from the active conversation when the maximum configured limit is reached.
*   **Details**:
    *   Implemented the `MaxHistoryMessages` field in settings (Windows Registry, default: 20).
    *   The orchestrator `TRadIAService.TrimHistory` trims older messages while preserving the system prompt and the most recent messages.
    *   Robust validation with 10 specific unit tests in `RadIA.Tests.Service.pas`.

### 2. DTO and Model Converter (JSON / DDL ➔ Delphi) - Item #22
*   **Description**: Automated generation of Object Pascal classes and records from JSON payloads or SQL DDL scripts, with built-in support for DEXT ORM, Aurelius, REST.Json, and Vanilla.
*   **Details**:
    *   Developed the central builder `TRadIADTOBuilder` inside `RadIA.Core.DTO.Generator.pas` with dynamic rule conversion engines.
    *   Direct DEXT ORM mapping utilizing Smart Properties (`IntType`, `StringType`, etc.) and lazy relationships (`ILazy<T>`, `TValueLazy<T>`) without redundant getters/setters.
    *   Robust validation with 96 unit tests inside `RadIA.Tests.DTOGenerator.pas`.

### 3. Prompt History (↑/↓ Navigation) - Item #6
*   **Description**: Allows the developer to navigate through the last queries sent using the up/down arrow keys on the keyboard.
*   **Details**:
    *   Created the `TPromptHistoryManager` limiting entries to 50, persisted in `%APPDATA%\RadIA\prompt_history.json`.
    *   Keyboard capture in `memPromptKeyDown` for dynamic prompt navigation.
    *   Validation with 13 dedicated unit tests in `RadIA.Tests.PromptHistory.pas`.

### 3. OpenAI Compatible Endpoints (LM Studio, Azure, Groq) - Item #8
*   **Description**: Support for any provider compatible with the OpenAI protocol by simply changing the base URL.
*   **Details**:
    *   Added the `Custom Base URL` field in OpenAI settings (`IAIConfig.OpenAICustomBaseUrl`).
    *   Request methods and model discovery use the custom URL when provided.
    *   Validation with 3 dedicated unit tests in `RadIA.Tests.Providers.pas`.

### 4. Token Tracking - Item #14
*   **Description**: Displays the count of tokens (Prompt and Completion) consumed in the Chat UI status bar.
*   **Details**:
    *   Implemented the `TTokenUsage` record to track input/output tokens.
    *   Dynamic status bar in HTML/CSS/JS synchronized with Delphi.
    *   Validation with unit tests in `RadIA.Tests.TokenUsage.pas`.

### 5. Export Conversation (.md / .html) - Item #7
*   **Description**: Allows saving the full history of the active chat in Markdown or structured HTML formats with a single click.
*   **Details**:
    *   Export button integrated into the sidebar and native `TSaveDialog` dialog.
    *   Standalone HTML exported with embedded CSS and Prism.js for Pascal highlighting.
    *   Validation with 4 unit tests in `RadIA.Tests.Exporter.pas`.

### 6. Prompt Templates - Item #12
*   **Description**: Quick prompt template library with code replacement and the `/template` slash command.
*   **Details**:
    *   Dynamic "Tpl" menu and slash command in the chat.
    *   Smart replacement of the `{code}` placeholder with the selected code block in the IDE.
    *   Validation with 4 unit tests in `RadIA.Tests.Templates.pas`.

### 7. Project Context (.radia file) - Item #11
*   **Description**: Allows customizing system prompts and reading additional project files as AI context.
*   **Details**:
    *   `TProjectContextLoader` reader that detects `.radia` files in the root folder of the active Delphi project via `IOTAProject`.
    *   Validation with 4 unit tests in `RadIA.Tests.ProjectContext.pas`.

### 8. Response Streaming (SSE) - Item #4
*   **Description**: Incremental token-by-token display (Server-Sent Events) in the IDE chat, optimizing the user experience.
*   **Details**:
    *   Native SSE streaming implemented in providers: OpenAI, Gemini, Claude, and Ollama.
    *   Usage of `TStreamingTargetStream` intercepting HTTP writes in real-time.
    *   Javascript functions `appendMessage`, `showTypingIndicator`, and `hideTypingIndicator` integrated in the WebView.
    *   Dedicated unit tests in `RadIA.Tests.Streaming.pas` covering incremental behavior, partial buffers, and completion events.

### 9. Integration with Local Models (Ollama) + Persistent History - Item #3
*   **Description**: Native support for local models without paid keys and full chat history restoration.

### 10. Native Providers: DeepSeek and Groq - Item #9
*   **Description**: Added direct native support to DeepSeek and Groq providers with SSE streaming and dynamic model autodiscovery.
*   **Details**:
    *   Created the `RadIA.Provider.DeepSeek.pas` unit for connection to the DeepSeek API.
    *   Created the `RadIA.Provider.Groq.pas` unit for connection to the Groq API.
    *   Extended settings for API keys with secure storage and DPAPI.
    *   New unit tests in `RadIA.Tests.ProvidersEx.pas` covering payload, response parsing, and streaming SSE flow.

### 11. AI Request Cancellation & New Prompt Design - Item #17
*   **Description**: Allows the developer to abort active AI HTTP requests asynchronously and instantly, and redesigns the chat input box into a modern and responsive floating capsule layout.
*   **Details**:
    *   Implemented network-level cancellation by intercepting the `OnReceiveData` callback of `THTTPClient`.
    *   The send button changes its function and icon dynamically to a stop button (`■`) during the request, and the UI displays a clean cancellation message without encoding issues.
    *   Input panel background configured for native transparency (`ParentBackground := True`), with the capsule shape (`shpInputBg`) and memo (`memPrompt`) styled with high contrast and visual integration.

### 12. Advanced Settings per AI Provider - Item #18
*   **Description**: Allows developers to configure generation parameters such as Temperature and Max Tokens individually per provider inside tabbed sections in the settings screen.
*   **Details**:
    *   Dynamic parameter editing and persistence within the Windows Registry via the `TRadIAConfig` class.
    *   Payload mapping and integration inside HTTP JSON request modules for all supported AI backends (Ollama, Gemini, OpenAI, Claude, Groq, and DeepSeek).

### 13. Multiple Chat Sessions - Item #5
*   **Description**: Allows developers to organize conversations by project, feature, or task without losing the context of previous sessions.
*   **Details**:
    *   Persistent session storage in `%APPDATA%\RadIA\sessions\<guid>.json` indexed within `sessions_index.json` managed by the `TRadIASessionManager` class.
    *   Collapsible sidebar panel in the UI (`pnlSessions`) with a `ListBox` and controls (New Session, Rename, Delete) featuring a smooth slide animation and a Hamburger toggle (☰) on the toolbar.
    *   Robust validation using unit tests in `RadIA.Tests.Sessions.pas`.

### 14. Local Token Budget and Quota Control - Item #19
*   **Description**: Allows developers to set a monthly local token usage limit in settings to avoid surprise charges on their API keys, accumulating the consumption locally and blocking new requests if exceeded.
*   **Details**:
        *   Windows Registry integration with automatic monthly token quota resets.
        *   Dynamic settings controls generated on the panel's configuration page.
        *   HTML-based quota consumption percentage display inside the WebView's status bar.
        *   Full test coverage in `RadIA.Tests.Quota.pas` checking blocking logic and reset cycles.

### 15. New Configuration Layout (Delphi-like) and Tools -> Options Integration - Item #2
*   **Description**: Refactoring the settings screen into a reusable frame integrated natively inside the IDE's global configuration (`Tools -> Options`), with a styled tree view dynamic mapping.
*   **Details**:
    *   Implementation of the `TFrameAIConfig` frame containing the PageControl and options controls.
    *   Implementation of the `TFormAIConfig` standalone wrapper form containing a sidebar with `TTreeView` and footer buttons to preserve the original standalone popup behavior.
    *   Integration of the Open Tools API bridge via `TRadIAAddInOptions` (`INTAAddInOptions`) registering the category tree under **Third Party > RadIA** (with subnodes for Gemini, OpenAI, Claude, DeepSeek, Groq, Ollama).
    *   Automated theming and styling following the native IDE theme using individual panel wrappers for style inheritance and preventing inappropriate color contrast in the IDE dark theme.
    *   Automated silent saving when clicking "OK" inside the IDE's options, and explicit success messages shown only on the standalone popup form.

### 16. Native Provider: OpenRouter - Item #20
*   **Description**: Added direct native support to the OpenRouter provider with SSE streaming, registry persistence, secure credential storage via DPAPI, and model configuration.
*   **Details**:
    *   Created the `RadIA.Provider.OpenRouter.pas` unit inheriting from `TRadIAOpenAICompatibleProvider`.
    *   Mapped `ptOpenRouter` in provider type enum, implemented API key settings, and defined fallback default models (`google/gemini-2.5-pro`, `meta-llama/llama-3.3-70b-instruct`, `deepseek/deepseek-r1`).
    *   Added the `tsOpenRouter` tab with layout design, and implemented dark/light mode paint controls.
    *   Created new unit tests in `RadIA.Tests.ProvidersEx.pas` covering payload generation, responses, and SSE event streaming parsing.

### 17. Dynamic and Simplified Provider Infrastructure (Plugin-like) - Item #21
*   **Description**: Refactored the AI provider infrastructure to support dynamic auto-registration of AI backends, removing cascaded static couplings and rigid enums.
*   **Details**:
    *   Implemented the centralized `TProviderRegistry` registry containing provider metadata (`TProviderMetadata`) and delegation of factory functions.
    *   Implemented auto-registration for the 7 native providers (Gemini, OpenAI, Claude, Ollama, DeepSeek, Groq, and OpenRouter) within their `initialization` sections.
    *   Decoupled the orchestrator `TRadIAService` which now dynamically resolves any active provider via `TProviderRegistry.CreateProvider` without static `case` statements.
    *   Added new unit tests in `RadIA.Tests.Service.pas` covering registry integrity and error handling.

### 18. Dynamic Providers via JSON (No Recompilation Plug-ins) - Item #21b
*   **Description**: Support for adding new OpenAI-compatible AI providers simply by placing `.json` configuration files inside RadIA's AppData, without compiling the plugin.
*   **Details**:
    *   Implemented automatic directory scanning in `TProviderRegistry.LoadJsonProviders` reading from `%APPDATA%\RadIA\providers\`.
    *   Developed the generic polymorphic class `TRadIAGenericOpenAIProvider` acting as a universal OpenAI client wrapper.
    *   Implemented API key fallback settings configured inside the JSON, and dynamic status marking for listing loaded JSON providers in the chat interface.
    *   New unit test suite integrated in `RadIA.Tests.JSONProviders.pas`.

---

## ⏳ In Development

### 1. Stack Trace Assistant (Debug Companion - Phase 1) - Item #23
*   **Goal**: Analyze pasted Stack Traces (from IDE exceptions, MadExcept, or EurekaLog) to pinpoint the failing unit/method and suggest fixes.

### 2. Memory Leak & Anti-pattern Analyzer (Static Analysis) - Item #24
*   **Goal**: Asynchronously analyze the active unit in the editor to locate memory leaks (e.g., missing try..finally) and semantic violations of SOLID/Clean Code.

### 3. Popup Shortcut Menu for Slash Commands (/) - Item #25
*   **Goal**: Show a modern shortcut and autocomplete popup when typing `/` in the chat input.

---

## 🔲 Pending Items

### 1. Cache Management Panel (Item #13)
*   **Goal**: Provide visibility and control over the response cache without having to edit the JSON file manually.

### 2. Automatic Code Review on Save (Item #15)
*   **Goal**: Silently analyze the unit upon saving and signal in the RadIA panel if the AI found any points of interest.

### 3. Applied Refactoring History (Item #16)
*   **Goal**: Maintain an auditable log of every time the [Apply Changes] button was triggered, allowing manual review and undo.
