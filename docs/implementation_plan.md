# Plano de Implementação: RadIA - Assistente de IA para Delphi IDE

Este documento descreve o planejamento técnico e a arquitetura para o desenvolvimento do plugin de IDE para o Embarcadero Delphi, permitindo chat integrado e comandos rápidos no editor de código com suporte a múltiplos provedores de IA (Google Gemini, OpenAI ChatGPT, Anthropic Claude).

## Arquitetura de Alto Nível

O plugin será desenvolvido como um **Design-time Package (.bpl)** do Delphi, integrando-se à IDE através da **Open Tools API (OTA)**. 

### Visão Geral dos Componentes

```mermaid
graph TD
    IDE[Delphi IDE / ToolsAPI] -->|Registra Wizard/Dockable| WizardManager[TAIWizardManager]
    IDE -->|Acesso ao Editor| EditorIntegration[TEditorIntegrationManager]
    
    WizardManager -->|Gerencia| DockableForm[TFormAIDockable]
    DockableForm -->|Apresenta Chat| ChatFrame[TFrameAIChat]
    DockableForm -->|Apresenta Configs| ConfigFrame[TFrameAIConfig]
    
    ChatFrame -->|Usa| AIService[TAIService]
    EditorIntegration -->|Usa| AIService
    
    AIService -->|Lê/Grava| ConfigManager[TAIConfigManager]
    AIService -->|Usa| IAProviderFactory[TIAProviderFactory]
    
    IAProviderFactory -->|Instancia| IIAProvider
    IIAProvider <|.. GoogleGeminiProvider[TGoogleGeminiProvider]
    IIAProvider <|.. OpenAIProvider[TOpenAIProvider]
    IIAProvider <|.. AnthropicClaudeProvider[TAnthropicClaudeProvider]
    
    IIAProvider -->|HTTP Request Assíncrona| HTTPClient[System.Net.HttpClient]
```

---

## User Review Required

> [!IMPORTANT]
> **1. Versão Alvo do Delphi: Delphi 10.4 Sydney em diante**
> O plugin focará no suporte a partir do **Delphi 10.4 Sydney**, estendendo-se até o **Delphi 11 Alexandria** e **Delphi 12 Athens**. Ao remover o suporte para versões anteriores (10.3 Rio e inferiores), evitamos a necessidade de lidar com o motor de renderização legado do Internet Explorer (MSHTML), simplificamos a compatibilidade de High DPI na IDE e facilitamos o uso de sintaxes mais modernas do Delphi.
> *A compilação do pacote (.dpk) e registro na IDE serão projetados exclusivamente para a IDE BDS 21.0 (10.4) e superiores.*

> [!TIP]
> **2. Renderização do Chat via Edge WebView2 Nativamente**
> Como o alvo mínimo é o Delphi 10.4 Sydney:
> *   Utilizaremos o componente nativo `TEdgeBrowser` (ou `TWebBrowser` configurado obrigatoriamente com `WindowsEngine = EdgeOnly`).
> *   Isso garante suporte nativo a HTML5, CSS3 moderno e Javascript ES6+, necessários para renderizar o Chat com visual premium, Markdown completo, blocos de código com botões de cópia rápida e syntax highlighting via Prism.js.
> *   **Requisito de Runtime:** O desenvolvedor precisará ter o *Microsoft Edge WebView2 Runtime* instalado no Windows (hoje pré-instalado por padrão no Windows 10/11 atualizados). Na inicialização do plugin, caso o runtime WebView2 não esteja disponível, exibiremos uma mensagem amigável no lugar do chat orientando o download.

> [!WARNING]
> **3. Segurança das API Keys no Registro do Windows**
> Conforme definido, as configurações do plugin serão salvas no Registro do Windows no caminho:
> `HKEY_CURRENT_USER\Software\RadIA`
> Desta forma, as configurações e chaves de API persistirão globalmente, mesmo quando o desenvolvedor alternar entre diferentes versões do Delphi instaladas na mesma máquina (ex: trabalhando no 10.4 e 12 na mesma máquina). As chaves de API (`API Keys`) de cada provedor serão **criptografadas** localmente antes de serem persistidas, utilizando a Windows Data Protection API (DPAPI via `CryptProtectData`), garantindo que apenas o usuário logado no Windows possa decifrá-las.

---

## Open Questions

As perguntas iniciais de planejamento foram resolvidas e alinhadas:
*   **Versão do Delphi:** Delphi 10.4 Sydney em diante (suportando 10.4, 11 e 12).
*   **Mecanismo de Renderização:** `TEdgeBrowser` / `TWebBrowser` (Edge Chromium nativo via WebView2).
*   **Persistência:** Registro do Windows (`HKEY_CURRENT_USER\Software\RadIA`), utilizando DPAPI para criptografar as chaves.

---

## Proposed Changes

### Estrutura de Diretórios Proposta

Propomos a seguinte organização do repositório para manter separação clara de responsabilidades (SOLID):

```
PluginDelphiIA/
│
├── README.md                           # Documentação básica do projeto
│
├── RadIA.groupproj                     # Project Group do Delphi
├── RadIA.dpk                           # Pacote de Design-time principal
├── RadIA.dproj                         # Projeto do pacote Delphi
│
├── Source/
│   ├── Core/
│   │   ├── RadIA.Core.Interfaces.pas    # Definição de IIAProvider, IAIConfig, etc.
│   │   ├── RadIA.Core.Config.pas        # Implementação do Gerenciador de Configurações
│   │   ├── RadIA.Core.Service.pas       # Orquestrador de requisições às IAs (Thread-safe)
│   │   └── RadIA.Core.Types.pas         # Tipos comuns, Enums, DTOs
│   │
│   ├── Providers/
│   │   ├── RadIA.Provider.Base.pas      # Classe base para os provedores (HTTP Client comum)
│   │   ├── RadIA.Provider.Gemini.pas    # Integração com API do Google Gemini
│   │   ├── RadIA.Provider.OpenAI.pas    # Integração com API da OpenAI
│   │   └── RadIA.Provider.Claude.pas    # Integração com API do Anthropic Claude
│   │
│   ├── Integration/
│   │   ├── RadIA.OTA.Register.pas       # Registro do Wizard e pacotes na IDE
│   │   ├── RadIA.OTA.Helper.pas         # Utilitários para interagir com a Open Tools API
│   │   ├── RadIA.OTA.EditorHook.pas     # Captura de eventos do editor de código
│   │   └── RadIA.OTA.DockableForm.pas   # Form dockable que encapsula a UI
│   │
│   └── UI/
│       ├── RadIA.UI.ChatFrame.pas       # Frame principal de conversa (VCL)
│       ├── RadIA.UI.ChatFrame.dfm
│       ├── RadIA.UI.ConfigFrame.pas     # Frame de configurações de modelos e chaves (VCL)
│       ├── RadIA.UI.ConfigFrame.dfm
│       ├── RadIA.UI.Resources.pas       # Recursos visuais, ícones (SVG/PNG) e scripts
│       └── Web/
│           ├── chat.html                # Template HTML para renderização no EdgeBrowser
│           ├── chat.css                 # Estilos modernos (Glassmorphism / Dark Mode adaptivo)
│           └── chat.js                  # Lógica JS de interação (Prism.js para realce de código)
│
└── Tests/
    ├── RadIATests.dproj                 # Projeto de Testes Unitários
    ├── Source/
    │   ├── RadIA.Tests.Providers.pas    # Testes de parse JSON e envio de payloads
    │   └── RadIA.Tests.Config.pas       # Testes de criptografia e leitura/escrita de configs
    └── RadIATests.dpr                   # Ponto de entrada DUnitX
```

---

### Detalhamento dos Componentes Técnicos

#### 1. Core e Interfaces (`DelphiAI.Core.Interfaces.pas`)

Definição de contratos para permitir a troca fácil de provedores de IA sem impacto no resto do plugin.

```pascal
unit RadIA.Core.Interfaces;

interface

uses
  System.SysUtils, System.Classes;

type
  // Callback para chamadas assíncronas de IA
  TIACompletionCallback = reference to procedure(const AResponse: string; const AError: string);

  // Interface para representação do histórico do chat
  IChatMessage = interface
    ['{69A8A5DC-0F88-46E1-AD7A-8A46101EA97D}']
    function GetRole: string; // 'user', 'assistant', 'system'
    function GetContent: string;
    procedure SetContent(const AValue: string);
  end;

  // Interface comum que todos os provedores de IA devem implementar
  IIAProvider = interface
    ['{A2833F49-9A0B-432D-8B8D-20DFF15FF25D}']
    procedure SendPromptAsync(const APrompt: string; const AHistory: TArray<IChatMessage>; 
      const ACallback: TIACompletionCallback);
    function GetAvailableModels: TArray<string>;
    function GetName: string;
  end;

  // Interface para gerenciar configurações
  IAIConfig = interface
    ['{88A9678F-520E-4BF5-BFB4-5C04A5826A6F}']
    function GetApiKey(const AProvider: string): string;
    procedure SetApiKey(const AProvider: string; const AKey: string);
    function GetActiveProvider: string;
    procedure SetActiveProvider(const AProvider: string);
    function GetActiveModel(const AProvider: string): string;
    procedure SetActiveModel(const AProvider: string; const AModel: string);
    procedure Save;
    procedure Load;
  end;

implementation

end.
```

#### 2. Provedores de IA (`DelphiAI.Provider.*`)

Cada provedor herdará de uma classe base comum `TAIProviderBase` que gerencia requisições HTTP assíncronas usando `System.Net.HttpClient.THTTPClient` em background tasks (`System.Threading.TTask`), garantindo que a IDE do Delphi continue responsiva durante a geração da resposta.

*   **Google Gemini:** Utilizará o endpoint `/v1beta/models/{model}:generateContent` (ou versão v1 se disponível).
*   **OpenAI:** Utilizará o endpoint `/v1/chat/completions`.
*   **Claude:** Utilizará o endpoint `/v1/messages`.

#### 3. Integração com a IDE (Open Tools API)

Para acoplar a janela na lateral da IDE:
1. Registraremos uma classe herdada de `TDockableForm` (ou formulário VCL padrão configurado via API de Dock do Delphi).
2. Usaremos `INTAServices` para obter acesso aos menus e criar ações na IDE.
3. Usaremos `IOTAEditorServices` para ler/escrever no editor ativo:

```pascal
function GetActiveEditorText(out ASelectedText: string): Boolean;
var
  LEditorServices: IOTAEditorServices;
  LEditBuffer: IOTAEditBuffer;
  LEditView: IOTAEditView;
  LEditBlock: IOTAEditBlock;
begin
  Result := False;
  ASelectedText := '';
  if Supports(BorlandIDEServices, IOTAEditorServices, LEditorServices) then
  begin
    LEditBuffer := LEditorServices.TopBuffer;
    if Assigned(LEditBuffer) and (LEditBuffer.EditViewsCount > 0) then
    begin
      LEditView := LEditBuffer.EditViews[0];
      LEditBlock := LEditBuffer.EditBlock;
      if Assigned(LEditBlock) and (LEditBlock.Size > 0) then
      begin
        ASelectedText := LEditBlock.Text;
        Result := True;
      end;
    end;
  end;
end;
```

#### 4. Interface Gráfica com Tema da IDE

A interface de chat utilizará VCL nativa integrada ao tema atual do Delphi (Light, Dark, Mountain Mist, etc.) monitorado através de `IOTAThemeServices`. 
Para a renderização premium do chat, faremos a ponte Delphi -> JavaScript via `TEdgeBrowser` ou `TWebBrowser` usando passagem de mensagens JSON (ex: `PostMessage` ou executando scripts via JS).

---

## Verification Plan

### Testes Automatizados
*   **DUnitX Test Suite:**
    *   Testes de integração com as APIs reais (usando chaves mockadas / mocks HTTP para testar tratamento de erros como Rate Limit, 401 Unauthorized e respostas malformadas).
    *   Testes de criptografia de API keys.
    *   Testes de geração de payloads JSON para Gemini, OpenAI e Claude.

### Testes Manuais de Integração com a IDE
1.  **Instalação do Pacote:** Compilar e instalar o `.bpl` na IDE ativa (componente Wizard registrado).
2.  **Docking Test:** Mover a janela de chat e fixá-la na lateral (Dock à direita/esquerda) e validar persistência do layout ao reabrir a IDE.
3.  **Teste de Threading:** Enviar uma pergunta longa no chat e rolar o código no editor do Delphi simultaneamente, garantindo ausência de congelamentos (Lag ou UI blocking).
4.  **Teste do Context Menu:** Selecionar código no editor, clicar com botão direito, selecionar "AI: Explicar Código" e verificar se o texto selecionado é transferido para o prompt e a resposta renderiza corretamente.
