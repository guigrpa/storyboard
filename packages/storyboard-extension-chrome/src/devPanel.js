import { merge } from 'timm';
import chalk from 'chalk';

chalk.enabled = true;

require('babel-polyfill');  /* from root packages */ // eslint-disable-line
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
