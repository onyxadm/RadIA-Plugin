<div align="right">

[🇧🇷 Português](ROADMAP.md) | [🇺🇸 English](ROADMAP.en.md)

</div>

# RadIA - Roadmap de Evolução

Este documento descreve o planejamento de evolução do plugin RadIA, organizado por versões e prioridades de entrega. Os itens estão agrupados por milestone e refletem a visão de longo prazo do projeto.

> [!NOTE]
> O RadIA segue o modelo de desenvolvimento **open source orientado à comunidade**. Pull Requests são bem-vindos para qualquer item listado abaixo. Consulte a seção de contribuição para mais detalhes.

---

## ✅ v0.0.1 — Lançamento Inicial (Concluído)

A versão v0.0.1 implementou todos os recursos essenciais do plugin, incluindo:

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

## ✅ v0.0.2 — Múltiplas Sessões e Gestão de Consumo (Concluído)

A versão v0.0.2 focou em fornecer maior gerenciamento de contexto, governança sobre o consumo de tokens e novos provedores:

- **Múltiplas Sessões de Chat (Histórico Avançado):**
  * Gerenciamento de conversas persistido localmente em `%APPDATA%\RadIA\sessions\<guid>.json`.
  * Barra lateral retrátil (sidebar) estilizada inteiramente em HTML/CSS/JS premium na WebView2 para listar, selecionar, criar, renomear de forma rápida (duplo clique inline) e excluir conversas.
  * Integração perfeita de eventos e concorrência na sincronização Delphi-WebView.
- **Controle de Cota e Orçamento de Tokens:**
  * Configuração de limite de consumo mensal nas opções do plugin.
  * Acúmulo persistido localmente e exibição do percentual de cota gasto na barra de status inferior.
  * Bloqueio dinâmico automático de novas chamadas ao ultrapassar 100% da cota.
- **Suporte ao OpenRouter:**
  * Integração do provedor OpenRouter como backend para unificar centenas de modelos em uma única API Key.

---

## ✅ v0.0.3 — Arquitetura de Provedores Dinâmicos e Estabilidade (Concluído)

A versão v0.0.3 trouxe melhorias de arquitetura cruciais para a extensibilidade do plugin e correções de estabilidade de memória:

- **Arquitetura de Provedores Dinâmicos:**
  * Implementação do registro central de provedores via metadados (`TProviderRegistry`), facilitando a adição de novos backends de IA de forma totalmente desacoplada.
- **Ciclo de Vida de Configuração Robusto:**
  * Migração do `TRadIAConfig` para o padrão Singleton com gerenciamento manual de ciclo de vida (sem ARC).
  * Substituição definitiva do uso de dicionários genéricos por `TStringList` nas configurações para evitar Access Violations e vazamentos de memória na finalização e descarregamento da BPL na IDE do Delphi.
- **Estabilidade do WebView2 e Threads:**
  * Proteção e sincronização via `TThread.Queue` e verificações de integridade (`ILifecycleGuard`) nos callbacks assíncronos das requisições para evitar crashes ao fechar/destruir frames ativamente.

---

## 🔲 v0.1.0 — Produtividade Avançada (Próxima Versão)

### 1. Conversor de DTO e Modelos (JSON / DDL ➔ Delphi) (✅ Concluído)
*   **Objetivo**: Colar um payload JSON ou DDL de tabelas SQL e gerar classes de dados (DTOs) ou records em Object Pascal correspondentes com um clique.
*   **Impacto**: ⭐⭐⭐⭐⭐ Alto
*   **Complexidade**: Baixa

### 2. Assistente de Stack Trace (Debug Companion - Fase 1)
*   **Objetivo**: Analisar Stack Traces colados no chat (de exceções da IDE, MadExcept ou EurekaLog), apontando a unidade e o método causador do erro com sugestão de correção.
*   **Impacto**: ⭐⭐⭐⭐ Alto
*   **Complexidade**: Média

### 3. Analisador de Memory Leaks e Anti-patterns (Análise Estática)
*   **Objetivo**: Analisar assincronamente a unit ativa no editor em busca de vazamentos de memória (ausência de try..finally) e violações semânticas de SOLID/Clean Code.
*   **Impacto**: ⭐⭐⭐⭐ Alto
*   **Complexidade**: Média

### 4. Revisão Automática de Código no Save
*   **Objetivo**: Analisar a unit silenciosamente ao salvar e sinalizar no painel do RadIA se a IA encontrou pontos de atenção (ex: possíveis bugs, código duplicado ou falta de tratamento de exceção).
*   **Impacto**: ⭐⭐⭐⭐ Alto
*   **Complexidade**: Média

### 5. Histórico de Refatorações Aplicadas
*   **Objetivo**: Manter um log auditável de todas as vezes que o botão **[Aplicar Alteração]** foi acionado, registrando o trecho original, o trecho aplicado, a data e o arquivo, permitindo revisão manual posterior.
*   **Impacto**: ⭐⭐⭐ Médio
*   **Complexidade**: Baixa

---

## 🔲 v0.2.0 — Administração e Diagnóstico

### 6. Assistente de Migração de Versão (Smart Migrate)
*   **Objetivo**: Comando contextual de menu ou chat lateral para reescrever trechos selecionados de código procedurais/legados usando recursos modernos do Delphi (Unicode, PPL, FireDAC).
*   **Impacto**: ⭐⭐⭐⭐ Alto
*   **Complexidade**: Média

### 7. Painel de Gerenciamento do Cache
*   **Objetivo**: Exibir uma tela de administração interna do cache de respostas, permitindo visualizar entradas em cache, limpar entradas específicas e ver o tamanho total do arquivo de cache sem editar o JSON manualmente.
*   **Impacto**: ⭐⭐⭐ Médio
*   **Complexidade**: Média

---

## 💡 Ideias Futuras (v0.3.0+)

Os itens abaixo ainda estão em fase de concepção e avaliação de viabilidade técnica com a Open Tools API:

- **Autocompletar Inline Inteligente (Ghost Text):** Sugestões de código em tempo real no editor de código com texto acinzentado estilo Copilot (Complexidade: Alta).
- **Integração Automática com Depurador da IDE:** Captura dinâmica e análise automática de exceções ativas durante sessões de depuração de código (Complexidade: Alta).
- **Geração automática de documentação de projeto** (varrer units e gerar um `docs/API.md` completo).
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
