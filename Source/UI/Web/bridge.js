(function() {
  const DEBUG = true;
  function log(...args) {
    if (DEBUG) console.log('[RadIABridge]', ...args);
  }

  // --- CONFIGURAÇÃO DE SELETORES E CSS ---
  const CONFIGS = {
    chatgpt: {
      domain: 'chatgpt.com',
      css: ``,
      getInput: () => document.getElementById('prompt-textarea'),
      getSendButton: () => {
        return document.querySelector('button[data-testid="send-button"]') ||
               document.querySelector('button[data-testid="fruitjuice-send-button"]') ||
               document.querySelector('button[aria-label="Send prompt"]');
      },
      isGenerating: () => {
        return !!(document.querySelector('button[data-testid="stop-button"]') ||
                  document.querySelector('button[aria-label="Stop generating"]') ||
                  document.querySelector('button[aria-label*="stop" i]') ||
                  document.querySelector('button[aria-label*="parar" i]'));
      },
      getLastResponseElement: () => {
        const turnElements = document.querySelectorAll('[data-testid^="conversation-turn-"]');
        if (turnElements.length === 0) return null;
        for (let i = turnElements.length - 1; i >= 0; i--) {
          const turn = turnElements[i];
          const md = turn.querySelector('.markdown');
          if (md) {
            return md;
          }
        }
        return null;
      }
    },
    gemini: {
      domain: 'gemini.google.com',
      css: ``,
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
                  document.querySelector('button[aria-label="Stop"]') ||
                  document.querySelector('button[aria-label*="stop" i]') ||
                  document.querySelector('button[aria-label*="parar" i]') ||
                  document.querySelector('button[aria-label*="interromper" i]'));
      },
      getLastResponseElement: () => {
        const chatElements = document.querySelectorAll('message-content, .message-content, .response-content');
        if (chatElements.length === 0) return null;
        return chatElements[chatElements.length - 1];
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
    try {
      const head = document.head || document.getElementsByTagName('head')[0];
      if (!head) {
        log('Erro: document.head não encontrado para injeção de CSS.');
        return;
      }
      if (document.getElementById('radia-clean-css')) return;
      const style = document.createElement('style');
      style.id = 'radia-clean-css';
      style.innerHTML = currentSite.css;
      head.appendChild(style);
      log('CSS limpo injetado.');
    } catch (err) {
      log('Erro ao injetar CSS de limpeza:', err);
    }
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

  // --- RECONSTRUÇÃO DE MARKDOWN E FORMATOS ---
  function getMarkdownFromElement(el) {
    if (!el) return '';
    try {
      const clone = el.cloneNode(true);
      
      // Remove botões internos (como botões de copiar ou o botão 'Inserir no Delphi' injetado)
      const buttons = clone.querySelectorAll('button, .radia-insert-btn, [class*="copy" i]');
      buttons.forEach(btn => btn.remove());
      
      // Localiza todos os elementos de bloco de código pre/code
      const preElements = clone.querySelectorAll('pre');
      preElements.forEach(pre => {
        const codeEl = pre.querySelector('code') || pre;
        let lang = 'pascal';
        
        // Tenta extrair a linguagem das classes do code ou do pre
        const classes = (codeEl.getAttribute('class') || '') + ' ' + (pre.getAttribute('class') || '');
        const langMatch = classes.match(/language-(\w+)/i);
        if (langMatch) {
          lang = langMatch[1];
        } else {
          // Fallback: tenta buscar no cabeçalho do bloco de código na página original
          const parent = pre.parentElement;
          if (parent) {
            const header = parent.querySelector('.code-header') || parent.querySelector('[class*="header" i]');
            if (header) {
              const headerText = header.innerText.trim().toLowerCase();
              if (headerText && headerText.length < 20) {
                lang = headerText;
              }
            }
          }
        }
        
        // Obtém o texto do código puro mantendo todas as quebras de linha (textContent)
        const codeText = codeEl.textContent || '';
        
        // Cria a representação do bloco em Markdown clássico
        const markdownText = `\n\`\`\`${lang}\n${codeText.trim()}\n\`\`\`\n`;
        
        const textNode = document.createTextNode(markdownText);
        pre.parentNode.replaceChild(textNode, pre);
      });

      // Adiciona quebras de linha explícitas para elementos de bloco comuns para evitar que o texto
      // fique colado quando extraído em abas ocultas/background (onde innerText falha em formatar quebras).
      const blockTags = clone.querySelectorAll('p, li, h1, h2, h3, h4, h5, h6, br');
      blockTags.forEach(tag => {
        if (tag.tagName === 'BR') {
          const brNewline = document.createTextNode('\n');
          tag.parentNode.replaceChild(brNewline, tag);
        } else {
          const beforeNode = document.createTextNode('\n');
          const afterNode = document.createTextNode('\n');
          tag.parentNode.insertBefore(beforeNode, tag);
          tag.parentNode.insertBefore(afterNode, tag.nextSibling);
        }
      });
      
      // Usamos textContent para ler o DOM bruto de forma independente de renderização visual/layout CSS
      let markdown = clone.textContent || '';
      
      // Limpa quebras de linha consecutivas excessivas para manter a formatação limpa
      markdown = markdown.replace(/\n{3,}/g, '\n\n');
      
      return markdown.trim();
    } catch (err) {
      log('Erro ao formatar Markdown do elemento:', err);
      return el.textContent || el.innerText || '';
    }
  }

  // --- MONITORAMENTO DA RESPOSTA (Scraping & Stream) ---
  let monitorInterval = null;
  let lastText = '';
  let generatingTimeout = 0;
  let previousResponseElement = null;
  let wasGeneratingDetected = false;

  function startMonitoring() {
    log('Iniciando monitoramento de resposta...');
    lastText = '';
    generatingTimeout = 0;
    wasGeneratingDetected = false;
    
    // Captura o elemento da última resposta existente ANTES de começar a nova
    previousResponseElement = currentSite.getLastResponseElement();
    log('Elemento de resposta anterior:', previousResponseElement);
    
    if (monitorInterval) clearInterval(monitorInterval);

    monitorInterval = setInterval(() => {
      const currentEl = currentSite.getLastResponseElement();
      
      // Se ainda não temos um elemento novo, ignoramos (espera o site criar o elemento de resposta do prompt atual)
      if (!currentEl || currentEl === previousResponseElement) {
        log('Aguardando criação da nova bolha de resposta no DOM...');
        return;
      }

      const text = getMarkdownFromElement(currentEl);
      const isGenerating = currentSite.isGenerating();
      if (isGenerating) {
        wasGeneratingDetected = true;
      }

      if (text && text !== lastText) {
        log('Enviando resposta completa de streaming:', text.length, 'bytes');
        sendToDelphi({
          action: 'update_stream',
          text: text,
          isDone: false
        });
        lastText = text;
        generatingTimeout = 0; // Reset timeout because text content is still growing
      }

      if (!isGenerating && lastText.length > 0) {
        generatingTimeout++;
        // Se detectamos que o botão de stop/loading funcionou antes, confiamos no isGenerating=false.
        // O silêncio necessário é de apenas 4 ciclos (1.2 segundo).
        // Se o botão nunca foi detectado (detector falhou), usamos um silêncio de segurança de 25 ciclos (7.5 segundos).
        const requiredCycles = wasGeneratingDetected ? 4 : 25;
        if (generatingTimeout >= requiredCycles) {
          log('Geração concluída.');
          clearInterval(monitorInterval);
          monitorInterval = null;

          // Envia o fechamento final com a resposta consolidada
          sendToDelphi({
            action: 'update_stream',
            text: lastText,
            isDone: true
          });
        }
      } else {
        generatingTimeout = 0;
      }
    }, 300);
  }

  // --- INJEÇÃO DE BOTÕES "INSERIR NO DELPHI" ---

  let observer = null;
  let injectTimeout = null;

  function injectInsertBtnCSS() {
    try {
      const head = document.head || document.getElementsByTagName('head')[0];
      if (!head) return;
      if (document.getElementById('radia-insert-btn-css')) return;

      const style = document.createElement('style');
      style.id = 'radia-insert-btn-css';
      style.innerHTML = `
        .radia-insert-btn {
          background: rgba(0, 122, 204, 0.85) !important;
          color: #ffffff !important;
          border: 1px solid rgba(255, 255, 255, 0.15) !important;
          border-radius: 4px !important;
          padding: 4px 8px !important;
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
          font-size: 11px !important;
          font-weight: 600 !important;
          cursor: pointer !important;
          z-index: 9999 !important;
          transition: all 0.2s ease !important;
          display: inline-flex !important;
          align-items: center !important;
          gap: 4px !important;
          line-height: 1 !important;
        }
        .radia-insert-btn:hover {
          background: rgba(0, 122, 204, 1.0) !important;
          transform: translateY(-1px) !important;
          box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2) !important;
        }
        .radia-insert-btn:active {
          transform: translateY(0) !important;
        }
      `;
      head.appendChild(style);
    } catch (err) {
      log('Erro ao injetar CSS do botão:', err);
    }
  }

  function injectDelphiButtons() {
    try {
      const preElements = document.querySelectorAll('pre');
      preElements.forEach(pre => {
        if (pre.getAttribute('data-radia-injected') === 'true') return;
        
        const code = pre.querySelector('code');
        if (!code) return;

        const computedStyle = window.getComputedStyle(pre);
        if (computedStyle.position === 'static') {
          pre.style.position = 'relative';
        }

        const btn = document.createElement('button');
        btn.className = 'radia-insert-btn';
        btn.title = 'Inserir este código diretamente no editor do Delphi';
        btn.innerHTML = `
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="display:inline-block; vertical-align:middle; width:12px; height:12px;">
            <polyline points="16 18 22 12 16 6"></polyline>
            <polyline points="8 6 2 12 8 18"></polyline>
          </svg>
          <span>Inserir no Delphi</span>
        `;

        btn.style.position = 'absolute';
        btn.style.top = '8px';
        btn.style.right = '85px';

        btn.addEventListener('click', (e) => {
          e.preventDefault();
          e.stopPropagation();
          
          let codeText = code.innerText;
          codeText = codeText.trim();
          
          log('Solicitando aplicação de código no Delphi:', codeText.length, 'bytes');
          sendToDelphi({
            action: 'apply_code',
            code: codeText
          });

          const span = btn.querySelector('span');
          const originalText = span.innerText;
          span.innerText = 'Inserido!';
          btn.style.background = '#4CAF50';
          setTimeout(() => {
            span.innerText = originalText;
            btn.style.background = '';
          }, 1500);
        });

        pre.appendChild(btn);
        pre.setAttribute('data-radia-injected', 'true');
      });
    } catch (err) {
      log('Erro ao injetar botões nos elementos pre:', err);
    }
  }

  function scheduleInjection() {
    if (injectTimeout) {
      clearTimeout(injectTimeout);
    }
    injectTimeout = setTimeout(() => {
      if (observer) {
        try {
          observer.disconnect();
        } catch (err) {
          log('Erro ao desconectar observer:', err);
        }
      }
      
      injectDelphiButtons();
      
      if (observer && document.body) {
        try {
          observer.observe(document.body, {
            childList: true,
            subtree: true
          });
        } catch (err) {
          log('Erro ao reconectar observer:', err);
        }
      }
    }, 300);
  }

  let loginSignaled = false;
  function checkLoginComplete() {
    if (loginSignaled) return true;
    try {
      const inputEl = currentSite.getInput();
      if (inputEl) {
        log('Login concluído! Avisando o Delphi.');
        sendToDelphi({ action: 'login_complete' });
        loginSignaled = true;
        return true;
      }
    } catch (err) {
      log('Erro ao checar estado de login:', err);
    }
    return false;
  }

  function initBridge() {
    checkLoginComplete();
    injectCSS();
    injectInsertBtnCSS();
    injectDelphiButtons();

    try {
      if (typeof MutationObserver !== 'undefined') {
        observer = new MutationObserver((mutations) => {
          checkLoginComplete();
          let shouldCheck = false;
          for (let mutation of mutations) {
            // Ignora se a mutação foi originada por nossa injeção direta de botões
            let isOurBtn = false;
            mutation.addedNodes.forEach(node => {
              if (node.classList && (node.classList.contains('radia-insert-btn') || node.classList.contains('radia-insert-btn-css'))) {
                isOurBtn = true;
              }
            });
            if (isOurBtn) continue;

            if (mutation.addedNodes.length > 0) {
              shouldCheck = true;
              break;
            }
          }
          if (shouldCheck) {
            scheduleInjection();
          }
        });

        if (document.body) {
          observer.observe(document.body, {
            childList: true,
            subtree: true
          });
          log('Observer de injeção de botões e bridge ativado com sucesso.');
        } else {
          log('Erro: document.body ausente ao tentar ativar o observer.');
        }
      } else {
        log('Aviso: MutationObserver não é suportado neste ambiente.');
      }
    } catch (err) {
      log('Erro ao inicializar MutationObserver:', err);
    }
  }

  if (document.body && document.head) {
    initBridge();
  } else {
    document.addEventListener('DOMContentLoaded', initBridge);
  }
})();
