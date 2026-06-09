<div align="right">

[🇧🇷 Português](README.md) | [🇺🇸 English](README.en.md) | [🗺️ Roadmap](ROADMAP.md) | [📋 Backlog](docs/backlog.md)

</div>

<p align="center">
  <img src="docs/images/radia_readme_banner-2.png" alt="RadIA - Assistente de IA para Delphi IDE" width="100%" />
</p>


# RadIA - Assistente de IA para Delphi IDE

**RadIA** é um plugin assistente de IA avançado projetado especificamente para a IDE do Embarcadero Delphi (usando a Open Tools API). Ele se acopla diretamente à barra lateral da IDE, fornecendo uma interface de chat interativa e integração contextual profunda com o editor de código para acelerar o desenvolvimento, refatoração e depuração.

<p align="center">
  <img src="docs/images/radia_ui_mockup.png" alt="RadIA Chat Panel Mockup" width="100%" />
</p>

---

### 1. Diretrizes de Desenvolvimento e Padrão de Linguagem

Este projeto adota regras claras de idioma e padrões de design para desenvolvedores humanos e assistentes de IA (LLMs/Co-pilots) que trabalham na base de código:

*   **Interações de IA e Humanos (AI & Human Interactions):**
    *   Toda conversa no chat, commits, descrições de pull requests, tarefas e discussões de design devem ser conduzidas em **Português do Brasil (pt-BR)**.
*   **Código Fonte & Arquitetura (Source Code & Architecture):**
    *   O código fonte é **100% escrito em Inglês (en-US)**.
    *   Todos os identificadores (nomes de units, variáveis, classes, métodos, records, enums), parâmetros, estruturas de dados (JSON/XML) e comentários embutidos no código devem ser escritos exclusivamente em inglês, seguindo as convenções e padrões Pascal.
    *   Adoção rigorosa de **Clean Code**, **SOLID**, **DRY** e **KISS** com total isolamento em threads (thread-safety).
*   **Documentação Oficial (Documentation):**
    *   Disponível principalmente em Português ([README.md](README.md)) com tradução equivalente em Inglês ([README.en.md](README.en.md)).

### 2. Funcionalidades
*   **Chat Lateral Acoplável (Dockable):** Painel integrado à IDE com visual nativo do Delphi, trazendo uma janela de chat em HTML5/JS moderno (WebView2) com suporte a Markdown e realce de sintaxe Pascal.
*   **Suporte a Múltiplas IAs & Conexão Híbrida:** Modelo híbrido flexível de conexão. Permite usar chaves de API próprias (BYOK) para **Google Gemini**, **OpenAI ChatGPT**, **Azure OpenAI**, **Anthropic Claude**, **AWS Bedrock**, **GitHub Copilot**, **DeepSeek**, **Groq**, **Alibaba Qwen**, **Mistral AI**, **OpenRouter**, **LM Studio** e **Ollama** local, OU conectar-se diretamente às suas contas pessoais/corporativas de consumo (**ChatGPT Plus/Pro** e **Gemini Advanced**) via login oficial no WebView2, contornando bloqueios de rede com injeção inteligente de DOM/CSS e ponte JS-Delphi.
*   **Integração Nativa com GitHub Copilot:** Suporte oficial para conectar-se diretamente aos servidores do GitHub Copilot (pessoal ou corporativo) na nuvem, com fluxo de autenticação do dispositivo embutido (OAuth Device Flow) e importação em um clique das credenciais ativas do VS Code.
*   **Histórico de Chat Persistente:** O histórico de conversas é salvo automaticamente localmente em formato JSON, restaurando o contexto ao fechar e abrir a IDE.
*   **Atalhos e Histórico de Prompts:** Atalhos integrados para aumentar a produtividade: `Ctrl + Enter` para enviar prompts, `Enter` para quebra de linha, e uso das setas `↑` (para cima) e `↓` (para baixo) na área de digitação para navegar rapidamente pelo histórico dos prompts que já foram digitados e enviados.
*   **Ações de Contexto no Editor:** Clique com o botão direito em qualquer trecho de código selecionado para:
    *   *Explicar Código Selecionado:* Analisar didaticamente a lógica.
    *   *Otimizar/Refatorar:* Melhorar a performance e aplicar princípios SOLID/Clean Code.
    *   *Gerar Testes Unitários:* Gerar estruturas prontas de testes usando DUnitX.
    *   *Localizar Bugs:* Buscar memory leaks, exceptions soltas e falhas de lógica.
*   **Comparador Visual Inteligente (Smart Diff):** Visualização de refatorações lado a lado (Original vs. Sugerido) com realce vermelho/verde e botão **[Aplicar Alteração]** de um clique direto no editor.
*   **Depurador de Compilação (Smart Build):** Integração com a aba *Messages* do Delphi. Clique com o botão direito nos erros de compilação da IDE para obter explicações e correções instantâneas.
*   **Documentação XML Automática:** Geração de comentários XML estruturados (`/// <summary>`) acima do cabeçalho de métodos para alimentar o Help Insight.
*   **Conversor de DTO e Modelos:** Geração automática e instantânea de classes (DTOs) e records Object Pascal a partir de JSON ou scripts de tabelas SQL (DDL), com suporte inteligente a DEXT ORM, TMS Aurelius, REST.Json e Vanilla Delphi.
*   **Comandos de Barra Customizáveis (Slash Commands):** Execução de ações rápidas digitando comandos no chat (ex: `/explain`, `/createprojectarch`). Permite cadastrar novos comandos dinâmicos associados a templates de prompts personalizados pelas opções do plugin.
*   **Biblioteca de Templates e Backup:** Interface para gerenciamento de prompts reutilizáveis com substituição inteligente de marcadores (`{code}`, `{specification}`) e diálogos para exportação e importação de backups (JSON) com suporte a mesclagem.
*   **Armazenamento Seguro de Chaves:** Credenciais criptografadas localmente via Windows DPAPI e salvas no Registro do Windows.
*   **Cancelamento de Requisições:** Botão de parada dinâmico redondo integrado na cápsula do prompt para interromper requisições assíncronas de forma segura. Ocorre também de forma automática ao criar, excluir ou alternar entre chats na barra lateral.

### 2.1 Tabela Completa de Recursos (Features)

Para conferir o status de desenvolvimento, atalhos de teclado, categorias e todos os provedores integrados em detalhes, consulte o nosso:

👉 [**Catálogo Completo de Recursos (docs/features.md)**](docs/features.md)

### 3. Como Funciona e Arquitetura
O RadIA é construído inteiramente em Object Pascal (Delphi) usando a **Open Tools API (OTA)** para interagir com o editor de código, gerenciamento de mensagens e detecção de temas da IDE.
A interface utiliza uma arquitetura híbrida:
1.  **VCL Nativa:** Gerencia o acoplamento da janela, a tela de configurações, ações de menus, gravação segura no registro e chamadas assíncronas.
2.  **Motor WebView2 (Edge):** Exibe as mensagens e respostas da IA utilizando HTML5, CSS e JS locais (Marked.js para Markdown e Prism.js para realce de sintaxe). A interface se adapta automaticamente ao tema da IDE (Light/Dark) e roda de forma fluida sem congelar a IDE.

### 4. Requisitos do Sistema
*   **IDE:** Embarcadero Delphi 10.4 Sydney, 11 Alexandria, 12 Athens ou 13 Florence (ou superior).
*   **OS:** Windows 10 / 11 (64-bit).
*   **Web Engine:** *Microsoft Edge WebView2 Runtime* instalado no sistema Windows (pré-instalado em versões modernas do Windows). **Importante:** A DLL `WebView2Loader.dll` correspondente à arquitetura da IDE (32-bit para Delphi 10.4, 64-bit para Delphi 11 e 12) deve estar presente na pasta `bin` da instalação do Delphi (ex: `C:\Program Files (x86)\Embarcadero\Studio\<versao>\bin`) ou no PATH do sistema.
### 5. Instalação e Configuração

O RadIA pode ser instalado de maneira **automatizada via PowerShell** (recomendado, com suporte a autodetecção de múltiplos ambientes Delphi e seleção interativa) ou **manualmente através da IDE**. Para instruções detalhadas de compilação, registro e configuração de chaves de API para todos os provedores ou uso local com o Ollama, consulte o nosso:

👉 [**Guia de Instalação e Configuração Completo (docs/install_config.md)**](docs/install_config.md)

### 5.1 Adicionando um Novo Provedor de IA (Arquitetura Plug-in)

O RadIA adota uma arquitetura de registro de provedores orientada a metadados (`TProviderRegistry`). Isso permite adicionar novos backends de IA de forma totalmente dinâmica e desacoplada. Para um tutorial passo a passo de como implementar sua classe de provedor e realizar o auto-registro, consulte o nosso:

👉 [**Guia para Adição de Novos Provedores (docs/new_provider_guide.md)**](docs/new_provider_guide.md)

### 5.2 Usando GitHub Copilot Remoto (Nativo - Fase 2) ou via Proxy Local (Fase 1)

O RadIA suporta a integração direta e remota com o **GitHub Copilot** na nuvem (sem necessidade de rodar proxies locais) a partir das opções do plugin, incluindo facilidades de login integrado por PIN e importação de chave do VS Code em um clique. 

Caso prefira rodar um proxy local compatível com a API da OpenAI (Fase 1), isso também continua suportado através do registro de provedor dinâmico em arquivo JSON. Para mais detalhes, consulte:

👉 [**Guia de Configuração do GitHub Copilot (docs/copilot_proxy_guide.md)**](docs/copilot_proxy_guide.md)

### 5.3 Guias de Uso e Referência de Recursos

Para aprender a tirar o máximo proveito das funcionalidades do RadIA no seu dia a dia de desenvolvimento, consulte os nossos manuais práticos e detalhados:

*   👉 [**Guia de Integração com Editor & Geração de Código (docs/user_guide_editor_generation.md)**](docs/user_guide_editor_generation.md): Ações contextuais de editor, comparador visual Smart Diff, documentação XML e criação de DTOs e projetos do zero.
*   👉 [**Guia de Diagnóstico de Erros & Análise de Código (docs/user_guide_diagnostics_analysis.md)**](docs/user_guide_diagnostics_analysis.md): Explicações e correções de erros com o Smart Build Debugger, decodificação de logs com o Assistente de Stack Trace e auditorias estáticas contra vazamento de memória.
*   👉 [**Guia do Painel de Chat & Gerenciamento de Sessões (docs/user_guide_chat_sessions.md)**](docs/user_guide_chat_sessions.md): Atalhos de digitação, histórico de prompts, múltiplas sessões persistentes e backups de templates.

---

### 6. Estrutura do Repositório
```
PluginDelphiIA/
│
├── docs/                               # Documentação e recursos visuais
│   ├── images/
│   │   ├── radia_ui_mockup.png         # Mockup do Chat na lateral da IDE
│   │   ├── radia_options_mockup.png    # Mockup da tela de configurações (Tools -> Options)
│   │   └── radia_diff_ui_mockup.png    # Mockup da tela de comparação Diff
│   ├── install_config.md               # Guia detalhado de instalação e chaves
│   ├── implementation_plan.md          # Plano detalhado de arquitetura
│   ├── radia_design_ui.md              # Especificação de layouts e fluxos de UI
│   ├── new_provider_guide.md           # Guia para criação de novos provedores de IA
│   └── task.md                         # Checklist de tarefas de desenvolvimento
│
├── RadIA.groupproj                     # Grupo de Projetos do Delphi
├── RadIA.dpk                           # Pacote Delphi de design-time
├── RadIA.dproj                         # Configurações do projeto de pacote
│
├── Source/
│   ├── Core/                           # Units centrais (Interfaces, tipos, configurações)
│   ├── Providers/                      # Clientes de API das IAs (Gemini, OpenAI, Claude)
│   ├── Integration/                    # Integração com a Open Tools API da IDE (Wizards, Hooks)
│   └── UI/                             # Formulários e Frames VCL
│       └── Web/                        # Template Web (HTML/CSS/JS) para WebView2
│
└── Tests/                              # Testes de Integração e Unitários (DUnitX)
```

### 7. Termos de Uso e Compliance Corporativo

Para diretrizes de conformidade corporativa (LGPD/GDPR), privacidade de dados, segurança de credenciais com Windows DPAPI e avisos legais sobre código gerado por IA, consulte o nosso:

👉 [**Guia de Termos de Uso, Compliance e Privacidade (docs/compliance.md)**](docs/compliance.md)
