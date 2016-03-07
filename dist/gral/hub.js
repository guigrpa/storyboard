(function() {
  var DEFAULT_CONFIG, _buf, _config, _listeners, addListener, bufSize, config, emit, getBufferedRecords, getListeners, hub, init, mainStory, removeAllListeners, timm;

  timm = require('timm');

  DEFAULT_CONFIG = bufSize = 1000;

  _listeners = [];

  _buf = [];

  _config = DEFAULT_CONFIG;

  mainStory = null;

  init = function(deps, options) {
    mainStory = deps.mainStory;

    /* !pragma coverage-skip-next */
    if (!(mainStory != null)) {
      throw new Error('MISSING_DEPENDENCIES');
    }
    if (options != null) {
      return config(options);
    }
  };

  config = function(options) {
    return _config = timm.merge(_config, options);
  };

  addListener = function(listenerFactory, config) {
    var listener, listenerConfig;
    listenerConfig = timm.merge({
      mainStory: mainStory,
      hub: hub
    }, config);
    listener = listenerFactory.create(listenerConfig);
    _listeners.push(listener);
    return typeof listener.init === "function" ? listener.init() : void 0;
  };

  getListeners = function() {
    return _listeners;
  };

  removeAllListeners = function() {
    return _listeners = [];
  };

  emit = function(record) {
    var bufLen, i, len, listener, results;
    _buf.push(record);
    bufLen = _config.bufSize;
    if (_buf.length > bufLen) {
      _buf.splice(0, _buf.length - bufLen);
    }
    results = [];
    for (i = 0, len = _listeners.length; i < len; i++) {
      listener = _listeners[i];
      results.push(listener.process(record));
    }
    return results;
  };

  getBufferedRecords = function() {
    return [].concat(_buf);
  };

  module.exports = hub = {
    init: init,
    config: config,
    addListener: addListener,
    getListeners: getListeners,
    removeAllListeners: removeAllListeners,
    emit: emit,
    getBufferedRecords: getBufferedRecords
  };

}).call(this);
