import { merge, addDefaults, set as timmSet } from 'timm';
import ansiColors from '../gral/ansiColors';
import k from '../gral/constants';
import recordToLines from './helpers/recordToLines';

const DEFAULT_CONFIG = {
  moduleNameLength: 20,
  relativeTime: k.IS_BROWSER,
  useStderr: false,
};

// -----------------------------------------
// Listener
// -----------------------------------------
class ConsoleListener {
  constructor(config, { hub }) {
    this.type = 'CONSOLE';
    this.config = config;
    this.hub = hub;
    this.hubId = hub.getHubId();
    this.prevTime = 0;
  }

  configure(config) {
    this.config = merge(this.config, config);
  }

  getConfig() {
    return this.config;
  }

  // No init() or tearDown() is required

  // -----------------------------------------
  // Main processing function
  // -----------------------------------------
  process(msg) {
    if (msg.type !== 'RECORDS') return;
    if (msg.hubId !== this.hubId) return; // only log local records
    msg.data.forEach(record => this.processRecord(record));
  }

  processRecord(record) {
    const options = timmSet(this.config, 'prevTime', this.prevTime);
    const lines = recordToLines(record, options);
    this.prevTime = new Date(record.t);
    lines.forEach(({ text, level, fLongDelay }) =>
      this.outputLog(text, level, fLongDelay)
    );
  }

  // -----------------------------------------
  // Helpers
  // -----------------------------------------
  /* eslint-disable no-console */
  outputLog(text, level, fLongDelay) {
    const args = k.IS_BROWSER ?
      ansiColors.getBrowserConsoleArgs(text) :
      [text];
    if (fLongDelay) console.log('          ...');
    if (k.IS_BROWSER) {
      switch (level) {
        case 40:
          console.warn.apply(console, args);
          break;
        case 50:
        case 60:
          console.error.apply(console, args);
          break;
        default:
          console.log.apply(console, args);
          break;
      }
    } else {
      if (this.config.useStderr && level >= 50) {
        console.error.apply(console, args);
      } else {
        console.log.apply(console, args);
      }
    }
  }
  /* eslint-enable no-console */
}

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new ConsoleListener(addDefaults(userConfig, DEFAULT_CONFIG), context);

export default create;
