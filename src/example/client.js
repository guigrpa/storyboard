require('babel-polyfill');    // for IE
require('isomorphic-fetch');  // for IE

// Here you'd write 'storyboard' or 'storyboard/lib/listeners/xxx':
import Promise from 'bluebird';
import { mainStory, chalk, addListener } from '../storyboard';
import consoleListener from '../listeners/console';
import browserExtensionListener from '../listeners/browserExtension';
import wsClientListener from '../listeners/wsClient';
addListener(consoleListener);
addListener(browserExtensionListener);
addListener(wsClientListener);

mainStory.info('client', 'Running client...');
mainStory.warn('client', 'Example warning');
mainStory.error('client', 'Example error', { attach: new Error('hi') });

const nodeButton = document.getElementById('refresh');
const nodeItems = document.getElementById('items');
nodeButton.addEventListener('click', () => refresh('Click on Refresh'));

const refresh = storyTitle => {
  const seq = Math.floor(Math.random() * 100);
  const story = mainStory.child({
    src: 'client',
    title: `${storyTitle} (seq=${seq})`,
    // level: 'trace',
  });
  story.info('serverInterface', 'Fetching animals from server...');
  nodeItems.innerHTML = 'Fetching...';
  return Promise.resolve()
  .then(() => fetch(`/animals?seq=${seq}`, {
    method: 'post',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ storyId: story.storyId }),
  }))
  .then(response => response.json())
  .then(items => {
    if (Array.isArray(items)) {
      story.info('serverInterface',
        `Fetched animals from server: ${chalk.cyan.bold(items.length)}`,
        { attach: items });
      nodeItems.innerHTML = items.map(o => `<li>${o}</li>`).join('');
    }
  })
  // .delay(7000)
  // .then(() => story.warn('A revelation!'))
  .finally(() => story.close());
};

refresh('Initial fetch');

setInterval(() => mainStory.debug('Repeated message'), 5000);

// Uncomment the following block to mount the developer tools
// in the main page (for faster development)
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
