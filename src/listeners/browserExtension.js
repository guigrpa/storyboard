import { merge, addDefaults, set as timmSet } from 'timm';
import filters from '../gral/filters';

const DEFAULT_CONFIG = {};

// -----------------------------------------
// Stubbable window
// -----------------------------------------
let _window;
if (!process.env.TEST_BROWSER) {
  try {
    _window = window;
  } catch (err) { /* ignore */ }
}

const _setWindow = w => { _window = w; };

// -----------------------------------------
// Listener
// -----------------------------------------
function BrowserExtensionListener(config, { hub }) {
  this.type = 'BROWSER_EXTENSION';
  this.config = config;
  this.hub = hub;
  this.hubId = hub.getHubId();
  this.fExtensionReady = false;
  this.extensionRx = this.extensionRx.bind(this);
  this.bufMessages = [];
}

BrowserExtensionListener.prototype.init = function() {
  if (_window && _window.addEventListener) {
    _window.addEventListener('message', this.extensionRx);
    this.extensionTx(this.buildMsg('CONNECT_REQUEST', undefined, { hubId: this.hubId }));
  }
};

BrowserExtensionListener.prototype.tearDown = function() {
  if (_window && _window.removeEventListener) {
    _window.removeEventListener('message', this.extensionRx);
  }
};

// From the extension
BrowserExtensionListener.prototype.extensionRx = function(event) {
  const { source, data: msg } = event;
  if (source !== _window) return;
  const { src, type, data } = msg;
  if (src !== 'DT') return;
  // console.log(`[PG] RX ${src}/${type}`, data);
  switch (type) {

    // CONNECT_XX are replied here, but are also relayed to the hub
    case 'CONNECT_REQUEST':
    case 'CONNECT_RESPONSE':
      this.fExtensionReady = true;
      if (type === 'CONNECT_REQUEST') {
        this.extensionTx(this.buildMsg('CONNECT_RESPONSE', 'SUCCESS', { hubId: this.hubId }));
      }
      this.extensionTxPending();
      this.hub.emitMsg(msg, this);
      break;

    // GET|SET_LOCAL_CLIENT_FILTER are handled here
    case 'GET_LOCAL_CLIENT_FILTER':
    case 'SET_LOCAL_CLIENT_FILTER':
      if (type === 'SET_LOCAL_CLIENT_FILTER') filters.config(data);
      this.extensionTx(this.buildMsg('LOCAL_CLIENT_FILTER', 'SUCCESS',
        { filter: filters.getConfig() }
      ));
      break;

    // All other messages are relayed to the hub
    default:
      this.hub.emitMsg(msg, this);
      break;
  }
};

BrowserExtensionListener.prototype.extensionTx = function(msg0) {
  const msg = timmSet(msg0, 'src', 'PAGE');
  if (this.fExtensionReady || msg.type === 'CONNECT_REQUEST') {
    this.doExtensionTx(msg);
  } else {
    this.bufMessages.push(msg);
  }
};

BrowserExtensionListener.prototype.extensionTxPending = function() {
  if (!this.fExtensionReady) return;
  this.bufMessages.forEach(msg => this.doExtensionTx(msg));
  this.bufMessages.length = 0;
};

BrowserExtensionListener.prototype.doExtensionTx = function(msg) {
  if (!_window) return;
  _window.postMessage(msg, '*');
};

BrowserExtensionListener.prototype.buildMsg = function(type, result, data) {
  return { src: 'PAGE', hubId: this.hubId, type, result, data };
};

// -----------------------------------------
// Hub interface
// -----------------------------------------
BrowserExtensionListener.prototype.process = function(msg) {
  this.extensionTx(msg);
};

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new BrowserExtensionListener(addDefaults(userConfig, DEFAULT_CONFIG), context);

export default create;

// Just for unit tests
export { _setWindow };
