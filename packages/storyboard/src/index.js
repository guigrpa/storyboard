/*!
 * Storyboard
 *
 * End-to-end, hierarchical, real-time, colorful logs and stories
 *
 * @copyright Guillermo Grau Panea 2016
 * @license MIT
 */

// Chalk is disabled by default in the browser. Override
// this default (we'll handle ANSI code conversion ourselves
// when needed)
import { chalk, mainStory, filters, hub } from 'storyboard-core';

hub.init({ mainStory });
filters.init({ mainStory });

const config = (options = {}) => {
  Object.keys(options).forEach((key) => {
    const val = options[key];
    switch (key) {
      case 'filter':
        filters.config(val);
        break;
      case 'onChangeFilter':
        filters.setOnChangeFilter(val);
        break;
      case 'bufSize':
        hub.configure({ bufSize: val });
        break;
      /* istanbul ignore next */
      default:
        break;
    }
  });
};

const gracefulExit = () => {
  mainStory.close();
  hub.removeAllListeners();
};
/* istanbul ignore next */
try {
  /* eslint-disable no-undef */
  window.addEventListener('beforeunload', gracefulExit);
  /* eslint-enable no-undef */
} catch (err) { /* ignore */ }
try {
  process.on('exit', gracefulExit);
} catch (err) { /* ignore */ }

// -------------------------------------
// API
// -------------------------------------
const { getListeners, addListener, removeListener, removeAllListeners } = hub;

export {
  mainStory,
  chalk,
  config,
  getListeners, addListener, removeListener, removeAllListeners,
};
