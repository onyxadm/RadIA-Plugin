<div align="right">

[🇧🇷 Português](radia_design_ui.md) | [🇺🇸 English](radia_design_ui.en.md)

</div>

# Design de Interface e Menus: RadIA

Este documento descreve o design de interface do usuário (UI), comportamento visual e integração de menus do **RadIA** dentro do ambiente da IDE do Delphi (RAD Studio). Reflete o estado atual da implementação.

---

## 1. Mockup Visual do RadIA na IDE

Abaixo está o mockup conceitual de alta fidelidade demonstrando a integração lateral do painel **RadIA** e o menu de contexto no editor de código:

![Mockup Visual do RadIA na IDE do Delphi](images/radia_ui_mockup.png)

---

## 2. Detalhamento dos Menus

### A. Integração com o Menu Principal da IDE
Um item no menu principal da IDE em **Tools** (Ferramentas):
*   **Tools** ➔ **RadIA Chat Panel** — Exibe/oculta o painel de chat dockável.

### B. Integração com o Menu de Contexto do Editor de Código
Ao selecionar qualquer trecho de código no editor do Delphi e clicar com o botão direito, um submenu dedicado do **RadIA** é exibido:

```
[ Copiar ]
[ Colar ]
[ ... ]
--------------------------------------------
🤖 RadIA ->
    ├── 📖 Explicar Código Selecionado
    ├── ⚡ Otimizar/Refatorar Código
    ├── 🧪 Gerar Teste Unitário (DUnitX)
    ├── 🐛 Localizar Bugs/Vulnerabilidades
    └── 💬 Enviar Seleção para o Chat
```

*   **Explicar Código Selecionado:** Envia o código selecionado para a IA ativa com um prompt instruindo a explicação didática do fluxo do código.
*   **Otimizar/Refatorar Código:** Solicita refatoração seguindo Clean Code, SOLID e melhores práticas do Delphi modernizado. Abre o **Smart Diff** para revisão antes de aplicar.
*   **Gerar Teste Unitário (DUnitX):** Cria uma estrutura completa de teste unitário baseada no código selecionado.
*   **Localizar Bugs/Vulnerabilidades:** Analisa o código em busca de memory leaks (ex: falta de `try..finally`), erros de concorrência ou vulnerabilidades.
*   **Enviar Seleção para o Chat:** Insere o código formatado na caixa de entrada do chat lateral do RadIA para que o desenvolvedor faça uma pergunta customizada.

### C. Slash Commands no Chat
Comandos rápidos digitados diretamente na caixa de entrada do chat:

| Comando | Ação |
|---|---|
| `/doc` | Gera documentação XML (`/// <summary>`) para o método/classe ativa |
| `/explain` | Explica o código selecionado no editor |
| `/refactor` | Refatora o código selecionado (abre Smart Diff) |
| `/bugs` | Analisa o código selecionado em busca de bugs |

---

## 3. Elementos do Painel de Chat (Dockable Form)

O painel do chat usa uma interface híbrida VCL + WebView2 (Edge Chromium) para garantir visual premium:

### Barra Superior (Toolbar VCL)
- **`cbProvider`** (TComboBox): alterna entre `Gemini`, `OpenAI`, `Claude`, `Ollama`. Ao mudar, salva no registro e recarrega a lista de modelos de forma assíncrona.
- **`cbModel`** (TComboBox): modelos disponíveis para o provedor ativo, carregados via `FetchAvailableModelsAsync`. Exibe `Loading...` enquanto aguarda. Para o Ollama, consulta o servidor em `GET /api/tags`.
- **`btnSettings`** (TButton): abre a tela de configurações em modal (340×585 px).
- **`btnClear`** (TButton): limpa o histórico na tela e apaga `%APPDATA%\RadIA\history.json`.

### Área de Chat (`TEdgeBrowser`)
- Renderiza mensagens em HTML5 local (`chat.html`).
- Suporte completo a **Markdown** via `Marked.js`.
- Realce de sintaxe Pascal/Delphi via **Prism.js**.
- Blocos de código com botão flutuante **"Apply Code"** → substitui o texto no editor ativo via OTA.
- Adapta-se automaticamente ao tema da IDE (Dark/Light) via mensagem `set_theme`.
- Ao inicializar, restaura o **histórico persistente** de `history.json` renderizando todas as mensagens anteriores.

### Barra Inferior (Input Area)
- **`memPrompt`** (TMemo): campo de digitação multi-linha. `Ctrl+Enter` para enviar (ou botão Send).
- **`lblContext`** (TLabel): exibe informação contextual (ex: *"Código Selecionado: 14 linhas"*) quando há seleção no editor.
- **`btnSend`** (TButton): desabilitado durante o processamento de uma resposta para evitar envios duplos.

---

## 4. Janela de Configurações (Config Frame)

Frame VCL (`TFrameAIConfig`, 320×525 px) aberto em modal a partir do botão **Settings**:

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

**Campos:**
- **API Key (Gemini/OpenAI/Claude):** Mascarados com `*`. Armazenados criptografados via DPAPI no Registro do Windows.
- **Ollama Server URL:** URL base do servidor Ollama (local ou em rede). Padrão: `http://localhost:11434`. Não requer API Key.
- **Custom System Instructions:** Instrução de sistema persistida em `HKEY_CURRENT_USER\Software\Embarcadero\BDS\<versao>\RadIA\SystemPrompt`. Injetada automaticamente como primeira mensagem `mrSystem` em toda interação.

> **Nota:** Para configurar o Ollama em rede, defina `OLLAMA_HOST=0.0.0.0` no servidor e use o IP/hostname aqui (ex: `http://192.168.1.100:11434`). Veja as instruções detalhadas no `README.md`.

---

## 5. Tela de Comparação de Refatoração (Smart Diff View)

Para as ações de refatoração, uma janela modal específica é aberta — **Smart Diff**. Esta tela realiza uma comparação visual detalhada antes que o desenvolvedor decida substituir seu código.

![Mockup da Tela de Diff do RadIA](images/radia_diff_ui_mockup.png)

### Elementos da Interface
*   **Coluna Esquerda (Código Original):** Apresenta o código atual do editor do Delphi, destacando em **vermelho-claro** as linhas que serão removidas ou modificadas.
*   **Coluna Direita (Código Refatorado):** Apresenta o código novo sugerido pelo RadIA, destacando em **verde-claro** as linhas inseridas ou modificadas.
*   **Barra de Controle (Inferior):**
    *   **[Aplicar Alteração]:** Substitui de forma atômica e segura o buffer do editor ativo via `TRadIAOTAHelper.ReplaceActiveEditorText`.
    *   **[Cancelar/Descartar]:** Fecha a janela sem alterar o código fonte.

---

## 6. Fluxo de Dados: Uma Mensagem no Chat

```
Usuário digita e clica Send
        │
        ▼
TFrameAIChat.btnSendClick
  ├── PostToWebView('add_message', 'user', text)   ← exibe na tela imediatamente
  └── SendPromptToAI(text)
        │
        ▼
TRadIAService.SendPrompt
  ├── Cria hash SHA-1 (provider+model+systemprompt+prompt+history)
  ├── Consulta TRadIACacheManager.Get(hash)
  │     ├── [HIT]  → ACallback(response, '', True)  ← nota "*[resposta de cache]*"
  │     └── [MISS] → Injeta SystemPrompt no history
  │                  Chama Provider.SendPromptAsync(prompt, history, callback)
  │                       │
  │                       ▼
  │               TTask.Run (background thread)
  │                 DoPostRequest → HTTP REST API
  │                 ParseResponseBody
  │                 TThread.Queue → volta para UI thread
  │                       │
  │                       ▼
  │               TRadIACacheManager.Put(hash, response)
  │               ACallback(response, '', False)
  │
  ▼
TFrameAIChat (callback na UI thread)
  ├── PostToWebView('add_message', 'assistant', response)
  ├── FHistory := FHistory + [userMsg, assistantMsg]
  └── SaveChatHistory → %APPDATA%\RadIA\history.json
```
