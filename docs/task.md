# Lista de Tarefas: Desenvolvimento do RadIA

Esta é a checklist de desenvolvimento para a implementação do plugin **RadIA**. As tarefas estão divididas por componentes arquiteturais e organizadas de forma sequencial, prontas para execução via comando `/goal`.

---

## Fase 1: Estrutura do Projeto & Configurações
- [x] **Configuração da Solução Delphi**
  - [x] Criar a árvore de pastas física sob `d:\Projetos\PluginDelphiIA\` (`Source/Core`, `Source/Providers`, `Source/Integration`, `Source/UI`, `Source/UI/Web`, `Tests/Source`)
  - [x] Criar o arquivo de grupo de projetos `RadIA.groupproj`
  - [x] Criar o projeto de pacote `RadIA.dpk` e o descritor de projeto `RadIA.dproj` pré-configurado para Delphi 10.4+ (BDS 21.0+)
- [x] **Interfaces e Tipos do Core**
  - [x] Criar `RadIA.Core.Types.pas` contendo enums dos provedores, modelos suportados e tipos de dados comuns (DTOs de mensagens)
  - [x] Criar `RadIA.Core.Interfaces.pas` com a declaração dos contratos das interfaces de serviço (`IIAProvider`, `IAIConfig`, `IChatMessage`)
- [x] **Gerenciador de Configurações**
  - [x] Criar `RadIA.Core.Config.pas` implementando o salvamento no Registro do Windows (`HKEY_CURRENT_USER\Software\RadIA`)
  - [x] Implementar criptografia de API keys usando a DPAPI do Windows (`CryptProtectData` e `CryptUnprotectData` via Unit `Winapi.Crypt`)

---

## Fase 2: Integração com as APIs de IA (Providers)
- [/] **Provedor Base**
  - [/] Criar `RadIA.Provider.Base.pas` com as funções comuns de requisições HTTP REST usando o componente nativo `System.Net.HttpClient.THTTPClient`
- [ ] **Implementação das APIs**
  - [ ] Criar `RadIA.Provider.Gemini.pas` integrando com a API do Google Gemini (geração de conteúdo)
  - [ ] Criar `RadIA.Provider.OpenAI.pas` integrando com a API do ChatGPT (chat completion)
  - [ ] Criar `RadIA.Provider.Claude.pas` integrando com a API do Anthropic Claude (messages API)
- [ ] **Orquestrador de IA**
  - [ ] Criar `RadIA.Core.Service.pas` contendo o orquestrador `TRadIAService` que seleciona a IA ativa e executa as chamadas em threads assíncronas (`System.Threading.TTask`), implementando isolamento rigoroso de exceções globais para estabilidade da IDE

---

## Fase 3: Integração com a IDE Delphi (Open Tools API)
- [ ] **Utilitários da IDE**
  - [ ] Criar `RadIA.OTA.Helper.pas` com métodos auxiliares para ler o texto selecionado, obter o buffer do editor de código ativo e substituir blocos de texto
- [ ] **Extração de Contexto do Código**
  - [ ] Criar `RadIA.OTA.ContextParser.pas` com o analisador de contexto capaz de extrair a cláusula `interface` da Unit ativa e os atributos da classe onde está o cursor do desenvolvedor
- [ ] **Hook de Erros de Build**
  - [ ] Criar `RadIA.OTA.MessageViewHook.pas` que monitora a Messages View da IDE e extrai dados do erro compilado ao disparar a ação do menu de contexto
- [ ] **Menus e Registro do Plugin**
  - [ ] Criar `RadIA.OTA.EditorHook.pas` para gerenciar atalhos de teclado e customizações de menus
  - [ ] Criar `RadIA.OTA.Register.pas` para registrar o Wizard na IDE e criar as opções do menu no menu `Tools` e no menu de contexto do botão direito do editor de código

---

## Fase 4: Interface do Usuário (VCL + Edge/WebView2)
- [ ] **Páginas e Estilos do Chat (Web)**
  - [ ] Criar `Source/UI/Web/chat.html` com estrutura de mensagens (balões) e suporte a temas Light/Dark
  - [ ] Criar `Source/UI/Web/chat.css` com estilos limpos e modernos (fontes profissionais, design de caixa de código)
  - [ ] Criar `Source/UI/Web/chat.js` incluindo Marked.js (Markdown parser) e Prism.js (Syntax Highlighting) e listeners de recebimento de dados do Delphi
- [ ] **Frames VCL do Chat e Configurações**
  - [ ] Criar `RadIA.UI.ChatFrame.pas` / `.dfm` gerenciando o `TEdgeBrowser`/`TWebBrowser` e a área de entrada de texto
  - [ ] Criar `RadIA.UI.ConfigFrame.pas` / `.dfm` contendo a UI VCL para configuração das chaves de API e seleção do modelo ativo de cada IA
- [ ] **Visualizador de Diff (Smart Diff Form)**
  - [ ] Criar `RadIA.UI.DiffForm.pas` / `.dfm` implementando a tela modal lado a lado para aceitar ou descartar as refatorações sugeridas via interface web local baseada em `diff2html`
- [ ] **Formulário Acoplável (Dockable Form)**
  - [ ] Criar `RadIA.OTA.DockableForm.pas` que implementa `INTADockableForm`, encapsula o frame do chat e se ajusta automaticamente ao tema de cores atual da IDE através de `IOTAThemeServices`

---

## Fase 5: Testes Unitários e Validação
- [ ] **Criação do Projeto de Testes**
  - [ ] Criar o projeto de console DUnitX `Tests/RadIATests.dproj` e o ponto de entrada `RadIATests.dpr`
- [ ] **Escrita das Suítes de Teste**
  - [ ] Criar `RadIA.Tests.Config.pas` para testar persistência e criptografia das credenciais no registro do Windows
  - [ ] Criar `RadIA.Tests.Providers.pas` com testes de parser de JSON, formatação de payloads e simulação de erro de HTTP
- [ ] **Validação Final da IDE**
  - [ ] Compilar, instalar o pacote e testar a usabilidade de docking, atalhos rápidos e o fluxo completo de "Otimizar Código" com a tela de Diff

---

## Critérios de Aceitação para Entrega
- [ ] **Compilação Sem Erros (Zero Errors/Warnings)**
  - [ ] Compilar com sucesso o pacote principal (`RadIA.dpk`) pelo compilador do Delphi no terminal (MSBuild / DCC32 / DCC64) ou na IDE.
  - [ ] Compilar com sucesso o projeto de testes unitários (`RadIATests.dproj`).
- [ ] **Suíte de Testes Unitários Aprovada**
  - [ ] Executar a suíte de testes do DUnitX (`RadIATests.exe`) e garantir que 100% dos testes unitários passem sem falhas.

