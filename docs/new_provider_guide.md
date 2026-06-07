# Guia para Adição de Novos Provedores de IA no RadIA

Graças à nova **Arquitetura de Provedores Dinâmicos**, a inclusão de um novo backend de IA (como por exemplo DeepSeek, Claude, ou um serviço interno proprietário) tornou-se extremamente simplificada e desacoplada. 

> [!NOTE]
> O RadIA adota uma arquitetura de registro dinâmica baseada inteiramente em strings. Não existem enums estáticos globais de provedores de IA no núcleo do plugin. A inclusão de um novo backend ocorre de forma puramente ad-hoc e autônoma através do bloco de auto-registro da própria unit do provedor.

---

## 🛠️ Passo a Passo para Criar um Novo Provedor

### 1. Criar a Unit do Provedor
Crie uma nova unit Pascal na pasta `Source/Providers` com o nome do seu provedor (ex: `RadIA.Provider.MyAwesomeAI.pas`).

### 2. Definir a Classe do Provedor
Sua classe deve herdar de:
*   `TRadIAProviderBase` (se o provedor tiver um formato de payload/API proprietário e requisições exclusivas).
*   `TRadIAOpenAICompatibleProvider` (se o provedor expor uma API compatível com o padrão da OpenAI, herdando as requisições, payloads e streamings SSE prontos).

Implemente a assinatura do construtor e os métodos obrigatórios:
```pascal
unit RadIA.Provider.MyAwesomeAI;

interface

uses
  System.SysUtils, System.Classes, RadIA.Core.Interfaces,
  RadIA.Core.Types, RadIA.Core.TokenUsage, RadIA.Provider.Base;

type
  TRadIAMyAwesomeAIProvider = class(TRadIAOpenAICompatibleProvider)
  protected
    function GetBaseUrl: string; override;
  public
    constructor Create(const AConfig: IAIConfig); override;
    function GetAvailableModels: TArray<string>; override;
    function GetName: string; override;
  end;
```

### 3. Implementar a Lógica do Provedor
Na seção `implementation`, forneça a URL base, os modelos padrão, e configure a identificação do provedor definindo o `FProviderId`:

```pascal
implementation

uses
  RadIA.Core.ProviderRegistry;

constructor TRadIAMyAwesomeAIProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  // ESSENCIAL: O FProviderId deve ser preenchido exatamente com a mesma string
  // identificadora que será usada no auto-registro global (passo 4).
  FProviderId := 'AwesomeAI'; 
end;

function TRadIAMyAwesomeAIProvider.GetBaseUrl: string;
begin
  Result := 'https://api.myawesomeai.com/v1';
end;

function TRadIAMyAwesomeAIProvider.GetAvailableModels: TArray<string>;
begin
  Result := TArray<string>.Create('awesome-chat-v1', 'awesome-coder-v2');
end;

function TRadIAMyAwesomeAIProvider.GetName: string;
begin
  Result := 'My Awesome AI';
end;
```

### 4. Auto-Registro no Registry Global
Ao final do arquivo, adicione um bloco `initialization` para cadastrar o provedor no `TProviderRegistry`. Isto diz para o plugin como instanciar o provedor, quais os modelos iniciais e se ele necessita de chave de API ou URL customizável:

```pascal
initialization
  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create(
      'AwesomeAI',                   // Id identificador (utilizado nas chaves de registro)
      'My Awesome AI',               // Nome para exibição na UI
      'https://api.myawesomeai.com', // URL Padrão
      True,                          // Requer API Key? (HasApiKey)
      False,                         // Permite URL customizada? (HasCustomUrl)
      ['awesome-chat-v1', 'awesome-coder-v2'], // Modelos de fallback padrão
      function(const ACfg: IAIConfig): IIAProvider
      begin
        Result := TRadIAMyAwesomeAIProvider.Create(ACfg);
      end
    )
  );

end.
```

### 5. Adicionar a Unit ao Pacote do Plugin (`RadIA.dpk`)
Adicione a nova unit no arquivo `RadIA.dpk` (e no `Tests/RadIATests.dpr` se aplicável) para que o compilador a inclua no build:

```pascal
contains
  RadIA.Provider.MyAwesomeAI in 'Source\Providers\RadIA.Provider.MyAwesomeAI.pas',
```

---

## ⚡ O que acontece a seguir? (Automático)
Sem alterar mais nenhuma linha de código no plugin:
1.  **Persistência:** O `TRadIAConfig` passará a salvar e ler as chaves de API, modelos, timeouts e temperaturas deste provedor automaticamente em subchaves do Registro do Windows sob a pasta `AwesomeAI` usando as novas APIs baseadas em string (ex: `GetApiKey('AwesomeAI')`).
2.  **Instanciação:** O `TRadIAService` interceptará a escolha no Chat e resolverá o factory dinâmico a partir do registro do `TProviderRegistry` automaticamente.
3.  **Wizards e Opções:** O novo provedor estará disponível para uso instantâneo pelo orquestrador e nos fluxos assíncronos e de streaming de texto, sendo listado na interface de configurações de forma 100% dinâmica.
