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
import chalk from 'chalk';
import mainStory from './gral/stories';
import filters from './gral/filters';
import hub, {
  addListener,
  removeListener, removeAllListeners,
  getListeners,
} from './gral/hub'

chalk.enabled = true;

hub.init({ mainStory });

const config = (options = {}) => {
  Object.keys(options).forEach(key => {
    const val = options[key];
    switch (key) {
      case 'filter':
        filters.config(val);
        break;
      case 'bufSize':
        hub.config({ bufSize: val });
        break;
      default:
        break;
    }
  })
};

export {
  mainStory,
  chalk,
  config,
  addListener,
  removeListener, removeAllListeners,
  getListeners,
};
