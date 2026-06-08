# RadIA Features and Capabilities

This document contains the complete checklist, categorization, and development status of all features integrated into the **RadIA** plugin.

---

## Complete Feature Checklist

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
| **Hybrid Login (Web Login)**| Provider | Choose between BYOK (API Keys) or Web Login (Plus/Pro) for OpenAI and Gemini, using smart DOM/CSS injection and JS bridge. | ✅ Completed |
| **Anthropic Claude** | Provider | Native BYOK integration for Claude 3 Haiku and Claude 3.5 Sonnet. | ✅ Completed |
| **DeepSeek** | Provider | Native BYOK integration for DeepSeek Chat and Reasoning models. | ✅ Completed |
| **Groq** | Provider | Native BYOK integration for Llama, Mixtral, and Gemma models via Groq's high-speed cloud. | ✅ Completed |
| **Ollama Local/Network** | Provider | Connects to local open-source models with no paid API keys and dynamic tags discovery. | ✅ Completed |
| **OpenRouter** | Provider | Native OpenRouter support with SSE streaming, dynamic model selection, and complete settings integration. | ✅ Completed |
| **LM Studio** | Provider | Native LM Studio support with SSE streaming, local models auto-discovery, and customizable server URL. | ✅ Completed |
| **Native GitHub Copilot** | Provider | Direct, remote connection to GitHub Copilot cloud (personal/business) with integrated PIN Device Flow and one-click VS Code token import. | ✅ Completed |
| **Custom Base URL** | Provider | Route OpenAI API payload to other endpoints like Groq, DeepSeek, or LM Studio. | ✅ Completed |
| **Dynamic Providers** | Provider | Metadata-driven plugin-like architecture for registering new models and AI backends dynamically. | ✅ Completed |
| **Dynamic JSON Providers** | Provider | Add new OpenAI-compatible providers by saving JSON files into `%APPDATA%\RadIA\providers\`. | ✅ Completed |
| **Project Context** | Intelligence | Automatic project context loading (system prompts/custom files) via `.radia`. | ✅ Completed |
| **Tokens & Cost Tracking** | Control | Status bar counter for session token usage and USD estimated cost. | ✅ Completed |
| **Local Quota Control** | Control | Define a monthly token limit with request blocking and a manual reset button. | ✅ Completed |
| **Editor Context Actions** | Integration | Right-click code selection to Explain, Optimize/Refactor, Test, or Scan for Bugs. | ✅ Completed |
| **Interactive Smart Diff** | Integration | Side-by-side original/suggested diff view with instant editor replacement. | ✅ Completed |
| **Smart Build Debugger** | Integration | Message tab integration to resolve compiler issues with one-click fixes. | ✅ Completed |
| **Auto XML Documentation** | Generation | Write Delphi-compliant XML help comments above methods automatically. | ✅ Completed |
| **DTO & Model Converter** | Generation | Convert JSON or SQL DDL payloads into Object Pascal data classes (DTOs) or records (DEXT ORM, Aurelius, REST.Json, or Vanilla). | ✅ Completed |
| **Slash Commands Popup Menu (/)** | Chat UX | Floating suggestions and autocomplete menu when typing `/` in the chat input. | ✅ Completed |
| **Stack Trace Assistant** | Integration | Error log/stack trace analyzer integrated with active unit context. | ✅ Completed |
| **Static Code Analysis** | Integration | Code scan for memory leaks (missing try..finally) and SOLID/Clean Code anti-patterns. | ✅ Completed |
| **Secure Credentials** | Security | API Keys saved securely inside the Windows Registry using DPAPI. | ✅ Completed |
| **Multi-IDE Build & Install** | Infrastructure | PowerShell script supporting multiple registry Delphi environments and interactive selection menu. | ✅ Completed |
