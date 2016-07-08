import uuid from 'node-uuid';
import { merge } from 'timm';

const DEFAULT_CONFIG = {
  bufSize: 1000
};

let listeners = [];
let bufRecords = [];
let mainStory = null;

// -------------------------------------
// Init and config
// -------------------------------------
let config = DEFAULT_CONFIG;
const hubId = uuid.v4();

const init = (deps, options) => {
  mainStory = deps.mainStory;
  /* istanbul ignore if */
  if (!(mainStory != null)) {
    throw new Error('MISSING_DEPENDENCIES');
  }
  /* istanbul ignore if */
  if (options != null) config(options);
};

const getHubId = () => hubId;
const configure = options => { config = merge(config, options); };

// -------------------------------------
// Managing listeners
// -------------------------------------
const getListeners = () => listeners;

const addListener = (listenerCreate, config = {}) => {
  const listener = listenerCreate(config, { mainStory, hub: hubApiForListeners });
  listeners.push(listener);
  if (listener.init) listener.init();
  bufRecords.forEach(record => listener.process(record));
  return listener;
};

const removeListener = listener => {
  if (listener.tearDown) listener.tearDown();
  listeners = listeners.filter(o => o !== listener);
};

const removeAllListeners = () => {
  listeners.forEach(removeListener);
  listeners = [];
};

// -------------------------------------
// Emitting messages
// -------------------------------------
const emit = record => {
  bufRecords.push(record);
  const bufLen = config.bufSize;
  if (bufRecords.length > bufLen) bufRecords.splice(0, bufRecords.length - bufLen);
  listeners.forEach(listener => listener.process(record));
};

const emitMsgWithFields = (src, type, data) => emitMsg({ src, hubId, type, data });
const emitMsg = (msg, srcListener) => {
  if (msg.type === 'RECORDS') {
    bufRecords = bufRecords.concat(msg.data);
    const { bufSize } = config;
    if (bufRecords.length > bufSize) bufRecords = bufRecords.slice(-bufSize);
  }
  listeners.forEach(listener => {
    if (listener === srcListener) return;
    listener.rxMsgFromHub(msg);
  });
};

const getBufferedRecords = () => [].concat(bufRecords);

// -------------------------------------
// APIs
// -------------------------------------
const hubApiForListeners = {
  emit, emitMsgWithFields, emitMsg,
  getBufferedRecords,
  getHubId,
};

export {
  init,
  getHubId,
  configure,
  getListeners, addListener, removeListener, removeAllListeners,
  emit, emitMsgWithFields, emitMsg,
  getBufferedRecords,
};
