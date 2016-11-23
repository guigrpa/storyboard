import { merge } from 'timm';

require('babel-polyfill');
const { init, processMsg } = require('./devToolsApp');  // eslint-disable-line import/no-unresolved, import/extensions

// Initialise connection to background page. All incoming
// messages are relayed to the devtools application
const { tabId } = chrome.devtools.inspectedWindow;
const bgConnection = chrome.runtime.connect();
bgConnection.onMessage.addListener(processMsg);

// Initialise application
init({
  sendMsg: (msg) => bgConnection.postMessage(merge(msg, { dst: tabId })),
});
