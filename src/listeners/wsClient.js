var DEFAULT_CONFIG, _, _extensionRxMsg, _fSocketConnected, _rxMsg, _socketInit, _socketio, _txMsg, _uploadBuf, _uploadPending, _uploadRecord, _uploaderId, create, ifExtension, k, socketio, timm;

socketio = require('socket.io-client');

timm = require('timm');

_ = require('../vendor/lodash');

k = require('../gral/constants');

ifExtension = require('./helpers/interfaceExtension');

DEFAULT_CONFIG = {
  uploadClientStories: false
};

_uploaderId = null;

// -----------------------------------------
// Extension I/O
// -----------------------------------------
_extensionRxMsg = function(msg) {
  var data, rspType, type;
  type = msg.type, data = msg.data;
  if (type === 'CONNECT_REQUEST') {
    rspType = _fSocketConnected ? 'WS_CONNECTED' : 'WS_DISCONNECTED';
    ifExtension.tx({
      type: rspType
    });
  }
  if (!(type === 'CONNECT_REQUEST' || type === 'CONNECT_RESPONSE' || type === 'GET_LOCAL_CLIENT_FILTER' || type === 'SET_LOCAL_CLIENT_FILTER')) {
    _txMsg({
      type: type,
      data: data
    });
  }
};

// -----------------------------------------
// Websocket I/O
// -----------------------------------------
_socketio = null;

_fSocketConnected = false;

_socketInit = function(config) {
  var socketConnected, socketDisconnected, url;
  if (!_socketio) {
    url = k.WS_NAMESPACE;
    if (process.env.TEST_BROWSER) {
      url = "http://localhost:8090" + k.WS_NAMESPACE;
    }
    _socketio = socketio.connect(url);
    socketConnected = function() {
      ifExtension.tx({
        type: 'WS_CONNECTED'
      });
      return _fSocketConnected = true;
    };
    socketDisconnected = function() {
      ifExtension.tx({
        type: 'WS_DISCONNECTED'
      });
      return _fSocketConnected = false;
    };
    _socketio.on('connect', socketConnected);
    _socketio.on('disconnect', socketDisconnected);
    _socketio.on('error', socketDisconnected);
    _socketio.on('MSG', _rxMsg);
  }
  return _socketio.sbConfig = config;
};

_rxMsg = function(msg) {
  if (msg.type === 'RECORDS') {
    msg.data = _.filter(msg.data, function(o) {
      return o.uploadedBy !== _uploaderId;
    });
  }
  return ifExtension.tx(msg);
};

_txMsg = function(msg) {

  /* istanbul ignore next */
  if (!_socketio) {
    console.error("Cannot send '" + msg.type + "' message to server: socket unavailable");
    return;
  }
  return _socketio.emit('MSG', msg);
};

_uploadBuf = [];

_uploadPending = function() {

  /* istanbul ignore next */
  if (!_fSocketConnected) {
    return;
  }
  _txMsg({
    type: 'UPLOAD_RECORDS',
    data: [].concat(_uploadBuf)
  });
  return _uploadBuf.length = 0;
};

_uploadRecord = function(record, config) {
  if (!config.uploadClientStories) {
    return;
  }
  record = timm.set(record, 'uploadedBy', _uploaderId);
  if (_uploadBuf.length < 2000) {
    _uploadBuf.push(record);
  }
  return _uploadPending();
};

// -----------------------------------------
// API
// -----------------------------------------
create = function(baseConfig) {
  var config, listener, ref;
  config = timm.addDefaults(baseConfig, DEFAULT_CONFIG);
  _uploaderId = (ref = config.mainStory.storyId) != null ? ref : '_SOMEBODY_';
  listener = {
    type: 'WS_CLIENT',
    init: function() {
      _socketInit(config);
      return ifExtension.rx(_extensionRxMsg);
    },
    process: function(record) {
      return _uploadRecord(record, config);
    },
    config: function(newConfig) {
      return _.extend(config, newConfig);
    }
  };
  return listener;
};

module.exports = create;
