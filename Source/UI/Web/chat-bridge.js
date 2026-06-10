// ============================================================
// RadIA Chat WebView bridge
// ============================================================

function postMessageToDelphi(payload) {
  if (window.chrome && window.chrome.webview) {
    window.chrome.webview.postMessage(payload);
  }
}

(function redirectConsoleToDelphi() {
  const originalLog = console.log;
  const originalError = console.error;
  const originalWarn = console.warn;

  function sendLog(type, args) {
    const text = args
      .map(arg => typeof arg === 'object' ? JSON.stringify(arg) : String(arg))
      .join(' ');

    postMessageToDelphi({ action: 'log', text: `[${type}] ${text}` });
  }

  console.log = function(...args) {
    originalLog.apply(console, args);
    sendLog('LOG', args);
  };

  console.error = function(...args) {
    originalError.apply(console, args);
    sendLog('ERROR', args);
  };

  console.warn = function(...args) {
    originalWarn.apply(console, args);
    sendLog('WARN', args);
  };

  window.addEventListener('error', (event) => {
    postMessageToDelphi({
      action: 'log',
      text: `[WINDOW_ERROR] ${event.message} at ${event.filename}:${event.lineno}:${event.colno}`
    });
  });
})();
