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

### 4. Rastreamento de Tokens e Custo Estimado - Item #14
*   **Descrição**: Exibe a contagem de tokens e estimativa de custos USD da sessão atual na barra de status da UI do Chat.
*   **Detalhes**:
    *   Implementado record `TTokenUsage` e cálculo em `TPricingManager` respeitando localidade invariant (USD).
    *   Barra de status dinâmica em HTML/CSS/JS sincronizada com o Delphi.
    *   Validação com 6 testes unitários em `RadIA.Tests.TokenUsage.pas`.

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

---

## 🔲 Pendentes

### 1. Automatização de DevOps (CI/CD Pipeline)
*   **Objetivo**: Compilar e empacotar o plugin automaticamente a cada nova versão, evitando processos manuais de geração de binários.
*   **Detalhamento**:
    *   Criar um workflow do GitHub Actions rodando em agentes Windows (`windows-latest`).
    *   Configurar a instalação de ferramentas de build do Delphi ou MSBuild via scripts.
    *   Compilar o pacote `RadIA.dpk` e o projeto de testes unitários.
    *   Executar os testes unitários (`RadIATests.exe`) de forma automatizada na pipeline e barrar o deploy se algum teste falhar.
    *   Compactar o binário compilado `.bpl`, o arquivo de símbolos `.dcp`, a DLL `WebView2Loader.dll` e os recursos web (`Web/*`) em um pacote de distribuição `.zip`.

### 2. Instalador Automatizado (Inno Setup)
*   **Objetivo**: Fornecer uma experiência de instalação fluida ("One-Click Install") para desenvolvedores que desejam apenas utilizar o plugin, sem a necessidade de compilar o código fonte.
*   **Detalhamento**:
    *   Criar um script Inno Setup (`installer.iss`) para empacotar o plugin.
    *   O instalador deve escanear o Registro do Windows para detectar as versões instaladas do Delphi (ex: `Software\Embarcadero\BDS\23.0`).
    *   Copiar a BPL apropriada do diretório de output para o diretório de destino do usuário.
    *   Registrar a BPL no Delphi adicionando uma nova entrada do tipo String no Registro sob a chave `Software\Embarcadero\BDS\<versao>\Known Packages` com o caminho completo da BPL instalada.
    *   Copiar automaticamente a DLL do WebView2 (`WebView2Loader.dll`) e os recursos web (`chat.html`, `chat.css`, etc.) para o local apropriado (pasta `%APPDATA%\RadIA\Web`).

### 3. Múltiplas Sessões de Chat (Item #5)
*   **Objetivo**: Permitir que o desenvolvedor organize conversas por projeto, feature ou tarefa, sem perder o contexto de sessões anteriores.
*   **Detalhamento**:
    *   Armazenar sessões em `%APPDATA%\RadIA\sessions\<id>.json`, cada uma com nome, data e array de mensagens.
    *   Adicionar painel lateral (ou dropdown) para listar, criar, renomear e excluir sessões.
    *   Botão "Nova Sessão" salva a corrente e abre uma vazia.

### 4. Provedores Nativos: DeepSeek e Groq (Item #9)
*   **Objetivo**: Adicionar provedores dedicados com suas particularidades de autenticação e endpoints para melhor UX e maior precisão de configuração.
*   **Detalhamento**:
    *   `RadIA.Provider.DeepSeek.pas`: endpoint `https://api.deepseek.com/v1/chat/completions`, header `Authorization: Bearer`.
    *   `RadIA.Provider.Groq.pas`: endpoint `https://api.groq.com/openai/v1/chat/completions`, header `Authorization: Bearer`.

### 5. Painel de Gerenciamento do Cache (Item #13)
*   **Objetivo**: Dar visibilidade e controle sobre o cache de respostas sem precisar editar o arquivo JSON manualmente.

### 6. Revisão Automática de Código no Save (Item #15)
*   **Objetivo**: Analisar a unit silenciosamente ao salvar e sinalizar no painel do RadIA se a IA encontrou pontos de atenção.

### 7. Histórico de Refatorações Aplicadas (Item #16)
*   **Objetivo**: Manter um log auditável de todas as vezes que o botão [Aplicar Alteração] foi acionado, permitindo revisão e desfazimento manual.
