import { merge, addDefaults, set as timmSet } from 'timm';
import filters from '../gral/filters';
import ifExtension from './helpers/interfaceExtension';

const DEFAULT_CONFIG = {};

// -----------------------------------------
// Listener
// -----------------------------------------
function BrowserExtensionListener(config, { hub }) {
  this.type = 'BROWSER_EXTENSION';
  this.config = config;
  this.hub = hub;
  this.hubId = hub.getHubId();
}

BrowserExtensionListener.prototype.init = function() {
  ifExtension.rx(msg => this.extensionRx(msg));
}

// From the hub
BrowserExtensionListener.prototype.process = function(msg) {
  ifExtension.tx(msg);
};

// From the extension
BrowserExtensionListener.prototype.extensionRx = function(msg) {
  const { type, data } = msg;
  switch (type) {
    case 'GET_LOCAL_CLIENT_FILTER':
    case 'SET_LOCAL_CLIENT_FILTER':
      if (type === 'SET_LOCAL_CLIENT_FILTER') filters.config(data);
      ifExtension.tx({
        type: 'LOCAL_CLIENT_FILTER',
        result: 'SUCCESS',
        data: { filter: filters.getConfig() },
      });
      break;
    default:
      this.hub.emitMsg(msg, this);
      break;
  }
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
  new BrowserExtensionListener(addDefaults(userConfig, DEFAULT_CONFIG), context);

export default create;
