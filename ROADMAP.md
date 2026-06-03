<div align="right">

[🇧🇷 Português](ROADMAP.md) | [🇺🇸 English](ROADMAP.en.md)

</div>

# RadIA - Roadmap de Evolução

Este documento descreve o planejamento de evolução do plugin RadIA, organizado por versões e prioridades de entrega. Os itens estão agrupados por milestone e refletem a visão de longo prazo do projeto.

> [!NOTE]
> O RadIA segue o modelo de desenvolvimento **open source orientado à comunidade**. Pull Requests são bem-vindos para qualquer item listado abaixo. Consulte a seção de contribuição para mais detalhes.

---

## ✅ v1.0 — Lançamento Inicial (Concluído)

A versão 1.0 implementou todos os recursos essenciais do plugin, incluindo:

- Chat lateral acoplável com WebView2 (HTML5/JS/CSS)
- Suporte a 6 provedores de IA: Gemini, OpenAI, Claude, DeepSeek, Groq e Ollama
- Streaming de respostas SSE token a token
- Histórico de chat persistente em JSON local
- Histórico de prompts com navegação por setas ↑/↓
- Exportação de conversa em Markdown e HTML
- Templates de prompt com `/template`
- Contexto de projeto via arquivo `.radia`
- Ações contextuais no editor (botão direito)
- Smart Diff (comparador visual lado a lado)
- Smart Build Debugger (erros de compilação)
- Documentação XML automática
- Armazenamento seguro de chaves via Windows DPAPI
- Distribuição offline-first das dependências Web
- Script de build automatizado (`build.ps1`) com `-Install` e `-Release`
- Licença Apache 2.0, `NOTICE` e isenções de responsabilidade completas

---

## 🔲 v1.1 — Controle e Visibilidade (Próxima Versão)

### 1. Múltiplas Sessões de Chat
*   **Objetivo**: Permitir que o desenvolvedor organize conversas por projeto, feature ou tarefa, sem perder o contexto de sessões anteriores.
*   **Detalhamento**:
    *   Armazenar sessões em `%APPDATA%\RadIA\sessions\<id>.json`, cada uma com nome, data e array de mensagens.
    *   Adicionar dropdown ou painel lateral para listar, criar, renomear e excluir sessões.
    *   Botão **"Nova Sessão"** salva a sessão corrente e abre uma nova vazia.
*   **Impacto**: ⭐⭐⭐⭐⭐ Alto

### 2. Controle de Cota e Orçamento de Tokens Local
*   **Objetivo**: Permitir que o desenvolvedor estabeleça um limite mensal de consumo de tokens para evitar surpresas no faturamento das chaves de API próprias.
*   **Detalhamento**:
    *   Campo nas configurações de limite de tokens (ex: cota mensal de 1.000.000 tokens).
    *   Acumular consumo de forma persistente localmente por chave de API.
    *   Exibir percentual de consumo na barra de status do chat e bloquear novas chamadas ao atingir 100% da cota.
*   **Impacto**: ⭐⭐⭐⭐⭐ Alto

---

## 🔲 v1.2 — Produtividade Avançada

### 3. Revisão Automática de Código no Save
*   **Objetivo**: Analisar a unit silenciosamente ao salvar e sinalizar no painel do RadIA se a IA encontrou pontos de atenção (ex: possíveis bugs, código duplicado ou falta de tratamento de exceção).
*   **Impacto**: ⭐⭐⭐⭐ Alto

### 4. Histórico de Refatorações Aplicadas
*   **Objetivo**: Manter um log auditável de todas as vezes que o botão **[Aplicar Alteração]** foi acionado, registrando o trecho original, o trecho aplicado, a data e o arquivo, permitindo revisão manual posterior.
*   **Impacto**: ⭐⭐⭐ Médio

---

## 🔲 v1.3 — Administração e Diagnóstico

### 5. Painel de Gerenciamento do Cache
*   **Objetivo**: Exibir uma tela de administração interna do cache de respostas, permitindo visualizar entradas em cache, limpar entradas específicas e ver o tamanho total do arquivo de cache sem editar o JSON manualmente.
*   **Impacto**: ⭐⭐⭐ Médio

---

## 💡 Ideias Futuras (v2.0+)

Os itens abaixo ainda estão em fase de concepção e avaliação de viabilidade técnica com a Open Tools API:

- **Geração automática de documentação de projeto** (varrer units e gerar um `docs/API.md` completo).
- **Assistente de migração de versão do Delphi** (análise de compatibilidade de código ao migrar entre versões da IDE).
- **Integração com GitHub Copilot / GitLab Duo** (bridging via protocolo LSP).
- **Suporte nativo a macOS/Linux** via FPC/Lazarus (análise de viabilidade).

---

## 🤝 Como Contribuir

Contribuições são muito bem-vindas! Caso queira implementar algum dos itens deste roadmap:

1. Faça um **fork** do repositório.
2. Crie uma branch descritiva: `feature/multiplas-sessoes`.
3. Implemente as mudanças seguindo os princípios **SOLID, Clean Code e DRY** adotados no projeto.
4. Certifique-se de que o comando `powershell -ExecutionPolicy Bypass -File .\build.ps1` passa com **todos os testes verdes**.
5. Abra um **Pull Request** descrevendo a sua contribuição.

> [!IMPORTANT]
> Todo o código-fonte do projeto é escrito **obrigatoriamente em inglês** (nomes de variáveis, métodos, classes, comentários). A documentação pode ser escrita em português ou inglês.
