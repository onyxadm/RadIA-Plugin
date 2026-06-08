# Guia de Instalação e Configuração — RadIA

Este documento descreve detalhadamente o processo de instalação, compilação e configuração do plugin **RadIA** para a IDE do Delphi.

---

## 1. Instalação

O RadIA exige chaves de API válidas e ativas para funcionar com provedores de nuvem (Gemini, OpenAI, Claude, DeepSeek ou Groq) ou uma instância configurada do **Ollama** rodando localmente ou na rede.

O plugin pode ser instalado de duas formas:

### Opção A: Instalação Automatizada (PowerShell) - Recomendada

Esta opção compila o plugin, executa os testes unitários (caso o framework **DUnitX** esteja instalado na IDE; caso contrário, os testes são ignorados de forma automática e transparente), copia os binários para os diretórios públicos oficiais do Delphi e registra o plugin no Registro do Windows automaticamente.

1. Abra o console do Windows PowerShell.
2. Certifique-se de que a pasta `bin` da instalação do Delphi contendo o `dcc32` está presente no PATH do sistema.
3. Execute o comando na raiz do projeto de acordo com a arquitetura da sua IDE:
   * **Para a IDE padrão de 32 bits (Delphi 10.4, 11 e 12)**:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\build.ps1 -Install
     ```
   * **Para a IDE de 64 bits (Delphi 13 Florence)**:
     ```powershell
     powershell -ExecutionPolicy Bypass -File .\build.ps1 -Install -IDE64
     ```
4. Pronto! O plugin estará instalado e ativo no próximo startup da IDE.

### Opção B: Instalação Manual via IDE

1. Clone o repositório em sua máquina.
2. Abra o grupo de projetos `RadIA.groupproj` no Delphi.
3. Clique com o botão direito em `RadIA.bpl` no Project Manager e selecione **Build**.
4. Clique novamente com o botão direito em `RadIA.bpl` e selecione **Install**.
5. A janela de confirmação de instalação da IDE será exibida, e o painel do **RadIA** aparecerá acoplado na lateral da IDE.
6. Acesse o menu **Tools ➔ RadIA Chat Panel** para exibir o chat, e clique no botão **Settings** no topo do painel para configurar suas chaves de API e começar.

---

## 2. Configurando o Ollama (Local ou em Rede)

O **Ollama** permite executar LLMs de código aberto (Llama 3, Mistral, Phi-3, CodeLlama etc.) diretamente na sua máquina ou em um servidor na rede local — sem dependência de APIs pagas.

**Pré-requisito:** Instale o Ollama a partir de [https://ollama.com](https://ollama.com) e baixe pelo menos um modelo com `ollama pull llama3`.

* **Para uso local (mesma máquina):**
  1. Inicie o servidor Ollama (o serviço é iniciado automaticamente após a instalação no Windows).
  2. A URL padrão já está configurada como `http://localhost:11434` — **nenhuma alteração é necessária**.
  3. Nas configurações do plugin (**Settings → Ollama Local/Network Settings**), confirme que a URL está como `http://localhost:11434`.
  4. Selecione **Ollama** no combo de provedores do chat.

* **Para uso em rede (servidor remoto):**
  1. Certifique-se que o Ollama está rodando no servidor remoto com escuta em todos os endereços. Defina a variável de ambiente `OLLAMA_HOST=0.0.0.0` no servidor antes de iniciar o serviço.
  2. Nas configurações do plugin (**Settings → Ollama Local/Network Settings**), defina a URL para o endereço IP ou hostname do servidor. Exemplo: `http://192.168.1.100:11434`.
  3. Certifique-se de que a porta `11434` está acessível no firewall da rede.
  4. Selecione **Ollama** no combo de provedores do chat.

> **Nota:** O plugin descobre automaticamente os modelos disponíveis no servidor Ollama via `/api/tags`. Se a conexão falhar, exibirá modelos padrão conhecidos como fallback.

---

## 3. Guia de Obtenção de Chaves de API por Provedor

Insira as chaves obtidas nas configurações do plugin (**Settings** no topo do painel de chat):

1. **Google Gemini (Recomendado)**
   * **Como obter:** Acesse o [Google AI Studio](https://aistudio.google.com/).
   * **Instruções:** Faça login, clique em **Create API Key** no painel lateral esquerdo, selecione o projeto e copie a chave.

2. **OpenAI ChatGPT**
   * **Como obter:** Acesse a [OpenAI Platform](https://platform.openai.com/).
   * **Instruções:** Faça login, acesse **API Keys** no menu lateral, clique em **Create new secret key** e copie o token gerado (iniciado em `sk-`).

3. **Anthropic Claude**
   * **Como obter:** Acesse o [Anthropic Console](https://console.anthropic.com/).
   * **Instruções:** Crie conta/login, acesse **API Keys**, clique em **Create Key** e copie a chave (iniciada em `sk-ant-`).

4. **DeepSeek**
   * **Como obter:** Acesse o [DeepSeek Console](https://platform.deepseek.com/).
   * **Instruções:** Faça login, acesse **API Keys**, clique em **Create API Key** e copie o token.

5. **Groq Cloud**
   * **Como obter:** Acesse o [Groq Console](https://console.groq.com/).
   * **Instruções:** Acesse **API Keys**, clique em **Create API Key** e copie o token (iniciado em `gsk_`).

6. **Azure OpenAI**
   * **Como obter:** Através do portal de gerenciamento da nuvem Microsoft Azure.
   * **Instruções:** Acesse o recurso do Azure OpenAI criado, vá na seção **Keys and Endpoint**, e copie o Endpoint e uma das chaves (Key 1 ou Key 2). Nas opções do RadIA, configure a API Key, a URL do Endpoint, o Deployment Name mapeado para o modelo ativo e a versão da API (padrão: `2024-02-15-preview`).

7. **Alibaba Qwen**
   * **Como obter:** Acesse o console [DashScope/ModelStudio da Alibaba Cloud](https://bailian.console.aliyun.com/).
   * **Instruções:** Crie sua chave na seção de API Keys e copie o token.

8. **Mistral AI**
   * **Como obter:** Acesse o console do [Mistral AI Console](https://console.mistral.ai/).
   * **Instruções:** Acesse a seção **API Keys**, crie uma nova chave e copie o token gerado.

> **Nota sobre Provedores Dinâmicos e Corporativos:** Você também pode adicionar de forma dinâmica novos provedores compatíveis com a API OpenAI (incluindo o GitHub Copilot ou proxies de terceiros) salvando arquivos JSON em `%APPDATA%\RadIA\providers\`. Para mais detalhes, consulte o [Guia para Adição de Novos Provedores (docs/new_provider_guide.md)](new_provider_guide.md) e o [Guia de Configuração do GitHub Copilot (docs/copilot_proxy_guide.md)](copilot_proxy_guide.md).

---

## 4. Script de Build PowerShell (Opções Avançadas)

O script `.\build.ps1` aceita os seguintes parâmetros:

* `-Install`: Compila, executa testes, copia os arquivos binários para a pasta pública do Delphi e cria o registro do pacote no Windows.
* `-Uninstall`: Desinstala o plugin de forma limpa apagando arquivos e chaves de registro.
* `-Release`: Ativa as otimizações do compilador Delphi e gera uma BPL menor.
* `-IDE64`: Compila e instala o plugin especificamente para a IDE de 64 bits do Delphi 13 Florence.
* `-DelphiVersion "<versao>"`: Opcional. Permite forçar o uso de uma versão específica do Delphi instalada no sistema (ex: `"23.0"`, `"37.0"`, `"Athens"`).
* `-SkipTests`: Opcional. Ignora a compilação e a execução da suíte de testes unitários (DUnitX). Recomendado para usuários finais que desejam apenas instalar o plugin de forma rápida.

> [!TIP]
> **Suporte a Múltiplas Versões da IDE:** Se você possuir mais de uma versão do Delphi instalada no Windows e executar o script com `-Install` ou `-Uninstall` sem passar o parâmetro `-DelphiVersion`, o script listará automaticamente as versões instaladas encontradas no registro e exibirá um menu no console para que você selecione de forma interativa qual deseja utilizar.

> [!NOTE]
> **Autodetecção do DUnitX:** O instalador verifica automaticamente se o framework DUnitX está instalado no Delphi selecionado. Se o DUnitX não for encontrado (instalação básica/mínima da IDE), o script exibirá um aviso no console e desativará os testes unitários de forma automática, prosseguindo com a compilação e a instalação bem-sucedida do plugin principal sem a necessidade de intervenção do usuário.

---

## 5. Login Híbrido (Web Login Plus/Pro vs BYOK)

O RadIA permite que você opte por dois métodos de conexão para os provedores **Google Gemini** e **OpenAI ChatGPT**:
1. **API Key (BYOK)**: Utiliza chaves de API oficiais e cobra por token consumido diretamente do seu saldo de desenvolvedor nas plataformas OpenAI Platform/Google AI Studio.
2. **Web Login (Plus/Pro)**: Permite que você faça login diretamente nas suas contas pessoais ou corporativas de consumidor (ChatGPT Plus/Pro e Gemini Advanced) utilizando a interface oficial deles no WebView2 integrado do RadIA.

### Como Ativar e Usar o Web Login
1. Acesse as Configurações (**Settings** no painel de chat ou o menu **Tools ➔ Options ➔ Third Party > RadIA**).
2. Selecione a aba do provedor (**Gemini** ou **OpenAI**).
3. No campo **Connection Method**, selecione a opção **Web Login (Plus/Pro)**.
4. Clique em **Save**.
5. No painel de chat do RadIA, selecione o provedor correspondente. Um botão de login em formato de cadeado 🔐 aparecerá no cabeçalho superior direito do chat.
6. Clique no botão de cadeado 🔐. Isso abrirá um popup de autenticação nativo (`TFormWebLogin`).
7. Faça login na sua conta na janela que se abre. A sessão e os cookies serão salvos de forma segura no diretório `%APPDATA%\RadIA\WebView2Data`, mantendo você conectado. Após o login bem-sucedido, você pode fechar o popup.
8. Pronto! Agora você pode conversar normalmente pela própria interface nativa do chat do RadIA (ou disparar ações no editor de código). O plugin usará uma WebView2 oculta em segundo plano para enviar os prompts e ler as respostas via streaming em tempo real, mantendo a experiência fluida e o design unificado.
