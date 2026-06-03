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

### 2. Histórico de Prompts (Navegação ↑/↓) - Item #6
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

---

## 🔲 Pendentes

### 1. Múltiplas Sessões de Chat (Item #5)
*   **Objetivo**: Permitir que o desenvolvedor organize conversas por projeto, feature ou tarefa, sem perder o contexto de sessões anteriores.
*   **Detalhamento**:
    *   Armazenar sessões em `%APPDATA%\RadIA\sessions\<id>.json`, cada uma com nome, data e array de mensagens.
    *   Adicionar painel lateral (ou dropdown) para listar, criar, renomear e excluir sessões.
    *   Botão "Nova Sessão" salva a corrente e abre uma vazia.

### 2. Painel de Gerenciamento do Cache (Item #13)
*   **Objetivo**: Dar visibilidade e controle sobre o cache de respostas sem precisar editar o arquivo JSON manualmente.

### 3. Revisão Automática de Código no Save (Item #15)
*   **Objetivo**: Analisar a unit silenciosamente ao salvar e sinalizar no painel do RadIA se a IA encontrou pontos de atenção.

### 4. Histórico de Refatorações Aplicadas (Item #16)
*   **Objetivo**: Manter um log auditável de todas as vezes que o botão [Aplicar Alteração] foi acionado, permitindo revisão e desfazimento manual.

### 5. Controle de Cota e Orçamento de Tokens Local
*   **Objetivo**: Permitir que o desenvolvedor estabeleça um limite de consumo de tokens mensal local para evitar surpresas no faturamento de suas chaves de API.
*   **Detalhamento**:
    *   Adicionar campo nas configurações de limite de tokens (ex: cota mensal de 1.000.000 de tokens).
    *   Armazenar e acumular o consumo de forma persistente localmente.
    *   Exibir percentual de consumo na barra de status do chat lateral e alertar/bloquear chamadas ao atingir 100% da cota definida.
