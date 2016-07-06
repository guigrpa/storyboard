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
function ConsoleListener(config) {
  this.type = 'CONSOLE';
  this.config = config;
  this.prevTime = 0;
}

ConsoleListener.prototype.process = function(record) {
  // Don't show client logs uploaded to the server
  if (!k.IS_BROWSER && record.uploadedBy != null) return;
  const options = timmSet(this.config, 'prevTime', this.prevTime);
  const lines = recordToLines(record, options);
  this.prevTime = new Date(record.t);
  lines.forEach(({ text, level, fLongDelay }) => outputLog(text, level, fLongDelay));
};

ConsoleListener.prototype.configure = function(config) {
  this.config = merge(this.config, config);
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
const create = config => new ConsoleListener(addDefaults(config, DEFAULT_CONFIG));

export default create;
