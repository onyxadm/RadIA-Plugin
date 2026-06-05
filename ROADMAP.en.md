<div align="right">

[🇧🇷 Português](ROADMAP.md) | [🇺🇸 English](ROADMAP.en.md)

</div>

# RadIA - Evolution Roadmap

This document describes the evolution roadmap of the RadIA plugin, organized by versions and delivery priorities. Items are grouped by milestone and reflect the long-term vision of the project.

> [!NOTE]
> RadIA follows a **community-driven open source development model**. Pull Requests are welcome for any item listed below. See the contribution section for more details.

---

## ✅ v1.0 — Initial Release (Completed)

Version 1.0 implemented all core plugin features, including:

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

## ✅ v1.1 — Control & Visibility (Completed)

Version 1.1 focused on context management and local governance over token usage:

- **Multiple Chat Sessions (Advanced History):**
  * Local conversation persistence saved inside `%APPDATA%\RadIA\sessions\<guid>.json`.
  * Collapsible sidebar built with high-fidelity HTML/CSS/JS premium styling inside WebView2 for listing, selecting, creating, renaming (inline double-click), and deleting active conversations.
  * Thread-safe event integration and sync handlers in Delphi-WebView channel.
- **Local Token Budget & Quota Control:**
  * Configurable monthly budget limit inside settings.
  * Local persistency accumulator with real-time percentage consumption status inside WebView status bar.
  * Dynamic network request block whenever usage exceeds 100% of the set quota.

---

## 🔲 v1.2 — Advanced Productivity (Next Version)

### 3. Automatic Code Review on Save
*   **Goal**: Silently analyze the active unit on save and signal in the RadIA panel if the AI found points of attention (e.g., potential bugs, duplicated code, or missing exception handling).
*   **Impact**: ⭐⭐⭐⭐ High

### 4. Applied Refactoring History
*   **Goal**: Maintain an auditable log of every time the **[Apply Changes]** button was clicked, recording the original snippet, the applied snippet, the date, and the file, allowing future manual review.
*   **Impact**: ⭐⭐⭐ Medium

---

## 🔲 v1.3 — Administration & Diagnostics

### 5. Cache Management Panel
*   **Goal**: Display an internal administration screen for the response cache, allowing users to view cached entries, delete specific ones, and see the total cache file size without manually editing JSON.
*   **Impact**: ⭐⭐⭐ Medium

---

## 💡 Future Ideas (v2.0+)

The items below are still in the conceptual stage and are being evaluated for technical feasibility with the Open Tools API:

- **Automatic project documentation generation** (scan units and generate a complete `docs/API.md`).
- **Delphi version migration assistant** (code compatibility analysis when migrating between IDE versions).
- **GitHub Copilot / GitLab Duo integration** (bridging via LSP protocol).
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
