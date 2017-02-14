import { merge, addDefaults, set as timmSet } from 'timm';

const REQUIRED_CORE_VERSION = '^3.0.0-rc.2';

/* eslint-disable no-undef */
const IS_BROWSER = (typeof window !== 'undefined' && window !== null) ||
  (process.env.TEST_BROWSER != null);
/* eslint-enable no-undef */

const DEFAULT_CONFIG = {
  moduleNameLength: 20,
  relativeTime: IS_BROWSER,
  colors: true,
  useStderr: false,
};

// -----------------------------------------
// Listener
// -----------------------------------------
class ConsoleListener {
  constructor(config, { hub, ansiColors, recordToLines }) {
    this.type = 'CONSOLE';
    this.config = config;
    this.hub = hub;
    this.hubId = hub.getHubId();
    this.ansiColors = ansiColors;
    this.recordToLines = recordToLines;
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
    msg.data.forEach((record) => this.processRecord(record));
  }

  processRecord(record) {
    const options = timmSet(this.config, 'prevTime', this.prevTime);
    const lines = this.recordToLines(record, options);
    this.prevTime = new Date(record.t);
    lines.forEach(({ text, level, fLongDelay }) =>
      this.outputLog(text, level, fLongDelay)
    );
  }

  // -----------------------------------------
  // Helpers
  // -----------------------------------------
  /* eslint-disable no-console, prefer-spread */
  outputLog(text, level, fLongDelay) {
    const args = IS_BROWSER ? this.ansiColors.getBrowserConsoleArgs(text) : [text];
    if (fLongDelay) console.log('          ...');
    if (IS_BROWSER) {
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
      /* eslint-disable no-lonely-if */
      if (this.config.useStderr && level >= 50) {
        console.error.apply(console, args);
      } else {
        console.log.apply(console, args);
      }
      /* eslint-enable no-lonely-if */
    }
  }
  /* eslint-enable no-console */
}

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new ConsoleListener(addDefaults(userConfig, DEFAULT_CONFIG), context);
create.requiredCoreVersion = REQUIRED_CORE_VERSION;

export default create;
