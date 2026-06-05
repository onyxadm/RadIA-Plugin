// ============================================================
//  RadIA Chat — JavaScript (Redesign Premium Integrado)
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
  _codeRegistry[id] = code;

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

// ============================================================
//  Elementos do DOM
// ============================================================
const chatContainer   = document.getElementById('chat-container');
const btnNewChat      = document.getElementById('btn-new-chat');
const btnHistory      = document.getElementById('btn-history');
const btnSettings     = document.getElementById('btn-settings');
const promptTextarea  = document.getElementById('prompt-textarea');
const btnSendPrompt   = document.getElementById('btn-send-prompt');
const selectProvider  = document.getElementById('select-provider');
const selectModel     = document.getElementById('select-model');
const statusBar       = document.getElementById('status-bar');
const statusText      = document.getElementById('status-text');
const contextBar      = document.getElementById('context-bar');
const contextText     = document.getElementById('context-text');

// ============================================================
//  Nomes e ícones dos remetentes (SVG Premium)
// ============================================================
const SENDER_INFO = {
  user: { 
    name: 'User', 
    icon: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="12" fill="#4E4E52"/><path d="M12 11C13.6569 11 15 9.65685 15 8C15 6.34315 13.6569 5 12 5C10.3431 5 9 6.34315 9 8C9 9.65685 10.3431 11 12 11Z" fill="#F1F1F1"/><path d="M12 12.5C9.33 12.5 4 13.84 4 16.5V18H20V16.5C20 13.84 14.67 12.5 12 12.5Z" fill="#F1F1F1"/></svg>`, 
    avatarClass: 'user-avatar', 
    headerClass: 'user-header' 
  },
  assistant: { 
    name: 'Codex AI', 
    icon: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="12" fill="var(--accent)"/><path d="M12 6L13.8 10.2L18 12L13.8 13.8L12 18L10.2 13.8L6 12L10.2 10.2L12 6Z" fill="#FFFFFF"/></svg>`, 
    avatarClass: 'ai-avatar',   
    headerClass: 'ai-header'   
  },
  system: { 
    name: 'System',   
    icon: `<svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><circle cx="12" cy="12" r="12" fill="var(--accent)"/><path d="M12 6L13.8 10.2L18 12L13.8 13.8L12 18L10.2 13.8L6 12L10.2 10.2L12 6Z" fill="#FFFFFF"/></svg>`, 
    avatarClass: 'ai-avatar',   
    headerClass: 'ai-header'   
  }
};

let requestInProgress = false;

// ============================================================
//  Ponte de Comunicação (PostMessage)
// ============================================================
function postMessageToDelphi(payload) {
  if (window.chrome && window.chrome.webview) {
    window.chrome.webview.postMessage(JSON.stringify(payload));
  }
}

// ============================================================
//  Lógica de Interface
// ============================================================

// Auto-expand do textarea ao digitar
promptTextarea.addEventListener('input', () => {
  promptTextarea.style.height = 'auto';
  promptTextarea.style.height = promptTextarea.scrollHeight + 'px';
});

// Envio por Ctrl+Enter ou Click
promptTextarea.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && e.ctrlKey) {
    e.preventDefault();
    handleSend();
  }
});

btnSendPrompt.addEventListener('click', handleSend);

function handleSend() {
  if (requestInProgress) {
    // Ação de cancelar requisição ativa
    postMessageToDelphi({ action: 'cancel_request' });
    return;
  }

  const text = promptTextarea.value.trim();
  if (!text) return;

  // Enviar prompt ao Delphi
  postMessageToDelphi({ action: 'send_prompt', text: text });
  promptTextarea.value = '';
  promptTextarea.style.height = 'auto';
}

// Eventos dos botões do topo
btnNewChat.addEventListener('click', () => postMessageToDelphi({ action: 'new_chat' }));
btnHistory.addEventListener('click', () => postMessageToDelphi({ action: 'toggle_history' }));
btnSettings.addEventListener('click', () => postMessageToDelphi({ action: 'open_settings' }));

// Mudança de Provedores e Modelos
selectProvider.addEventListener('change', () => {
  postMessageToDelphi({ action: 'change_provider', provider: selectProvider.value });
});

selectModel.addEventListener('change', () => {
  postMessageToDelphi({ action: 'change_model', model: selectModel.value });
});

// ============================================================
//  Lógica do Chat (Add, Clear, Theme, etc.)
// ============================================================
function addMessage(role, text, provider, model) {
  hideTypingIndicator();
  if (text === undefined || text === null) {
    text = '';
  }
  const info = SENDER_INFO[role] || SENDER_INFO.assistant;

  const wrapper = document.createElement('div');
  wrapper.classList.add('message-wrapper');

  const avatar = document.createElement('div');
  avatar.classList.add('message-avatar', info.avatarClass);
  avatar.innerHTML = info.icon;

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

function clearChat() {
  chatContainer.innerHTML = '';
  currentAssistantWrapper = null;
  currentAssistantContent = null;
  currentAssistantText = '';
}

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
  postMessageToDelphi({ action: 'apply_code', code: code });
}

function updateTokens(text) {
  if (text) {
    statusText.innerText = text;
    statusBar.classList.remove('hidden');
  } else {
    statusBar.classList.add('hidden');
  }
}

// Typing Indicator
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

// Streaming
let currentAssistantWrapper = null;
let currentAssistantContent = null;
let currentAssistantText    = '';

function appendMessage(text, isDone, provider, model) {
  hideTypingIndicator();

  if (text === undefined || text === null) {
    text = '';
  }

  if (!currentAssistantWrapper) {
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
//  Controle de Seleção Dinâmica (Providers & Models)
// ============================================================
function initializeConfig(data) {
  // Preencher provedores
  selectProvider.innerHTML = '';
  data.providers.forEach(p => {
    const opt = document.createElement('option');
    opt.value = p.value;
    opt.textContent = p.name;
    if (p.value === data.activeProvider) {
      opt.selected = true;
    }
    selectProvider.appendChild(opt);
  });

  // Preencher modelos
  updateModelsList(data.models, data.activeModel);
}

function updateModelsList(models, activeModel) {
  selectModel.innerHTML = '';
  
  if (!models || models.length === 0) {
    const opt = document.createElement('option');
    opt.value = '';
    opt.textContent = 'No models available';
    selectModel.appendChild(opt);
    return;
  }

  models.forEach(m => {
    const opt = document.createElement('option');
    opt.value = m;
    opt.textContent = m;
    if (m === activeModel) {
      opt.selected = true;
    }
    selectModel.appendChild(opt);
  });
}

function setRequestState(inProgress) {
  requestInProgress = inProgress;
  if (inProgress) {
    btnSendPrompt.classList.add('stop-btn');
    btnSendPrompt.title = 'Cancel request';
    // Opcional: desabilitar selects enquanto carrega
    selectProvider.disabled = true;
    selectModel.disabled = true;
  } else {
    btnSendPrompt.classList.remove('stop-btn');
    btnSendPrompt.title = 'Send message';
    selectProvider.disabled = false;
    selectModel.disabled = false;
  }
}

function setContextText(text) {
  if (text && text.trim()) {
    contextText.innerText = text;
    contextBar.classList.remove('hidden');
  } else {
    contextBar.classList.add('hidden');
  }
}

// ============================================================
//  Listener de mensagens do Delphi (WebView2)
// ============================================================
if (window.chrome && window.chrome.webview) {
  window.chrome.webview.addEventListener('message', event => {
    const data = event.data;
    switch (data.action) {
      case 'add_message':       addMessage(data.role, data.text, data.provider, data.model); break;
      case 'clear_chat':        clearChat();                                                 break;
      case 'set_theme':         setTheme(data);                                              break;
      case 'update_tokens':     updateTokens(data.text);                                     break;
      case 'show_typing':       showTypingIndicator();                                       break;
      case 'hide_typing':       hideTypingIndicator();                                       break;
      case 'append_message':    appendMessage(data.text, data.isDone, data.provider, data.model); break;
      case 'initialize_config': initializeConfig(data);                                      break;
      case 'update_models':     updateModelsList(data.models, data.activeModel);             break;
      case 'set_request_state': setRequestState(data.inProgress);                            break;
      case 'set_context':       setContextText(data.text);                                   break;
    }
  });
  window.chrome.webview.postMessage(JSON.stringify({ action: 'ready' }));
}
