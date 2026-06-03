<div align="right">

[🇧🇷 Português](radia_design_ui.md) | [🇺🇸 English](radia_design_ui.en.md)

</div>

# Interface Design and Menus: RadIA

This document describes the user interface (UI) design, visual behavior, and menu integration of **RadIA** within the Delphi IDE (RAD Studio) environment. It reflects the current state of the implementation.

---

## 1. Visual Mockup of RadIA in the IDE

Below is the conceptual high-fidelity mockup demonstrating the lateral integration of the **RadIA** panel and the context menu in the code editor:

![Visual Mockup of RadIA in the Delphi IDE](images/radia_ui_mockup.png)

---

## 2. Menu Details

### A. IDE Main Menu Integration
An item in the IDE's main menu under **Tools**:
*   **Tools** ➔ **RadIA Chat Panel** — Shows/hides the dockable chat panel.

### B. Code Editor Context Menu Integration
When selecting any block of code in the Delphi editor and right-clicking, a dedicated **RadIA** submenu is shown:

```
[ Copy ]
[ Paste ]
[ ... ]
--------------------------------------------
🤖 RadIA ->
    ├── 📖 Explain Selected Code
    ├── ⚡ Optimize/Refactor Code
    ├── 🧪 Generate Unit Test (DUnitX)
    ├── 🐛 Locate Bugs/Vulnerabilities
    └── 💬 Send Selection to Chat
```

*   **Explain Selected Code:** Sends the selected code to the active AI with a prompt instructing a pedagogical explanation of the code's execution flow.
*   **Optimize/Refactor Code:** Requests a refactoring following Clean Code, SOLID, and modernized Delphi best practices. Opens the **Smart Diff** for review before applying.
*   **Generate Unit Test (DUnitX):** Creates a complete unit test structure based on the selected code.
*   **Locate Bugs/Vulnerabilities:** Analyzes the code looking for memory leaks (e.g., missing `try..finally`), concurrency errors, or vulnerabilities.
*   **Send Selection to Chat:** Inserts the formatted code into the input box of the RadIA lateral chat so that the developer can ask a custom question.

### C. Slash Commands in Chat
Quick commands typed directly into the chat input box:

| Command | Action |
|---|---|
| `/doc` | Generates XML documentation (`/// <summary>`) for the active method/class |
| `/explain` | Explains the selected code in the editor |
| `/refactor` | Refactors the selected code (opens Smart Diff) |
| `/bugs` | Analyzes the selected code for bugs |

---

## 3. Chat Panel Elements (Dockable Form)

The chat panel uses a hybrid VCL + WebView2 (Edge Chromium) interface to ensure a premium look:

### Top Bar (VCL Toolbar)
- **`cbProvider`** (TComboBox): switches between `Gemini`, `OpenAI`, `Claude`, `Ollama`. Upon switching, it saves to the registry and asynchronously reloads the model list.
- **`cbModel`** (TComboBox): available models for the active provider, loaded via `FetchAvailableModelsAsync`. Displays `Loading...` while waiting. For Ollama, queries the server at `GET /api/tags`.
- **`btnSettings`** (TButton): opens the settings screen in a modal (340×585 px).
- **`btnClear`** (TButton): clears the history on screen and deletes `%APPDATA%\RadIA\history.json`.

### Chat Area (`TEdgeBrowser`)
- Renders messages in local HTML5 (`chat.html`).
- Full support for Markdown via `Marked.js`.
- Pascal/Delphi syntax highlighting via `Prism.js`.
- Code blocks with a floating **"Apply Code"** button → replaces the text in the active editor via OTA.
- Automatically adapts to the IDE theme (Dark/Light) via the `set_theme` message.
- Upon initialization, restores the **persistent history** from `history.json` rendering all previous messages.

### Bottom Bar (Input Area)
- **`memPrompt`** (TMemo): multi-line input field. `Ctrl+Enter` to send (or the Send button).
- **`lblContext`** (TLabel): displays contextual information (e.g., *"Selected Code: 14 lines"*) when there is a selection in the editor.
- **`btnSend`** (TButton): disabled during response processing to prevent double submissions.

---

## 4. Settings Window (Config Frame)

VCL Frame (`TFrameAIConfig`, 320×525 px) opened in modal from the **Settings** button:

```
┌─────────────────────────────────────────┐
│  Google Gemini Settings                 │
│  API Key: [********************]        │
├─────────────────────────────────────────┤
│  OpenAI ChatGPT Settings                │
│  API Key: [********************]        │
├─────────────────────────────────────────┤
│  Anthropic Claude Settings              │
│  API Key: [********************]        │
├─────────────────────────────────────────┤
│  Ollama Local/Network Settings          │
│  Server URL: [http://localhost:11434]   │
├─────────────────────────────────────────┤
│  Custom System Instructions             │
│  ┌─────────────────────────────────┐   │
│  │ (System Prompt - TMemo)         │   │
│  └─────────────────────────────────┘   │
├─────────────────────────────────────────┤
│               [Save]  [Cancel]          │
└─────────────────────────────────────────┘
```

**Fields:**
- **API Key (Gemini/OpenAI/Claude):** Masked with `*`. Stored encrypted via DPAPI in the Windows Registry.
- **Ollama Server URL:** Base URL of the Ollama server (local or network). Default: `http://localhost:11434`. Does not require an API Key.
- **Custom System Instructions:** System instruction persisted in `HKEY_CURRENT_USER\Software\Embarcadero\BDS\<versao>\RadIA\SystemPrompt`. Automatically injected as the first `mrSystem` message in every interaction.

> **Note:** To configure Ollama over network, define `OLLAMA_HOST=0.0.0.0` on the server and use the IP/hostname here (e.g., `http://192.168.1.100:11434`). See detailed instructions in `README.md`.

---

## 5. Refactoring Comparison Screen (Smart Diff View)

For refactoring actions, a specific modal window is opened — **Smart Diff**. This screen performs a detailed visual comparison before the developer decides to replace their code.

![Smart Diff Screen Mockup](images/radia_diff_ui_mockup.png)

### UI Elements
*   **Left Column (Original Code):** Presents the current code from the Delphi editor, highlighting in **light-red** the lines that will be removed or modified.
*   **Right Column (Refactored Code):** Presents the new code suggested by RadIA, highlighting in **light-green** the lines inserted or modified.
*   **Control Bar (Bottom):**
    *   **[Apply Changes]:** Atomically and safely replaces the active editor buffer via `TRadIAOTAHelper.ReplaceActiveEditorText`.
    *   **[Cancel/Discard]:** Closes the window without changing the source code.

---

## 6. Data Flow: One Chat Message

```
User types and clicks Send
        │
        ▼
TFrameAIChat.btnSendClick
  ├── PostToWebView('add_message', 'user', text)   ← displays on screen immediately
  └── SendPromptToAI(text)
        │
        ▼
TRadIAService.SendPrompt
  ├── Creates SHA-1 hash (provider+model+systemprompt+prompt+history)
  ├── Queries TRadIACacheManager.Get(hash)
  │     ├── [HIT]  → ACallback(response, '', True)  ← note "*[cache response]*"
  │     └── [MISS] → Injects SystemPrompt into history
  │                  Calls Provider.SendPromptAsync(prompt, history, callback)
  │                       │
  │                       ▼
  │               TTask.Run (background thread)
  │                 DoPostRequest → HTTP REST API
  │                 ParseResponseBody
  │                 TThread.Queue → back to UI thread
  │                       │
  │                       ▼
  │               TRadIACacheManager.Put(hash, response)
  │               ACallback(response, '', False)
  │
  ▼
TFrameAIChat (callback on UI thread)
  ├── PostToWebView('add_message', 'assistant', response)
  ├── FHistory := FHistory + [userMsg, assistantMsg]
  └── SaveChatHistory → %APPDATA%\RadIA\history.json
```
