# Guide for Adding New AI Providers to RadIA

Thanks to the new **Dynamic Provider Architecture**, adding a new AI backend (such as DeepSeek, Claude, or a custom internal service) has become extremely simple and decoupled.

> [!NOTE]
> RadIA adopts a dynamic registration architecture based entirely on strings. There are no global static AI provider enums in the plugin core. Adding a new backend is completely ad-hoc and autonomous, relying only on the auto-registration block of the provider unit itself.

---

## 🛠️ Step-by-Step to Create a New Provider

### 1. Create the Provider Unit
Create a new Pascal unit in the `Source/Providers` directory named after your provider (e.g., `RadIA.Provider.MyAwesomeAI.pas`).

### 2. Define the Provider Class
Your class must inherit from:
*   `TRadIAProviderBase` (if the provider uses a proprietary API/payload format and exclusive HTTP requests).
*   `TRadIAOpenAICompatibleProvider` (if the provider exposes an OpenAI-compatible API, inheriting all ready-to-use HTTP payloads, requests, and SSE streaming mechanisms).

Implement the constructor signature and mandatory methods:
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

### 3. Implement the Provider Logic
In the `implementation` section, supply the base URL, default models, and configure the provider identification by setting `FProviderId`:

```pascal
implementation

uses
  RadIA.Core.ProviderRegistry;

constructor TRadIAMyAwesomeAIProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  // ESSENTIAL: FProviderId must be set to the exact same string identifier
  // that will be used in the global auto-registration block (step 4).
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

### 4. Auto-Register in the Global Registry
At the bottom of the file, add an `initialization` block to register the provider with `TProviderRegistry`. This tells the plugin how to instantiate the provider class, what the default models are, and if it requires an API key or custom endpoint URLs:

```pascal
initialization
  TProviderRegistry.RegisterProvider(
    TProviderMetadata.Create(
      'AwesomeAI',                   // Identifier ID (used in Windows registry subkeys)
      'My Awesome AI',               // Display Name in UI
      'https://api.myawesomeai.com', // Default Base URL
      True,                          // Requires API Key? (HasApiKey)
      False,                         // Supports custom endpoint URLs? (HasCustomUrl)
      ['awesome-chat-v1', 'awesome-coder-v2'], // Default fallback models list
      function(const ACfg: IAIConfig): IIAProvider
      begin
        Result := TRadIAMyAwesomeAIProvider.Create(ACfg);
      end
    )
  );

end.
```

### 5. Add the Unit to the Package (`RadIA.dpk`)
Add your new unit to the `RadIA.dpk` package file (and `Tests/RadIATests.dpr` if applicable) so that the compiler includes it during compilation:

```pascal
contains
  RadIA.Provider.MyAwesomeAI in 'Source\Providers\RadIA.Provider.MyAwesomeAI.pas',
```

---

## ⚡ What Happens Next? (Automatic)
Without changing any other line of code in the plugin:
1.  **Persistence:** The `TRadIAConfig` class will automatically load and save API keys, models, timeouts, and temperatures for this provider under the `AwesomeAI` subkey in the Windows Registry using the new string-based APIs (e.g. `GetApiKey('AwesomeAI')`).
2.  **Instantiation:** The `TRadIAService` orchestrator will automatically intercept chat selector choices and resolve your dynamic factory registered inside `TProviderRegistry`.
3.  **Wizards and Options:** The new provider will immediately become available in the options frame, orchestrator, async execution loops, and SSE text streaming in a 100% dynamic way.
