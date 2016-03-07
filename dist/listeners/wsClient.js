(function() {
  var DEFAULT_CONFIG, _extensionDoTxMsg, _extensionInit, _extensionMsgQueue, _extensionRxMsg, _extensionTxMsg, _extensionTxPendingMsgs, _fExtensionInitialised, _fExtensionReady, _preprocessAttachments, _socket, _socketInit, _socketRxMsg, _socketTxMsg, create, socketio, timm, treeLines;

  socketio = require('socket.io-client');

  timm = require('timm');

  treeLines = require('../gral/treeLines');

  DEFAULT_CONFIG = {};

  _fExtensionInitialised = false;

  _fExtensionReady = false;

  _extensionInit = function(config) {
    if (_fExtensionInitialised) {
      return;
    }
    _fExtensionInitialised = true;
    window.addEventListener('message', function(event) {
      var data, msg, ref, source, src, type;
      source = event.source, msg = event.data;
      if (source !== window) {
        return;
      }
      ref = event.data, src = ref.src, type = ref.type, data = ref.data;
      return _extensionRxMsg(msg);
    });
    return _extensionTxMsg({
      type: 'CONNECT_REQUEST'
    });
  };

  _extensionRxMsg = function(msg) {
    var data, src, type;
    src = msg.src, type = msg.type, data = msg.data;
    if (src !== 'DT') {
      return;
    }
    console.log("[PG] RX " + src + "/" + type, data);
    switch (type) {
      case 'CONNECT_REQUEST':
      case 'CONNECT_RESPONSE':
        _fExtensionReady = true;
        if (type === 'CONNECT_REQUEST') {
          _extensionTxMsg({
            type: 'CONNECT_RESPONSE'
          });
        }
        _extensionTxPendingMsgs();
        break;
      default:
        _socketTxMsg({
          type: type,
          data: data
        });
    }
  };

  _extensionMsgQueue = [];

  _extensionTxMsg = function(msg) {
    msg.src = 'PAGE';
    if (_fExtensionReady || (msg.type === 'CONNECT_REQUEST')) {
      return _extensionDoTxMsg(msg);
    } else {
      return _extensionMsgQueue.push(msg);
    }
  };

  _extensionTxPendingMsgs = function() {
    var i, len, msg;
    if (!_fExtensionReady) {
      return;
    }
    for (i = 0, len = _extensionMsgQueue.length; i < len; i++) {
      msg = _extensionMsgQueue[i];
      _extensionDoTxMsg(msg);
    }
    return _extensionMsgQueue.length = 0;
  };

  _extensionDoTxMsg = function(msg) {
    return window.postMessage(msg, '*');
  };

  _socket = null;

  _socketInit = function(config) {
    var story;
    story = config.mainStory;
    story.info('storyboard', "Connecting to WebSocket server...");
    if (!_socket) {
      _socket = socketio.connect();
      _socket.on('connect', function() {
        return story.info('storyboard', "WebSocket connected");
      });
      _socket.on('MSG', _socketRxMsg);
    }
    return _socket.sbConfig = config;
  };

  _socketRxMsg = function(msg) {
    return _extensionTxMsg(msg);
  };

  _socketTxMsg = function(msg) {
    if (!_socket) {
      console.error("Cannot send '" + msg.type + "' message to server: socket unavailable");
      return;
    }
    return _socket.emit('MSG', msg);
  };

  _preprocessAttachments = function(record) {
    if (record.obj == null) {
      return record;
    }
    return timm.set(record, 'obj', treeLines(record.obj));
  };

  create = function(baseConfig) {
    var config, listener;
    config = timm.addDefaults(baseConfig, DEFAULT_CONFIG);
    listener = {
      type: 'WS_CLIENT',
      init: function() {
        _extensionInit(config);
        return _socketInit(config);
      },
      process: function(record) {
        return _extensionTxMsg({
          type: 'RECORDS',
          data: [_preprocessAttachments(record)]
        });
      }
    };
    return listener;
  };

  module.exports = {
    create: create
  };

}).call(this);
