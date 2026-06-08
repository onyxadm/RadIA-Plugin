(function() {
  const DEBUG = true;
  function log(...args) {
    if (DEBUG) console.log('[RadIABridge]', ...args);
  }

  // --- CONFIGURAÇÃO DE SELETORES E CSS ---
  const CONFIGS = {
    chatgpt: {
      domain: 'chatgpt.com',
      css: `
        /* Oculta painel lateral esquerdo */
        [data-testid="profile-button"],
        [data-testid="sidebar"] {
          display: none !important;
        }
        /* Oculta botão de toggle da sidebar */
        span[data-state] button.absolute {
          display: none !important;
        }
        /* Oculta barra superior/cabeçalho */
        header, .sticky.top-0 {
          display: none !important;
        }
        /* Ajusta margens do container principal */
        main {
          padding-top: 0 !important;
        }
        /* Oculta rodapé de termos/limites */
        .text-xs.text-center, 
        footer {
          display: none !important;
        }
      `,
      getInput: () => document.getElementById('prompt-textarea'),
      getSendButton: () => {
        return document.querySelector('button[data-testid="send-button"]') ||
               document.querySelector('button[data-testid="fruitjuice-send-button"]') ||
               document.querySelector('button[aria-label="Send prompt"]');
      },
      isGenerating: () => {
        return !!(document.querySelector('button[data-testid="stop-button"]') ||
                  document.querySelector('button[aria-label="Stop generating"]'));
      },
      getLastResponseText: () => {
        const turnElements = document.querySelectorAll('[data-testid^="conversation-turn-"]');
        if (turnElements.length === 0) return '';
        // Pega o último turn do assistente (normalmente turns ímpares ou com classe específica)
        // Uma abordagem mais segura é buscar de trás para frente
        for (let i = turnElements.length - 1; i >= 0; i--) {
          const turn = turnElements[i];
          // ChatGPT identifica o autor no atributo ou classe, mas podemos verificar se contém o conteúdo da resposta
          // Geralmente, o turn do usuário tem classes diferentes ou contém o prompt
          // No ChatGPT moderno, a classe "agent-turn" ou elemento com classe "markdown" está na resposta
          const md = turn.querySelector('.markdown');
          if (md) {
            return md.innerText;
          }
        }
        return '';
      }
    },
    gemini: {
      domain: 'gemini.google.com',
      css: `
        /* Oculta barra superior de navegação e usuário */
        header, .header-container, .top-nav, sign-in-button {
          display: none !important;
        }
        /* Oculta menu lateral */
        side-navigation, .side-nav, .left-rail {
          display: none !important;
        }
        /* Oculta dicas e rodapés de disclaimer */
        .disclaimer, footer, .footer-container, .policy-links {
          display: none !important;
        }
        /* Ajusta margem principal para ocupar o espaço do header removido */
        main, .main-container, .chat-view {
          padding-top: 0 !important;
          margin-top: 0 !important;
        }
      `,
      getInput: () => {
        return document.querySelector('div[contenteditable="true"]') ||
               document.querySelector('.ql-editor') ||
               document.querySelector('textarea');
      },
      getSendButton: () => {
        return document.querySelector('button.send-button') ||
               document.querySelector('button[aria-label="Send"]') ||
               document.querySelector('.send-button-container button');
      },
      isGenerating: () => {
        // Verifica se há alguma animação de carregamento ativa ou se o botão de parar geração está visível
        return !!(document.querySelector('stop-button') ||
                  document.querySelector('.loading-spinner') ||
                  document.querySelector('button[aria-label="Stop"]'));
      },
      getLastResponseText: () => {
        const chatElements = document.querySelectorAll('message-content, .message-content, .response-content');
        if (chatElements.length === 0) return '';
        const lastEl = chatElements[chatElements.length - 1];
        return lastEl.innerText;
      }
    }
  };

  // Identifica o site ativo
  let currentSite = null;
  const host = window.location.hostname;
  if (host.includes('chatgpt.com')) {
    currentSite = CONFIGS.chatgpt;
  } else if (host.includes('gemini.google.com')) {
    currentSite = CONFIGS.gemini;
  }

  if (!currentSite) {
    log('Domínio não mapeado:', host);
    return;
  }

  log('Ponte inicializada para:', host);

  // Injeta CSS customizado para limpar a tela
  function injectCSS() {
    const style = document.createElement('style');
    style.id = 'radia-clean-css';
    style.innerHTML = currentSite.css;
    document.head.appendChild(style);
    log('CSS limpo injetado.');
  }

  if (document.head) {
    injectCSS();
  } else {
    document.addEventListener('DOMContentLoaded', injectCSS);
  }

  // --- COMUNICAÇÃO DE ENTRADA (Delphi -> WebView) ---
  if (window.chrome && window.chrome.webview) {
    window.chrome.webview.addEventListener('message', event => {
      const msg = event.data;
      log('Mensagem recebida do Delphi:', msg);

      if (msg && msg.action === 'send_prompt') {
        const inputEl = currentSite.getInput();
        if (!inputEl) {
          log('Erro: Campo de input não localizado.');
          sendToDelphi({ action: 'error', text: 'Input textarea not found in page.' });
          return;
        }

        // Insere o texto no input
        if (inputEl.tagName === 'TEXTAREA' || inputEl.tagName === 'INPUT') {
          inputEl.value = msg.text;
        } else if (inputEl.getAttribute('contenteditable') === 'true') {
          inputEl.innerText = msg.text;
        }
        
        // Dispara eventos necessários para ativar o botão de enviar no site
        inputEl.dispatchEvent(new Event('input', { bubbles: true }));
        inputEl.dispatchEvent(new Event('change', { bubbles: true }));

        // Pequeno delay para garantir que o framework JS da página valide o texto
        setTimeout(() => {
          const btn = currentSite.getSendButton();
          if (btn) {
            log('Clicando no botão de enviar oficial...');
            btn.click();
            startMonitoring();
          } else {
            log('Erro: Botão de enviar não localizado.');
            sendToDelphi({ action: 'error', text: 'Send button not found in page.' });
          }
        }, 150);
      }
    });
  }

  // Envia mensagem de volta para o Delphi
  function sendToDelphi(data) {
    if (window.chrome && window.chrome.webview) {
      window.chrome.webview.postMessage(data);
    } else {
      log('Simulação PostMessage:', data);
    }
  }

  // --- MONITORAMENTO DA RESPOSTA (Scraping & Stream) ---
  let monitorInterval = null;
  let lastSentLength = 0;
  let lastText = '';
  let generatingTimeout = 0;

  function startMonitoring() {
    log('Iniciando monitoramento de resposta...');
    lastSentLength = 0;
    lastText = '';
    generatingTimeout = 0;
    
    if (monitorInterval) clearInterval(monitorInterval);

    monitorInterval = setInterval(() => {
      const text = currentSite.getLastResponseText();
      const isGenerating = currentSite.isGenerating();

      if (text && text !== lastText) {
        // Obtém apenas a fatia nova gerada para enviar como chunk de stream
        const chunk = text.substring(lastSentLength);
        if (chunk.length > 0) {
          log('Enviando chunk de streaming:', chunk.length, 'bytes');
          sendToDelphi({
            action: 'stream_chunk',
            text: chunk,
            isDone: false
          });
          lastSentLength = text.length;
          lastText = text;
        }
      }

      if (!isGenerating && lastText.length > 0) {
        // Damos uma pequena margem (2 ciclos de verificação) para ter certeza de que a geração terminou
        generatingTimeout++;
        if (generatingTimeout >= 3) {
          log('Geração concluída.');
          clearInterval(monitorInterval);
          monitorInterval = null;

          // Envia o fechamento
          sendToDelphi({
            action: 'stream_chunk',
            text: '',
            isDone: true
          });
        }
      } else {
        generatingTimeout = 0;
      }
    }, 300);
  }
})();
