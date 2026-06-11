# Backlog de Evolução do Rad IA

Este documento registra o status de desenvolvimento, planejamento futuro e o histórico técnico das tarefas concluídas do plugin **Rad IA**.

---

## 📊 Kanban Dashboard

O quadro abaixo resume o status atual das features mapeadas a curto e médio prazo no projeto:

| Funcionalidade / Tarefa | Status | Dificuldade | Prioridade | Versão Alvo |
| :--- | :---: | :---: | :---: | :---: |
| **Smart SQL Optimizer no Editor** | 🔲 Planejado | 🟢 Baixa | ⭐⭐⭐⭐ Alta | v0.1.0 |
| **Delphi Compiler & OS Warning Scanner** | 🔲 Planejado | 🟢 Baixa | ⭐⭐⭐⭐ Alta | v0.1.0 |
| **Revisão Automática de Código no Save** | 🔲 Planejado | 🟡 Média | ⭐⭐⭐⭐ Alta | v0.1.0 |
| **Histórico de Refatorações Aplicadas** | 🔲 Planejado | 🟢 Baixa | ⭐⭐⭐ Média | v0.1.0 |
| **Otimizador de Cláusula Uses (Clean Uses)** | 🔲 Planejado | 🟡 Média | ⭐⭐⭐⭐ Alta | v0.2.0 |
| **Gerador de Mocks para Testes Unitários** | 🔲 Planejado | 🟡 Média | ⭐⭐⭐⭐ Alta | v0.2.0 |
| **Smart Multi-Unit Trace Resolver** | 🔲 Planejado | 🟡 Média | ⭐⭐⭐⭐⭐ Crítica | v0.2.0 |
| **MadExcept / EurekaLog Context Extractor** | 🔲 Planejado | 🟡 Média | ⭐⭐⭐⭐⭐ Crítica | v0.2.0 |
| **Gerador de Documentação OpenAPI/Swagger** | 🔲 Planejado | 🟡 Média | ⭐⭐⭐⭐ Alta | v0.2.0 |
| **Análise Semântica Bidirecional (DFM vs PAS)** | 🔲 Planejado | 🟡 Média | ⭐⭐⭐⭐ Alta | v0.2.0 |
| **Assistente de Migração (Smart Migrate)** | 🔲 Planejado | 🟡 Média | ⭐⭐⭐⭐ Alta | v0.2.0 |
| **Painel de Gerenciamento do Cache** | 🔲 Planejado | 🟡 Média | ⭐⭐⭐ Média | v0.2.0 |
| **Conversão BDE/ADO/dbExpress ➔ DEXT com FireDAC** | 🔲 Planejado | 🔴 Alta | ⭐⭐⭐⭐ Alta | v0.3.0+ |
| **Decompositor de Forms (Code-Behind)** | 🔲 Planejado | 🔴 Alta | ⭐⭐⭐⭐ Alta | v0.3.0+ |
| **Assistente de Threads e PPL** | 🔲 Planejado | 🔴 Alta | ⭐⭐⭐⭐ Alta | v0.3.0+ |
| **Internacionalização Automática (i18n Wizard)** | 🔲 Planejado | 🔴 Alta | ⭐⭐⭐⭐ Alta | v0.3.0+ |
| **Autocompletar Inline (Ghost Text)** | 🔲 Planejado | 🔴 Alta | ⭐⭐⭐⭐ Alta | v0.3.0+ |
| **Integração com Depurador da IDE (OTA)** | 🔲 Planejado | 🔴 Alta | ⭐⭐⭐⭐ Alta | v0.3.0+ |
| **Geração de Docs de Projeto (API.md)** | 🔲 Planejado | 🟡 Média | ⭐⭐⭐ Média | v0.3.0+ |
| **Suporte Nativo macOS/Linux (Lazarus)** | 🔲 Planejado | 🔴 Alta | 🟢 Baixa | v0.3.0+ |

---

## ⏳ 1. Em Desenvolvimento (Work in Progress)

*   *Nenhuma tarefa em andamento ativo nesta branch.*

---

## 🔲 2. Próximos Passos (Planned Backlog)

Para detalhes completos de objetivos, impactos e referências técnicas de cada funcionalidade futura, consulte a [Matriz de Priorização de Features (docs/feature_prioritization_matrix.md)](feature_prioritization_matrix.md) ou o [Roadmap de Evolução (docs/roadmap.md)](roadmap.md).

---

## ✅ 3. Histórico de Conclusões (Completed)

Consulte os detalhes de implementação de cada recurso agrupado por versão:

<details>
  <summary><b>📦 v0.0.21 — Create Example from Comment (Clique para expandir)</b></summary>

  #### 1. Geração de Exemplo a partir de Comentário
  *   **Descrição**: Nova ação **Create Example from Comment** no menu contextual do editor para preencher métodos vazios a partir de um comentário em linguagem natural.
  *   **Detalhes**:
      *   O parser identifica o método atual pelo cursor, aceita comentários `//`, `{ ... }` e `(* ... *)`, inclusive multilinha.
      *   A ação recusa métodos fora do padrão esperado, sem comentário ou com código existente além de espaços e comentários.
      *   O código gerado é inserido diretamente abaixo do comentário, preservando a intenção original e sem abrir o Smart Diff.
      *   O fluxo respeita provedores com Web Login, abrindo a ponte do chat antes de enviar o prompt quando necessário.
      *   O mecanismo do hook contextual foi mantido no comportamento validado em Delphi 12 e Delphi 13.
      *   Validação realizada com `build.ps1 -DelphiVersion "23.0" -Test`, com 155 testes aprovados.
</details>

<details>
  <summary><b>📦 v0.0.20 — Smart Diff com Web Login e Persistência de Configuração (Clique para expandir)</b></summary>

  #### 1. Smart Diff com Provedores Web Login
  *   **Descrição**: Correção do fluxo de refatoração via Smart Diff para provedores autenticados por Web Login, mantendo a janela do chat funcional e exibindo corretamente o comparador.
  *   **Detalhes**:
      *   O Smart Diff passou a reutilizar o caminho de Web Login sem exigir chave de API quando o provedor ativo está configurado para autenticação web.
      *   A resposta de refatoração agora é solicitada em um único bloco `pascal`, preservando a formatação recebida da IA.
      *   A extração do WebView preserva quebras de linha e indentação dos blocos de código antes de enviar o conteúdo para o Delphi.

  #### 2. Estabilidade de Configurações e Editor
  *   **Descrição**: Ajustes para evitar regressões de configuração e interferências no editor durante criação de projetos.
  *   **Detalhes**:
      *   Configurações específicas dos provedores foram gravadas e lidas em suas chaves próprias, mantendo compatibilidade com valores legados.
      *   Testes automatizados deixaram de gravar no registro real do usuário, evitando alteração acidental da configuração do Gemini.
      *   O hook do menu contextual evita acessar o buffer interno do editor enquanto a IDE ainda está criando views.
      *   Validação realizada com `build.ps1 -DelphiVersion "37.0" -Test` e `build.ps1 -DelphiVersion "23.0" -Test`, ambos com 144 testes aprovados.
</details>

<details>
  <summary><b>📦 v0.0.19 — Ações do Editor com Fallback para Unit Ativa (Clique para expandir)</b></summary>

  #### 1. Menus do Editor sem Seleção - Item #52
  *   **Descrição**: As ações do menu contextual do editor agora funcionam mesmo quando o usuário não seleciona nenhum trecho de código.
  *   **Detalhes**:
      *   Os comandos **Explain**, **Generate Tests**, **Locate Bugs**, **Document Method** e **Optimize/Refactor** tentam usar a seleção primeiro.
      *   Quando não há seleção, o Rad IA lê a unit ativa inteira e envia esse conteúdo como contexto ao chat ou ao comparador Smart Diff.
      *   O fluxo de refatoração marca corretamente quando a sugestão deve substituir o buffer inteiro, evitando inserir resultado no cursor.

  #### 2. Estabilidade Delphi 13 e Leitura do Editor
  *   **Descrição**: Correção de estabilidade no Delphi 13 ao criar novos projetos e ajuste da leitura do buffer ativo.
  *   **Detalhes**:
      *   O hook do menu contextual deixou de usar notifiers OTA durante a criação de views do editor, evitando conflito com a reconstrução de elisions do Delphi 13.
      *   A leitura de `IOTAEditReader` passou a ser feita em blocos, garantindo que a unit ativa seja capturada corretamente no Delphi 12 e Delphi 13.
      *   Validação realizada com `build.ps1 -DelphiVersion "37.0" -Test` e `build.ps1 -DelphiVersion "23.0" -Test`, ambos com 143 testes aprovados.
</details>

<details>
  <summary><b>📦 v0.0.18 — Polimento do Chat, Web Login e Marca Rad IA (Clique para expandir)</b></summary>

  #### 1. Experiência Inicial e Tema do Chat - Itens #46, #47
  *   **Descrição**: Refinamento da abertura do chat e da adaptação visual ao tema da IDE para reduzir ruído visual e tornar o primeiro uso mais intuitivo.
  *   **Detalhes**:
      *   Criação de uma tela inicial com animação central, atalhos rápidos e carregamento de histórico sob demanda.
      *   Tratamento do tema Mountain Mist como light, mantendo apenas os modos dark e light no CSS do chat.
      *   Ajuste da largura da scrollbar e correção do bloco de código no tema light para remover a borda escura ao redor do `pre`.
      *   Redução do flash visual no primeiro carregamento do WebView2.

  #### 2. Sessões, Bloqueios e Generator - Itens #48, #49
  *   **Descrição**: Correção do comportamento de múltiplos chats para evitar perda de contexto durante respostas em andamento e tornar a navegação mais previsível.
  *   **Detalhes**:
      *   Selecionar uma conversa não a move mais para o topo da lista.
      *   Ações de sessão, botões da barra superior, edição, exclusão, criação, limpeza e troca de conversa ficam bloqueados durante processamento.
      *   Sessões vazias não são restauradas como chats extras no próximo carregamento.
      *   O botão **History** foi renomeado para **Chats** e o generator passou a ocupar toda a área, evitando manipulação cruzada da lista de chats.

  #### 3. Web Login e Identidade Visual - Itens #50, #51
  *   **Descrição**: Melhoria do fluxo de login web e alinhamento da marca exibida ao usuário como **Rad IA**.
  *   **Detalhes**:
      *   Tela de Web Login ganhou status claros, fallback visual quando o browser embutido demora a iniciar e ação **Use Current Session** para contas já autenticadas.
      *   Textos de UI, menu da IDE, splash/about, documentação e metadados do pacote foram revisados para exibir **Rad IA** separado.
      *   Metadados de versão atualizados para `v0.0.18`.
      *   Validação realizada com build local no Delphi 12 (`23.0`) e lint dos recursos web sem erros bloqueantes.
</details>

<details>
  <summary><b>📦 v0.0.17 — Estabilização do Menu do Editor e Chat WebView2 (Clique para expandir)</b></summary>

  #### 1. Formatação de Código e Slash Commands do Editor - Itens #43, #44
  *   **Descrição**: Correção dos fluxos acionados pelo menu contextual do editor para preservar blocos Pascal formatados no chat e garantir que cada comando resolva o template correto desde a primeira execução.
  *   **Detalhes**:
      *   Montagem dos prompts do editor com comando, instrução e bloco `pascal` em linhas separadas para manter a renderização Markdown.
      *   Renderização de Markdown também em mensagens do usuário quando houver blocos fenced, preservando destaque Pascal e ações de cópia/aplicação.
      *   Criação do template nativo **Explain Code** para o comando `/explain` e migração de overlays legados de review para `/review`.
      *   Alinhamento do processamento global de prompts com `PreProcessPrompt`, evitando diferenças entre comandos disparados pelo menu e comandos digitados no chat.

  #### 2. Instalação e Cache de Recursos Web - Item #45
  *   **Descrição**: Reforço do processo de instalação multi-IDE para evitar que Delphi 12/13 carreguem JavaScript antigo do WebView2 após atualizações.
  *   **Detalhes**:
      *   `chat.html` passou a carregar `chat.js` com cache busting por timestamp.
      *   `build.ps1 -Install` agora espelha `Source\UI\Web` na pasta pública da IDE e em `%APPDATA%\RadIA\Web`.
      *   Limpeza automática do cache `%APPDATA%\RadIA\WebView2` durante a instalação quando a IDE está fechada.
      *   Validação sequencial no Delphi 12 (`23.0`) e Delphi 13 (`37.0`) com **143 testes DUnitX aprovados** em ambos.
</details>

<details>
  <summary><b>📦 v0.0.16 — Refatoração Arquitetural MVP, Storage Abstraction e Robustez do Editor (Clique para expandir)</b></summary>

  #### 1. Implementação do Padrão MVP e Abstração de Armazenamento - Itens #40, #41
  *   **Descrição**: Desacoplamento da lógica de negócios e UI no Chat e na tela de Configurações introduzindo o padrão MVP, e criação de uma abstração flexível para persistência de dados de configurações (`ISettingsStorage`), permitindo testes unitários determinísticos com mock storage em memória.
  *   **Detalhes**:
      *   Desenvolvimento da unit `RadIA.Core.SettingsStorage.pas` com a interface `ISettingsStorage` e as implementações concretas `TRegistrySettingsStorage` (produção) e `TMemorySettingsStorage` (testes).
      *   Refatoração de `RadIA.Core.Config.pas` para suportar injeção de dependência de Storage via `SetStorage`.
      *   Implementação do padrão MVP no painel de chat com a criação do `TChatPresenter` e a interface `IChatView`, delegando a lógica do `TChatFrame` (View).
      *   Implementação do padrão MVP no frame de configurações com a criação do `TConfigPresenter` e a interface `IConfigView`, incluindo regras robustas de validação de URL, temperatura e parâmetros inteiros.
      *   Desenvolvimento e integração de testes unitários mockados em `RadIA.Tests.ChatPresenter.pas`, `RadIA.Tests.ConfigPresenter.pas` e `RadIA.Tests.EditorHook.pas`, atingindo **135 testes aprovados** com sucesso na suíte de testes.

  #### 2. Robustez do Menu Contextual do Editor - Item #42
  *   **Descrição**: Reforço da integração com o menu de contexto do editor Delphi para reduzir dependência de detalhes frágeis da VCL e preservar compatibilidade com Delphi 12/13 e plugins de terceiros.
  *   **Detalhes**:
      *   Registro de notifiers OTA (`IOTAIDENotifier` e `IOTAEditorNotifier`) para agendar o hook quando arquivos `.pas` e views do editor são abertas ou ativadas.
      *   Hook seguro e assíncrono do menu após a IDE concluir a montagem do `TEditWindow`, evitando regressões na criação de novos projetos e no code folding/elision tree.
      *   Detecção de `TPopupMenu` tanto por componentes do form quanto pela árvore de controles (`Control.PopupMenu`), cobrindo o menu real do editor em diferentes versões/layouts da IDE.
      *   Injeção do submenu **Rad IA** no topo do menu contextual, após o `OnPopup` original da IDE reconstruir os itens padrão.
</details>

<details>
  <summary><b>📦 v0.0.15 — Arquitetura de Templates em Duas Camadas (Clique para expandir)</b></summary>

  #### 1. Arquitetura de Templates Segregada (Nativo vs. Usuário com Overlays) - Item #12c
  *   **Descrição**: Segregação de templates padrões embutidos no código daqueles modificados pelo usuário no AppData, permitindo atualizações sem perder personalizações, com suporte a overlays e restauração de fábrica.
  *   **Detalhes**:
      *   Carregamento em duas camadas com mesclagem em runtime no `TPromptTemplateManager`.
      *   Limpeza automática de templates redundantes não modificados no AppData do usuário (`CleanRedundantUserTemplates`).
      *   Tela de opções aprimorada com legendas de origem (`lblTemplateOrigin`) e lógica contextual de exclusão/restauração.
      *   Suíte de testes unitários expandida com 117 testes DUnitX aprovados com sucesso.
</details>

<details>
  <summary><b>📦 v0.0.14 — Templates Dinâmicos e Backup (Clique para expandir)</b></summary>

  #### 1. Templates Dinâmicos, Backup de Prompt e Nova Arquitetura - Item #12b
  *   **Descrição**: Customização dinâmica total de prompts/templates e slash commands, com diálogos de importação/exportação na VCL e suporte à arquitetura limpa (SOLID).
  *   **Detalhes**:
      *   Remoção de condicionais rígidos no Delphi no processamento de slash commands; varredura totalmente dinâmica pela classe `TPromptTemplateManager` com placeholders (`{code}`, `{specification}`, `{stacktrace}`, `{argument}`).
      *   Diálogos de importação/exportação com verificação transacional JSON de estrutura de arquivos e opções de mesclar (*Merge*) ou sobrescrever (*Overwrite*).
      *   Lançamento do template nativo `'Create Project Delphi Architecture'` (`/createprojectarch`) incorporando injeção de dependências, injeção sistemática de blocos `try..finally` e guia de nomenclatura Pascal.
      *   Atualização da cobertura de testes unitários em `RadIA.Tests.Templates.pas` cobrindo fluxos de backup e esquema.
</details>

<details>
  <summary><b>📦 v0.0.13 — Geração de Projetos Delphi Inteiros (Clique para expandir)</b></summary>

  #### 1. Geração de Projeto Completo (Prompt-Based) - Item #24b
  *   **Descrição**: Criação automatizada de projetos Delphi completos baseados em especificações textuais de chat, salvando-os em disco e abrindo-os de forma automática na IDE.
  *   **Detalhes**:
      *   Desenvolvimento do serviço transacional `TRadIAProjectGenerator` in `RadIA.Core.ProjectGenerator.pas`.
      *   Exigência de pasta limpa/vazia para salvamento e tratamento transacional (rollback em caso de falha de gravação de arquivos).
      *   Parser e renderização visual premium dos arquivos gerados na interface WebView2 com atalhos de navegação e destaque na tela.
</details>

<details>
  <summary><b>📦 v0.0.12 — Provedor AWS Bedrock (Clique para expandir)</b></summary>

  #### 1. Provedor Nativo AWS Bedrock com Assinatura SigV4 e Parser EventStream - Item #33
  *   **Descrição**: Suporte nativo completo ao provedor AWS Bedrock, utilizando assinaturas criptográficas AWS Signature Version 4 (SigV4) e decodificação sob demanda do stream binário no padrão AWS EventStream.
  *   **Detalhes**:
      *   Desenvolvimento da classe do provedor `TRadIABedrockProvider` na unit `RadIA.Provider.Bedrock.pas` integrado ao barramento central.
      *   Desenvolvimento do utilitário criptográfico `TAwsSigV4Signer` na unit `RadIA.Core.AwsSigner.pas` para cálculo SHA-256 e HMAC-SHA-256 das assinaturas SigV4 exigidas pelos cabeçalhos da Amazon.
      *   Implementação do parser binário `TAwsEventStreamParser` para ler de forma incremental e decodificar payloads binários do tipo EventStream transmitidos nas respostas assíncronas do Bedrock.
      *   Criação da aba VCL correspondente na interface de opções da IDE do Delphi com campos persistidos criptograficamente para as chaves IAM da AWS (Access Key, Secret Key, Region e Session Token).
      *   Inclusão de novos testes unitários em `RadIA.Tests.ProvidersEx.pas`, totalizando a aprovação de **112 testes verdes** na suite completa de testes.
</details>

<details>
  <summary><b>📦 v0.0.11 — Provedores Azure, Qwen e Mistral AI (Clique para expandir)</b></summary>

  #### 1. Provedores Nativos Adicionais (Azure OpenAI, Alibaba Qwen e Mistral AI) - Itens #30, #31, #32
  *   **Descrição**: Adicionado suporte direto e nativo para as APIs oficiais do Azure OpenAI, Alibaba Qwen (ModelStudio) e Mistral AI, com abas dedicadas de configuração, links de atalho para chaves de API, suporte a streaming SSE e ordenação customizada de provedores na interface.
  *   **Detalhes**:
      *   Desenvolvimento das classes de provedores `TRadIAAzureOpenAIProvider`, `TRadIAQwenProvider` e `TRadIAMistralProvider` integradas de forma desacoplada no `TProviderRegistry`.
      *   Mapeamento de chaves de API seguras via Windows DPAPI e parâmetros específicos (como `AzureApiVersion`).
      *   Criação das abas de opções VCL Claro/Escuro para cada provedor na IDE (`Tools -> Options`) e formulário de configurações.
      *   Implementação de ordenação personalizada em `TProviderRegistry.GetProviders` para manter **Ollama** e **LM Studio** sempre no final de todas as listagens de provedores.
      *   Validação com novos testes unitários em `RadIA.Tests.ProvidersEx.pas` e correções de mocks de configuração em `RadIA.Tests.Service.pas`.
</details>

<details>
  <summary><b>📦 v0.0.10 — Conexão Nativa ao GitHub Copilot (Clique para expandir)</b></summary>

  #### 1. Provedor Nativo GitHub Copilot (Fase 2) - Item #29
  *   **Descrição**: Suporte nativo à nuvem do GitHub Copilot com autenticação integrada (Device Flow por PIN) e importação em um clique de chaves do VS Code, além de atalhos rápidos de hyperlink para obtenção de API Keys dos demais provedores.
  *   **Detalhes**:
      *   Desenvolvimento da unit `RadIA.Provider.GithubCopilot.pas` contendo a classe do provedor e seu auto-registro, além do gerenciamento thread-safe do token de sessão temporário obtido de `https://api.github.com/copilot_internal/v2/token`.
      *   Desenvolvimento da unit de UI `RadIA.UI.GithubAuthForm.pas` para o fluxo de autenticação por PIN em segundo plano.
      *   Modificações no frame e formulário de configurações VCL para inclusão da aba do Copilot com botões de login/importação e dos links rápidos de atalho para as demais plataformas.
</details>

<details>
  <summary><b>📦 v0.0.9 — Suporte Multi-IDE no Build (Clique para expandir)</b></summary>

  #### 1. Suporte a Múltiplas Versões do Delphi no Build - Item #27
  *   **Descrição**: Melhoria na robustez do script de build e instalação (`build.ps1`) para suportar máquinas com múltiplos ambientes Delphi instalados, permitindo escolha via menu interativo ou parâmetro.
  *   **Detalhes**:
      *   Implementado o parâmetro `-DelphiVersion` para forçar o uso de uma versão específica do Delphi.
      *   Implementada a varredura dinâmica no Registro do Windows (`HKCU:\Software\Embarcadero\BDS`) para mapear caminhos de instalação reais (`RootDir`) e nomes amigáveis.
      *   Desenvolvido menu interativo no console PowerShell para seleção de versão quando múltiplas IDEs forem detectadas durante a instalação/desinstalação.
      *   Dinamicização de todos os diretórios internos e caminhos da IDE baseados em `$rootDir` ao invés de caminhos estáticos globais no drive C:.
</details>

<details>
  <summary><b>📦 v0.0.8 — Provedor Local LM Studio (Clique para expandir)</b></summary>

  #### 1. Provedor Nativo LM Studio - Item #21c
  *   **Descrição**: Adicionado suporte nativo completo e opcional para o provedor local LM Studio com streaming SSE, autodescoberta de modelos locais e interface de opções.
  *   **Detalhes**:
      *   Criada unit `RadIA.Provider.LMStudio.pas` contendo a classe do provedor e seu auto-registro no `TProviderRegistry`.
      *   Criada a aba dedicada do LM Studio no Frame de opções com estilização baseada no tema da IDE e persistência de URL.
      *   Refatorada a detecção no chat lateral para carregar o LM Studio dinamicamente como opcional (aparecendo se a URL for configurada no registro).
      *   Desenvolvidos novos testes unitários cobrindo a modelagem e streaming SSE da chamada no LM Studio em `RadIA.Tests.ProvidersEx.pas`.
</details>

<details>
  <summary><b>📦 v0.0.6 — Provedores Dinâmicos via JSON (Clique para expandir)</b></summary>

  #### 1. Provedores Dinâmicos via JSON (Plug-ins sem Recompilação) - Item #21b
  *   **Descrição**: Suporte para adicionar novos provedores compatíveis com a API OpenAI apenas colocando arquivos de configuração `.json` no AppData do Rad IA, sem necessidade de recompilar o plugin.
  *   **Detalhes**:
      *   Implementado escaneamento automático de diretório no `TProviderRegistry.LoadJsonProviders` lendo de `%APPDATA%\RadIA\providers\`.
      *   Criação de classe genérica polimórfica `TRadIAGenericOpenAIProvider` servindo como client universal de OpenAI.
      *   Tratamento de fallback da chave de API configurada opcionalmente no JSON e marcação do status dinâmico para listagem incondicional de provedores carregados no chat lateral.
      *   Nova suíte de testes unitários integrada em `RadIA.Tests.JSONProviders.pas`.
</details>

<details>
  <summary><b>📦 v0.0.4 — Produtividade & Análise Estática (Clique para expandir)</b></summary>

  #### 1. Conversor de DTO e Modelos (JSON / DDL ➔ Delphi) - Item #22
  *   **Descrição**: Geração automatizada de classes e records Object Pascal correspondentes a partir de JSON ou scripts SQL DDL, com suporte a DEXT ORM, Aurelius, REST.Json e Vanilla.
  *   **Detalhes**:
      *   Desenvolvido gerador central `TRadIADTOBuilder` em `RadIA.Core.DTO.Generator.pas` com regras dinâmicas de conversão.
      *   Integração com DEXT ORM utilizando Smart Properties (`IntType`, `StringType`, etc.) e tratamento de relacionamentos Lazy (`ILazy<T>`, `TValueLazy<T>`) sem getters/setters desnecessários.
      *   Validação de geração robusta com 96 testes unitários em `RadIA.Tests.DTOGenerator.pas`.

  #### 2. Assistente de Stack Trace, Análise Estática de Código e Menu Popup - Itens #23, #24, #25
  *   **Descrição**: Lançamento dos comandos de barra integrados `/stacktrace` e `/bugs`, juntamente com menu flutuante de sugestões de autocompletar ao digitar `/` no chat.
  *   **Detalhes**:
      *   Mapeamento estático e dinâmico de prompts, com injeção automática de contexto do editor (código da unit ativa ou trechos selecionados).
      *   Popup flutuante de sugestões renderizado com suporte a teclado (`↑`/`↓`/`Enter`/`Esc`) e cliques no mouse no chat do WebView2.
</details>

<details>
  <summary><b>📦 v0.0.3 — Estabilidade de Runtime (Clique para expandir)</b></summary>

  #### 1. Infraestrutura de Provedores Dinâmicos e Simplificados (Plugin-like) - Item #21
  *   **Descrição**: Refatoração da infraestrutura de IA para auto-registro dinâmico de backends de IA, removendo acoplamentos em cascata e enums estáticos.
  *   **Detalhes**:
      *   Implementado o registro centralizado `TProviderRegistry` contendo metadados de provedores (`TProviderMetadata`) e delegação de factory functions.
      *   Implementado o auto-registro dos 7 provedores nativos (Gemini, OpenAI, Claude, Ollama, DeepSeek, Groq e OpenRouter) em suas seções `initialization`.
      *   Desacoplamento do orquestrador `TRadIAService` que agora resolve dinamicamente qualquer provedor a partir do `TProviderRegistry.CreateProvider` sem fallbacks estáticos em loops `case`.
      *   Adicionados novos testes unitários em `RadIA.Tests.Service.pas` cobrindo a integridade do registro e tratamento de erros.
</details>

<details>
  <summary><b>📦 v0.0.2 — Múltiplas Sessões e Gestão de Consumo (Clique para expandir)</b></summary>

  #### 1. Múltiplas Sessões de Chat - Item #5
  *   **Descrição**: Permite organizar conversas por projeto, feature ou tarefa, sem perder o contexto de sessões anteriores.
  *   **Detalhes**:
      *   Armazenamento persistente de sessões em `%APPDATA%\RadIA\sessions\<guid>.json` indexadas em `sessions_index.json` pela classe `TRadIASessionManager`.
      *   Painel lateral retrátil integrado na UI (`pnlSessions`) contendo `ListBox` e controles (Nova Sessão, Renomear, Excluir) com transição suave e botão de Toggle (☰) na barra de ferramentas.
      *   Validação robusta com testes unitários em `RadIA.Tests.Sessions.pas`.

  #### 2. Controle de Cota e Orçamento de Tokens Local - Item #19
  *   **Descrição**: Permite configurar um limite mensal de tokens nas configurações do plugin para evitar surpresas no faturamento das chaves de API, acumulando o consumo localmente e bloqueando requisições.
  *   **Detalhes**:
      *   Integração no Registro do Windows com redefinição mensal automática de cota de tokens.
      *   Controles visuais dinâmicos criados na aba de configurações do painel.
      *   Exibição do percentual de cota consumida na barra de status em HTML na WebView.
      *   Validação completa com testes unitários cobrindo o bloqueio e ciclos de cota em `RadIA.Tests.Quota.pas`.

  #### 3. Provedor Nativo: OpenRouter - Item #20
  *   **Descrição**: Adicionado suporte nativo direto ao OpenRouter com streaming SSE, persistência no registro do Windows, armazenamento seguro de credenciais com DPAPI e listagem de modelos.
  *   **Detalhes**:
      *   Criada a unit `RadIA.Provider.OpenRouter.pas` herdando de `TRadIAOpenAICompatibleProvider`.
      *   Mapeamento de `ptOpenRouter` no enum de provedores, configurações de chaves de API e modelos padrão (`google/gemini-2.5-pro`, `meta-llama/llama-3.3-70b-instruct`, `deepseek/deepseek-r1`).
      *   Adicionada aba `tsOpenRouter` com estilização e suporte de tema VCL para a tela de configurações.
      *   Novos testes unitários em `RadIA.Tests.ProvidersEx.pas` cobrindo geração de payloads, parsing de respostas e buffering SSE.

  #### 4. Context Window Management (Trimming Automático) - Item #10
  *   **Descrição**: Evita erros silenciosos de limite de tokens da API cortando mensagens antigas da conversa ativa quando atinge o limite máximo configurado.
  *   **Detalhes**:
      *   Implementado campo `MaxHistoryMessages` nas configurações (Registro do Windows, padrão: 20).
      *   Orquestrador `TRadIAService.TrimHistory` corta as mensagens mais antigas preservando o prompt de sistema e as mensagens mais recentes.
      *   Validação robusta com 10 testes unitários específicos em `RadIA.Tests.Service.pas`.

  #### 5. Rastreamento de Tokens - Item #14
  *   **Descrição**: Exibe a contagem de tokens (Prompt e Completion) consumidos na barra de status da UI do Chat.
  *   **Detalhes**:
      *   Implementado record `TTokenUsage` para contabilizar tokens de entrada/saída.
      *   Barra de status dinâmica em HTML/CSS/JS sincronizada com o Delphi.
      *   Validação com testes unitários em `RadIA.Tests.TokenUsage.pas`.
</details>

<details>
  <summary><b>📦 v0.0.1 — Lançamento Inicial (Clique para expandir)</b></summary>

  #### 1. Histórico de Prompts (Navegação ↑/↓) - Item #6
  *   **Descrição**: Permite que o desenvolvedor navegue pelas últimas consultas enviadas utilizando as setas para cima/para baixo do teclado.
  *   **Detalhes**:
      *   Criado o gerenciador `TPromptHistoryManager` limitando a 50 entradas persistidas em `%APPDATA%\RadIA\prompt_history.json`.
      *   Captura de teclado no `memPromptKeyDown` para navegação dinâmica de prompts.
      *   Validação com 13 testes unitários dedicados em `RadIA.Tests.PromptHistory.pas`.

  #### 2. Endpoints Compatíveis com OpenAI - Item #8
  *   **Descrição**: Suporte a qualquer provedor compatível com o protocolo da OpenAI apenas trocando a URL base.
  *   **Detalhes**:
      *   Adicionado campo `Custom Base URL` nas configurações de OpenAI (`IAIConfig.OpenAICustomBaseUrl`).
      *   Os métodos de requisição e descoberta de modelos usam a URL personalizada quando fornecida.
      *   Validação com 3 testes unitários dedicados em `RadIA.Tests.Providers.pas`.

  #### 3. Exportar Conversa (.md / .html) - Item #7
  *   **Descrição**: Permite salvar o histórico completo do chat ativo nos formatos Markdown ou HTML estruturado com um único clique.
  *   **Detalhes**:
      *   Botão "Export" integrado à barra lateral e diálogo nativo de salvamento `TSaveDialog`.
      *   HTML standalone exportado com CSS embutido e Prism.js para highlight Pascal.
      *   Validação com 4 testes unitários em `RadIA.Tests.Exporter.pas`.

  #### 4. Templates de Prompt - Item #12
  *   **Descrição**: Biblioteca de templates rápidos de prompt com substituição de código e slash command `/template`.
  *   **Detalhes**:
      *   Menu dinâmico "Tpl" e comando de barra no chat.
      *   Substituição inteligente do marcador `{code}` pelo trecho de código selecionado na IDE.
      *   Validação com 4 testes unitários em `RadIA.Tests.Templates.pas`.

  #### 5. Contexto de Projeto (Arquivo `.radia`) - Item #11
  *   **Descrição**: Permite customizar prompts de sistema e ler arquivos adicionais do projeto como contexto de IA.
  *   **Detalhes**:
      *   Leitor `TProjectContextLoader` que detecta arquivos `.radia` na pasta raiz do projeto Delphi ativo via `IOTAProject`.
      *   Validação com 4 testes unitários em `RadIA.Tests.ProjectContext.pas`.

  #### 6. Streaming de Respostas (SSE) - Item #4
  *   **Descrição**: Exibição incremental token a token (Server-Sent Events) no chat da IDE, otimizando a experiência do usuário.
  *   **Detalhes**:
      *   Streaming SSE nativo implementado nos provedores: OpenAI, Gemini, Claude e Ollama.
      *   Uso de `TStreamingTargetStream` interceptando gravação HTTP em tempo real.
      *   Funções javascript `appendMessage`, `showTypingIndicator` e `hideTypingIndicator` integradas na WebView.
      *   Testes unitários dedicados em `RadIA.Tests.Streaming.pas` cobrindo comportamento incremental, buffers parciais e eventos de conclusão.

  #### 7. Integração com Modelos Locais (Ollama) + Histórico Persistente - Item #3
  *   **Descrição**: Suporte nativo para modelos locais sem chaves pagas e restauração completa de histórico do chat.

  #### 8. Provedores Nativos: DeepSeek e Groq - Item #9
  *   **Descrição**: Adicionado suporte nativo direto aos provedores DeepSeek e Groq com streaming SSE e autodescoberta dinâmica de modelos.
  *   **Detalhes**:
      *   Criada unit `RadIA.Provider.DeepSeek.pas` para conexão com a API DeepSeek.
      *   Criada unit `RadIA.Provider.Groq.pas` para conexão com a API da Groq.
      *   Configurações estendidas para chaves de API com armazenamento seguro e DPAPI.
      *   Novos testes unitários em `RadIA.Tests.ProvidersEx.pas` cobrindo payload, parsing de response e fluxo SSE de streaming.

  #### 9. Cancelamento de Requisições de IA e Novo Design do Prompt - Item #17
  *   **Descrição**: Permite que o desenvolvedor aborte chamadas HTTP de IA ativas de forma assíncrona instantaneamente e redesenha a caixa de entrada de chat no formato de uma cápsula flutuante moderna e responsiva.
  *   **Detalhes**:
      *   Implementado o cancelamento de rede em nível de socket interceptando o callback `OnReceiveData` do `THTTPClient`.
      *   O botão de envio muda de função e ícone dinamicamente para stop (`■`) durante a chamada, e a UI exibe uma mensagem amigável sem erros de encoding.
      *   Fundo do painel de input configurado para transparência nativa (`ParentBackground := True`), com a cápsula (`shpInputBg`) e o memo (`memPrompt`) exibidos de forma destacada e contrastante.

  #### 10. Configurações Avançadas por Provedor de IA - Item #18
  *   **Descrição**: Permite parametrizar valores de geração de IA como Temperatura e Max Tokens individualmente para cada provedor a partir de abas organizadas na tela de configurações.
  *   **Detalhes**:
      *   Campos de edição e persistência dinâmica de parâmetros no Registro do Windows pela classe `TRadIAConfig`.
      *   Mapeamento e integração no payload de requisição HTTP JSON de todos os provedores suportados (Ollama, Gemini, OpenAI, Claude, Groq e DeepSeek).

  #### 11. Conexão Híbrida e Login Web (Plus/Pro) - Item #28
  *   **Descrição**: Implementação de modo complementar de conexão via Login Web em contas de consumidor (ChatGPT Plus/Pro e Gemini Advanced) com automação DOM e ponte JS, convivendo harmoniosamente com o modelo BYOK tradicional (API Keys).
  *   **Detalhes**:
      *   Criação de chaves de configuração e seletor na interface de configurações ("Tools -> Options") por provedor.
      *   Desenvolvimento do script `bridge.js` para controle de input/output do DOM, injeção de CSS para ocultação de elementos desnecessários do site oficial e monitoramento de stream.
      *   Criação do provedor virtual `TRadIAWebViewBridgeProvider` para orquestração síncrona/assíncrona de requisições de IA para a janela ativa do WebView2.
      *   Configuração do User-Agent seguro do Chromium para prevenção de bloqueios OAuth durante o fluxo de autenticação do Google.

  #### 12. Novo Layout de Configurações (Delphi-like) e Integração no Tools -> Options - Item #2
  *   **Descrição**: Separação da tela de configuração em um frame reutilizável integrado nativamente no diálogo global da IDE (`Tools -> Options`), com visual estilizado e mapeamento dinâmico em árvore.
  *   **Detalhes**:
      *   Implementação do frame `TFrameAIConfig` contendo o PageControl e controle das opções.
      *   Implementação do formulário wrapper `TFormAIConfig` contendo uma barra lateral com `TTreeView` e botões de rodapé para manter o comportamento original de popup independente.
      *   Integração da ponte Open Tools API via `TRadIAAddInOptions` (`INTAAddInOptions`) registrando a árvore de categorias sob **Third Party > Rad IA** (com subnós para Gemini, OpenAI, Claude, DeepSeek, Groq, Ollama).
      *   Pintura e estilização automatizada seguindo o tema nativo da IDE usando painéis wrappers individuais para herança de estilo e prevenção de contraste inadequado de cores no tema escuro.
      *   Salvamento automatizado silencioso ao pressionar "OK" nas opções da IDE, e aviso explícito de sucesso apenas no formulário popup standalone.
</details>
