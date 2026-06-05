// ============================================================
//  RadIA Chat — JavaScript (Redesign Premium com Sidebar)
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

// -- Ícones SVG discretos e nítidos (Mockup 1:1) --
const SVG_ICONS = {
  copy: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>`,
  apply: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"></path></svg>`,
  check: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"></path></svg>`,
  edit: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"></path><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"></path></svg>`,
  trash: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>`
};

// -- Renderer de Markdown com botões baseados em SVGs nítidos --
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

  return `
    <div class="code-block-container">
      <div class="code-header">
        <span>${language.toUpperCase()}</span>
        <div class="code-header-actions">
          <button class="copy-btn" title="Copy Code" onclick="copyCode(this, '${id}')">${SVG_ICONS.copy}</button>
          ${isPascal ? `<button class="apply-btn" title="Apply to Editor" onclick="applyCode('${id}')">${SVG_ICONS.apply}</button>` : ''}
        </div>
      </div>
      <pre><code class="language-${language}">${code}</code></pre>
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

// Elementos da Sidebar
const sessionsSidebar = document.getElementById('sessions-sidebar');
const btnNewChatSidebar = document.getElementById('btn-new-chat-sidebar');
const sessionsList    = document.getElementById('sessions-list');

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
const _promptHistory = [];
let _promptHistoryIndex = -1;
let _promptDraft = '';

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

// Envio por Ctrl+Enter, e navegação no histórico com Seta Cima/Baixo
promptTextarea.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && e.ctrlKey) {
    e.preventDefault();
    handleSend();
  } else if (e.key === 'ArrowUp') {
    // Só navega se o cursor estiver na primeira linha (sem \n antes do cursor)
    const textBeforeCursor = promptTextarea.value.substring(0, promptTextarea.selectionStart);
    if (!textBeforeCursor.includes('\n')) {
      if (_promptHistory.length > 0) {
        if (_promptHistoryIndex === -1) {
          _promptDraft = promptTextarea.value;
          _promptHistoryIndex = _promptHistory.length - 1;
        } else if (_promptHistoryIndex > 0) {
          _promptHistoryIndex--;
        }
        promptTextarea.value = _promptHistory[_promptHistoryIndex];
        setTimeout(() => {
          promptTextarea.selectionStart = promptTextarea.selectionEnd = promptTextarea.value.length;
          promptTextarea.dispatchEvent(new Event('input'));
        }, 0);
        e.preventDefault();
      }
    }
  } else if (e.key === 'ArrowDown') {
    // Só navega se o cursor estiver na última linha (sem \n depois do cursor)
    const textAfterCursor = promptTextarea.value.substring(promptTextarea.selectionEnd);
    if (!textAfterCursor.includes('\n')) {
      if (_promptHistoryIndex !== -1) {
        if (_promptHistoryIndex < _promptHistory.length - 1) {
          _promptHistoryIndex++;
          promptTextarea.value = _promptHistory[_promptHistoryIndex];
        } else {
          _promptHistoryIndex = -1;
          promptTextarea.value = _promptDraft;
        }
        setTimeout(() => {
          promptTextarea.selectionStart = promptTextarea.selectionEnd = promptTextarea.value.length;
          promptTextarea.dispatchEvent(new Event('input'));
        }, 0);
        e.preventDefault();
      }
    }
  }
});

btnSendPrompt.addEventListener('click', handleSend);

function handleSend() {
  if (requestInProgress) {
    postMessageToDelphi({ action: 'cancel_request' });
    return;
  }

  const text = promptTextarea.value.trim();
  if (!text) return;

  // Salva no histórico de prompts locais enviados
  if (_promptHistory.length === 0 || _promptHistory[_promptHistory.length - 1] !== text) {
    _promptHistory.push(text);
    if (_promptHistory.length > 100) {
      _promptHistory.shift();
    }
  }
  _promptHistoryIndex = -1;
  _promptDraft = '';

  postMessageToDelphi({ action: 'send_prompt', text: text });
  promptTextarea.value = '';
  promptTextarea.style.height = 'auto';
}

// Eventos dos botões do topo
btnNewChat.addEventListener('click', () => postMessageToDelphi({ action: 'new_chat' }));
btnHistory.addEventListener('click', () => {
  // Alterna o estado recolhido da sidebar HTML
  sessionsSidebar.classList.toggle('collapsed');
});
btnSettings.addEventListener('click', () => postMessageToDelphi({ action: 'open_settings' }));

// Novo chat pela sidebar
btnNewChatSidebar.addEventListener('click', () => postMessageToDelphi({ action: 'new_chat' }));

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
  
  // Realça sintaxe usando Prism de forma assíncrona
  setTimeout(() => {
    Prism.highlightAllUnder(wrapper);
  }, 10);

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
    const orig = btn.innerHTML;
    btn.innerHTML = SVG_ICONS.check;
    setTimeout(() => { btn.innerHTML = orig; }, 2000);
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
  
  // Executa Prism de forma contínua nos blocos de código adicionados
  Prism.highlightAllUnder(currentAssistantContent);

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
//  Renderização Dinâmica do Histórico de Sessões (HTML Premium)
// ============================================================
function updateSessions(sessions, activeSessionId) {
  sessionsList.innerHTML = '';

  if (!sessions || sessions.length === 0) {
    sessionsList.innerHTML = `<div class="no-sessions">No conversations active</div>`;
    return;
  }

  sessions.forEach(session => {
    const item = document.createElement('div');
    item.classList.add('session-item');
    if (session.id === activeSessionId) {
      item.classList.add('active');
    }

    // Nome da Sessão (ou input para renomear)
    const nameEl = document.createElement('span');
    nameEl.classList.add('session-name');
    nameEl.textContent = session.name;
    
    // Suporte a duplo clique para renomeação inline rápida
    nameEl.addEventListener('dblclick', () => startRename(item, session.id, nameEl));

    // Ações (Editar e Deletar)
    const actions = document.createElement('div');
    actions.classList.add('session-item-actions');

    const btnRename = document.createElement('button');
    btnRename.classList.add('session-action-btn');
    btnRename.title = "Rename Conversation";
    btnRename.innerHTML = SVG_ICONS.edit;
    btnRename.addEventListener('click', (e) => {
      e.stopPropagation();
      startRename(item, session.id, nameEl);
    });

    const btnDelete = document.createElement('button');
    btnDelete.classList.add('session-action-btn', 'delete-btn');
    btnDelete.title = "Delete Conversation";
    btnDelete.innerHTML = SVG_ICONS.trash;
    btnDelete.addEventListener('click', (e) => {
      e.stopPropagation();
      if (confirm(`Excluir conversa "${session.name}"?`)) {
        postMessageToDelphi({ action: 'delete_session', id: session.id });
      }
    });

    actions.appendChild(btnRename);
    actions.appendChild(btnDelete);

    item.appendChild(nameEl);
    item.appendChild(actions);

    // Seleção de Sessão ao clicar no item
    item.addEventListener('click', (e) => {
      if (item.classList.contains('renaming')) return;
      postMessageToDelphi({ action: 'select_session', id: session.id });
    });

    sessionsList.appendChild(item);
  });
}

function startRename(item, sessionId, nameEl) {
  item.classList.add('renaming');
  const currentName = nameEl.textContent;
  
  const input = document.createElement('input');
  input.type = 'text';
  input.classList.add('session-rename-input');
  input.value = currentName;
  
  nameEl.style.display = 'none';
  item.insertBefore(input, nameEl);
  input.focus();
  input.select();

  // Função para salvar a renomeação
  function saveRename() {
    const newName = input.value.trim();
    if (newName && newName !== currentName) {
      postMessageToDelphi({ action: 'rename_session', id: sessionId, name: newName });
    }
    cleanup();
  }

  function cleanup() {
    input.remove();
    nameEl.style.display = '';
    item.classList.remove('renaming');
  }

  input.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      saveRename();
    } else if (e.key === 'Escape') {
      cleanup();
    }
  });

  input.addEventListener('blur', saveRename);
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
      case 'update_sessions':   updateSessions(data.sessions, data.activeSessionId);         break;
    }
  });
  window.chrome.webview.postMessage(JSON.stringify({ action: 'ready' }));
}
