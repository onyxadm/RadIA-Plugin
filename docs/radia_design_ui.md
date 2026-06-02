# Design de Interface e Menus: RadIA

Este documento descreve o design de interface do usuário (UI), comportamento visual e integração de menus do **RadIA** dentro do ambiente da IDE do Delphi (RAD Studio).

---

## 1. Mockup Visual do RadIA na IDE

Abaixo está o mockup conceitual de alta fidelidade demonstrando a integração lateral do painel **RadIA** e o menu de contexto no editor de código:

![Mockup Visual do RadIA na IDE do Delphi](images/radia_ui_mockup.png)

---

## 2. Detalhamento dos Menus

### A. Integração com o Menu Principal da IDE
Criaremos um item no menu principal da IDE em **Tools** (Ferramentas) para facilitar a inicialização e configuração inicial:
*   **Tools** ➔ **RadIA...**
    *   *RadIA Chat (Exibir/Ocultar painel)*
    *   *Configurações do RadIA*

### B. Integração com o Menu de Contexto do Editor de Código (Editor Context Menu)
Ao selecionar qualquer trecho de código no editor do Delphi e clicar com o botão direito, um submenu dedicado do **RadIA** será exibido:

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
*   **Otimizar/Refatorar Código:** Solicita refatoração seguindo Clean Code, SOLID e melhores práticas do Delphi modernizado.
*   **Gerar Teste Unitário (DUnitX):** Cria uma estrutura completa de teste unitário baseada no código selecionado.
*   **Localizar Bugs/Vulnerabilidades:** Analisa o código em busca de memory leaks (ex: falta de try..finally), erros de concorrência ou vulnerabilidades.
*   **Enviar Seleção para o Chat:** Insere o código formatado na caixa de entrada do chat lateral do RadIA para que o desenvolvedor digite uma pergunta customizada.

---

## 3. Elementos do Painel de Chat (Dockable Form)

O painel do chat usará uma interface híbrida VCL + Web para garantir visual premium:
*   **Barra Superior (Toolbar VCL):**
    *   **Dropdown Selector:** Para alternar dinamicamente entre `Google Gemini`, `OpenAI` e `Anthropic Claude`.
    *   **Model Selector:** Sub-dropdown exibindo os modelos compatíveis com o provedor (ex: `gemini-1.5-pro`, `gpt-4o`, `claude-3-5-sonnet`).
    *   **Botão de Configurações (Ícone de Engrenagem):** Abre o Form VCL de configurações.
    *   **Botão de Nova Conversa (Ícone de Lixeira):** Limpa o histórico de chat atual.
*   **Área de Chat (TEdgeBrowser / TWebBrowser):**
    *   Renderiza o histórico em um documento HTML5 local extremamente leve, responsivo e que responde aos temas da IDE (Light/Dark).
    *   Blocos de código no chat virão com formatação de cores e um botão flutuante **"Copy Code"** ou **"Insert into Editor"** para facilitar o dia a dia.
*   **Barra Inferior (Input Area VCL):**
    *   **TMemo:** Caixa de digitação multi-linha que aceita atalhos (ex: `Ctrl + Enter` para enviar).
    *   **Label de Contexto:** Um pequeno texto indicador quando há código selecionado no editor (ex: *"Código Selecionado: 14 linhas"*).

---

## 4. Janela de Configurações (Config Form)

Uma janela VCL modal simples, dividida em abas ou seções para cada IA:
*   **Google Gemini:**
    *   Campo para API Key (ocultada/mascarada).
    *   Seleção de Modelos Padrão.
*   **OpenAI:**
    *   Campo para API Key.
    *   Configuração de Custom Endpoint (caso use proxy/gateway).
*   **Anthropic Claude:**
    *   Campo para API Key.
*   **Configurações Gerais:**
    *   Atalhos globais de teclado (ex: abrir o chat com `Ctrl + Shift + A`).
    *   Configurações de tema (Ajustar automaticamente ao tema da IDE do Delphi ou Forçar Dark Mode).

---

## 5. Tela de Comparação de Refatoração (Smart Diff View)

Para as ações de refatoração, abriremos uma janela modal específica chamada **Smart Diff**. Esta tela realiza uma comparação visual detalhada antes que o desenvolvedor decida substituir seu código.

![Mockup da Tela de Diff do RadIA](images/radia_diff_ui_mockup.png)

### Elementos da Interface:
*   **Coluna Esquerda (Código Original):** Apresenta o código atual do editor do Delphi, destacando em vermelho-claro as linhas que serão removidas ou modificadas.
*   **Coluna Direita (Código Refatorado):** Apresenta o código novo sugerido pelo RadIA, destacando em verde-claro as linhas inseridas ou modificadas.
*   **Barra de Controle (Inferior):**
    *   **Botão Aplicar (VCL Blue Style):** Copia as alterações e substitui de forma atômica e segura o buffer de texto original do editor da IDE.
    *   **Botão Cancelar/Descartar:** Fecha a janela sem fazer nenhuma alteração no código fonte.

