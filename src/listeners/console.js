import { merge, addDefaults, set as timmSet } from 'timm';
import ansiColors from '../gral/ansiColors';
import k from '../gral/constants';
import recordToLines from './helpers/recordToLines';

const DEFAULT_CONFIG = {
  moduleNameLength: 20,
  relativeTime: k.IS_BROWSER,
};

// -----------------------------------------
// Listener
// -----------------------------------------
function ConsoleListener(config, { hub }) {
  this.type = 'CONSOLE';
  this.config = config;
  this.hub = hub;
  this.hubId = hub.getHubId();
  this.prevTime = 0;
}

ConsoleListener.prototype.configure = function(config) {
  this.config = merge(this.config, config);
};

// No init() or tearDown() is required

// -----------------------------------------
// Main processing function
// -----------------------------------------
ConsoleListener.prototype.process = function(msg) {
  if (msg.type !== 'RECORDS') return;
  if (msg.hubId !== this.hubId) return; // only log local records
  msg.data.forEach(record => this.processRecord(record));
};

ConsoleListener.prototype.processRecord = function(record) {
  const options = timmSet(this.config, 'prevTime', this.prevTime);
  const lines = recordToLines(record, options);
  this.prevTime = new Date(record.t);
  lines.forEach(({ text, level, fLongDelay }) => outputLog(text, level, fLongDelay));
};

// -----------------------------------------
// Helpers
// -----------------------------------------
const outputLog = function(text, level, fLongDelay) {
  const args = k.IS_BROWSER ?
    ansiColors.getBrowserConsoleArgs(text) :
    [text];
  if (fLongDelay) console.log('          ...');
  const output = (level >= 50 && level <= 60) ? 'error' : 'log';
  console[output].apply(console, args);
};

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new ConsoleListener(addDefaults(userConfig, DEFAULT_CONFIG), context);

export default create;
