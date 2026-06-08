# Installation and Configuration Guide — RadIA

This document describes in detail the installation, compilation, and configuration process of the **RadIA** plugin for the Delphi IDE.

---

## 1. Installation

RadIA requires active and valid API keys to function with cloud models (Gemini, OpenAI, Claude, DeepSeek, or Groq) or a configured **Ollama** instance running on your machine or local network.

The plugin can be installed in two ways:

### Option A: Automated Installation (PowerShell) - Recommended

This option automatically compiles the plugin, runs unit tests (if the **DUnitX** framework is installed in the IDE; otherwise, tests are automatically and transparently ignored), copies the binaries to the official public Delphi directories, and registers the plugin in the Windows Registry.

1. Open the Windows PowerShell console.
2. Make sure the Delphi installation `bin` folder containing `dcc32` is present in your system PATH.
3. Run the command in the project root directory according to your IDE's architecture:
   * **For the default 32-bit IDE (Delphi 10.4, 11, and 12)**:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\build.ps1 -Install
     ```
   * **For the 64-bit IDE (Delphi 13 Florence)**:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\build.ps1 -Install -IDE64
     ```
4. Done! The plugin will be installed and active on the next startup of the IDE.

### Option B: Manual Installation via IDE

1. Clone this repository to your computer.
2. Open the project group `RadIA.groupproj` in Delphi.
3. Right-click on `RadIA.bpl` in the Project Manager and click **Build**.
4. Right-click on `RadIA.bpl` again and click **Install**.
5. A confirmation dialog will appear, and the **RadIA** panel will dock on the right side of your IDE.
6. Go to **Tools ➔ RadIA Chat Panel** to display the chat, and click the **Settings** button at the top of the panel to configure your API keys.

---

## 2. Configuring Ollama (Local or Network)

**Ollama** lets you run open-source LLMs (Llama 3, Mistral, Phi-3, CodeLlama, etc.) directly on your machine or on a server in your local network — with no paid API dependency.

**Prerequisite:** Install Ollama from [https://ollama.com](https://ollama.com) and pull at least one model with `ollama pull llama3`.

* **For local use (same machine):**
  1. Start the Ollama server (on Windows, the service starts automatically after installation).
  2. The default URL `http://localhost:11434` is already pre-configured — **no changes required**.
  3. In the plugin settings (**Settings → Ollama Local/Network Settings**), confirm the URL reads `http://localhost:11434`.
  4. Select **Ollama** in the provider dropdown in the chat panel.

* **For network use (remote server):**
  1. Make sure Ollama is running on the remote server and listening on all interfaces. Set the environment variable `OLLAMA_HOST=0.0.0.0` on the server before starting the service.
  2. In the plugin settings (**Settings → Ollama Local/Network Settings**), set the URL to the server's IP address or hostname. Example: `http://192.168.1.100:11434`.
  3. Make sure port `11434` is reachable through the network's firewall.
  4. Select **Ollama** in the provider dropdown in the chat panel.

> **Note:** The plugin automatically discovers available models from the Ollama server via `/api/tags`. If the connection fails, it falls back to a built-in list of well-known model names.

---

## 3. API Key Acquisition Guide by Provider

Enter the obtained keys in the plugin settings (**Settings** at the top of the chat panel):

1. **Google Gemini (Recommended)**
   * **How to obtain:** Access the [Google AI Studio Console](https://aistudio.google.com/).
   * **Instructions:** Log in, click **Create API Key** on the left sidebar menu, select your project, and copy the generated key.

2. **OpenAI ChatGPT**
   * **How to obtain:** Access the [OpenAI Platform](https://platform.openai.com/).
   * **Instructions:** Log in, navigate to **API Keys** in the side menu, click **Create new secret key**, and copy the token (starts with `sk-`).

3. **Anthropic Claude**
   * **How to obtain:** Access the [Anthropic Console](https://console.anthropic.com/).
   * **Instructions:** Log in, go to the **API Keys** tab, click **Create Key**, and copy the token (starts with `sk-ant-`).

4. **DeepSeek**
   * **How to obtain:** Access the [DeepSeek Platform Console](https://platform.deepseek.com/).
   * **Instructions:** Log in, go to the **API Keys** section, click **Create API Key**, and copy it.

5. **Groq Cloud**
   * **How to obtain:** Access the [Groq Console](https://console.groq.com/).
   * **Instructions:** Navigate to **API Keys**, click **Create API Key**, and copy it (starts with `gsk_`).

> **Note on Dynamic and Enterprise Providers:** You can also dynamically add new OpenAI-compatible API providers (such as GitHub Copilot or third-party proxies) by saving JSON configuration files under `%APPDATA%\RadIA\providers\`. For more details, check our [Guide for Adding New Providers (docs/new_provider_guide.en.md)](new_provider_guide.en.md) and the [GitHub Copilot Configuration Guide (docs/copilot_proxy_guide.en.md)](copilot_proxy_guide.en.md).

---

## 4. PowerShell Build Script (Advanced Options)

The `.\build.ps1` script supports the following switches:

* `-Install`: Builds the plugin, runs unit tests, copies binaries to public Delphi paths, and registers the package.
* `-Uninstall`: Clean uninstalls the plugin, deleting files and registry keys.
* `-Release`: Enables compiler optimizations and outputs a smaller BPL binary.
* `-IDE64`: Compiles and installs specifically for the 64-bit Delphi IDE in Delphi 13 Florence.
* `-DelphiVersion "<version>"`: Optional. Allows forcing a specific Delphi version installed in the system (e.g., `"23.0"`, `"37.0"`, `"Athens"`).
* `-SkipTests`: Optional. Skips building and running the unit test suite (DUnitX). Recommended for end-users who only want a quick plugin installation.

> [!TIP]
> **Multiple IDE Versions Support:** If you have more than one Delphi version installed on Windows and execute the script with `-Install` or `-Uninstall` without passing the `-DelphiVersion` parameter, the script will automatically list all valid installations found in the Registry and display a console menu for interactive selection.

> [!NOTE]
> **DUnitX Auto-Detection:** The installer automatically detects if the DUnitX framework is present in your selected Delphi installation. If DUnitX is missing (typical in basic/minimal IDE installations), the script will display a warning and automatically disable the unit tests suite, continuing with the compilation and successful installation of the main plugin without requiring user intervention.

---

## 5. Hybrid Login (Web Login Plus/Pro vs BYOK)

RadIA allows you to choose between two connection methods for both **Google Gemini** and **OpenAI ChatGPT** providers:
1. **API Key (BYOK)**: Uses official API keys and charges per consumed token directly from your developer balance on OpenAI Platform/Google AI Studio.
2. **Web Login (Plus/Pro)**: Allows you to log in directly to your personal or corporate consumer accounts (ChatGPT Plus/Pro and Gemini Advanced) using their official interface inside RadIA's integrated WebView2.

### How to Enable and Use Web Login
1. Open settings (**Settings** at the top of the chat panel or via the menu **Tools ➔ Options ➔ Third Party > RadIA**).
2. Select the provider tab (**Gemini** or **OpenAI**).
3. Under **Connection Method**, select **Web Login (Plus/Pro)**.
4. Click **Save**.
5. In the RadIA chat panel, select the corresponding provider. A lock login button 🔐 will appear in the top-right corner of the chat header.
6. Click the lock button 🔐. This will open a native Delphi login popup window (`TFormWebLogin`).
7. Log in to your account in the popup window. Your session and cookies will be securely saved under `%APPDATA%\RadIA\WebView2Data` to keep you logged in. Once authenticated, you can close the popup.
8. That's it! You can now chat normally inside RadIA's unified local chat interface (or use right-click editor actions). The plugin will use a background, hidden WebView2 instance to send prompts and stream responses back in real time, keeping a unified premium experience.
