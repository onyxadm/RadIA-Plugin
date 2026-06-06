# Guide for Adding New AI Providers to RadIA

Thanks to the new **Dynamic Provider Architecture**, adding a new AI backend (such as DeepSeek, Claude, or a custom internal service) has become extremely simple and decoupled. You no longer need to modify global orchestration files or hardcoded switch-case structures.

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
In the `implementation` section, supply the base URL, default models, and set the provider type identification:

```pascal
implementation

uses
  RadIA.Core.ProviderRegistry;

constructor TRadIAMyAwesomeAIProvider.Create(const AConfig: IAIConfig);
begin
  inherited Create(AConfig);
  // Optional: If you need a static mapping for backward compatibility
  // FProviderType := ptCustom; 
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
1.  **Persistence:** The `TRadIAConfig` class will automatically load and save API keys, models, timeouts, and temperatures for this provider under the `AwesomeAI` subkey in the Windows Registry.
2.  **Instantiation:** The `TRadIAService` orchestrator will resolve the chat selector choices and invoke your dynamic factory automatically.
3.  **Wizards and Options:** The new provider will immediately become available for the orchestrator, async execution loops, and SSE text streaming.
