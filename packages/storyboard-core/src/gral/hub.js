import uuid from 'uuid';
import { merge } from 'timm';
import chalk from 'chalk';
import semver from 'semver';
import * as filters from './filters';
import * as ansiColors from './ansiColors';
import recordToLines from './recordToLines';

const coreVersion = require('../../package.json').version;

const DEFAULT_CONFIG = {
  bufMsgSize: 1000,
  bufSize: 1000,
};

// -------------------------------------
// Init and config
// -------------------------------------
let mainStory = null;
let config = DEFAULT_CONFIG;
const hubId = uuid.v4();

const init = (deps, options) => {
  mainStory = deps.mainStory;
  /* istanbul ignore if */
  if (!mainStory) throw new Error('MISSING_DEPENDENCIES');
  /* istanbul ignore if */
  if (options != null) configure(options);
};

const getHubId = () => hubId;
const configure = (options) => { config = merge(config, options); };

// -------------------------------------
// Managing listeners
// -------------------------------------
let listeners = [];

const getListeners = () => listeners;

const addListener = (listenerCreate, userConfig = {}) => {
  const { requiredCoreVersion } = listenerCreate;
  if (requiredCoreVersion && !semver.satisfies(coreVersion, requiredCoreVersion)) {
    /* eslint-disable no-console */
    console.error(`Incompatible listener (requires storyboard-core ${requiredCoreVersion}, current ${coreVersion})`);
    /* eslint-enable no-console */
    return null;
  }
  const listener = listenerCreate(userConfig, {
    mainStory,
    filters,
    ansiColors,
    recordToLines,
    chalk,
    hub: hubApiForListeners,
  });
  listeners.push(listener);
  if (listener.init) listener.init();
  getBufferedMessages().forEach((msg) => listener.process(msg));
  return listener;
};

const removeListener = (listener) => {
  if (listener.tearDown) listener.tearDown();
  listeners = listeners.filter((o) => o !== listener);
};

const removeAllListeners = () => {
  listeners.forEach(removeListener);
  listeners = [];
};

// -------------------------------------
// Message buffer
// -------------------------------------
let bufMessages = [];
let bufRecords = [];

const addToMsgBuffers = (msg) => {
  bufMessages.push(msg);
  const { bufMsgSize } = config;
  if (bufMessages.length > bufMsgSize) bufMessages = bufMessages.slice(-bufMsgSize);
  if (msg.type === 'RECORDS') {
    const { data: records } = msg;
    const { bufSize } = config;
    bufRecords = bufRecords.concat(records);
    if (bufRecords.length > bufSize) bufRecords = bufRecords.slice(-bufSize);
  }
};

const getBufferedMessages = () => bufMessages;
const getBufferedRecords = () => bufRecords;

// -------------------------------------
// Emitting messages
// -------------------------------------
const emitMsgWithFields = (src, type, data, srcListener) => {
  emitMsg({ src, hubId, type, data }, srcListener);
};

// Add message to buffer and broadcast it (to all but the sender)
const emitMsg = (msg, srcListener) => {
  addToMsgBuffers(msg);
  listeners.forEach((listener) => {
    if (listener === srcListener) return;
    listener.process(msg);
  });
};

// -------------------------------------
// APIs
// -------------------------------------
const hubApiForListeners = {
  getHubId,
  emitMsgWithFields, emitMsg,
  getBufferedMessages,
  getBufferedRecords,
};

export {
  init,
  getHubId,
  configure,
  getListeners, addListener, removeListener, removeAllListeners,
  emitMsgWithFields, emitMsg,
  getBufferedMessages,
  getBufferedRecords,
};
