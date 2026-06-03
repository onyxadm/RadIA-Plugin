<div align="right">

[🇧🇷 Português](README.md) | [🇺🇸 English](README.en.md) | [🗺️ Roadmap](ROADMAP.md)

</div>

# RadIA - Assistente de IA para Delphi IDE

**RadIA** é um plugin assistente de IA avançado projetado especificamente para a IDE do Embarcadero Delphi (usando a Open Tools API). Ele se acopla diretamente à barra lateral da IDE, fornecendo uma interface de chat interativa e integração contextual profunda com o editor de código para acelerar o desenvolvimento, refatoração e depuração.

<p align="center">
  <img src="docs/images/radia_ui_mockup.png" alt="RadIA Chat Panel Mockup" width="45%" />
  &nbsp;&nbsp;
  <img src="docs/images/radia_diff_ui_mockup.png" alt="RadIA Diff View Mockup" width="45%" />
</p>

---

### 1. Padrão de Linguagem
*   **Documentação (README / Docs):** Disponível em Português (padrão) e Inglês (alternativo).
*   **Código Fonte:** 100% escrito em **Inglês** (nomes, units, variáveis, classes, métodos e comentários de código) seguindo o clean code e os padrões Pascal.

### 2. Funcionalidades
*   **Chat Lateral Acoplável (Dockable):** Painel integrado à IDE com visual nativo do Delphi, trazendo uma janela de chat em HTML5/JS moderno (WebView2) com suporte a Markdown e realce de sintaxe Pascal.
*   **Suporte a Múltiplas IAs:** Modelo de uso de chaves próprias (BYOK) com suporte nativo ao **Google Gemini**, **OpenAI ChatGPT**, **Anthropic Claude**, **DeepSeek**, **Groq** e modelos locais/rede via **Ollama** (ex: Llama 3, Phi-3, Mistral, CodeLlama).
*   **Histórico de Chat Persistente:** O histórico de conversas é salvo automaticamente localmente em formato JSON, restaurando o contexto ao fechar e abrir a IDE.
*   **Ações de Contexto no Editor:** Clique com o botão direito em qualquer trecho de código selecionado para:
    *   *Explicar Código Selecionado:* Analisar didaticamente a lógica.
    *   *Otimizar/Refatorar:* Melhorar a performance e aplicar princípios SOLID/Clean Code.
    *   *Gerar Testes Unitários:* Gerar estruturas prontas de testes usando DUnitX.
    *   *Localizar Bugs:* Buscar memory leaks, exceptions soltas e falhas de lógica.
*   **Comparador Visual Inteligente (Smart Diff):** Visualização de refatorações lado a lado (Original vs. Sugerido) com realce vermelho/verde e botão **[Aplicar Alteração]** de um clique direto no editor.
*   **Depurador de Compilação (Smart Build):** Integração com a aba *Messages* do Delphi. Clique com o botão direito nos erros de compilação da IDE para obter explicações e correções instantâneas.
*   **Documentação XML Automática:** Geração de comentários XML estruturados (`/// <summary>`) acima do cabeçalho de métodos para alimentar o Help Insight.
*   **Comandos de Barra (Slash Commands):** Ações rápidas digitando comandos no chat (ex: `/doc`, `/explain`, `/refactor`, `/bugs`).
*   **Armazenamento Seguro de Chaves:** Credenciais criptografadas localmente via Windows DPAPI e salvas no Registro do Windows.

### 2.1 Tabela Completa de Recursos (Features)

| Recurso | Categoria | Descrição | Status |
| :--- | :--- | :--- | :--- |
| **Chat Lateral Acoplável** | Chat UX | Painel integrado à IDE rodando WebView2 com suporte a Markdown e Pascal highlight. | ✅ Concluído |
| **Streaming de Respostas** | Chat UX | Respostas incrementais token a token (SSE) nos provedores OpenAI, Gemini, Claude e Ollama. | ✅ Concluído |
| **Histórico de Chat Persistente** | Chat UX | Salvamento automático e restauração de sessões anteriores de chat em JSON. | ✅ Concluído |
| **Histórico de Prompts (↑/↓)** | Chat UX | Navegação rápida pelos prompts enviados anteriormente usando as setas do teclado. | ✅ Concluído |
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
| **Ações no Editor** | Integração | Explicação de código, otimização, testes e bugs com botão direito no editor. | ✅ Concluído|
| **Smart Diff (Comparador)** | Integração | Visualização lado a lado de código sugerido vs. original com aplicação instantânea. | ✅ Concluído |
| **Smart Build Debugger** | Integração | Clique com o botão direito nos erros de compilação da IDE para correções instantâneas. | ✅ Concluído |
| **Documentação XML Automática** | Geração | Geração automática de comentários `/// <summary>` sobre os métodos da unit. | ✅ Concluído |
| **Armazenamento Seguro** | Segurança | Chaves de API salvas localmente criptografadas usando a API do Windows DPAPI. | ✅ Concluído |

### 3. Como Funciona e Arquitetura
O RadIA é construído inteiramente em Object Pascal (Delphi) usando a **Open Tools API (OTA)** para interagir com o editor de código, gerenciamento de mensagens e detecção de temas da IDE.
A interface utiliza uma arquitetura híbrida:
1.  **VCL Nativa:** Gerencia o acoplamento da janela, a tela de configurações, ações de menus, gravação segura no registro e chamadas assíncronas.
2.  **Motor WebView2 (Edge):** Exibe as mensagens e respostas da IA utilizando HTML5, CSS e JS locais (Marked.js para Markdown e Prism.js para realce de sintaxe). A interface se adapta automaticamente ao tema da IDE (Light/Dark) e roda de forma fluida sem congelar a IDE.

### 4. Requisitos do Sistema
*   **IDE:** Embarcadero Delphi 10.4 Sydney, 11 Alexandria ou 12 Athens (ou superior).
*   **OS:** Windows 10 / 11 (64-bit).
*   **Web Engine:** *Microsoft Edge WebView2 Runtime* instalado no sistema Windows (pré-instalado em versões modernas do Windows). **Importante:** A DLL `WebView2Loader.dll` correspondente à arquitetura da IDE (32-bit para Delphi 10.4, 64-bit para Delphi 11 e 12) deve estar presente na pasta `bin` da instalação do Delphi (ex: `C:\Program Files (x86)\Embarcadero\Studio\<versao>\bin`) ou no PATH do sistema.
*   **API Keys:** Chaves de desenvolvedor ativas obtidas em seus respectivos consoles: [Google AI Studio](https://aistudio.google.com/) (Gemini), [OpenAI Platform](https://platform.openai.com/) (ChatGPT), [Anthropic Console](https://console.anthropic.com/) (Claude), [DeepSeek Console](https://platform.deepseek.com/) e [Groq Console](https://console.groq.com/). Para uso local/rede com o **Ollama**, certifique-se de que a instância do servidor Ollama está ativa no endereço configurado (ex: `http://localhost:11434`).

### 5. Instalação

> [!IMPORTANT]
> **Modelo Bring Your Own Key (BYOK) & IA Local:** O RadIA exige chaves de API válidas e ativas para funcionar com nuvem (Gemini, OpenAI ou Claude) ou uma instância configurada do **Ollama** rodando na máquina ou na rede. Se você não configurar pelo menos uma API Key ou a URL do Ollama nas configurações do plugin, as funções de chat e ações de contexto não poderão ser utilizadas.

O RadIA pode ser instalado de duas maneiras: **Automatizada (Recomendada)** via PowerShell, ou **Manual** através da IDE do Delphi.

#### Opção A: Instalação Automatizada (PowerShell) - Recomendada

Esta opção compila o plugin, executa os testes unitários, copia os binários para os diretórios públicos oficiais do Delphi e registra o plugin no Registro do Windows automaticamente.

1. Abra o console do Windows PowerShell.
2. Certifique-se de que a pasta `bin` da instalação do Delphi contendo o `dcc32` está presente no PATH do sistema.
3. Execute o comando na raiz do projeto de acordo com a arquitetura da sua IDE:
   * **Para a IDE padrão de 32 bits (Recomendado)**:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\build.ps1 -Install
     ```
   * **Para a IDE de 64 bits (Delphi 13 Florence)**:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\build.ps1 -Install -IDE64
     ```
4. Pronto! O plugin estará instalado e ativo no próximo startup da IDE.

#### Opção B: Instalação Manual via IDE

1. Clone este repositório em sua máquina.
2. Abra o grupo de projetos `RadIA.groupproj` no Delphi.
3. Clique com o botão direito em `RadIA.bpl` no Project Manager e selecione **Build**.
4. Clique novamente com o botão direito em `RadIA.bpl` e selecione **Install**.
5. A janela de confirmação de instalação da IDE será exibida, e o painel do **RadIA** aparecerá acoplado na lateral da IDE.
6. Acesse o menu **Tools ➔ RadIA Chat Panel** para exibir o chat, e clique no botão **Settings** no topo do painel para configurar suas chaves de API e começar.

### 5.1 Configurando o Ollama (Local ou em Rede)

O **Ollama** permite executar LLMs de código aberto (Llama 3, Mistral, Phi-3, CodeLlama etc.) diretamente na sua máquina ou em um servidor na rede local — sem dependência de APIs pagas.

**Pré-requisito:** Instale o Ollama a partir de [https://ollama.com](https://ollama.com) e baixe pelo menos um modelo com `ollama pull llama3`.

**Para uso local (mesma máquina):**
1.  Inicie o servidor Ollama (o serviço é iniciado automaticamente após a instalação no Windows).
2.  A URL padrão já está configurada como `http://localhost:11434` — **nenhuma alteração é necessária**.
3.  Nas configurações do plugin (**Settings → Ollama Local/Network Settings**), confirme que a URL está como `http://localhost:11434`.
4.  Selecione **Ollama** no combo de provedores do chat.

**Para uso em rede (servidor remoto):**
1.  Certifique-se que o Ollama está rodando no servidor remoto com escuta em todos os endereços. Defina a variável de ambiente `OLLAMA_HOST=0.0.0.0` no servidor antes de iniciar o serviço.
2.  Nas configurações do plugin (**Settings → Ollama Local/Network Settings**), defina a URL para o endereço IP ou hostname do servidor. Exemplo: `http://192.168.1.100:11434`.
3.  Certifique-se de que a porta `11434` está acessível no firewall da rede.
4.  Selecione **Ollama** no combo de provedores do chat.

> **Nota:** O plugin descobre automaticamente os modelos disponíveis no servidor Ollama via `/api/tags`. Se a conexão falhar, exibirá modelos padrão conhecidos como fallback.

### 5.2 Histórico de Conversas Persistente

OPara compilar o pacote principal, executar os testes unitários de forma automatizada, realizar a instalação direta ou desinstalação na IDE do Delphi, você pode utilizar o script de build integrado na raiz do projeto. Ele suporta os seguintes parâmetros/switches:

*   `-Install`: Compila o plugin, executa os testes unitários, copia a BPL/DCP para o diretório público de documentos do Delphi e adiciona o pacote no Registro do Windows (`Known Packages`) da respectiva versão detectada da IDE.
*   `-Uninstall`: Remove as BPLs, DCPs e a pasta de recursos Web copiados anteriormente das pastas públicas da IDE do Delphi e apaga o pacote do Registro do Windows (`Known Packages`), desinstalando o plugin de forma limpa.
*   `-Release`: Compila o plugin e os testes unitários na configuração de Produção (Release), desligando símbolos de depuração e informações de debug (gerando uma BPL consideravelmente menor e mais rápida) e ativando as otimizações do compilador do Delphi.
*   `-IDE64`: Compila e instala o plugin especificamente para a IDE de 64 bits do Delphi (disponível a partir do Delphi 13 Florence), gerando o binário em Win64 e registrando na chave de registro correspondente `Known Packages` de 64 bits (`BDS\<versao>_x64`). Se omitido, compila para a IDE padrão de 32 bits (Win32).

Exemplo de comandos:

1. Abra o console do Windows PowerShell.
2. Certifique-se de que a pasta `bin` da instalação do Delphi contendo o `dcc32` está presente no PATH do sistema.
3. Execute o comando na raiz do projeto para apenas compilar e testar em modo Debug:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\build.ps1
   ```
4. Para compilar, testar e instalar na IDE em modo **Release** (Produção recomendado):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\build.ps1 -Install -Release
   ```
5. Para desinstalar o plugin da IDE de forma limpa:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\build.ps1 -Uninstall
   ```
6. O script detectará automaticamente a versão ativa do compilador, criará os diretórios de saída isolados por versão (ex: `Output\23.0\bpl`, `Output\23.0\dcp`, `Output\23.0\dcu`, etc.), executará a limpeza de arquivos DCU temporários das pastas de fontes, compilará o pacote principal, compilará os testes unitários e rodará automaticamente a suite de validação de testes.
7. Se o parâmetro `-Install` foi informado, o script também copiará os arquivos de saída (`RadIA.bpl` e `RadIA.dcp`) para as pastas oficiais do Delphi (`C:\Users\Public\Documents\Embarcadero\Studio\<versao>\Bpl` e `Dcp`) e registrará o plugin na chave de Registro `Known Packages` do Delphi da respectiva versão detectada.�rios e rodará automaticamente a suite de validação de testes.
5. Se o parâmetro `-Install` foi informado, o script também copiará os arquivos de saída (`RadIA.bpl` e `RadIA.dcp`) para as pastas oficiais do Delphi (`C:\Users\Public\Documents\Embarcadero\Studio\<versao>\Bpl` e `Dcp`) e registrará o plugin na chave de Registro `Known Packages` do Delphi da respectiva versão detectada.

### 5.4 Guia de Obtenção de Chaves de API e Configurações por Provedor

Para configurar e utilizar o RadIA com os seus respectivos provedores de inteligência artificial, você precisará gerar e inserir as chaves de API nas configurações do plugin (**Settings** no topo do painel). Abaixo estão as instruções e links para cada provedor:

1. **Google Gemini (Recomendado)**
   * **Como obter:** Acesse o console do [Google AI Studio](https://aistudio.google.com/).
   * **Passo a passo:** Faça login com uma conta Google, clique no botão **Create API Key** no painel lateral esquerdo, selecione o seu projeto e copie a chave gerada.
   * **Modelos Sugeridos:** `gemini-1.5-flash` ou `gemini-1.5-pro` (ou mais recentes).

2. **OpenAI ChatGPT**
   * **Como obter:** Acesse a [OpenAI Platform](https://platform.openai.com/).
   * **Passo a passo:** Faça login, navegue até a seção **API Keys** no menu lateral, clique em **Create new secret key**, nomeie-a e copie o token gerado (iniciado em `sk-`). *Nota: É necessário possuir créditos ativos na plataforma da OpenAI.*
   * **Modelos Sugeridos:** `gpt-4o-mini`, `gpt-4o`.

3. **Anthropic Claude**
   * **Como obter:** Acesse o [Anthropic Console](https://console.anthropic.com/).
   * **Passo a passo:** Faça login, acesse a aba **API Keys**, clique em **Create Key** e copie a chave gerada (iniciada em `sk-ant-`). *Nota: Requer saldo de recarga pré-pago na plataforma.*
   * **Modelos Sugeridos:** `claude-3-5-sonnet-latest`, `claude-3-haiku`.

4. **DeepSeek**
   * **Como obter:** Acesse o [DeepSeek Console](https://platform.deepseek.com/).
   * **Passo a passo:** Crie uma conta ou faça login, acesse a seção **API Keys**, clique em **Create API Key** e copie a chave gerada.
   * **Modelos Sugeridos:** `deepseek-chat` (para conversação e refatoração geral) ou `deepseek-reasoning` (para problemas lógicos profundos).

5. **Groq Cloud (Ultrarrápido)**
   * **Como obter:** Acesse o [Groq Console](https://console.groq.com/).
   * **Passo a passo:** Crie sua conta, acesse a seção **API Keys**, clique em **Create API Key** e copie a chave gerada (iniciada em `gsk_`).
   * **Modelos Sugeridos:** `llama-3.3-70b-versatile`, `mixtral-8x7b-32768`.

6. **Ollama (Modelos Locais Sem Custos)**
   * **Como obter:** Não requer chaves de API. Baixe e instale o [Ollama](https://ollama.com).
   * **Configuração:** O plugin tenta se conectar automaticamente ao endereço de loopback padrão `http://localhost:11434`. Certifique-se de baixar o modelo que deseja usar executando no terminal de comandos do Windows (CMD/PowerShell) o comando: `ollama pull llama3` (ou o modelo de sua preferência).
   * **Uso em Rede:** Caso o Ollama esteja rodando em outro servidor na sua rede, configure a variável de ambiente `OLLAMA_HOST=0.0.0.0` na máquina servidora para permitir conexões externas e insira o IP correspondente (exemplo: `http://192.168.1.100:11434`) no painel de configurações do RadIA.

### 6. Estrutura do Repositório
```
PluginDelphiIA/
│
├── docs/                               # Documentação e recursos visuais
│   ├── images/
│   │   ├── radia_ui_mockup.png         # Mockup do Chat na lateral da IDE
│   │   └── radia_diff_ui_mockup.png    # Mockup da tela de comparação Diff
│   ├── implementation_plan.md          # Plano detalhado de arquitetura
│   ├── radia_design_ui.md              # Especificação de layouts e fluxos de UI
│   └── task.md                         # Lista/Checklist de tarefas de desenvolvimento
│
├── RadIA.groupproj                     # Grupo de Projetos do Delphi
├── RadIA.dpk                           # Pacote Delphi de design-time
├── RadIA.dproj                         # Configurações do projeto de pacote
│
├── Source/
│   ├── Core/                           # Units centrais (Interfaces, tipos, configurações)
│   ├── Providers/                      # Clientes de API das IAs (Gemini, OpenAI, Claude)
│   ├── Integration/                    # Integração com a Open Tools API da IDE (Wizards, Hooks)
│   └── UI/                             # Formulários e Frames VCL
│       └── Web/                        # Template Web (HTML/CSS/JS) para WebView2
│
└── Tests/                              # Testes de Integração e Unitários (DUnitX)
```

### 7. Princípios de Desenvolvimento
Este projeto adota rigidamente:
*   Princípios de design **SOLID**.
*   Práticas de **Clean Code** com total isolamento em threads (thread-safety).
*   Princípios **DRY** (Don't Repeat Yourself) e **KISS** (Keep It Simple, Stupid).
*   Uso exclusivo do idioma **Inglês** para todo código fonte do projeto.

### 8. Aviso de Marcas Registradas (Trademark Disclaimer)
Todas as marcas registradas, logotipos, marcas de serviço e nomes comerciais mencionados neste projeto (incluindo, mas não se limitando a: *Embarcadero Delphi*, *Microsoft Windows*, *Microsoft Edge*, *WebView2*, *Google Gemini*, *OpenAI ChatGPT*, *Anthropic Claude*, *DeepSeek*, *Groq* e *Ollama*) são de propriedade de seus respectivos proprietários.

A menção a estes nomes e marcas serve unicamente para fins de descrição de compatibilidade, configuração e integração tecnológica. O **RadIA** é um projeto independente e open-source, não possuindo qualquer filiação, patrocínio, endosso ou associação oficial com os proprietários das referidas marcas.

### 8.1 Isenção de Responsabilidade sobre Uso de Inteligência Artificial (AI Assistant Disclaimer)
*   **Revisão Obrigatória de Código**: O RadIA é um assistente de produtividade que gera sugestões de código baseando-se em modelos de inteligência artificial de terceiros. As sugestões geradas (incluindo refatorações, correções de bugs e geração de testes) podem conter imprecisões, erros de lógica ou vulnerabilidades. O usuário é o **único responsável** por revisar, validar, testar e aprovar qualquer código sugerido pela IA antes de integrá-lo a sistemas de produção.
*   **Limitação de Danos**: Os criadores e colaboradores do RadIA não se responsabilizam por quaisquer danos, perdas de dados, lucros cessantes, falhas de segurança ou interrupções de serviço que ocorram em decorrência do uso das sugestões de código ou da execução do plugin na IDE.
*   **Segurança de Credenciais (BYOK)**: O RadIA armazena as chaves de API (API Keys) localmente e criptografadas utilizando a API de Proteção de Dados do Windows (DPAPI) no Registro do Windows. As chaves são enviadas de forma direta e segura aos servidores oficiais de cada provedor correspondente (Google, OpenAI, Anthropic, DeepSeek, Groq ou Ollama). Os autores do projeto não coletam, armazenam remotamente ou compartilham suas chaves de API. O controle de custos e limites de uso das chaves é de inteira responsabilidade do usuário.

### 8.2 Privacidade de Dados e Compliance Corporativo (Data Privacy)
Ao utilizar provedores de nuvem (Google Gemini, OpenAI, Anthropic, DeepSeek ou Groq), trechos do seu código-fonte selecionado e informações contextuais do projeto serão enviados para os respectivos servidores externos para processamento. 

*   **Uso Corporativo Confidencial**: Caso você trabalhe em projetos com código proprietário restrito ou sob normas de compliance corporativo (como LGPD ou GDPR), **recomendamos utilizar o Ollama** configurado localmente. Executando modelos locais de forma offline, o RadIA processará suas solicitações inteiramente dentro da sua máquina ou rede interna, garantindo que nenhum dado proprietário de código saia do ambiente seguro da sua empresa.
