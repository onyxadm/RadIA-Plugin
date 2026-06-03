# Backlog de Evolução Futura do RadIA

Este documento registra as tarefas e ideias de evolução futura do plugin RadIA, planejadas para desenvolvimento posterior.

---

## ✅ Itens Concluídos

### 3. Integração com Modelos Locais (Ollama) + Histórico Persistente
> **Entregue nos commits `fd483b6` e `0dfcf10`**

*   ✅ **Provedor Ollama:** Suporte completo para rodar modelos open-source (Llama 3, Phi-3, Mistral, CodeLlama etc.) via API local do Ollama, tanto na mesma máquina (`localhost`) quanto em servidores na rede local, sem dependência de APIs pagas.
*   ✅ **Descoberta Dinâmica de Modelos:** O plugin consulta automaticamente `/api/tags` para listar os modelos instalados no servidor Ollama, com fallback para lista de modelos conhecidos.
*   ✅ **Configuração de URL:** Campo dedicado nas configurações do plugin para definir o endereço do servidor Ollama (padrão: `http://localhost:11434`).
*   ✅ **Histórico de Conversas Persistente:** O histórico do chat é salvo automaticamente em `%APPDATA%\RadIA\history.json` (formato JSON), restaurado integralmente ao reabrir a IDE. O botão **Clear** apaga o arquivo físico.

---

## 🔲 Pendentes

### 1. Automatização de DevOps (CI/CD Pipeline)
*   **Objetivo**: Compilar e empacotar o plugin automaticamente a cada nova versão, evitando processos manuais de geração de binários.
*   **Detalhamento**:
    *   Criar um workflow do GitHub Actions rodando em agentes Windows (`windows-latest`).
    *   Configurar a instalação de ferramentas de build do Delphi ou MSBuild via scripts.
    *   Compilar o pacote `RadIA.dpk` e o projeto de testes unitários para a versão ativa (e outras versões suportadas da IDE).
    *   Executar os testes unitários (`RadIATests.exe`) de forma automatizada na pipeline e barrar o deploy se algum teste falhar.
    *   Compactar o binário compilado `.bpl`, o arquivo de símbolos `.dcp`, a DLL `WebView2Loader.dll` e os recursos web (`Web/*`) em um pacote de distribuição `.zip` associado à tag/release do GitHub.

---

### 2. Instalador Automatizado (Inno Setup)
*   **Objetivo**: Fornecer uma experiência de instalação fluida ("One-Click Install") para desenvolvedores que desejam apenas utilizar o plugin, sem a necessidade de compilar o código fonte.
*   **Detalhamento**:
    *   Criar um script Inno Setup (`installer.iss`) para empacotar o plugin.
    *   O instalador deve escanear o Registro do Windows para detectar as versões instaladas do Delphi (ex: `Software\Embarcadero\BDS\23.0`).
    *   Copiar a BPL apropriada do diretório de output para o diretório de destino do usuário.
    *   Registrar a BPL no Delphi adicionando uma nova entrada do tipo String no Registro sob a chave `Software\Embarcadero\BDS\<versao>\Known Packages` com o caminho completo da BPL instalada.
    *   Copiar automaticamente a DLL do WebView2 (`WebView2Loader.dll`) e os recursos web (`chat.html`, `chat.css`, etc.) para o local apropriado (pasta `%APPDATA%\RadIA\Web`).

---

## 💬 UX do Chat

### 4. Streaming de Respostas (SSE)
*   **Objetivo**: Exibir as respostas token a token (como no ChatGPT), tornando a experiência muito mais fluida, especialmente para respostas longas.
*   **Detalhamento**:
    *   Gemini, OpenAI, Claude e Ollama suportam streaming via `text/event-stream` (SSE).
    *   Substituir `stream: false` por `stream: true` nos providers.
    *   Implementar parser de SSE em cada provider — acumular chunks e enviar incrementalmente para o WebView via `PostToWebView('append_message', ...)`.
    *   Adicionar ação `append_message` no `chat.js` para concatenar ao balão atual em vez de criar um novo.
    *   Adicionar indicador visual de "digitando..." enquanto o stream está em progresso.

### 5. Múltiplas Sessões de Chat
*   **Objetivo**: Permitir que o desenvolvedor organize conversas por projeto, feature ou tarefa, sem perder o contexto de sessões anteriores.
*   **Detalhamento**:
    *   Armazenar sessões em `%APPDATA%\RadIA\sessions\<id>.json`, cada uma com nome, data e array de mensagens.
    *   Adicionar painel lateral (ou dropdown) para listar, criar, renomear e excluir sessões.
    *   Botão "Nova Sessão" salva a corrente e abre uma vazia.
    *   Sessão ativa persiste no Registro (`ActiveSessionId`).

### 6. Histórico de Prompts (Navegação ↑/↓)
*   **Objetivo**: Navegar pelos últimos N prompts enviados com a seta para cima no campo de entrada — padrão de terminal, extremamente útil no dia a dia.
*   **Detalhamento**:
    *   Manter um `TList<string>` de prompts da sessão em memória.
    *   Interceptar `KeyDown` no `memPrompt`: seta ↑ carrega prompt anterior, seta ↓ avança.
    *   Opcional: persistir os últimos 50 prompts entre sessões em `%APPDATA%\RadIA\prompt_history.json`.

### 7. Exportar Conversa
*   **Objetivo**: Exportar o histórico atual para `.md` ou `.html` com um clique — útil para documentar sessões de refatoração ou design review.
*   **Detalhamento**:
    *   Botão "Export" no toolbar do chat.
    *   Gerar arquivo `.md` com cabeçalho (data, provedor, modelo) e as mensagens formatadas.
    *   Abrir diálogo `TSaveDialog` para o usuário escolher o destino.
    *   Opção secundária: exportar como `.html` standalone com os estilos embutidos.

---

## 🤖 Provedores e Modelos

### 8. Endpoints Compatíveis com OpenAI (LM Studio, vLLM, Azure OpenAI, Groq, DeepSeek)
*   **Objetivo**: Suportar qualquer servidor que implemente a API da OpenAI com zero código extra — basta alterar a URL base.
*   **Detalhamento**:
    *   Adicionar campo `Custom Base URL` na seção OpenAI do ConfigFrame.
    *   Quando preenchido, substituir `https://api.openai.com` pelo endpoint informado.
    *   Colocar exemplos no tooltip: `http://localhost:1234/v1` (LM Studio), `https://api.groq.com/openai/v1` (Groq), `https://<resource>.openai.azure.com/openai` (Azure).
    *   Isso cobre LM Studio, vLLM, Groq, DeepSeek e Azure OpenAI sem nenhuma unit extra.

### 9. Provedores Nativos: DeepSeek e Groq
*   **Objetivo**: Adicionar provedores dedicados com suas particularidades de autenticação e endpoints para melhor UX e maior precisão de configuração.
*   **Detalhamento**:
    *   `RadIA.Provider.DeepSeek.pas`: endpoint `https://api.deepseek.com/v1/chat/completions`, header `Authorization: Bearer`.
    *   `RadIA.Provider.Groq.pas`: endpoint `https://api.groq.com/openai/v1/chat/completions`, header `Authorization: Bearer`. Listar modelos disponíveis via `GET /openai/v1/models`.
    *   Adicionar `ptDeepSeek` e `ptGroq` ao enum `TAIProviderType`.

---

## 🧠 Contexto e Inteligência

### 10. Context Window Management (Trimming Automático)
*   **Objetivo**: Evitar erros silenciosos causados pelo crescimento ilimitado do `FHistory` ao atingir o limite de tokens do modelo.
*   **Detalhamento**:
    *   Adicionar campo `MaxHistoryMessages` configurável (padrão: 20 pares).
    *   Ao montar o payload de envio, se `Length(FHistory) > MaxHistoryMessages * 2`, truncar as mensagens mais antigas preservando sempre o system prompt.
    *   Exibir um aviso sutil no chat quando o histórico for truncado.
    *   Opcional: implementar contagem aproximada de tokens (palavras × 1.3) para limitar por tokens em vez de por número de mensagens.

### 11. Contexto de Projeto (Arquivo `.radia`)
*   **Objetivo**: Permitir que cada projeto defina um system prompt e lista de arquivos de contexto próprios, carregados automaticamente ao abrir o projeto na IDE.
*   **Detalhamento**:
    *   Formato JSON: `{ "system_prompt": "...", "context_files": ["Unit1.pas", "DataModule.pas"] }`.
    *   O plugin detecta o arquivo `.radia` na raiz do projeto ativo via `IOTAProject`.
    *   Conteúdo dos arquivos listados é concatenado ao system prompt como contexto adicional.
    *   Forma simplificada de RAG sem dependência de embeddings.

### 12. Templates de Prompt
*   **Objetivo**: Biblioteca de templates pré-definidos e editáveis pelo usuário para as tarefas mais comuns, acessíveis rapidamente.
*   **Detalhamento**:
    *   Templates padrão incluídos: "Revisar segundo Clean Code Delphi", "Documentar unit completa", "Criar mock DUnitX", "Analisar performance".
    *   Armazenados em `%APPDATA%\RadIA\templates.json` (editáveis pelo usuário).
    *   Acessíveis via dropdown na toolbar ou slash command `/template <nome>`.

---

## 📊 Transparência e Controle

### 13. Painel de Gerenciamento do Cache
*   **Objetivo**: Dar visibilidade e controle sobre o cache de respostas sem precisar editar o arquivo JSON manualmente.
*   **Detalhamento**:
    *   Nova aba ou janela acessível via Settings: lista de entradas do cache com hash, data, tamanho da resposta.
    *   Busca por texto no prompt.
    *   Botão para deletar entradas individualmente ou limpar tudo.
    *   Exibir estatísticas: total de entradas, taxa de acerto, espaço em disco ocupado.

### 14. Rastreamento de Tokens e Custo Estimado
*   **Objetivo**: Informar o desenvolvedor sobre o consumo de tokens e custo estimado por sessão, especialmente importante para quem usa APIs pagas.
*   **Detalhamento**:
    *   Extrair `usage.prompt_tokens` e `usage.completion_tokens` das respostas da API (Gemini, OpenAI, Claude retornam isso no JSON).
    *   Exibir no rodapé do chat: `↑ 512 tokens · ↓ 1024 tokens · ~$0.002`.
    *   Acumulado da sessão com reset ao limpar o chat.
    *   Tabela de preços configurável em `%APPDATA%\RadIA\pricing.json`.

---

## 🔧 Integração com a IDE

### 15. Revisão Automática de Código no Save
*   **Objetivo**: Analisar a unit silenciosamente ao salvar e sinalizar no painel do RadIA se a IA encontrou pontos de atenção.
*   **Detalhamento**:
    *   Hook no evento `AfterSave` via `IOTAEditorServices`.
    *   Envio assíncrono para a IA com prompt de revisão rápida.
    *   Se a IA retornar issues: exibir badge numérico no botão do RadIA na IDE e notificação discreta (não invasiva).
    *   Configurável: ativar/desativar, escolher quais categorias verificar (estilo, bugs, performance).

### 16. Histórico de Refatorações Aplicadas
*   **Objetivo**: Manter um log auditável de todas as vezes que o botão [Aplicar Alteração] foi acionado, permitindo revisão e desfazimento manual.
*   **Detalhamento**:
    *   Armazenar em `%APPDATA%\RadIA\refactor_history.json`: timestamp, nome do arquivo, unit path, código original, código aplicado.
    *   UI acessível via menu Tools → RadIA → Histórico de Refatorações.
    *   Exibir lista com possibilidade de reabrir o Smart Diff de qualquer entrada passada.
    *   Limite configurável de entradas (padrão: 100).
