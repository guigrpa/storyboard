let _window;
const listeners = [];
let fExtensionReady = false;

if (!process.env.TEST_BROWSER) {
  try {
    _window = window;
  } catch (err) { /* ignore */ }
}

// For unit tests
const _setWindow = w => {
  _window = w;
  init();
};

// -------------------------------------
// Main
// -------------------------------------
const tx = msg => txMsg(msg);
const rx = listener => { listeners.push(listener); };

// -------------------------------------
// Internal
// -------------------------------------
const init = () => {
  if (_window == null) return;
  _window.addEventListener('message', event => {
    console.log(event)
    const { source, data: msg } = event;
    if (source !== _window) return;
    rxMsg(msg);
  });
  txMsg({ type: 'CONNECT_REQUEST' });
};

const rxMsg = msg => {
  const { src, type, data } = msg;
  if (src !== 'DT') return;
  // console.log(`[PG] RX ${src}/${type}`, data);

  if ((type === 'CONNECT_REQUEST') || (type === 'CONNECT_RESPONSE')) {
    fExtensionReady = true;
    if (type === 'CONNECT_REQUEST') {
      txMsg({ type: 'CONNECT_RESPONSE' });
    }
    txPendingMsgs();
  }
  listeners.forEach(listener => listener({ type, data }));
};

const msgQueue = [];
const txMsg = msg => {
  msg.src = 'PAGE';
  if (fExtensionReady || msg.type === 'CONNECT_REQUEST') {
    doTxMsg(msg);
  } else {
    msgQueue.push(msg);
  }
};
const txPendingMsgs = () => {
  if (!fExtensionReady) return;
  msgQueue.forEach(doTxMsg);
  msgQueue.length = 0;
};
const doTxMsg = msg => {
  if (_window != null) _window.postMessage(msg, '*');
};

// -------------------------------------
// Public API
// -------------------------------------
// May do nothing (browser tests). In this case, `setWindow`
// will really do the initialisation
init();

module.exports = {
  tx, rx,

  // Just for unit tests
  _setWindow,
};
