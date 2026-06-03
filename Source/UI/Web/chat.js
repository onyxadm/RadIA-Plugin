// Configure marked to render code blocks using Prism
marked.setOptions({
  highlight: function(code, lang) {
    const language = lang || 'pascal';
    if (Prism.languages[language]) {
      return Prism.highlight(code, Prism.languages[language], language);
    }
    return code;
  }
});

// Custom renderer to add copy & apply buttons to code blocks
const renderer = new marked.Renderer();
renderer.code = function(code, lang) {
  const language = lang || 'pascal';
  const escapedCode = code.replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  const isPascal = language.toLowerCase() === 'pascal' || language.toLowerCase() === 'delphi';
  
  return `
    <div class="code-block-container">
      <div class="code-header">
        <span>${language.toUpperCase()}</span>
        <div>
          <button class="copy-btn" onclick="copyCode(this, \`${escapedCode}\`)">Copy</button>
          ${isPascal ? `<button class="apply-btn" onclick="applyCode(\`${escapedCode}\`)">Apply to Editor</button>` : ''}
        </div>
      </div>
      <pre><code class="language-${language}">${Prism.highlight(code, Prism.languages[language] || Prism.languages.pascal, language)}</code></pre>
    </div>
  `;
};
marked.use({ renderer });

const chatContainer = document.getElementById('chat-container');

function addMessage(role, text) {
  const messageDiv = document.createElement('div');
  messageDiv.classList.add('message', role);
  
  if (role === 'assistant') {
    messageDiv.innerHTML = marked.parse(text);
  } else {
    // Escape HTML for user prompts to prevent injection
    const textNode = document.createTextNode(text);
    const p = document.createElement('p');
    p.appendChild(textNode);
    messageDiv.appendChild(p);
  }
  
  chatContainer.appendChild(messageDiv);
  chatContainer.scrollTop = chatContainer.scrollHeight;
}

function clearChat() {
  chatContainer.innerHTML = '';
}

function setTheme(themeName) {
  document.body.className = '';
  document.body.classList.add(themeName + '-theme');
}

function copyCode(btn, code) {
  navigator.clipboard.writeText(code).then(() => {
    const originalText = btn.innerText;
    btn.innerText = 'Copied!';
    setTimeout(() => { btn.innerText = originalText; }, 2000);
  });
}

function applyCode(code) {
  if (window.chrome && window.chrome.webview) {
    window.chrome.webview.postMessage(JSON.stringify({
      action: 'apply_code',
      code: code
    }));
  }
}

// Listen for messages from Delphi (WebView2)
if (window.chrome && window.chrome.webview) {
  window.chrome.webview.addEventListener('message', event => {
    const data = event.data;
    if (data.action === 'add_message') {
      addMessage(data.role, data.text);
    } else if (data.action === 'clear_chat') {
      clearChat();
    } else if (data.action === 'set_theme') {
      setTheme(data.theme);
    }
  });
}
