# Recursos e Funcionalidades do RadIA

Este documento contém o checklist completo de recursos, categorização e status de desenvolvimento de todas as funcionalidades integradas ao plugin **RadIA**.

---

## Tabela Completa de Recursos

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
| **Ações no Editor** | Integração | Explicação de código, otimização, testes e bugs com botão direito no editor. | ✅ Concluído |
| **Smart Diff (Comparador)** | Integração | Visualização lado a lado de código sugerido vs. original com aplicação instantânea. | ✅ Concluído |
| **Smart Build Debugger** | Integração | Clique com o botão direito nos erros de compilação da IDE para correções instantâneas. | ✅ Concluído |
| **Documentação XML Automática** | Geração | Geração automática de comentários `/// <summary>` sobre os métodos da unit. | ✅ Concluído |
| **Armazenamento Seguro** | Segurança | Chaves de API salvas localmente criptografadas usando a API do Windows DPAPI. | ✅ Concluído |
