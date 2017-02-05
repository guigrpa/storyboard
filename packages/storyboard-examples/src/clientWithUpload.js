/* eslint-env browser */

// Here you'd write 'storyboard' or 'storyboard/lib/listeners/xxx':
import { mainStory, chalk, addListener } from '../storyboard';
import browserExtensionListener from '../listeners/browserExtension';
import wsClientListener from '../listeners/wsClient';

require('babel-polyfill');    // for IE
require('isomorphic-fetch');  // for IE

addListener(browserExtensionListener);
addListener(wsClientListener, { uploadClientStories: true });

mainStory.info('client', 'Running client...');

const nodeButton = document.getElementById('refresh');
const nodeItems = document.getElementById('items');
nodeButton.addEventListener('click', () => refresh('Click on Refresh'));

const refresh = (storyTitle) => {
  const seq = Math.floor(Math.random() * 100);
  const story = mainStory.child({ src: 'client', title: `${storyTitle} (seq=${seq})` });
  story.info('serverInterface', 'Fetching animals from server...');
  nodeItems.innerHTML = 'Fetching...';
  return fetch(`/animals?seq=${seq}`, {
    method: 'post',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ storyId: story.storyId }),
  })
  .then((response) => response.json())
  .then((items) => {
    if (Array.isArray(items)) {
      story.info('serverInterface',
        `Fetched animals from server: ${chalk.cyan.bold(items.length)}`,
        { attach: items });
      nodeItems.innerHTML = items.map((o) => `<li>${o}</li>`).join('');
    }
    story.close();
  });
};

refresh('Initial fetch');

setInterval(() => mainStory.debug('Repeated message'), 5000);
