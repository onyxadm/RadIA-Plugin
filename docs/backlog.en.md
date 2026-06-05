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

### 2. Prompt History (↑/↓ Navigation) - Item #6
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

---

## 🔲 Pending Items

### 1. Multiple Chat Sessions (Item #5)
*   **Goal**: Allow the developer to organize conversations by project, feature, or task, without losing the context of previous sessions.
*   **Details**:
    *   Store sessions in `%APPDATA%\RadIA\sessions\<id>.json`, each with a name, date, and array of messages.
    *   Add a sidebar panel (or dropdown) to list, create, rename, and delete sessions.
    *   The "New Session" button saves the current one and opens a blank one.

### 2. Cache Management Panel (Item #13)
*   **Goal**: Provide visibility and control over the response cache without having to edit the JSON file manually.

### 3. Automatic Code Review on Save (Item #15)
*   **Goal**: Silently analyze the unit upon saving and signal in the RadIA panel if the AI found any points of interest.

### 4. Applied Refactoring History (Item #16)
*   **Goal**: Maintain an auditable log of every time the [Apply Changes] button was triggered, allowing manual review and undo.

### 5. Local Token Budget and Quota Control
*   **Goal**: Allow the developer to set a monthly local token consumption limit to avoid surprise billing on their API keys.
*   **Details**:
	*   Add a setting field for token limit (e.g., monthly quota of 1,000,000 tokens).
	*   Store and accumulate consumption persistently local.
	*   Display consumption percentage in the sidebar chat status bar and alert/block calls upon reaching 100% of the defined quota.
