<div align="right">

[🇧🇷 Português](README.md) | [🇺🇸 English](README.en.md) | [🗺️ Roadmap](ROADMAP.md)

</div>

# RadIA - Assistente de IA para Delphi IDE

**RadIA** é um plugin assistente de IA avançado projetado especificamente para a IDE do Embarcadero Delphi (usando a Open Tools API). Ele se acopla diretamente à barra lateral da IDE, fornecendo uma interface de chat interativa e integração contextual profunda com o editor de código para acelerar o desenvolvimento, refatoração e depuração.

<p align="center">
  <img src="docs/images/radia_ui_mockup.png" alt="RadIA Chat Panel Mockup" width="45%" />
  &nbsp;&nbsp;
  <img src="docs/images/radia_diff_ui_mockup.png" alt="RadIA Diff View Mockup" width="45%" />
</p>

---

### 1. Padrão de Linguagem
*   **Documentação (README / Docs):** Disponível em Português (padrão) e Inglês (alternativo).
*   **Código Fonte:** 100% escrito em **Inglês** (nomes, units, variáveis, classes, métodos e comentários de código) seguindo o clean code e os padrões Pascal.

### 2. Funcionalidades
*   **Chat Lateral Acoplável (Dockable):** Painel integrado à IDE com visual nativo do Delphi, trazendo uma janela de chat em HTML5/JS moderno (WebView2) com suporte a Markdown e realce de sintaxe Pascal.
*   **Suporte a Múltiplas IAs:** Modelo de uso de chaves próprias (BYOK) com suporte nativo ao **Google Gemini**, **OpenAI ChatGPT**, **Anthropic Claude**, **DeepSeek**, **Groq** e modelos locais/rede via **Ollama** (ex: Llama 3, Phi-3, Mistral, CodeLlama).
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
*   **Comandos de Barra (Slash Commands):** Ações rápidas digitando comandos no chat (ex: `/doc`, `/explain`, `/refactor`, `/bugs`).
*   **Armazenamento Seguro de Chaves:** Credenciais criptografadas localmente via Windows DPAPI e salvas no Registro do Windows.
*   **Cancelamento de Requisições:** Botão de parada dinâmico redondo integrado na cápsula do prompt para interromper requisições assíncronas de forma segura. Ocorre também de forma automática ao criar, excluir ou alternar entre chats na barra lateral.

### 2.1 Tabela Completa de Recursos (Features)

| Recurso | Categoria | Descrição | Status |
| :--- | :--- | :--- | :--- |
| **Chat Lateral Acoplável** | Chat UX | Painel integrado à IDE rodando WebView2 com suporte a Markdown e Pascal highlight. | ✅ Concluído |
| **Atalhos de Teclado** | Chat UX | Atalho `Ctrl + Enter` para enviar prompts e `Enter` para quebra de linha. | ✅ Concluído |
| **Persistência de Layout** | Chat UX | Salvamento e restauração automática de tamanho/posição flutuante e visibilidade no startup. | ✅ Concluído |
| **Streaming de Respostas** | Chat UX | Respostas incrementais token a token (SSE) nos provedores OpenAI, Gemini, Claude e Ollama. | ✅ Concluído |
| **Múltiplas Sessões de Chat** | Chat UX | Criação, renomeação, exclusão e isolamento de conversas em barra lateral retrátil (bloqueadas durante requisições ativas). | ✅ Concluído |
| **Histórico de Chat Persistente** | Chat UX | Salvamento automático e restauração de sessões anteriores de chat em JSON. | ✅ Concluído |
| **Histórico de Prompts (↑/↓)** | Chat UX | Navegação rápida pelos prompts enviados anteriormente usando as setas do teclado. | ✅ Concluído |
| **Cancelamento de Requisições** | Chat UX | Permite abortar chamadas ativas de IA de forma assíncrona (com botão stop ou automaticamente ao alternar/criar chats). | ✅ Concluído |
| **Exportação de Conversa** | Chat UX | Botão para salvar histórico nos formatos Markdown (.md) ou HTML autônomo com Prism.js. | ✅ Concluído |
| **Templates de Prompt** | Chat UX | Biblioteca de templates (Clean Code, DUnitX, Documentação) com slash command `/template`. | ✅ Concluído |
| **Google Gemini** | Provedor | Suporte nativo aos modelos Gemini 1.5 Flash e Pro via chaves próprias (BYOK). | ✅ Concluído |
| **OpenAI ChatGPT** | Provedor | Suporte nativo aos modelos GPT-4o, GPT-4o-mini e outros. | ✅ Concluído |
| **Anthropic Claude** | Provedor | Suporte nativo aos modelos Claude 3 Haiku e Claude 3.5 Sonnet. | ✅ Concluído |
| **DeepSeek** | Provedor | Suporte nativo aos modelos DeepSeek Chat e Reasoning via chaves próprias (BYOK). | ✅ Concluído |
| **Groq** | Provedor | Suporte nativo aos modelos Llama, Mixtral e Gemma na nuvem ultrarrápida da Groq via chaves próprias (BYOK). | ✅ Concluído |
| **Ollama Local/Rede** | Provedor | Integração com modelos locais open-source sem chaves pagas e autodescoberta de tags. | ✅ Concluído |
| **Custom Base URL** | Provedor | Suporte a qualquer endpoint compatível com OpenAI (Groq, DeepSeek, LM Studio). | ✅ Concluído |
| **Contexto de Projeto** | Inteligência | Carregamento automático de instruções de system e arquivos de contexto via `.radia`. | ✅ Concluído |
| **Rastreamento de Tokens e Custo**| Transparência | Contador dinâmico de consumo e custo acumulado estimado em USD (locale invariant). | ✅ Concluído |
| **Limite de Cota Local** | Transparência | Definição de limite de tokens mensal com bloqueio de chamadas e botão de reset. | ✅ Concluído |
| **Ações no Editor** | Integração | Explicação de código, otimização, testes e bugs com botão direito no editor. | ✅ Concluído|
| **Smart Diff (Comparador)** | Integração | Visualização lado a lado de código sugerido vs. original com aplicação instantânea. | ✅ Concluído |
| **Smart Build Debugger** | Integração | Clique com o botão direito nos erros de compilação da IDE para correções instantâneas. | ✅ Concluído |
| **Documentação XML Automática** | Geração | Geração automática de comentários `/// <summary>` sobre os métodos da unit. | ✅ Concluído |
| **Armazenamento Seguro** | Segurança | Chaves de API salvas localmente criptografadas usando a API do Windows DPAPI. | ✅ Concluído |

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

O RadIA pode ser instalado de maneira **automatizada via PowerShell** (recomendado) ou **manualmente através da IDE**. Para instruções detalhadas de compilação, registro e configuração de chaves de API para todos os provedores ou uso local com o Ollama, consulte o nosso:

👉 [**Guia de Instalação e Configuração Completo (docs/install_config.md)**](docs/install_config.md)

---

### 6. Estrutura do Repositório
```
PluginDelphiIA/
│
├── docs/                               # Documentação e recursos visuais
│   ├── images/
│   │   ├── radia_ui_mockup.png         # Mockup do Chat na lateral da IDE
│   │   └── radia_diff_ui_mockup.png    # Mockup da tela de comparação Diff
│   ├── install_config.md               # Guia detalhado de instalação e chaves
│   ├── implementation_plan.md          # Plano detalhado de arquitetura
│   ├── radia_design_ui.md              # Especificação de layouts e fluxos de UI
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

### 7. Princípios de Desenvolvimento
Este projeto adota rigidamente:
*   Princípios de design **SOLID**.
*   Práticas de **Clean Code** com total isolamento em threads (thread-safety).
*   Princípios **DRY** (Don't Repeat Yourself) e **KISS** (Keep It Simple, Stupid).
*   Uso exclusivo do idioma **Inglês** para todo código fonte do projeto.

### 8. Termos de Uso e Compliance Corporativo

*   **Aviso de Marcas Registradas (Trademark Disclaimer):** Todas as marcas mencionadas (Delphi, Windows, WebView2, Gemini, OpenAI, Claude, DeepSeek, Groq e Ollama) pertencem aos seus respectivos proprietários. A menção a elas serve apenas para fins de descrição de compatibilidade.
*   **Revisão Obrigatória de Código:** O RadIA gera sugestões baseando-se em modelos de terceiros que podem conter falhas. O usuário é o único responsável por validar e testar qualquer sugestão gerada antes de utilizá-la em produção.
*   **Privacidade de Dados:** Para código proprietário restrito ou sob normas de compliance corporativo (como LGPD/GDPR), **recomendamos utilizar o Ollama local**. Rodando de forma offline, o RadIA processará suas solicitações localmente sem enviar dados para APIs na nuvem.
*   **Segurança de Credenciais:** As chaves de API são salvas localmente criptografadas usando a API do Windows DPAPI e gravadas no Registro do Windows do usuário. Nenhuma credencial é enviada para servidores de telemetria ou terceiros.
*   **Envio de Dados para Nuvem:** Ao utilizar provedores de nuvem (Google Gemini, OpenAI, Anthropic, DeepSeek ou Groq), trechos do seu código-fonte selecionado e informações contextuais do projeto serão enviados para os respectivos servidores externos para processamento. Para uso corporativo com código confidencial sob restrições rígidas, recomendamos o uso do Ollama local.
