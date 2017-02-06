/* eslint-env browser */

import { mainStory, chalk, addListener } from 'storyboard';
import browserExtensionListener from 'storyboard-listener-browser-extension';
import wsClientListener from 'storyboard-listener-ws-client';

require('babel-polyfill');  /* from root packages */ // eslint-disable-line
require('isomorphic-fetch');  // for IE

addListener(browserExtensionListener);
addListener(wsClientListener, { uploadClientStories: true });

mainStory.info('client', 'Running client...');

const nodeButton = document.getElementById('refresh');
const nodeItems = document.getElementById('items');
nodeButton.addEventListener('click', () => refresh('Click on Refresh'));

const refresh = async (storyTitle) => {
  const seq = Math.floor(Math.random() * 100);
  const story = mainStory.child({ src: 'client', title: `${storyTitle} (seq=${seq})` });
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
};

refresh('Initial fetch');

setInterval(() => mainStory.debug('Repeated message'), 5000);
