import { addDefaults, set as timmSet } from 'timm';

const REQUIRED_CORE_VERSION = '^3.0.0-rc.2';
const DEFAULT_CONFIG = {};

// -----------------------------------------
// Stubbable window
// -----------------------------------------
let windowCopy;
if (!process.env.TEST_BROWSER) {
  try {
    windowCopy = window;  // eslint-disable-line no-undef
  } catch (err) { /* ignore */ }
}

const setWindow = (w) => { windowCopy = w; };

// -----------------------------------------
// Listener
// -----------------------------------------
class BrowserExtensionListener {
  constructor(config, { hub, filters }) {
    this.type = 'BROWSER_EXTENSION';
    this.config = config;
    this.hub = hub;
    this.hubId = hub.getHubId();
    this.filters = filters;
    this.fExtensionReady = false;
    this.extensionRx = this.extensionRx.bind(this);
    this.bufMessages = [];
  }

  init() {
    if (windowCopy && windowCopy.addEventListener) {
      windowCopy.addEventListener('message', this.extensionRx);
      this.extensionTx(this.buildMsg('CONNECT_REQUEST', undefined, { hubId: this.hubId }));
    }
  }

  tearDown() {
    if (windowCopy && windowCopy.removeEventListener) {
      windowCopy.removeEventListener('message', this.extensionRx);
    }
  }

  getConfig() {
    return this.config;
  }

  // From the extension
  extensionRx(event) {
    const { source, data: msg } = event;
    if (source !== windowCopy) return;
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
        if (type === 'SET_LOCAL_CLIENT_FILTER') this.filters.config(data);
        this.extensionTx(this.buildMsg('LOCAL_CLIENT_FILTER', 'SUCCESS',
          { filter: this.filters.getConfig() }
        ));
        break;

      // All other messages are relayed to the hub
      default:
        this.hub.emitMsg(msg, this);
        break;
    }
  }

  extensionTx(msg0) {
    const msg = timmSet(msg0, 'src', 'PAGE');
    if (this.fExtensionReady || msg.type === 'CONNECT_REQUEST') {
      this.doExtensionTx(msg);
    } else {
      this.bufMessages.push(msg);
    }
  }

  extensionTxPending() {
    if (!this.fExtensionReady) return;
    this.bufMessages.forEach((msg) => this.doExtensionTx(msg));
    this.bufMessages.length = 0;
  }

  doExtensionTx(msg) {
    if (!windowCopy) return;
    windowCopy.postMessage(msg, '*');
  }

  buildMsg(type, result, data) {
    return { src: 'PAGE', hubId: this.hubId, type, result, data };
  }

  // -----------------------------------------
  // Hub interface
  // -----------------------------------------
  process(msg) {
    this.extensionTx(msg);
  }
}

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new BrowserExtensionListener(addDefaults(userConfig, DEFAULT_CONFIG), context);
create.requiredCoreVersion = REQUIRED_CORE_VERSION;

export default create;

export {
  // Just for unit tests
  setWindow as _setWindow,
};
