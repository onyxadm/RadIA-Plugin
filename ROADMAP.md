# RadIA - Roadmap de Evolução

Este documento descreve o planejamento estratégico e a visão de futuro do assistente de IA **RadIA**, focado em trazer produtividade e resolver as dores reais do desenvolvedor Delphi no seu dia a dia.

> [!NOTE]
> O RadIA segue um modelo de desenvolvimento **open-source orientado à comunidade**.
> *   Para uma visualização detalhada das prioridades, estimativas de esforço e impacto de cada recurso, consulte a [Matriz de Priorização (docs/feature_prioritization_matrix.md)](docs/feature_prioritization_matrix.md).
> *   Para os detalhes técnicos das implementações passadas e pendentes (como nomes de classes, testes DUnitX aprovados e commits), consulte o [Backlog de Evolução Técnica (docs/backlog.md)](docs/backlog.md).

---

## 📅 Histórico de Versões Concluídas

Abaixo estão listadas as conquistas e os valores entregues em cada versão já lançada do plugin:

<details>
  <summary><b>📦 v0.0.15 — Templates em Duas Camadas e Overlays (Concluído)</b></summary>

  *   **Valor Entregue**: Segurança de que novas atualizações do plugin trazem prompts novos da comunidade sem sobrescrever ou apagar suas personalizações locais.
  *   **Destaques**: Segregação de templates nativos e de usuário, indicador visual de origem no menu de configurações e opção de "Restaurar Padrão".
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.15)](docs/backlog.md#v0015--arquitetura-de-templates-em-duas-camadas-clique-para-expandir).*
</details>

<details>
  <summary><b>📦 v0.0.14 — Templates Dinâmicos e Backup (Concluído)</b></summary>

  *   **Valor Entregue**: Liberdade para criar comandos personalizados barra (`/`) associados a prompts repetitivos e facilidade para migrar e compartilhar sua biblioteca de templates de IA entre computadores.
  *   **Destaques**: Customização dinâmica total de comandos barra, backup em JSON com controle de importação (mesclar ou sobrescrever) e template nativo de Clean Architecture Delphi.
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.14)](docs/backlog.md#v0014--templates-dinâmicos-e-backup-clique-para-expandir).*
</details>

<details>
  <summary><b>📦 v0.0.13 — Geração de Projetos Delphi Inteiros via Prompt (Concluído)</b></summary>

  *   **Valor Entregue**: Velocidade extrema no início de novas ideias e microsserviços. A IA cria a estrutura completa de pastas e arquivos e os carrega diretamente na sua IDE prontos para uso.
  *   **Destaques**: Gerador transacional de arquivos, painel visual com design *glassmorphism* no chat e abertura automática do projeto gerado na IDE do Delphi.
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.13)](docs/backlog.md#v0013--geração-de-projetos-delphi-inteiros-clique-para-expandir).*
</details>

<details>
  <summary><b>📦 v0.0.12 — Provedor AWS Bedrock e Estabilização (Concluído)</b></summary>

  *   **Valor Entregue**: Integração com os modelos de ponta da Amazon (Anthropic Claude, Llama 3) em ambientes corporativos rígidos que demandam segurança em nuvens AWS.
  *   **Destaques**: Suporte nativo ao AWS Bedrock, assinador criptográfico SigV4 e parser de streaming binário.
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.12)](docs/backlog.md#v0012--provedor-aws-bedrock-clique-para-expandir).*
</details>

<details>
  <summary><b>📦 v0.0.11 — Provedores Azure, Qwen e Mistral AI (Concluído)</b></summary>

  *   **Valor Entregue**: Expansão do catálogo de IAs nativas de ponta do plugin para atender a políticas de compliance de TI internas de diferentes empresas.
  *   **Destaques**: Suporte nativo para Azure OpenAI, Alibaba Qwen 2.5 e Mistral AI, com abas dedicadas e atalhos na tela de opções da IDE.
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.11)](docs/backlog.md#v0011--provedores-azure-qwen-e-mistral-ai-clique-para-expandir).*
</details>

<details>
  <summary><b>📦 v0.0.10 — Suporte Nativo ao GitHub Copilot (Concluído)</b></summary>

  *   **Valor Entregue**: Autenticação oficial e simplificada com a IA de desenvolvimento mais popular do mundo diretamente do painel do RadIA, sem a necessidade de proxies locais.
  *   **Destaques**: Suporte nativo ao GitHub Copilot na nuvem, fluxo de login interativo por PIN do dispositivo e importação do token ativo do VS Code em um clique.
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.10)](docs/backlog.md#v0010--conexão-nativa-ao-github-copilot-clique-para-expandir).*
</details>

<details>
  <summary><b>📦 v0.0.9 — Suporte Multi-IDE e Acentuação de Build (Concluído)</b></summary>

  *   **Valor Entregue**: Facilidade de implantação em computadores de desenvolvimento que rodam múltiplas versões da IDE do Delphi simultaneamente (ex: Alexandria e Athens).
  *   **Destaques**: Instalador PowerShell interativo com autodescoberta do registro do Windows e correções de encodings de consoles locais.
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.9)](docs/backlog.md#v009--suporte-multi-ide-no-build-clique-para-expandir).*
</details>

<details>
  <summary><b>📦 v0.0.8 — Provedor Local LM Studio e Estabilidade (Concluído)</b></summary>

  *   **Valor Entregue**: Autonomia de uso com modelos de IA locais e offline rodando em servidores corporativos ou computadores locais pelo LM Studio.
  *   **Destaques**: Provedor nativo do LM Studio e aba dedicada Claro/Escuro de configurações.
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.8)](docs/backlog.md#v008--provedor-local-lm-studio-clique-para-expandir).*
</details>

<details>
  <summary><b>📦 v0.0.7 — System Prompt Otimizado (Concluído)</b></summary>

  *   **Valor Entregue**: Respostas da IA muito mais rápidas, enxutas e focadas estritamente em código Delphi Object Pascal de qualidade, evitando explicações verborrágicas desnecessárias.
  *   **Destaques**: System Prompt otimizado de fábrica e respeito a preferências e customizações salvas pelo usuário.
</details>

<details>
  <summary><b>📦 v0.0.6 — Provedores via JSON e Suporte ao Copilot (Concluído)</b></summary>

  *   **Valor Entregue**: Extensibilidade imediata. Permite cadastrar qualquer nova IA de mercado compatível com a API da OpenAI apenas salvando um arquivo JSON, sem necessitar reinstalar ou compilar o plugin.
  *   **Destaques**: Provedores dinâmicos configuráveis por JSON local e conexões iniciais de proxies do Copilot.
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.6)](docs/backlog.md#v006--provedores-dinâmicos-via-json-clique-para-expandir).*
</details>

<details>
  <summary><b>📦 v0.0.5 — Desacoplamento e Estabilização de UI (Concluído)</b></summary>

  *   **Valor Entregue**: Melhoria na robustez interna das opções da IDE e remoção definitiva de problemas de interface.
  *   **Destaques**: Migração interna para identificadores dinâmicos baseados em strings e correções na renderização de abas sob o menu da IDE.
</details>

<details>
  <summary><b>📦 v0.0.4 — Produtividade Avançada e Análise Estática (Concluído)</b></summary>

  *   **Valor Entregue**: Automatização de tarefas manuais repetitivas (como criar classes DTO) e análise rápida de pilha de erros no código ativo.
  *   **Destaques**: Conversor DTO (JSON/SQL para Pascal), Assistente de Stack Trace em relatórios de exceções, análise estática de memory leaks e popup visual flutuante de sugestões barra (`/`).
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.4)](docs/backlog.md#v004--produtividade--análise-estática-clique-para-expandir).*
</details>

<details>
  <summary><b>📦 v0.0.3 — Estabilidade de Runtime (Concluído)</b></summary>

  *   **Valor Entregue**: Garantia de que o plugin rode em background na IDE sem causar travamentos, vazamentos de memória da BPL ou Access Violations durante o uso diário.
  *   **Destaques**: Barramento central de registro dinâmico de IAs e ciclo de vida robusto com threads secundárias.
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.3)](docs/backlog.md#v003--estabilidade-de-runtime-clique-para-expandir).*
</details>

<details>
  <summary><b>📦 v0.0.2 — Múltiplas Sessões e Gestão de Consumo (Concluído)</b></summary>

  *   **Valor Entregue**: Organização das conversas por projetos e controle direto sobre os custos das chaves de API.
  *   **Destaques**: Sidebar de chat de múltiplas sessões persistentes, controle local de orçamento de tokens mensal na barra de status e integração com OpenRouter.
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.2)](docs/backlog.md#v002--múltiplas-sessões-e-gestão-de-consumo-clique-para-expandir).*
</details>

<details>
  <summary><b>📦 v0.0.1 — Lançamento Inicial (Concluído)</b></summary>

  *   **Valor Entregue**: A IA acoplada de forma nativa e fluida à IDE do Delphi, trazendo respostas incrementais rápidas e atalhos na tela.
  *   **Destaques**: Chat lateral VCL integrado com Edge WebView2, suporte a 6 provedores, streaming SSE, histórico local, atalhos contextuais no editor de código, comparador visual Diff de alterações, Smart Build Debugger e documentação XML automática.
  *   👉 *Veja os detalhes de implementação e testes no [Backlog Técnico (v0.0.1)](docs/backlog.md#v001--lançamento-inicial-clique-para-expandir).*
</details>

---

## 🔲 Milestones de Planejamento Futuro

As próximas versões do RadIA focarão em trazer automação inteligente em diagnóstico de erros e refatorações complexas de código legado:

### 🔲 v0.1.0 — Automação, Auditoria e Ganhos Rápidos
Esta versão trará auditoria de código e correções no editor em tempo real de forma leve, silenciosa e sem atritos na produtividade:
*   **Smart SQL Optimizer no Editor**: Varredura inteligente de strings SQL dentro do Pascal para otimizar joins, performance e validar sintaxes.
*   **Delphi Compiler & OS Warning Scanner**: Auditoria estática focada no compilador Delphi e em armadilhas de baixo nível do Windows (concorrência, vazamento de GDI handles).
*   **Revisão Automática no Save**: Análise estática rápida executada em background ao salvar arquivos na IDE, sinalizando bugs potenciais.
*   **Histórico de Refatorações Aplicadas**: Logs das modificações aplicadas com possibilidade de reversão manual.

### 🔲 v0.2.0 — Engenharia de Código e Análise Estrutural
Foco em estruturação arquitetural de APIs, testes automatizados e depuração profunda de exceções:
*   **Smart Multi-Unit Trace Resolver**: Decodificação inteligente de stack traces colados no chat que lê em background os múltiplos arquivos físicos do projeto citados no log para apontar a causa raiz.
*   **MadExcept / EurekaLog Context Extractor**: Parser automatizado de dumps de variáveis de runtime coletados nos logs de erro do sistema para dar visibilidade exata à IA sobre a falha.
*   **Otimizador de Cláusula Uses (Clean Uses)**: Limpeza automática de imports não referenciados na unit ativa e inclusões rápidas de units do sistema.
*   **Gerador de Mocks para Testes**: Geração automatizada de classes e mocks de interfaces para viabilizar testes unitários em ambientes acoplados.
*   **Swagger/OpenAPI Generator**: Geração de documentação estruturada Swagger a partir das rotas e controllers registrados (Horse / RAD Server).
*   **Análise Semântica DFM vs PAS**: Auditoria bidirecional para remoção automática de componentes visuais do DFM e eventos que ficaram órfãos no código.

### 💡 Ideias Futuras (v0.3.0+)
Ideias em fase de concepção e estudo de viabilidade técnica na ToolsAPI ou que demandam hooks de baixo nível:
*   **Conversão BDE/ADO/dbExpress ➔ DEXT com FireDAC**: Assistente interativo de migração estrutural que converte componentes visuais obsoletos do DFM e reescreve a lógica do código Pascal para o DEXT ORM com FireDAC.
*   **Decompositor de Formulários (Code-Behind Extractor)**: Extração cirúrgica de lógica de negócios acoplada nos eventos de cliques de telas para classes de serviços limpas separadas.
*   **Assistente de Threads e PPL**: Auxiliar a reescrever rotinas pesadas síncronas para rodarem de forma assíncrona segura e sem travar a interface da aplicação.
*   **Internacionalização Automática (i18n Wizard)**: Extrair todas as propriedades de tela e textos hardcoded Pascal para arquivos centralizados de tradução.
*   **Autocompletar Inline (Ghost Text)**: Exibição de sugestões de código em tempo real no editor com texto cinza (Copilot/Cursor style).
*   **Suporte Nativo macOS/Linux**: Compatibilidade e portabilidade de UI e editor do RadIA para Lazarus / Free Pascal.
