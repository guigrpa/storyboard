/* eslint-env browser */

let bgConnection = null;

// Connect to the actual page via DOM messaging
window.addEventListener('message', (event) => {
  // We only accept messages from ourselves
  if (event.source !== window) return;

  // Extract the message contents from the event, and
  // discard messages with wrong `src`
  const { data: { src, type } } = event;
  if (src !== 'PAGE') return;
  // console.log(`[CS] RX ${src}/${type}`, data)

  // A `CONNECT_REQUEST` message causes a bidirectional connection to be established
  // with the background page and is then relayed
  if (type === 'CONNECT_REQUEST') {
    bgConnection = chrome.runtime.connect();

    // All messages from the background page are just relayed to the actual page
    bgConnection.onMessage.addListener((msg) => {
      window.postMessage(msg, '*');
    });
  }

  // All other messages from the page are just relayed to the background page
  if (bgConnection != null) bgConnection.postMessage(event.data);
});
