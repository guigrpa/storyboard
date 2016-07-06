import uuid from 'node-uuid';
import { merge } from 'timm';

const DEFAULT_CONFIG = {
  bufSize: 1000
};

let plugins = [];
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
// Managing plugins
// -------------------------------------
const getPlugins = () => plugins;

const addPlugin = (pluginCreate, config) => {
  const pluginConfig = merge({ mainStory, hub: hubApiForPlugins }, config);
  const plugin = pluginCreate(pluginConfig);
  plugins.push(plugin);
  if (plugin.init) plugin.init();
  bufRecords.forEach(record => plugin.process(record));
  return plugin;
};

const removePlugin = plugin => {
  if (plugin.tearDown) plugin.tearDown();
  plugins = plugins.filter(o => o !== plugin);
};

const removeAllPlugins = () => {
  plugins.forEach(removePlugin);
  plugins = [];
};

// -------------------------------------
// Emitting messages
// -------------------------------------
const emit = record => {
  bufRecords.push(record);
  const bufLen = config.bufSize;
  if (bufRecords.length > bufLen) bufRecords.splice(0, bufRecords.length - bufLen);
  plugins.forEach(plugin => plugin.process(record));
};

const emitMsgWithFields = (src, type, data) => emitMsg({ src, hubId, type, data });
const emitMsg = (msg, srcPlugin) => {
  if (msg.type === 'RECORDS') {
    bufRecords = bufRecords.concat(msg.data);
    const { bufSize } = config;
    if (bufRecords.length > bufSize) bufRecords = bufRecords.slice(-bufSize);
  }
  plugins.forEach(plugin => {
    if (plugin === srcPlugin) return;
    plugin.rxMsgFromHub(msg);
  });
};

const getBufferedRecords = () => [].concat(bufRecords);

// -------------------------------------
// APIs
// -------------------------------------
const hubApiForPlugins = {
  emit, emitMsgWithFields, emitMsg,
  getBufferedRecords,
  getHubId,
};

export {
  init,
  getHubId,
  configure,
  getPlugins, addPlugin, removePlugin, removeAllPlugins,
  emit, emitMsgWithFields, emitMsg,
  getBufferedRecords,
};
