/* eslint-env browser */

import { mainStory, chalk, addListener } from 'storyboard';
import consoleListener from 'storyboard-listener-console';
import browserExtensionListener from 'storyboard-listener-browser-extension';
import wsClientListener from 'storyboard-listener-ws-client';

require('babel-polyfill');    // for IE
require('isomorphic-fetch');  // for IE

addListener(consoleListener);
addListener(browserExtensionListener);
addListener(wsClientListener);

mainStory.info('client', 'Running client...');
mainStory.warn('client', 'Example warning');
mainStory.error('client', 'Example error', { attach: new Error('hi') });

const nodeButton = document.getElementById('refresh');
const nodeItems = document.getElementById('items');
nodeButton.addEventListener('click', () => refresh('Click on Refresh'));

const refresh = async (storyTitle) => {
  const seq = Math.floor(Math.random() * 100);
  const story = mainStory.child({
    src: 'client',
    title: `${storyTitle} (seq=${seq})`,
    // level: 'trace',
  });
  story.info('serverInterface', 'Fetching animals from server...');
  nodeItems.innerHTML = 'Fetching...';
  try {
    const response = await fetch(`/animals?seq=${seq}`, {
      method: 'post',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ storyId: story.storyId }),
    });
    const items = await response.json();
    if (Array.isArray(items)) {
      story.info('serverInterface',
        `Fetched animals from server: ${chalk.cyan.bold(items.length)}`,
        { attach: items });
      nodeItems.innerHTML = items.map((o) => `<li>${o}</li>`).join('');
    }
  } finally {
    story.close();
  }
  // .delay(7000)
  // .then(() => story.warn('A revelation!'))
};

refresh('Initial fetch');

setInterval(() => mainStory.debug('Repeated message'), 5000);

// Uncomment the following block to mount the developer tools
// in the main page (for faster development)
// TO BE UPDATED (pre-3.0)
/*
const devToolsApp = require('../chromeExtension/devToolsApp');

// Emulate the content script for page -> devtools messages
window.addEventListener('message', event => {
  const { source, data: msg } = event;
  if (source !== window) return;
  if (msg.src !== 'PAGE') return;
  devToolsApp.processMsg(msg);
});

// Emulate the content script for devtools -> page messages
devToolsApp.init({ sendMsg: msg => window.postMessage(msg, '*') });
*/
