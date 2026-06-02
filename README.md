# RadIA - Assistente de IA para Delphi IDE

Este projeto consiste no desenvolvimento do **RadIA**, um plugin de IDE para o Embarcadero Delphi (usando a Open Tools API - OTA). O plugin permite que desenvolvedores interajam com inteligências artificiais diretamente de dentro da IDE do Delphi através de uma janela acoplável (dockable form) contendo um chat e integrações diretas com o editor de código.

## Principais Funcionalidades

*   **Painel Dockable (Lateral):** Um painel lateral integrado à IDE que pode ser fixado, contendo a interface de Chat com a IA.
*   **Provedores de IA Suportados:**
    *   Google Gemini
    *   OpenAI ChatGPT
    *   Anthropic Claude
*   **Integração com o Editor de Código:**
    *   Interação direta com o código selecionado no editor.
    *   Substituição, refatoração, explicação ou geração de código baseada no texto selecionado.
*   **Configurações Personalizadas:**
    *   Seleção de provedor ativo e modelo.
    *   Gerenciamento seguro de API Keys e parâmetros de geração (Temperature, Max Tokens, etc.).

## Arquitetura do Projeto

O projeto é estruturado seguindo os princípios **SOLID**, **Clean Code** e padrões de projeto Delphi apropriados para extensões da IDE (Wizards/Open Tools API).

*   **Source/Core:** Abstrações das APIs de IA, gerenciamento de configurações do usuário e interfaces comuns.
*   **Source/Providers:** Implementação dos clientes HTTP para comunicação direta com as APIs do Gemini, OpenAI e Claude.
*   **Source/UI:** Telas VCL para a interface do Chat e Configurações (integradas ao tema da IDE).
*   **Source/Integration:** Classes de registro de pacotes, hooks e manipuladores da Open Tools API (OTA) do Delphi.
*   **Tests:** Testes unitários com DUnitX para validação dos parsers JSON e chamadas de API.

