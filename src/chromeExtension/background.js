// Connections hub. Each key corresponds is a tab ID, and the associated value
// is an object with (eventually) `DT` (devtools) and `CS` (content-script) keys,
// each of them holding the corresponding connection.

/* eslint-disable no-console */

const curConnections = {};  // map of tabId to DT + CS connections

console.log('[BG] Launched');

const logConnections = () => {
  let title = '[BG] Current connections:';
  if (!Object.keys(curConnections).length) title += ' none';
  console.log(title);
  Object.keys(curConnections).forEach((tabId) => {
    const { DT, CS } = curConnections[tabId];
    console.log(`- ${tabId}: ` +
      `DevTools (DT): ${DT != null ? 'YES' : 'NO'}, ` +
      `content script (CS): ${CS != null ? 'YES' : 'NO'}`);
  });
};

chrome.runtime.onConnect.addListener((port) => {
  const senderTabId = port.sender.tab != null ? port.sender.tab.id : undefined;
  console.log(`[BG] Connected: ${port.sender.url} [tabId: ${senderTabId}]`);

  // Message listener
  const listener = (msg) => {
    const { src, dst, type, data } = msg;
    if (process.env.NODE_ENV !== 'production') {
      console.log(`[BG] RX ${src}/${type}`, data);
    }

    // Determine the related tab ID
    let tabId;
    if (src === 'DT') tabId = dst;
    else if (src === 'PAGE') tabId = port.sender.tab.id;

    // Connection initialisation
    if (type === 'CONNECT_REQUEST') {
      if (tabId == null) {
        console.error('[BG] Could not determine the tab ID associated to the connection');
        return;
      }
      if (curConnections[tabId] == null) curConnections[tabId] = {};
      const cxType = src === 'PAGE' ? 'CS' : 'DT';
      curConnections[tabId][cxType] = port;
      logConnections();
    }

    // Message relays: `PAGE` <-> `DT`
    const connections = curConnections[tabId];
    if (src === 'PAGE' && connections.DT != null) connections.DT.postMessage(msg);
    if (src === 'DT' && connections.CS != null) connections.CS.postMessage(msg);
  };

  port.onMessage.addListener(listener);

  // Clean up when connections are closed
  port.onDisconnect.addListener(() => {
    port.onMessage.removeListener(listener);
    Object.keys(curConnections).forEach((tabId) => {
      const connections = curConnections[tabId];
      Object.keys(connections).forEach((cxType) => {
        const connection = connections[cxType];
        if (connection === port) {
          delete connections[cxType];

          // Tell the DT for a given page that the user went away
          if (connections.DT != null) {
            connections.DT.postMessage({
              src: 'PAGE',
              type: 'CX_DISCONNECTED',
            });
          }

          // Purge entry in `curConnections`, if needed
          if (connections.DT == null && connections.CS == null) {
            delete curConnections[tabId];
          }
        }
      });
    });
    logConnections();
  });
});

logConnections();
