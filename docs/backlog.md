# Backlog de Evolução Futura do RadIA

Este documento registra as tarefas e ideias de evolução futura do plugin RadIA, planejadas para desenvolvimento posterior.

---

## ✅ Itens Concluídos

### 3. Integração com Modelos Locais (Ollama) + Histórico Persistente
> **Entregue nos commits `fd483b6` e `0dfcf10`**

*   ✅ **Provedor Ollama:** Suporte completo para rodar modelos open-source (Llama 3, Phi-3, Mistral, CodeLlama etc.) via API local do Ollama, tanto na mesma máquina (`localhost`) quanto em servidores na rede local, sem dependência de APIs pagas.
*   ✅ **Descoberta Dinâmica de Modelos:** O plugin consulta automaticamente `/api/tags` para listar os modelos instalados no servidor Ollama, com fallback para lista de modelos conhecidos.
*   ✅ **Configuração de URL:** Campo dedicado nas configurações do plugin para definir o endereço do servidor Ollama (padrão: `http://localhost:11434`).
*   ✅ **Histórico de Conversas Persistente:** O histórico do chat é salvo automaticamente em `%APPDATA%\RadIA\history.json` (formato JSON), restaurado integralmente ao reabrir a IDE. O botão **Clear** apaga o arquivo físico.

---

## 🔲 Pendentes

### 1. Automatização de DevOps (CI/CD Pipeline)
*   **Objetivo**: Compilar e empacotar o plugin automaticamente a cada nova versão, evitando processos manuais de geração de binários.
*   **Detalhamento**:
    *   Criar um workflow do GitHub Actions rodando em agentes Windows (`windows-latest`).
    *   Configurar a instalação de ferramentas de build do Delphi ou MSBuild via scripts.
    *   Compilar o pacote `RadIA.dpk` e o projeto de testes unitários para a versão ativa (e outras versões suportadas da IDE).
    *   Executar os testes unitários (`RadIATests.exe`) de forma automatizada na pipeline e barrar o deploy se algum teste falhar.
    *   Compactar o binário compilado `.bpl`, o arquivo de símbolos `.dcp`, a DLL `WebView2Loader.dll` e os recursos web (`Web/*`) em um pacote de distribuição `.zip` associado à tag/release do GitHub.

---

### 2. Instalador Automatizado (Inno Setup)
*   **Objetivo**: Fornecer uma experiência de instalação fluida ("One-Click Install") para desenvolvedores que desejam apenas utilizar o plugin, sem a necessidade de compilar o código fonte.
*   **Detalhamento**:
    *   Criar um script Inno Setup (`installer.iss`) para empacotar o plugin.
    *   O instalador deve escanear o Registro do Windows para detectar as versões instaladas do Delphi (ex: `Software\Embarcadero\BDS\23.0`).
    *   Copiar a BPL apropriada do diretório de output para o diretório de destino do usuário.
    *   Registrar a BPL no Delphi adicionando uma nova entrada do tipo String no Registro sob a chave `Software\Embarcadero\BDS\<versao>\Known Packages` com o caminho completo da BPL instalada.
    *   Copiar automaticamente a DLL do WebView2 (`WebView2Loader.dll`) e os recursos web (`chat.html`, `chat.css`, etc.) para o local apropriado (pasta `%APPDATA%\RadIA\Web`).
