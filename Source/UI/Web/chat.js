// ============================================================
//  RadIA Chat — JavaScript
//  Redesign para alinhar com mockup oficial
// ============================================================

// -- Configuração do Marked com Prism para highlight de código --
marked.setOptions({
  highlight: function(code, lang) {
    const language = lang || 'pascal';
    if (Prism.languages[language]) {
      return Prism.highlight(code, Prism.languages[language], language);
    }
    return code;
  }
});

// -- Code block registry — stores code by ID to avoid newline/escaping issues in onclick attrs --
const _codeRegistry = {};
let _codeRegistryCounter = 0;

// -- Renderer customizado com copy + apply buttons --
const renderer = new marked.Renderer();
renderer.code = function(codeOrToken, lang) {
  let code = '';
  let language = '';

  if (typeof codeOrToken === 'string') {
    code = codeOrToken;
    language = lang || 'pascal';
  } else if (codeOrToken && typeof codeOrToken === 'object') {
    code = codeOrToken.text || '';
    language = codeOrToken.lang || lang || 'pascal';
  } else {
    code = String(codeOrToken || '');
    language = lang || 'pascal';
  }

  const id = 'cb_' + (++_codeRegistryCounter);
  _codeRegistry[id] = code; // Store original code with proper newlines

  const isPascal = ['pascal', 'delphi', 'objectpascal'].includes(language.toLowerCase());
  const highlighted = Prism.languages[language]
    ? Prism.highlight(code, Prism.languages[language], language)
    : code;

  return `
    <div class="code-block-container">
      <div class="code-header">
        <span>${language.toUpperCase()}</span>
        <div class="code-header-actions">
          <button class="copy-btn" title="Copy Code" onclick="copyCode(this, '${id}')">❐</button>
          ${isPascal ? `<button class="apply-btn" title="Apply to Editor" onclick="applyCode('${id}')">✓</button>` : ''}
        </div>
      </div>
      <pre><code class="language-${language}">${highlighted}</code></pre>
    </div>
  `;
};
marked.use({ renderer });

// -- Container principal --
const chatContainer = document.getElementById('chat-container');

// ============================================================
//  Nomes e ícones dos remetentes
// ============================================================
const SENDER_INFO = {
  user:      { name: 'User',     icon: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="12" fill="#4E4E52"/><path d="M12 11C13.6569 11 15 9.65685 15 8C15 6.34315 13.6569 5 12 5C10.3431 5 9 6.34315 9 8C9 9.65685 10.3431 11 12 11Z" fill="#F1F1F1"/><path d="M12 12.5C9.33 12.5 4 13.84 4 16.5V18H20V16.5C20 13.84 14.67 12.5 12 12.5Z" fill="#F1F1F1"/></svg>`, avatarClass: 'user-avatar', headerClass: 'user-header' },
  assistant: { name: 'Codex AI', icon: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="12" fill="var(--accent)"/><path d="M12 6L13.8 10.2L18 12L13.8 13.8L12 18L10.2 13.8L6 12L10.2 10.2L12 6Z" fill="#FFFFFF"/></svg>`, avatarClass: 'ai-avatar',   headerClass: 'ai-header'   },
  system:    { name: 'System',   icon: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="12" fill="var(--accent)"/><path d="M12 6L13.8 10.2L18 12L13.8 13.8L12 18L10.2 13.8L6 12L10.2 10.2L12 6Z" fill="#FFFFFF"/></svg>`, avatarClass: 'ai-avatar',   headerClass: 'ai-header'   }
};

// ============================================================
//  addMessage — gera HTML com avatar + cabeçalho + conteúdo
// ============================================================
function addMessage(role, text, provider, model) {
  hideTypingIndicator();
  if (text === undefined || text === null) {
    text = '';
  }
  const info = SENDER_INFO[role] || SENDER_INFO.assistant;

  const wrapper = document.createElement('div');
  wrapper.classList.add('message-wrapper');

  // Avatar
  const avatar = document.createElement('div');
  avatar.classList.add('message-avatar', info.avatarClass);
  avatar.innerHTML = info.icon;

  // Corpo (header + conteúdo)
  const body = document.createElement('div');
  body.classList.add('message-body');

  const header = document.createElement('div');
  header.classList.add('message-header', info.headerClass);
  let headerText = info.name;
  if (role === 'assistant' && provider && model) {
    headerText += ` • ${provider} (${model})`;
  }
  header.textContent = headerText;

  const content = document.createElement('div');
  content.classList.add('message-content');

  if (role === 'assistant' || role === 'system') {
    content.innerHTML = marked.parse(text);
  } else {
    // Escape HTML para mensagens do usuário
    const p = document.createElement('p');
    p.textContent = text;
    content.appendChild(p);
  }

  body.appendChild(header);
  body.appendChild(content);

  wrapper.appendChild(avatar);
  wrapper.appendChild(body);

  chatContainer.appendChild(wrapper);
  chatContainer.scrollTop = chatContainer.scrollHeight;

  return wrapper;
}

// ============================================================
//  clearChat
// ============================================================
function clearChat() {
  chatContainer.innerHTML = '';
  currentAssistantWrapper = null;
  currentAssistantContent = null;
  currentAssistantText = '';
}

// ============================================================
//  setTheme
// ============================================================
function setTheme(themeInfo) {
  if (!themeInfo) return;

  if (typeof themeInfo === 'string') {
    document.body.className = themeInfo + '-theme';
    return;
  }

  document.body.className = themeInfo.theme + '-theme';

  const root = document.documentElement;
  if (themeInfo.bgBase) root.style.setProperty('--bg-base', themeInfo.bgBase);
  if (themeInfo.bgPanel) root.style.setProperty('--bg-panel', themeInfo.bgPanel);
  if (themeInfo.bgInput) root.style.setProperty('--bg-input', themeInfo.bgInput);
  if (themeInfo.fgPrimary) root.style.setProperty('--fg-primary', themeInfo.fgPrimary);
  if (themeInfo.bgElevated) root.style.setProperty('--bg-elevated', themeInfo.bgElevated);
  if (themeInfo.fgSecondary) root.style.setProperty('--fg-secondary', themeInfo.fgSecondary);
  if (themeInfo.border) root.style.setProperty('--border', themeInfo.border);
  if (themeInfo.accent) root.style.setProperty('--accent', themeInfo.accent);
  if (themeInfo.codeBg) root.style.setProperty('--code-bg', themeInfo.codeBg);
  if (themeInfo.codeHeader) root.style.setProperty('--code-header', themeInfo.codeHeader);
  if (themeInfo.greenApply) root.style.setProperty('--green-apply', themeInfo.greenApply);
}

// ============================================================
//  copyCode / applyCode
// ============================================================
function copyCode(btn, id) {
  const code = _codeRegistry[id] || '';
  navigator.clipboard.writeText(code).then(() => {
    const orig = btn.innerText;
    btn.innerText = '✓';
    setTimeout(() => { btn.innerText = orig; }, 2000);
  });
}

function applyCode(id) {
  const code = _codeRegistry[id] || '';
  if (window.chrome && window.chrome.webview) {
    window.chrome.webview.postMessage(JSON.stringify({
      action: 'apply_code',
      code: code
    }));
  }
}

// ============================================================
//  Barra de status (token usage)
// ============================================================
const statusBar  = document.getElementById('status-bar');
const statusText = document.getElementById('status-text');

function updateTokens(text) {
  if (text) {
    statusText.innerText = text;
    statusBar.classList.remove('hidden');
  } else {
    statusBar.classList.add('hidden');
  }
}

// ============================================================
//  Typing indicator
// ============================================================
let typingIndicatorEl = null;

function showTypingIndicator() {
  if (typingIndicatorEl) return;

  const info = SENDER_INFO.assistant;

  const wrapper = document.createElement('div');
  wrapper.classList.add('typing-wrapper');

  const avatar = document.createElement('div');
  avatar.classList.add('message-avatar', info.avatarClass);
  avatar.innerHTML = info.icon;

  const indicator = document.createElement('div');
  indicator.classList.add('typing-indicator');
  indicator.innerHTML = `
    <div class="typing-dot"></div>
    <div class="typing-dot"></div>
    <div class="typing-dot"></div>
  `;

  wrapper.appendChild(avatar);
  wrapper.appendChild(indicator);

  chatContainer.appendChild(wrapper);
  chatContainer.scrollTop = chatContainer.scrollHeight;
  typingIndicatorEl = wrapper;
}

function hideTypingIndicator() {
  if (typingIndicatorEl) {
    typingIndicatorEl.remove();
    typingIndicatorEl = null;
  }
}

// ============================================================
//  Streaming — appendMessage (constrói mensagem incrementalmente)
// ============================================================
let currentAssistantWrapper = null;
let currentAssistantContent = null;
let currentAssistantText    = '';

function appendMessage(text, isDone, provider, model) {
  hideTypingIndicator();

  if (text === undefined || text === null) {
    text = '';
  }

  if (!currentAssistantWrapper) {
    // Se terminou e não tem texto, não cria a bolha
    if (isDone && text === '') {
      return;
    }

    const info = SENDER_INFO.assistant;

    currentAssistantWrapper = document.createElement('div');
    currentAssistantWrapper.classList.add('message-wrapper');

    const avatar = document.createElement('div');
    avatar.classList.add('message-avatar', info.avatarClass);
    avatar.innerHTML = info.icon;

    const body = document.createElement('div');
    body.classList.add('message-body');

    const header = document.createElement('div');
    header.classList.add('message-header', info.headerClass);
    let headerText = info.name;
    if (provider && model) {
      headerText += ` • ${provider} (${model})`;
    }
    header.textContent = headerText;

    currentAssistantContent = document.createElement('div');
    currentAssistantContent.classList.add('message-content');

    body.appendChild(header);
    body.appendChild(currentAssistantContent);
    currentAssistantWrapper.appendChild(avatar);
    currentAssistantWrapper.appendChild(body);
    chatContainer.appendChild(currentAssistantWrapper);
  }

  currentAssistantText += text;
  currentAssistantContent.innerHTML = marked.parse(currentAssistantText);
  chatContainer.scrollTop = chatContainer.scrollHeight;

  if (isDone) {
    currentAssistantWrapper = null;
    currentAssistantContent  = null;
    currentAssistantText     = '';
  }
}

// ============================================================
//  Listener de mensagens do Delphi (WebView2)
// ============================================================
if (window.chrome && window.chrome.webview) {
  window.chrome.webview.addEventListener('message', event => {
    const data = event.data;
    switch (data.action) {
      case 'add_message':    addMessage(data.role, data.text, data.provider, data.model); break;
      case 'clear_chat':     clearChat();                                                 break;
      case 'set_theme':      setTheme(data);                                              break;
      case 'update_tokens':  updateTokens(data.text);                                     break;
      case 'show_typing':    showTypingIndicator();                                       break;
      case 'append_message': appendMessage(data.text, data.isDone, data.provider, data.model); break;
    }
  });
  window.chrome.webview.postMessage(JSON.stringify({ action: 'ready' }));
}
