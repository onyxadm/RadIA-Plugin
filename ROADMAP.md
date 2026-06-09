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

## ✅ v0.0.4 — Produtividade Avançada e Análise Estática (Concluído)

A versão v0.0.4 trouxe recursos de análise avançada de código, automação de testes e atalhos de usabilidade no painel:

- **Conversor de DTO e Modelos (JSON / DDL ➔ Delphi):**
  * Conversão de payloads JSON ou DDL para classes e records Delphi, com suporte nativo a Vanilla, DEXT, Aurelius e REST.Json.
- **Assistente de Stack Trace:**
  * Análise inteligente de relatórios de exceções e erros (MadExcept, EurekaLog) com mapeamento de causa raiz no arquivo aberto na IDE.
- **Analisador de Memory Leaks e Anti-patterns:**
  * Análise estática da unit ativa na IDE com foco em detecção de try..finally faltantes e infrações de SOLID.
- **Popup Menu de Atalhos Barra (Slash Commands - /):**
  * Caixa de prompt interativa que exibe atalhos rápidos de comandos barra (como `/explain`, `/refactor`, `/bugs`, `/doc`, `/review`, `/stacktrace`) ao digitar `/`.

---

## ✅ v0.0.5 — Desacoplamento do Provedor e Otimizações de UI (Concluído)

A versão v0.0.5 focou em refatoração estrutural profunda e melhorias na tela de opções:

- **Arquitetura Dinâmica sem Enum:**
  * Removido o enum global estático `TAIProviderType`. O plugin agora utiliza 100% strings dinâmicas (`FProviderId`) para identificar, salvar configurações e gerenciar o ciclo de vida dos provedores de IA.
- **Correções Visuais na UI de Configurações:**
  * Corrigida a aba superior "Templates" que aparecia de forma indesejada em todos os painéis das opções do Delphi.
  * Ocultação e limpeza das referências do recurso experimental "Inline Autocomplete" nesta branch para mantê-la focada e isolada da branch dedicada ao recurso.
- **Documentação de Extensibilidade:**
  * Guias de novos provedores (`new_provider_guide.md` e seu equivalente em inglês) totalmente atualizados refletindo as novidades da API baseada em strings.

---

## ✅ v0.0.6 — Provedores Dinâmicos via JSON e Suporte ao Copilot (Concluído)

A versão v0.0.6 expandiu drasticamente a extensibilidade do plugin ao permitir adição ad-hoc de novos modelos sem recompilação e suporte a IAs corporativas:

- **Provedores Dinâmicos via JSON (Plug-ins sem Recompilação):**
  * Suporte para adicionar qualquer provedor compatível com OpenAI criando arquivos `.json` na pasta `%APPDATA%\RadIA\providers\`.
- **Suporte ao GitHub Copilot (Proxy Local - Fase 1):**
  * Integração documentada passo a passo para conectar assinaturas corporativas ou pessoais do Copilot via utilitários de proxy local (como o `copilot-gpt4-service`), viabilizando o compliance e economia de custos em empresas.

---

## ✅ v0.0.7 — System Prompt Padrão e Ajustes de Configuração (Concluído)

A versão v0.0.7 introduziu melhorias e otimizações nas configurações iniciais do assistente:

- **System Prompt Otimizado Padrão:**
  * Definição de uma diretriz padrão (fallback) estruturada que instrui a IA a responder no mesmo idioma do usuário e retornar apenas trechos específicos e limpos de código Pascal, evitando respostas verbosas com units Delphi completas.
- **Respeito às Preferências Gravadas:**
  * O prompt padrão funciona de forma não-intrusiva como valor de inicialização padrão (default) e não substitui de forma oculta ou forçada as customizações que o desenvolvedor já gravou e salvou no Registro do Windows.

---

## ✅ v0.0.8 — Provedor Local LM Studio e Estabilidade de Testes (Concluído)

A versão v0.0.8 adicionou suporte nativo e opcional para o LM Studio como provedor local de IA e refinou a robustez dos testes unitários:

- **Provedor Nativo LM Studio:**
  * Integração direta da classe `TRadIALMStudioProvider` herdando de `TRadIAOpenAICompatibleProvider`.
  * URL padrão local definida em `http://localhost:1234/v1`.
  * Comportamento 100% opcional (assim como o Ollama): o provedor só é exibido no combo de chat se possuir URL ativa configurada nas opções, mantendo a lista limpa para quem não o utiliza.
- **Tela de Opções da IDE:**
  * Nova aba dedicada para o LM Studio na tela de opções (`Tools -> Options -> Third Party -> RadIA`) com tratamento de temas nativos Claro e Escuro da IDE.
- **Suite de Testes Automatizada:**
  * Criação de testes unitários em `RadIA.Tests.ProvidersEx.pas` cobrindo payload, resposta e streaming SSE do LM Studio (totalizando 103 testes DUnitX aprovados na suite).


---

## ✅ v0.0.9 — Suporte Multi-IDE e Acentuação de Build (Concluído)

A versão v0.0.9 refinou a infraestrutura de compilação e suporte a múltiplos ambientes de desenvolvimento Delphi no Windows:

- **Instalador Multi-IDE Dinâmico:**
  * O script `build.ps1` agora descobre todas as versões instaladas do Delphi varrendo a chave `HKCU:\Software\Embarcadero\BDS` no Registro.
  * Inclusão do parâmetro `-DelphiVersion` para definir qual IDE utilizar.
  * Exibição de menu interativo no terminal PowerShell para escolha quando múltiplas versões forem detectadas (com opção de Cancelar de forma segura).
  * Injeção dinâmica do compilador (`dcc32` correspondente) e dinamicização de caminhos da IDE através de `$rootDir`.
- **Compatibilidade do Console:**
  * Remoção completa de caracteres acentuados nas strings de console PowerShell para prevenir problemas de codificação de console (UTF-8/CP1252/CP850) em diferentes sistemas.

---

## ✅ v0.0.10 — Suporte Nativo ao GitHub Copilot (Concluído)

A versão v0.0.10 introduziu o suporte nativo e oficial para conexão direta com o GitHub Copilot remoto na nuvem e atalhos na UI para obtenção de chaves de API:

- **Provedor Nativo GitHub Copilot (Fase 2):**
  * Classe `TRadIAGithubCopilotProvider` integrada herdando de `TRadIAOpenAICompatibleProvider` para comunicação 100% remota com a nuvem do GitHub Copilot (`https://api.githubcopilot.com`) sem a necessidade de proxies locais.
  * Gerenciamento e renovação em background de tokens de sessão temporários via `https://api.github.com/copilot_internal/v2/token` a partir da chave permanente.
- **UX de Autenticação Facilitada:**
  * Login por código PIN integrado diretamente na tela de opções (OAuth Device Flow) com abertura automática do navegador do sistema.
  * Botão de importação rápida de token do VS Code em um clique (leitura do arquivo `hosts.json`).
- **Links Rápidos para API Keys:**
  * Atalhos no formato de hyperlink ao lado dos campos de chave na UI (Gemini, OpenAI, Claude, DeepSeek, Groq e OpenRouter) apontando direto para os consoles de desenvolvedores oficiais.

---

## ✅ v0.0.11 — Provedores Nativos Adicionais (Concluído)

A versão v0.0.11 expandiu as conexões diretas BYOK do plugin ao introduzir suporte nativo e otimizado para três grandes provedores de IA:

- **Azure OpenAI Nativo:**
  * Implementação da classe de provedor `TRadIAAzureOpenAIProvider` com mapeamento do parâmetro `AzureApiVersion` e suporte a URLs personalizadas e chaves criptografadas via DPAPI.
- **Alibaba Qwen (ModelStudio) Nativo:**
  * Comunicação direta com a API oficial do Alibaba Cloud ModelStudio para acesso à família de modelos **Qwen 2.5** (incluindo o *Qwen 2.5 Coder*).
- **Mistral AI Nativo:**
  * Integração nativa com os endpoints oficiais e modelos da Mistral AI.
- **Aba de Configurações e UI:**
  * Criação de abas VCL com suporte nativo a temas Claro e Escuro da IDE do Delphi para os três provedores, bem como links de atalho para obtenção das API Keys.
- **Ordenação Customizada de Provedores:**
  * Implementação de ordenação personalizada na listagem de provedores do chat e WebView, garantindo que os provedores locais **Ollama** e **LM Studio** fiquem estritamente localizados no final de todas as listas.
- **Suite de Testes Unitários:**
  * Atualização da suite de testes para cobrir a modelagem de payloads e streaming SSE das novas APIs com 109 testes verdes (DUnitX).

---

## ✅ v0.0.12 — Provedor AWS Bedrock e Estabilização (Concluído)

A versão v0.0.12 adicionou suporte oficial para o provedor AWS Bedrock, incluindo assinatura criptográfica segura SigV4 e decodificação incremental de streaming EventStream:

- **Provedor AWS Bedrock Nativo:**
  * Implementação da classe `TRadIABedrockProvider` em `RadIA.Provider.Bedrock.pas` integrada ao barramento de registro central.
  * Criação do utilitário `TAwsSigV4Signer` em `RadIA.Core.AwsSigner.pas` para cálculo e assinatura criptográfica de cabeçalhos de requisição seguindo a especificação AWS Signature Version 4.
  * Implementação do parser binário `TAwsEventStreamParser` para processar incrementalmente frames de streaming no formato binário AWS EventStream, convertendo-os em blocos de texto SSE em tempo real.
- **Aba de Configurações e Persistência:**
  * Criação de aba de configurações específica para o AWS Bedrock na UI (`Tools -> Options`), com persistência segura das credenciais AWS Access Key, Secret Key, Region e Session Token via Windows DPAPI.
- **Resolução de Bugs e Testes:**
  * Correção de vazamento/loop infinito de processamento de bytes no parser EventStream.
  * Correção de conflito de resolução RTTI nos testes unitários e coerção de parâmetros reais.
  * Atualização da suite de testes unitários (`RadIA.Tests.ProvidersEx.pas`), alcançando **112 testes DUnitX aprovados**.

---

## ✅ v0.0.13 — Geração de Projetos Delphi Inteiros via Prompt (Concluído)

A versão v0.0.13 adicionou suporte para criação automatizada de projetos Delphi completos a partir de um prompt, com gravação física e carregamento imediato na IDE:

- **Geração de Projeto Inteiro:**
  * Nova classe de serviço especialista `TRadIAProjectGenerator` (em `RadIA.Core.ProjectGenerator.pas`) para parsear múltiplos arquivos via JSON.
  * Diálogo de salvamento dinâmico que exige obrigatoriamente uma pasta destino vazia para segurança de dados.
  * Mecanismo transacional de gravação que desfaz a operação de salvamento caso ocorra qualquer erro de disco ou escrita.
  * Autodetecção inteligente de projetos (.dproj e .dpr) e abertura automática na IDE usando a Open Tools API.
- **Prompt Template e Slash Command `/createproject`:**
  * Centralização das diretivas do prompt no gerenciador de templates (`TPromptTemplateManager` em `RadIA.Core.PromptTemplates.pas`), mantendo o design alinhado com o princípio de responsabilidade única.
  * Injeção de regras rígidas de formatação de código com o comentário de metadado `// filepath: caminho/relativo`.
- **Interface Premium de Projeto:**
  * Painel consolidado com visual premium (glassmorphism moderno) listando todos os arquivos gerados com ícones elegantes por extensão.
  * Navegação interativa que rola a tela do chat de forma suave (`scrollIntoView`) e destaca o bloco correspondente com uma animação de borda flash ao inspecionar o arquivo na lista.

---

## ✅ v0.0.14 — Templates Dinâmicos, Backup e Nova Arquitetura de Projetos (Concluído)

A versão v0.0.14 trouxe flexibilidade total para gerenciamento de prompts e templates de projetos na IDE, além de suporte a backup importável e um gerador de projetos otimizado:

- **Customização Dinâmica de Slash Commands:**
  * Remoção completa de ifs estáticos hardcoded no processamento de comandos. Agora o RadIA varre dinamicamente a lista de templates ativos para reconhecer e aplicar os slash commands e seus argumentos correspondentes.
  * Sincronização automatizada da lista de slash commands com a interface web (WebView2) para autocompletar dinamicamente no chat.
- **Mecanismo de Backup de Templates (Importar / Exportar):**
  * Botões dedicados e diálogos nativos do Windows integrados à UI da VCL (`Tools -> Options -> RadIA -> Templates`).
  * Implementação de exportação e importação estrutural robusta de arquivos JSON, realizando validação rigorosa das propriedades mandatórias (`name` e `template`).
  * Suporte transacional para mesclar (*Merge*) com os templates atuais ou sobrescrevê-los (*Overwrite*) por completo.
- **Template Otimizado de Arquitetura Clean Delphi (`/createprojectarch`):**
  * Criação do template nativo `'Create Project Delphi Architecture'` incorporando conceitos arquiteturais sólidos (SOLID, injeção de dependência via interfaces, isolamento de lógica de negócio e try..finally sistemático para garantia de liberação de memória).
- **Suite de Testes e Correções:**
  * Atualização da suite de testes para cobrir as rotinas de importação (com e sem merge), validação de erros sintáticos e exportação. Todos os **112 testes unitários DUnitX aprovados**.

---

## ✅ v0.0.15 — Arquitetura de Templates em Duas Camadas e Overlays (Concluído)

A versão v0.0.15 introduziu a segregação completa dos templates padrões de prompts definidos no código daqueles criados ou modificados pelo usuário (gravados em disco), garantindo que atualizações de prompts padrões no código se propaguem automaticamente:

- **Segregação Físico-Lógica de Templates:**
  * Armazenamento limpo e delta no arquivo local `templates.json` (contém apenas novos templates do usuário ou overlays de customização).
  * Mesclagem dinâmica de runtime (`BuildActiveTemplates`) entre os templates embutidos do sistema e os customizados do usuário.
- **Higienização de Dados Redundantes (Auto-Migration):**
  * Limpeza automática (`CleanRedundantUserTemplates`) de itens redundantes no JSON local que coincidem exatamente com a versão atualizada do código do plugin.
- **Premium UX de Gerenciamento de Origem:**
  * Indicador dinâmico de origem (`Origin: Default System (Read-Only)`, `Origin: Default System (Customized)` e `Origin: User Custom`) criado programaticamente no frame de opções.
  * Lógica inteligente de controle dos botões VCL (botão Excluir vira **"Restaurar Padrão"** para overlays, limpando a customização e reativando as propriedades originais do sistema).
- **Testes Unitários:**
  * Inclusão de testes de unidade cobrindo detecção de templates nativos, criação de overlays e restauração ao padrão. Todos os **116 testes unitários DUnitX aprovados**.

## 🔲 v0.1.0 — Automação, Auditoria e Ganhos Rápidos (Próxima Versão)

### 1. Smart SQL Optimizer no Editor (Quick Win)
*   **Objetivo**: Detectar strings de comandos SQL dentro do código Pascal ativo e oferecer uma refatoração assistida para otimização de performance, indexação sugerida e validação de sintaxe conforme o dialeto do banco de dados configurado.
*   **Impacto**: ⭐⭐⭐⭐ Alto
*   **Complexidade**: Baixa

### 2. Revisão Automática de Código no Save
*   **Objetivo**: Analisar a unit silenciosamente ao salvar e sinalizar no painel do RadIA se a IA encontrou pontos de atenção (ex: possíveis bugs, código duplicado ou falta de tratamento de exceção).
*   **Impacto**: ⭐⭐⭐⭐ Alto
*   **Complexidade**: Média

### 3. Histórico de Refatorações Aplicadas
*   **Objetivo**: Manter um log auditável de todas as vezes que o botão **[Aplicar Alteração]** foi acionado, registrando o trecho original, o trecho aplicado, a data e o arquivo, permitindo revisão manual posterior.
*   **Impacto**: ⭐⭐⭐ Médio
*   **Complexidade**: Baixa

---

## 🔲 v0.2.0 — Administração e Análise Estrutural

### 5. Otimizador de Cláusula Uses (Clean Uses)
*   **Objetivo**: Analisar a cláusula `uses` da unit ativa para sugerir a remoção de imports órfãos e sugerir a importação automática de units do sistema ou de terceiros quando classes conhecidas forem digitadas sem seus respectivos imports.
*   **Impacto**: ⭐⭐⭐⭐ Alto
*   **Complexidade**: Média

### 6. Gerador de Mocks para Testes Unitários
*   **Objetivo**: Analisar os construtores e dependências de uma classe Pascal selecionada para gerar classes Mock automatizadas (puros com interfaces ou integrando o framework `Delphi-Mocks`), facilitando a escrita de testes isolados.
*   **Impacto**: ⭐⭐⭐⭐ Alto
*   **Complexidade**: Média

### 7. Gerador de Documentação OpenAPI/Swagger (Horse, RAD Server)
*   **Objetivo**: Varrer as configurações de rotas e controllers de APIs Delphi modernas para extrair automaticamente a especificação Swagger (JSON/YAML) e mapear os esquemas JSON dos DTOs associados.
*   **Impacto**: ⭐⭐⭐⭐ Alto
*   **Complexidade**: Média

### 8. Análise Semântica Bidirecional (DFM vs PAS)
*   **Objetivo**: Varrer de forma cruzada o arquivo visual de formulário (`.dfm`) e a unit `.pas` para sinalizar e remover com segurança componentes órfãos e declarações de eventos vazios que continuam declarados e poluindo o código.
*   **Impacto**: ⭐⭐⭐⭐ Alto
*   **Complexidade**: Média

### 9. Assistente de Migração de Versão (Smart Migrate)
*   **Objetivo**: Comando contextual de menu ou chat lateral para reescrever trechos selecionados de código procedurais/legados usando recursos modernos do Delphi (Unicode, PPL, FireDAC).
*   **Impacto**: ⭐⭐⭐⭐ Alto
*   **Complexidade**: Média

### 10. Painel de Gerenciamento do Cache
*   **Objetivo**: Exibir uma tela de administração interna do cache de respostas, permitindo visualizar entradas em cache, limpar entradas específicas e ver o tamanho total do arquivo de cache sem editar o JSON manualmente.
*   **Impacto**: ⭐⭐⭐ Médio
*   **Complexidade**: Média

---

## 💡 Ideias Futuras (v0.3.0+)

Os itens abaixo ainda estão em fase de concepção e avaliação de viabilidade técnica com a Open Tools API e dependem de refatorações complexas ou hooks de baixo nível:

- **Conversão BDE/ADO/dbExpress ➔ DEXT com FireDAC:** Migração profunda e estruturada de persistência de dados manual legada e acoplada em formulários para o DEXT ORM de forma orientada a objetos usando FireDAC por baixo (Complexidade: Alta).
- **Decompositor de Formulários Legados (Code-Behind Extractor):** Extração cirúrgica de lógica de negócio acoplada nos eventos visuais do code-behind para classes de serviço independentes, criando acoplamentos limpos e interfaces (Complexidade: Alta).
- **Assistente de Threads e PPL (Parallel Programming Library):** Identificar trechos síncronos demorados no editor e reescrevê-los para execução segura em segundo plano usando `TTask.Run` e sincronizações de UI com `TThread.Queue` (Complexidade: Alta).
- **Internacionalização Automática (i18n Wizard):** Varrer PAS e DFM para extrair strings literais exibidas na tela, organizá-las em arquivos de localização centralizados e substituir as ocorrências no código por chamadas de funções de tradução (Complexidade: Alta).
- **Autocompletar Inline Inteligente (Ghost Text):** Sugestões de código em tempo real no editor de código com texto acinzentado estilo Copilot (Complexidade: Alta).
- **Integração Automática com Depurador da IDE:** Captura dinâmica e análise automática de exceções ativas durante sessões de depuração de código (Complexidade: Alta).
- **Geração automática de documentação de projeto:** Varrer a estrutura de diretórios e unidades do projeto para compilar e gerar um `docs/API.md` estruturado (Complexidade: Média).
- **Suporte nativo a macOS/Linux:** Portar a UI e integrações de editor para o Lazarus / Free Pascal (Complexidade: Alta).

---

## 🤝 Como Contribuir

Contribuições são muito bem-vindas! Caso queira implementar algum dos itens deste roadmap:

1. Faça um **fork** do repositório.
2. Crie uma branch descritiva: `feature/multiplas-sessoes`.
3. Implemente as mudanças seguindo os princípios **SOLID, Clean Code e DRY** adotados no projeto.
4. Certifique-se de que o comando `powershell -ExecutionPolicy Bypass -File .\build.ps1 -Test` passa com **todos os testes verdes**.
5. Abra um **Pull Request** descrevendo a sua contribuição.

> [!IMPORTANT]
> Todo o código-fonte do projeto é escrito **obrigatoriamente em inglês** (nomes de variáveis, métodos, classes, comentários). A documentação pode ser escrita em português ou inglês.
