/* global postMessageToDelphi */


marked.setOptions({
  gfm: true,
  breaks: true,
  pedantic: false,
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

const SVG_ICONS = {
  copy: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>`,
  apply: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"></path></svg>`,
  check: `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"></path></svg>`,
  edit: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20h9"></path><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"></path></svg>`,
  trash: `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>`
};

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

  const FILEPATH_REGEX = /^(?:\/\/|\{#|\{\*|<!--)\s*filepath:\s*([^\r\n]+?)(?:\s*\}|\s*\*\}|\s*-->)?(?:\r?\n|$)/i;
  const fileMatch = code.match(FILEPATH_REGEX);
  let filepath = '';
  let isProjectFile = false;

  if (fileMatch) {
    filepath = fileMatch[1].trim();
    isProjectFile = true;
    code = code.replace(FILEPATH_REGEX, '');
  }

  const id = 'cb_' + (++_codeRegistryCounter);
  _codeRegistry[id] = code;

  const isPascal = ['pascal', 'delphi', 'objectpascal'].includes(language.toLowerCase());
  const headerTitle = isProjectFile ? `${language.toUpperCase()} - ${filepath}` : language.toUpperCase();

  return `
    <div class="code-block-container" ${isProjectFile ? `data-filepath="${filepath}" data-project-file="true"` : ''}>
      <div class="code-header">
        <span>${headerTitle}</span>
        <div class="code-header-actions">
          <button class="copy-btn" title="Copy Code" onclick="copyCode(this, '${id}')">${SVG_ICONS.copy}</button>
          ${isPascal ? `<button class="apply-btn" title="Apply to Editor" onclick="applyCode('${id}')">${SVG_ICONS.apply}</button>` : ''}
        </div>
      </div>
      <pre><code class="language-${language}">${code}</code></pre>
    </div>
  `;
};
marked.use({
  renderer,
  gfm: true,
  breaks: true
});

const chatContainer   = document.getElementById('chat-container');
const btnNewChat      = document.getElementById('btn-new-chat');
const btnClearChat    = document.getElementById('btn-clear-chat');
const btnHistory      = document.getElementById('btn-history');
const btnSettings     = document.getElementById('btn-settings');
const btnWebLogin     = document.getElementById('btn-web-login');
const promptTextarea  = document.getElementById('prompt-textarea');
const btnSendPrompt   = document.getElementById('btn-send-prompt');
const selectProvider  = document.getElementById('select-provider');
const selectModel     = document.getElementById('select-model');
const modelDropdownWrapper = document.getElementById('model-dropdown-wrapper');
const modelDropdownTrigger = document.getElementById('model-dropdown-trigger');
const modelDropdownValue   = document.getElementById('model-dropdown-value');
const modelSearchInput     = document.getElementById('model-search-input');
const modelOptionsList     = document.getElementById('model-options-list');
const statusBar       = document.getElementById('status-bar');
const statusText      = document.getElementById('status-text');
const contextBar      = document.getElementById('context-bar');
const contextText     = document.getElementById('context-text');

const sessionsSidebar = document.getElementById('sessions-sidebar');
const btnNewChatSidebar = document.getElementById('btn-new-chat-sidebar');
const sessionsList    = document.getElementById('sessions-list');

let SLASH_COMMANDS = [
  { name: '/explain', desc: 'Explains the selected code in the editor', shortcut: 'Ctrl+Shift+E' },
  { name: '/refactor', desc: 'Optimizes and refactors the selected code', shortcut: 'Ctrl+Shift+R' },
  { name: '/bugs', desc: 'Finds bugs and memory leaks in the selected code', shortcut: 'Ctrl+Shift+B' },
  { name: '/doc', desc: 'Generates XML documentation for the selected method', shortcut: 'Ctrl+Shift+D' },
  { name: '/template', desc: 'Opens the prompt templates library', shortcut: 'Ctrl+Shift+T' },
  { name: '/stacktrace', desc: 'Analyzes an error log or stack trace and points out the root cause', shortcut: '' },
  { name: '/review', desc: 'Performs static analysis on the active unit (leaks/SOLID)', shortcut: '' },
  { name: '/createproject', desc: 'Generates a complete Delphi project from specification', shortcut: '' }
];

let slashPopupVisible = false;
let slashPopupSelectedIndex = 0;
let filteredSlashCommands = [];

const chatWrapper          = document.getElementById('chat-wrapper');
const generatorsWrapper    = document.getElementById('generators-wrapper');
const btnGenerators        = document.getElementById('btn-generators');
const btnGenerateModel     = document.getElementById('btn-generate-model');
const btnCopyGenerator     = document.getElementById('btn-copy-generator');
const btnInsertGenerator   = document.getElementById('btn-insert-generator');
const generatorInput       = document.getElementById('generator-input');
const generatorInputType   = document.getElementById('generator-input-type');
const generatorOutputType  = document.getElementById('generator-output-type');
const generatorPreviewCard = document.getElementById('generator-preview-card');
const generatorOutputCode  = document.getElementById('generator-output-code');

let generatorAccumulatedCode = '';

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


promptTextarea.addEventListener('input', () => {
  promptTextarea.style.height = 'auto';
  promptTextarea.style.height = promptTextarea.scrollHeight + 'px';

  const text = promptTextarea.value;
  if (text.startsWith('/')) {
    showSlashPopup(text);
  } else {
    hideSlashPopup();
  }
});

promptTextarea.addEventListener('keydown', (e) => {
  if (slashPopupVisible) {
    if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (filteredSlashCommands.length > 0) {
        slashPopupSelectedIndex = (slashPopupSelectedIndex - 1 + filteredSlashCommands.length) % filteredSlashCommands.length;
        renderSlashCommands();
      }
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (filteredSlashCommands.length > 0) {
        slashPopupSelectedIndex = (slashPopupSelectedIndex + 1) % filteredSlashCommands.length;
        renderSlashCommands();
      }
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (filteredSlashCommands.length > 0) {
        insertSlashCommand(filteredSlashCommands[slashPopupSelectedIndex].name);
      }
    } else if (e.key === 'Escape') {
      e.preventDefault();
      hideSlashPopup();
    }
  } else {
    if (e.key === 'Enter' && e.ctrlKey) {
      e.preventDefault();
      handleSend();
    } else if (e.key === 'ArrowUp') {
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

function showTab(tabName) {
  if (tabName === 'generators') {
    chatWrapper.classList.add('hidden');
    generatorsWrapper.classList.remove('hidden');
    btnGenerators.classList.add('active');
  } else {
    generatorsWrapper.classList.add('hidden');
    chatWrapper.classList.remove('hidden');
    btnGenerators.classList.remove('active');
  }
}

btnGenerators.addEventListener('click', () => {
  if (generatorsWrapper.classList.contains('hidden')) {
    showTab('generators');
  } else {
    showTab('chat');
  }
});

btnNewChat.addEventListener('click', () => {
  showTab('chat');
  postMessageToDelphi({ action: 'new_chat' });
});

btnClearChat.addEventListener('click', () => {
  if (confirm('Clear the current conversation history?')) {
    postMessageToDelphi({ action: 'clear_chat' });
  }
});

btnHistory.addEventListener('click', () => {
  sessionsSidebar.classList.toggle('collapsed');
});

btnSettings.addEventListener('click', () => postMessageToDelphi({ action: 'open_settings' }));
if (btnWebLogin) {
  btnWebLogin.addEventListener('click', () => postMessageToDelphi({ action: 'web_login_connect' }));
}

btnNewChatSidebar.addEventListener('click', () => {
  showTab('chat');
  postMessageToDelphi({ action: 'new_chat' });
});

btnGenerateModel.addEventListener('click', () => {
  const inputVal = generatorInput.value.trim();
  if (!inputVal) return;

  btnGenerateModel.disabled = true;
  btnGenerateModel.textContent = 'Generating...';
  generatorAccumulatedCode = '';
  generatorPreviewCard.classList.add('hidden');
  generatorOutputCode.textContent = '';

  postMessageToDelphi({
    action: 'generate_dto',
    input: inputVal,
    inputType: generatorInputType.value,
    outputType: generatorOutputType.value
  });
});

btnCopyGenerator.addEventListener('click', () => {
  navigator.clipboard.writeText(generatorAccumulatedCode).then(() => {
    const orig = btnCopyGenerator.innerHTML;
    btnCopyGenerator.innerHTML = SVG_ICONS.check;
    setTimeout(() => { btnCopyGenerator.innerHTML = orig; }, 2000);
  });
});

btnInsertGenerator.addEventListener('click', () => {
  postMessageToDelphi({ action: 'apply_code', code: generatorAccumulatedCode });
  const orig = btnInsertGenerator.innerHTML;
  btnInsertGenerator.innerHTML = SVG_ICONS.check;
  setTimeout(() => { btnInsertGenerator.innerHTML = orig; }, 2000);
});

selectProvider.addEventListener('change', () => {
  postMessageToDelphi({ action: 'change_provider', provider: selectProvider.value });
});

selectModel.addEventListener('change', () => {
  postMessageToDelphi({ action: 'change_model', model: selectModel.value });
});

modelDropdownTrigger.addEventListener('click', (e) => {
  if (modelDropdownWrapper.classList.contains('disabled')) return;
  e.stopPropagation();
  modelDropdownWrapper.classList.toggle('open');
  if (modelDropdownWrapper.classList.contains('open')) {
    modelSearchInput.value = '';
    filterModels('');
    modelSearchInput.focus();
  }
});

modelSearchInput.addEventListener('click', (e) => {
  e.stopPropagation();
});

modelSearchInput.addEventListener('input', () => {
  filterModels(modelSearchInput.value.trim().toLowerCase());
});

function filterModels(query) {
  const options = modelOptionsList.getElementsByClassName('custom-dropdown-option');
  for (let opt of options) {
    const text = opt.textContent.toLowerCase();
    if (text.includes(query)) {
      opt.style.display = '';
    } else {
      opt.style.display = 'none';
    }
  }
}

document.addEventListener('click', () => {
  modelDropdownWrapper.classList.remove('open');
  hideSlashPopup();
});

function showSlashPopup(filterText) {
  filteredSlashCommands = SLASH_COMMANDS.filter(cmd => 
    cmd.name.toLowerCase().startsWith(filterText.toLowerCase())
  );
  
  if (filteredSlashCommands.length === 0) {
    hideSlashPopup();
    return;
  }
  
  const popup = document.getElementById('slash-commands-popup');
  popup.classList.remove('hidden');
  slashPopupVisible = true;
  renderSlashCommands();
}

function hideSlashPopup() {
  const popup = document.getElementById('slash-commands-popup');
  if (popup) {
    popup.classList.add('hidden');
  }
  slashPopupVisible = false;
}

function renderSlashCommands() {
  const popup = document.getElementById('slash-commands-popup');
  popup.innerHTML = '';
  
  if (slashPopupSelectedIndex >= filteredSlashCommands.length) {
    slashPopupSelectedIndex = 0;
  }
  
  filteredSlashCommands.forEach((cmd, idx) => {
    const item = document.createElement('div');
    item.classList.add('slash-command-item');
    if (idx === slashPopupSelectedIndex) {
      item.classList.add('selected');
    }
    
    item.innerHTML = `
      <div class="slash-command-info">
        <span class="slash-command-name">${cmd.name}</span>
        <span class="slash-command-desc">${cmd.desc}</span>
      </div>
      ${cmd.shortcut ? `<span class="slash-command-shortcut">${cmd.shortcut}</span>` : ''}
    `;
    
    item.addEventListener('mousedown', (e) => {
      e.preventDefault();
      e.stopPropagation();
      insertSlashCommand(cmd.name);
    });
    
    popup.appendChild(item);
  });
}

function insertSlashCommand(name) {
  promptTextarea.value = name + ' ';
  promptTextarea.focus();
  promptTextarea.style.height = 'auto';
  promptTextarea.style.height = promptTextarea.scrollHeight + 'px';
  hideSlashPopup();
}

function shouldRenderMessageAsMarkdown(role, text) {
  return role === 'assistant' || role === 'system' || text.includes('```');
}

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
    headerText += ` - ${provider} (${model})`;
  }
  header.textContent = headerText;

  const content = document.createElement('div');
  content.classList.add('message-content');

  if (shouldRenderMessageAsMarkdown(role, text)) {
    content.innerHTML = marked.parse(text);
    processProjectFiles(content);
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
      headerText += ` - ${provider} (${model})`;
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
  
  Prism.highlightAllUnder(currentAssistantContent);

  chatContainer.scrollTop = chatContainer.scrollHeight;

  if (isDone) {
    processProjectFiles(currentAssistantContent);
    currentAssistantWrapper = null;
    currentAssistantContent  = null;
    currentAssistantText     = '';
  }
}

function processProjectFiles(contentElement) {
  if (!contentElement) return;

  const fileBlocks = contentElement.querySelectorAll('.code-block-container[data-project-file="true"]');
  if (fileBlocks.length === 0) return;

  if (contentElement.querySelector('.radia-project-panel')) return;

  const projectPanel = document.createElement('div');
  projectPanel.className = 'radia-project-panel';

  const header = document.createElement('div');
  header.className = 'radia-project-header';
  header.innerHTML = `
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" style="color: var(--accent);">
      <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
    </svg>
    <span>PROJETO DELPHI GERADO</span>
  `;
  projectPanel.appendChild(header);

  const filesList = document.createElement('div');
  filesList.className = 'radia-project-files-list';

  fileBlocks.forEach((block) => {
    const filepath = block.getAttribute('data-filepath');
    const ext = filepath.split('.').pop().toLowerCase();
    const copyBtn = block.querySelector('.copy-btn');
    if (!copyBtn) return;
    const onclickAttr = copyBtn.getAttribute('onclick') || '';
    const onclickMatch = onclickAttr.match(/'([^']+)'/);
    const blockId = onclickMatch ? onclickMatch[1] : '';
    
    let iconColor = 'var(--fg-secondary)';
    let fileIconSvg = `
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
        <polyline points="14 2 14 8 20 8"></polyline>
      </svg>
    `;

    if (ext === 'dpr' || ext === 'dproj') {
      iconColor = 'var(--accent)';
      fileIconSvg = `
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="${iconColor}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="16 18 22 12 16 6"></polyline>
          <polyline points="8 6 2 12 8 18"></polyline>
        </svg>
      `;
    } else if (ext === 'pas') {
      iconColor = '#4caf50';
      fileIconSvg = `
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="${iconColor}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"></path>
          <polyline points="14 2 14 8 20 8"></polyline>
        </svg>
      `;
    } else if (ext === 'dfm') {
      iconColor = '#ff9800';
      fileIconSvg = `
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="${iconColor}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
          <line x1="9" y1="3" x2="9" y2="21"></line>
        </svg>
      `;
    }

    const item = document.createElement('div');
    item.className = 'radia-project-file-item';
    item.innerHTML = `
      <div class="file-item-info">
        <span class="file-item-icon" style="color: ${iconColor};">${fileIconSvg}</span>
        <span class="file-item-name" title="${filepath}">${filepath}</span>
      </div>
      <div class="file-item-actions">
        <button class="file-item-btn" title="View file code" onclick="scrollToBlock('${blockId}')">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
            <circle cx="12" cy="12" r="3"></circle>
          </svg>
        </button>
      </div>
    `;
    filesList.appendChild(item);
  });
  projectPanel.appendChild(filesList);

  const actionBtn = document.createElement('button');
  actionBtn.className = 'radia-project-action-btn';
  actionBtn.innerHTML = `
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="margin-right: 6px; display: inline-block; vertical-align: middle;">
      <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
      <polyline points="17 21 17 13 7 13 7 21"></polyline>
      <polyline points="7 3 7 8 15 8"></polyline>
    </svg>
    <span>Criar Projeto e Abrir na IDE</span>
  `;

  actionBtn.addEventListener('click', () => {
    const filesData = [];
    fileBlocks.forEach(block => {
      const filepath = block.getAttribute('data-filepath');
      const codeEl = block.querySelector('code');
      const content = codeEl ? codeEl.textContent : '';
      filesData.push({ path: filepath, content: content });
    });

    actionBtn.disabled = true;
    actionBtn.querySelector('span').textContent = 'Processando no Delphi...';

    postMessageToDelphi({
      action: 'create_project',
      files: filesData
    });

    setTimeout(() => {
      actionBtn.disabled = false;
      actionBtn.querySelector('span').textContent = 'Criar Projeto e Abrir na IDE';
    }, 4000);
  });

  projectPanel.appendChild(actionBtn);
  contentElement.appendChild(projectPanel);
}

function scrollToBlock(blockId) {
  const codeRegistryKey = Object.keys(_codeRegistry).find(key => key === blockId);
  if (codeRegistryKey) {
    const copyButton = document.querySelector(`button[onclick*="${blockId}"]`);
    if (copyButton) {
      const container = copyButton.closest('.code-block-container');
      if (container) {
        container.scrollIntoView({ behavior: 'smooth', block: 'center' });
        container.classList.add('highlight-flash');
        setTimeout(() => {
          container.classList.remove('highlight-flash');
        }, 1500);
      }
    }
  }
}

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

  if (data.slashCommands && Array.isArray(data.slashCommands)) {
    const baseCommands = [
      { name: '/template', desc: 'Opens the prompt templates library', shortcut: 'Ctrl+Shift+T' },
      { name: '/refactor', desc: 'Optimizes and refactors the selected code', shortcut: 'Ctrl+Shift+R' },
      { name: '/optimize', desc: 'Performs performance analysis and optimizations', shortcut: '' },
      { name: '/review', desc: 'Performs static analysis on the active unit (leaks/SOLID)', shortcut: '' }
    ];

    SLASH_COMMANDS = [...baseCommands];
    data.slashCommands.forEach(cmd => {
      const commandName = cmd.command.toLowerCase();
      SLASH_COMMANDS = SLASH_COMMANDS.filter(c => c.name.toLowerCase() !== commandName);

      let shortcut = '';
      if (cmd.command === '/explain') shortcut = 'Ctrl+Shift+E';
      else if (cmd.command === '/bugs') shortcut = 'Ctrl+Shift+B';
      else if (cmd.command === '/doc') shortcut = 'Ctrl+Shift+D';

      SLASH_COMMANDS.push({
        name: cmd.command,
        desc: cmd.description || cmd.name,
        shortcut: shortcut
      });
    });
  }

  if (btnWebLogin) {
    if (data.isWebLogin) {
      btnWebLogin.classList.remove('hidden');
    } else {
      btnWebLogin.classList.add('hidden');
    }
  }
}

function updateModelsList(models, activeModel) {
  selectModel.innerHTML = '';
  
  if (!models || models.length === 0) {
    const opt = document.createElement('option');
    opt.value = '';
    opt.textContent = 'No models available';
    selectModel.appendChild(opt);
    
    modelDropdownValue.textContent = 'No models available';
    modelOptionsList.innerHTML = '<div class="no-sessions">No models available</div>';
    return;
  }

  modelOptionsList.innerHTML = '';
  
  models.forEach(m => {
    const opt = document.createElement('option');
    opt.value = m;
    opt.textContent = m;
    if (m === activeModel) {
      opt.selected = true;
    }
    selectModel.appendChild(opt);

    const div = document.createElement('div');
    div.classList.add('custom-dropdown-option');
    if (m === activeModel) {
      div.classList.add('selected');
      modelDropdownValue.textContent = m;
    }
    div.textContent = m;
    
    div.addEventListener('click', (e) => {
      e.stopPropagation();
      
      const selectedOpt = modelOptionsList.querySelector('.custom-dropdown-option.selected');
      if (selectedOpt) selectedOpt.classList.remove('selected');
      div.classList.add('selected');
      
      modelDropdownValue.textContent = m;
      selectModel.value = m;
      modelDropdownWrapper.classList.remove('open');
      
      selectModel.dispatchEvent(new Event('change'));
    });

    modelOptionsList.appendChild(div);
  });

  if (!activeModel && models.length > 0) {
    modelDropdownValue.textContent = 'Select model...';
  }
}

function setRequestState(inProgress) {
  console.log('[DEBUG] setRequestState called with:', inProgress);
  requestInProgress = inProgress;
  if (inProgress) {
    btnSendPrompt.classList.add('stop-btn');
    btnSendPrompt.title = 'Cancel request';
    selectProvider.disabled = true;
    selectModel.disabled = true;
    modelDropdownWrapper.classList.add('disabled');
  } else {
    btnSendPrompt.classList.remove('stop-btn');
    btnSendPrompt.title = 'Send message';
    selectProvider.disabled = false;
    selectModel.disabled = false;
    modelDropdownWrapper.classList.remove('disabled');
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

    const nameEl = document.createElement('span');
    nameEl.classList.add('session-name');
    nameEl.textContent = session.name;
    
    nameEl.addEventListener('dblclick', () => startRename(item, session.id, nameEl));

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

    item.addEventListener('click', (e) => {
      if (item.classList.contains('renaming')) return;
      showTab('chat');
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

function appendGeneratorCode(text, isDone) {
  if (text === undefined || text === null) text = '';
  
  if (generatorAccumulatedCode === '' && text !== '') {
    generatorPreviewCard.classList.remove('hidden');
    generatorOutputCode.textContent = '';
  }
  
  generatorAccumulatedCode += text;
  generatorOutputCode.textContent = generatorAccumulatedCode;
  
  if (isDone) {
    try {
      Prism.highlightElement(generatorOutputCode);
    } catch (e) {
    }
    btnGenerateModel.disabled = false;
    btnGenerateModel.textContent = 'Generate Model';
  }
}

function updateMessage(text, isDone, provider, model) {
  hideTypingIndicator();
  if (text === undefined || text === null) text = '';
  
  if (!currentAssistantWrapper) {
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
      headerText += ` - ${provider} (${model})`;
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
  
  currentAssistantText = text;
  currentAssistantContent.innerHTML = marked.parse(currentAssistantText);
  Prism.highlightAllUnder(currentAssistantContent);
  chatContainer.scrollTop = chatContainer.scrollHeight;
  
  if (isDone) {
    processProjectFiles(currentAssistantContent);
    currentAssistantWrapper = null;
    currentAssistantContent  = null;
    currentAssistantText     = '';
  }
}

if (window.chrome && window.chrome.webview) {
  window.chrome.webview.addEventListener('message', event => {
    const data = event.data;
    console.log('[DEBUG] Received message from Delphi:', data);
    switch (data.action) {
      case 'add_message':           addMessage(data.role, data.text, data.provider, data.model); break;
      case 'update_message':        updateMessage(data.text, data.isDone, data.provider, data.model); break;
      case 'clear_chat':            clearChat();                                                 break;
      case 'set_theme':             setTheme(data);                                              break;
      case 'update_tokens':         updateTokens(data.text);                                     break;
      case 'show_typing':           showTypingIndicator();                                       break;
      case 'hide_typing':           hideTypingIndicator();                                       break;
      case 'append_message':        appendMessage(data.text, data.isDone, data.provider, data.model); break;
      case 'initialize_config':     initializeConfig(data);                                      break;
      case 'update_models':         updateModelsList(data.models, data.activeModel);             break;
      case 'set_request_state':     setRequestState(data.inProgress);                            break;
      case 'set_context':           setContextText(data.text);                                   break;
      case 'update_sessions':       updateSessions(data.sessions, data.activeSessionId);         break;
      case 'append_generator_code': appendGeneratorCode(data.text, data.isDone);                 break;
    }
  });
  window.chrome.webview.postMessage(JSON.stringify({ action: 'ready' }));
}
