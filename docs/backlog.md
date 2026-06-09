<div align="right">

[🇧🇷 Português](backlog.md) | [🇺🇸 English](backlog.en.md)

</div>

# Backlog de Evolução Futura do RadIA

Este documento registra as tarefas e ideias de evolução do plugin RadIA, detalhando o status de cada recurso.

---

## ✅ Itens Concluídos

### 1. Context Window Management (Trimming Automático) - Item #10
*   **Descrição**: Evita erros silenciosos de limite de tokens da API cortando mensagens antigas da conversa ativa quando atinge o limite máximo configurado.
*   **Detalhes**:
    *   Implementado campo `MaxHistoryMessages` nas configurações (Registro do Windows, padrão: 20).
    *   Orquestrador `TRadIAService.TrimHistory` corta as mensagens mais antigas preservando o prompt de sistema e as mensagens mais recentes.
    *   Validação robusta com 10 testes unitários específicos em `RadIA.Tests.Service.pas`.

### 2. Conversor de DTO e Modelos (JSON / DDL ➔ Delphi) - Item #22
*   **Descrição**: Geração automatizada de classes e records Object Pascal correspondentes a partir de JSON ou scripts SQL DDL, com suporte a DEXT ORM, Aurelius, REST.Json e Vanilla.
*   **Detalhes**:
    *   Desenvolvido gerador central `TRadIADTOBuilder` em `RadIA.Core.DTO.Generator.pas` com regras dinâmicas de conversão.
    *   Integração com DEXT ORM utilizando Smart Properties (`IntType`, `StringType`, etc.) e tratamento de relacionamentos Lazy (`ILazy<T>`, `TValueLazy<T>`) sem getters/setters desnecessários.
    *   Validação de geração robusta com 96 testes unitários em `RadIA.Tests.DTOGenerator.pas`.

### 3. Histórico de Prompts (Navegação ↑/↓) - Item #6
*   **Descrição**: Permite que o desenvolvedor navegue pelas últimas consultas enviadas utilizando as setas para cima/para baixo do teclado.
*   **Detalhes**:
    *   Criado o gerenciador `TPromptHistoryManager` limitando a 50 entradas persistidas em `%APPDATA%\RadIA\prompt_history.json`.
    *   Captura de teclado no `memPromptKeyDown` para navegação dinâmica de prompts.
    *   Validação com 13 testes unitários dedicados em `RadIA.Tests.PromptHistory.pas`.

### 3. Endpoints Compatíveis com OpenAI (LM Studio, Azure, Groq) - Item #8
*   **Descrição**: Suporte a qualquer provedor compatível com o protocolo da OpenAI apenas trocando a URL base.
*   **Detalhes**:
    *   Adicionado campo `Custom Base URL` nas configurações de OpenAI (`IAIConfig.OpenAICustomBaseUrl`).
    *   Os métodos de requisição e descoberta de modelos usam a URL personalizada quando fornecida.
    *   Validação com 3 testes unitários dedicados em `RadIA.Tests.Providers.pas`.

### 4. Rastreamento de Tokens - Item #14
*   **Descrição**: Exibe a contagem de tokens (Prompt e Completion) consumidos na barra de status da UI do Chat.
*   **Detalhes**:
    *   Implementado record `TTokenUsage` para contabilizar tokens de entrada/saída.
    *   Barra de status dinâmica em HTML/CSS/JS sincronizada com o Delphi.
    *   Validação com testes unitários em `RadIA.Tests.TokenUsage.pas`.

### 5. Exportar Conversa (.md / .html) - Item #7
*   **Descrição**: Permite salvar o histórico completo do chat ativo nos formatos Markdown ou HTML estruturado com um único clique.
*   **Detalhes**:
    *   Botão "Export" integrado à barra lateral e diálogo nativo de salvamento `TSaveDialog`.
    *   HTML standalone exportado com CSS embutido e Prism.js para highlight Pascal.
    *   Validação com 4 testes unitários em `RadIA.Tests.Exporter.pas`.

### 6. Templates de Prompt - Item #12
*   **Descrição**: Biblioteca de templates rápidos de prompt com substituição de código e slash command `/template`.
*   **Detalhes**:
    *   Menu dinâmico "Tpl" e comando de barra no chat.
    *   Substituição inteligente do marcador `{code}` pelo trecho de código selecionado na IDE.
    *   Validação com 4 testes unitários em `RadIA.Tests.Templates.pas`.

### 7. Contexto de Projeto (Arquivo `.radia`) - Item #11
*   **Descrição**: Permite customizar prompts de sistema e ler arquivos adicionais do projeto como contexto de IA.
*   **Detalhes**:
    *   Leitor `TProjectContextLoader` que detecta arquivos `.radia` na pasta raiz do projeto Delphi ativo via `IOTAProject`.
    *   Validação com 4 testes unitários em `RadIA.Tests.ProjectContext.pas`.

### 8. Streaming de Respostas (SSE) - Item #4
*   **Descrição**: Exibição incremental token a token (Server-Sent Events) no chat da IDE, otimizando a experiência do usuário.
*   **Detalhes**:
    *   Streaming SSE nativo implementado nos provedores: OpenAI, Gemini, Claude e Ollama.
    *   Uso de `TStreamingTargetStream` interceptando gravação HTTP em tempo real.
    *   Funções javascript `appendMessage`, `showTypingIndicator` e `hideTypingIndicator` integradas na WebView.
    *   Testes unitários dedicados em `RadIA.Tests.Streaming.pas` cobrindo comportamento incremental, buffers parciais e eventos de conclusão.

### 9. Integração com Modelos Locais (Ollama) + Histórico Persistente - Item #3
*   **Descrição**: Suporte nativo para modelos locais sem chaves pagas e restauração completa de histórico do chat.

### 10. Provedores Nativos: DeepSeek e Groq - Item #9
*   **Descrição**: Adicionado suporte nativo direto aos provedores DeepSeek e Groq com streaming SSE e autodescoberta dinâmica de modelos.
*   **Detalhes**:
    *   Criada unit `RadIA.Provider.DeepSeek.pas` para conexão com a API DeepSeek.
    *   Criada unit `RadIA.Provider.Groq.pas` para conexão com a API da Groq.
    *   Configurações estendidas para chaves de API com armazenamento seguro e DPAPI.
    *   Novos testes unitários em `RadIA.Tests.ProvidersEx.pas` cobrindo payload, parsing de response e fluxo SSE de streaming.

### 11. Cancelamento de Requisições de IA e Novo Design do Prompt - Item #17
*   **Descrição**: Permite que o desenvolvedor aborte chamadas HTTP de IA ativas de forma assíncrona instantaneamente e redesenha a caixa de entrada de chat no formato de uma cápsula flutuante moderna e responsiva.
*   **Detalhes**:
    *   Implementado o cancelamento de rede em nível de socket interceptando o callback `OnReceiveData` do `THTTPClient`.
    *   O botão de envio muda de função e ícone dinamicamente para stop (`■`) durante a chamada, e a UI exibe uma mensagem amigável sem erros de encoding.
    *   Fundo do painel de input configurado para transparência nativa (`ParentBackground := True`), com a cápsula (`shpInputBg`) e o memo (`memPrompt`) exibidos de forma destacada e contrastante.

### 12. Configurações Avançadas por Provedor de IA - Item #18
*   **Descrição**: Permite parametrizar valores de geração de IA como Temperatura e Max Tokens individualmente para cada provedor a partir de abas organizadas na tela de configurações.
*   **Detalhes**:
    *   Campos de edição e persistência dinâmica de parâmetros no Registro do Windows pela classe `TRadIAConfig`.
    *   Mapeamento e integração no payload de requisição HTTP JSON de todos os provedores suportados (Ollama, Gemini, OpenAI, Claude, Groq e DeepSeek).

### 13. Múltiplas Sessões de Chat - Item #5
*   **Descrição**: Permite organizar conversas por projeto, feature ou tarefa, sem perder o contexto de sessões anteriores.
*   **Detalhes**:
    *   Armazenamento persistente de sessões em `%APPDATA%\RadIA\sessions\<guid>.json` indexadas em `sessions_index.json` pela classe `TRadIASessionManager`.
    *   Painel lateral retrátil integrado na UI (`pnlSessions`) contendo `ListBox` e controles (Nova Sessão, Renomear, Excluir) com transição suave e botão de Toggle (☰) na barra de ferramentas.
    *   Validação robusta com testes unitários em `RadIA.Tests.Sessions.pas`.

### 14. Controle de Cota e Orçamento de Tokens Local - Item #19
*   **Descrição**: Permite configurar um limite mensal de tokens nas configurações do plugin para evitar surpresas no faturamento das chaves de API, acumulando o consumo localmente e bloqueando requisições.
*   **Detalhes**:
    *   Integração no Registro do Windows com redefinição mensal automática de cota de tokens.
    *   Controles visuais dinâmicos criados na aba de configurações do painel.
    *   Exibição do percentual de cota consumida na barra de status em HTML na WebView.
    *   Validação completa com testes unitários cobrindo o bloqueio e ciclos de cota em `RadIA.Tests.Quota.pas`.

### 15. Novo Layout de Configurações (Delphi-like) e Integração no Tools -> Options - Item #2
*   **Descrição**: Separação da tela de configuração em um frame reutilizável integrado nativamente no diálogo global da IDE (`Tools -> Options`), com visual estilizado e mapeamento dinâmico em árvore.
*   **Detalhes**:
    *   Implementação do frame `TFrameAIConfig` contendo o PageControl e controle das opções.
    *   Implementação do formulário wrapper `TFormAIConfig` contendo uma barra lateral com `TTreeView` e botões de rodapé para manter o comportamento original de popup independente.
    *   Integração da ponte Open Tools API via `TRadIAAddInOptions` (`INTAAddInOptions`) registrando a árvore de categorias sob **Third Party > RadIA** (com subnós para Gemini, OpenAI, Claude, DeepSeek, Groq, Ollama).
    *   Pintura e estilização automatizada seguindo o tema nativo da IDE usando painéis wrappers individuais para herança de estilo e prevenção de contraste inadequado de cores no tema escuro.
    *   Salvamento automatizado silencioso ao pressionar "OK" nas opções da IDE, e aviso explícito de sucesso apenas no formulário popup standalone.

### 16. Provedor Nativo: OpenRouter - Item #20
*   **Descrição**: Adicionado suporte nativo direto ao OpenRouter com streaming SSE, persistência no registro do Windows, armazenamento seguro de credenciais com DPAPI e listagem de modelos.
*   **Detalhes**:
    *   Criada a unit `RadIA.Provider.OpenRouter.pas` herdando de `TRadIAOpenAICompatibleProvider`.
    *   Mapeamento de `ptOpenRouter` no enum de provedores, configurações de chaves de API e modelos padrão (`google/gemini-2.5-pro`, `meta-llama/llama-3.3-70b-instruct`, `deepseek/deepseek-r1`).
    *   Adicionada aba `tsOpenRouter` com estilização e suporte de tema VCL para a tela de configurações.
    *   Novos testes unitários em `RadIA.Tests.ProvidersEx.pas` cobrindo geração de payloads, parsing de respostas e buffering SSE.

### 17. Infraestrutura de Provedores Dinâmicos e Simplificados (Plugin-like) - Item #21
*   **Descrição**: Refatoração da infraestrutura de IA para auto-registro dinâmico de backends de IA, removendo acoplamentos em cascata e enums estáticos.
*   **Detalhes**:
    *   Implementado o registro centralizado `TProviderRegistry` contendo metadados de provedores (`TProviderMetadata`) e delegação de factory functions.
    *   Implementado o auto-registro dos 7 provedores nativos (Gemini, OpenAI, Claude, Ollama, DeepSeek, Groq e OpenRouter) em suas seções `initialization`.
    *   Desacoplamento do orquestrador `TRadIAService` que agora resolve dinamicamente qualquer provedor a partir do `TProviderRegistry.CreateProvider` sem fallbacks estáticos em loops `case`.
    *   Adicionados novos testes unitários em `RadIA.Tests.Service.pas` cobrindo a integridade do registro e tratamento de erros.

### 18. Provedores Dinâmicos via JSON (Plug-ins sem Recompilação) - Item #21b
*   **Descrição**: Suporte para adicionar novos provedores compatíveis com a API OpenAI apenas colocando arquivos de configuração `.json` no AppData do RadIA, sem necessidade de recompilar o plugin.
*   **Detalhes**:
    *   Implementado escaneamento automático de diretório no `TProviderRegistry.LoadJsonProviders` lendo de `%APPDATA%\RadIA\providers\`.
    *   Criação de classe genérica polimórfica `TRadIAGenericOpenAIProvider` servindo como client universal de OpenAI.
    *   Tratamento de fallback da chave de API configurada opcionalmente no JSON e marcação do status dinâmico para listagem incondicional de provedores carregados no chat lateral.
    *   Nova suíte de testes unitários integrada em `RadIA.Tests.JSONProviders.pas`.

### 19. Provedor Nativo LM Studio - Item #21c
*   **Descrição**: Adicionado suporte nativo completo e opcional para o provedor local LM Studio com streaming SSE, autodescoberta de modelos locais e interface de opções.
*   **Detalhes**:
    *   Criada unit `RadIA.Provider.LMStudio.pas` contendo a classe do provedor e seu auto-registro no `TProviderRegistry`.
    *   Criada a aba dedicada do LM Studio no Frame de opções com estilização baseada no tema da IDE e persistência de URL.
    *   Refatorada a detecção no chat lateral para carregar o LM Studio dinamicamente como opcional (aparecendo se a URL for configurada no registro).
    *   Desenvolvidos novos testes unitários cobrindo a modelagem e streaming SSE da chamada no LM Studio em `RadIA.Tests.ProvidersEx.pas`.

### 20. Suporte a Múltiplas Versões do Delphi no Build - Item #27
*   **Descrição**: Melhoria na robustez do script de build e instalação (`build.ps1`) para suportar máquinas com múltiplos ambientes Delphi instalados, permitindo escolha via menu interativo ou parâmetro.
*   **Detalhes**:
    *   Implementado o parâmetro `-DelphiVersion` para forçar o uso de uma versão específica do Delphi.
    *   Implementada a varredura dinâmica no Registro do Windows (`HKCU:\Software\Embarcadero\BDS`) para mapear caminhos de instalação reais (`RootDir`) e nomes amigáveis.
    *   Desenvolvido menu interativo no console PowerShell para seleção de versão quando múltiplas IDEs forem detectadas durante a instalação/desinstalação.
    *   Dinamicização de todos os diretórios internos e caminhos da IDE baseados em `$rootDir` ao invés de caminhos estáticos globais no drive C:.

### 21. Conexão Híbrida e Login Web (Plus/Pro) - Item #28
*   **Descrição**: Implementação de modo complementar de conexão via Login Web em contas de consumidor (ChatGPT Plus/Pro e Gemini Advanced) com automação DOM e ponte JS, convivendo harmoniosamente com o modelo BYOK tradicional (API Keys).
*   **Detalhes**:
    *   Criação de chaves de configuração e seletor na interface de configurações ("Tools -> Options") por provedor.
    *   Desenvolvimento do script `bridge.js` para controle de input/output do DOM, injeção de CSS para ocultação de elementos desnecessários do site oficial e monitoramento de stream.
    *   Criação do provedor virtual `TRadIAWebViewBridgeProvider` para orquestração síncrona/assíncrona de requisições de IA para a janela ativa do WebView2.
    *   Configuração do User-Agent seguro do Chromium para prevenção de bloqueios OAuth durante o fluxo de autenticação do Google.

### 22. Provedor Nativo GitHub Copilot (Fase 2) - Item #29
*   **Descrição**: Suporte nativo à nuvem do GitHub Copilot com autenticação integrada (Device Flow por PIN) e importação em um clique de chaves do VS Code, além de atalhos rápidos de hyperlink para obtenção de API Keys dos demais provedores.
*   **Detalhes**:
    *   Desenvolvimento da unit `RadIA.Provider.GithubCopilot.pas` contendo a classe do provedor e seu auto-registro, além do gerenciamento thread-safe do token de sessão temporário obtido de `https://api.github.com/copilot_internal/v2/token`.
    *   Desenvolvimento da unit de UI `RadIA.UI.GithubAuthForm.pas` para o fluxo de autenticação por PIN em segundo plano.
    *   Modificações no frame e formulário de configurações VCL para inclusão da aba do Copilot com botões de login/importação e dos links rápidos de atalho para as demais plataformas.

### 23. Provedores Nativos Adicionais (Azure OpenAI, Alibaba Qwen e Mistral AI) - Itens #30, #31, #32
*   **Descrição**: Adicionado suporte direto e nativo para as APIs oficiais do Azure OpenAI, Alibaba Qwen (ModelStudio) e Mistral AI, com abas dedicadas de configuração, links de atalho para chaves de API, suporte a streaming SSE e ordenação customizada de provedores na interface.
*   **Detalhes**:
    *   Desenvolvimento das classes de provedores `TRadIAAzureOpenAIProvider`, `TRadIAQwenProvider` e `TRadIAMistralProvider` integradas de forma desacoplada no `TProviderRegistry`.
    *   Mapeamento de chaves de API seguras via Windows DPAPI e parâmetros específicos (como `AzureApiVersion`).
    *   Criação das abas de opções VCL Claro/Escuro para cada provedor na IDE (`Tools -> Options`) e formulário de configurações.
    *   Implementação de ordenação personalizada em `TProviderRegistry.GetProviders` para manter **Ollama** e **LM Studio** sempre no final de todas as listagens de provedores.
    *   Validação com novos testes unitários em `RadIA.Tests.ProvidersEx.pas` e correções de mocks de configuração em `RadIA.Tests.Service.pas`.


### 24. Provedor Nativo AWS Bedrock com Assinatura SigV4 e Parser EventStream - Item #33
*   **Descrição**: Suporte nativo completo ao provedor AWS Bedrock, utilizando assinaturas criptográficas AWS Signature Version 4 (SigV4) e decodificação sob demanda do stream binário no padrão AWS EventStream.
*   **Detalhes**:
    *   Desenvolvimento da classe do provedor `TRadIABedrockProvider` na unit `RadIA.Provider.Bedrock.pas` integrado ao barramento central.
    *   Desenvolvimento do utilitário criptográfico `TAwsSigV4Signer` na unit `RadIA.Core.AwsSigner.pas` para cálculo SHA-256 e HMAC-SHA-256 das assinaturas SigV4 exigidas pelos cabeçalhos da Amazon.
    *   Implementação do parser binário `TAwsEventStreamParser` para ler de forma incremental e decodificar payloads binários do tipo EventStream transmitidos nas respostas assíncronas do Bedrock.
    *   Criação da aba VCL correspondente na interface de opções da IDE do Delphi com campos persistidos criptograficamente para as chaves IAM da AWS (Access Key, Secret Key, Region e Session Token).
    *   Inclusão de novos testes unitários em `RadIA.Tests.ProvidersEx.pas`, totalizando a aprovação de **112 testes verdes** na suite completa de testes.

### 25. Geração de Projeto Completo (Prompt-Based) - Item #24b
*   **Descrição**: Criação automatizada de projetos Delphi completos baseados em especificações textuais de chat, salvando-os em discos e abrindo-os de forma automática na IDE.
*   **Detalhes**:
    *   Desenvolvimento do serviço transacional `TRadIAProjectGenerator` em `RadIA.Core.ProjectGenerator.pas`.
    *   Exigência de pasta limpa/vazia para salvamento e tratamento transacional (rollback em caso de falha de gravação de arquivos).
    *   Parser e renderização visual premium dos arquivos gerados na interface WebView2 com atalhos de navegação e destaque na tela.

### 26. Assistente de Stack Trace, Análise Estática de Código e Menu Popup - Itens #23, #24, #25
*   **Descrição**: Lançamento dos comandos de barra integrados `/stacktrace` e `/bugs`, juntamente com menu flutuante de sugestões de autocompletar ao digitar `/` no chat.
*   **Detalhes**:
    *   Mapeamento estático e dinâmico de prompts, com injeção automática de contexto do editor (código da unit ativa ou trechos selecionados).
    *   Popup flutuante de sugestões renderizado com suporte a teclado (`↑`/`↓`/`Enter`/`Esc`) e cliques no mouse no chat do WebView2.

### 27. Templates Dinâmicos, Backup de Prompt e Nova Arquitetura - Item #12b
*   **Descrição**: Customização dinâmica total de prompts/templates e slash commands, com diálogos de importação/exportação na VCL e suporte à arquitetura limpa (SOLID).
*   **Detalhes**:
    *   Remoção de condicionais rígidos no Delphi no processamento de slash commands; varredura totalmente dinâmica pela classe `TPromptTemplateManager` com placeholders (`{code}`, `{specification}`, `{stacktrace}`, `{argument}`).
    *   Diálogos de importação/exportação com verificação transacional JSON de estrutura de arquivos e opções de mesclar (*Merge*) ou sobrescrever (*Overwrite*).
    *   Lançamento do template nativo `'Create Project Delphi Architecture'` (`/createprojectarch`) incorporando injeção de dependências, injeção sistemática de blocos `try..finally` e guia de nomenclatura Pascal.
    *   Atualização da cobertura de testes unitários em `RadIA.Tests.Templates.pas` cobrindo fluxos de backup e esquema.

### 28. Arquitetura de Templates Segregada (Nativo vs. Usuário com Overlays) - Item #12c
*   **Descrição**: Segregação de templates padrões embutidos dos customizados em disco, permitindo atualizações automáticas do plugin sem sobrescrever personalizações do usuário, com suporte a overlays e restauração de fábrica.
*   **Detalhes**:
    *   Carregamento em duas camadas com mesclagem em runtime no `TPromptTemplateManager`.
    *   Limpeza automática de templates redundantes não modificados no AppData do usuário (`CleanRedundantUserTemplates`).
    *   Tela de opções aprimorada com legendas de origem (`lblTemplateOrigin`) e lógica contextual de exclusão/restauração.
    *   Suíte de testes unitários expandida com 116 testes DUnitX aprovados com sucesso.

---

## ⏳ Em Desenvolvimento

*   *Nenhum item em desenvolvimento ativo no momento.*

---

## 🔲 Pendentes

### 1. Painel de Gerenciamento do Cache (Item #13)
*   **Objetivo**: Dar visibilidade e controle sobre o cache de respostas sem precisar editar o arquivo JSON manualmente.

### 2. Revisão Automática de Código no Save (Item #15)
*   **Objetivo**: Analisar a unit silenciosamente ao salvar e sinalizar no painel do RadIA se a IA encontrou pontos de atenção.

### 3. Histórico de Refatorações Aplicadas (Item #16)
*   **Objetivo**: Manter um log auditável de todas as vezes que o botão [Aplicar Alteração] foi acionado, permitindo revisão e desfazimento manual.

### 4. Autocompletar Inline Inteligente (Ghost Text) (Item #26)
*   **Objetivo**: Sugestões de código em tempo real no editor de código com texto acinzentado estilo Copilot/Cursor.
*   **Nota de Arquitetura**: A pesquisa técnica e prototipagem na ToolsAPI (utilizando `INTAEditViewNotifier.PaintLine`, isolamento de Canvas GDI com `SaveDC`/`RestoreDC`, debounce síncrono e interceptação de teclas VK_TAB/VK_ESCAPE com `IOTAKeyboardBinding`) foram concluídas. O desenvolvimento foi temporariamente pausado devido a restrições no ciclo de repaints síncronos da IDE que afetam a estabilidade do cursor nativo em High DPI. Os módulos foram arquivados para futura evolução quando novas APIs de pintura assíncrona da Embarcadero forem avaliadas.



