(function() {
  var DEFAULT_CONFIG, LOG_SRC, Promise, _, _broadcastBuf, _enqueueRecord, _getBufferedRecords, _ioServerAdaptor, _ioStandalone, _preprocessAttachments, _process, _socketBroadcast, _socketInit, _socketOnConnection, _socketRxMsg, _socketTxMsg, chalk, create, express, http, path, socketio, timm, treeLines;

  _ = require('../vendor/lodash');

  path = require('path');

  http = require('http');

  express = require('express');

  socketio = require('socket.io');

  Promise = require('bluebird');

  chalk = require('chalk');

  timm = require('timm');

  treeLines = require('../gral/treeLines');

  DEFAULT_CONFIG = {
    port: 8090,
    throttle: 200,
    authenticate: null
  };

  LOG_SRC = 'storyboard';

  _ioStandalone = null;

  _ioServerAdaptor = null;

  _socketInit = function(config) {
    var expressApp, httpServer, port, port2, story;
    if (_ioStandalone) {
      return;
    }
    port = config.port, story = config.mainStory;
    expressApp = express();
    expressApp.use(express["static"](path.join(__dirname, '../../serverLogsApp')));
    httpServer = http.createServer(expressApp);
    _ioStandalone = socketio(httpServer);
    _ioStandalone.on('connection', function(socket) {
      return _socketOnConnection(socket, config);
    });
    httpServer.listen(port);
    story.info(LOG_SRC, "Server logs available on port " + (chalk.cyan(port)));
    if (config.httpServer) {
      _ioServerAdaptor = socketio(config.httpServer);
      _ioServerAdaptor.on('connection', function(socket) {
        return _socketOnConnection(socket, config);
      });
      port2 = config.httpServer.address().port;
      story.info(LOG_SRC, "Server logs also available through main HTTP server on port " + (chalk.cyan(port2)));
    }
  };

  _socketOnConnection = function(socket, config) {
    socket.sbAuthenticated = config.authenticate == null;
    socket.sbConfig = config;
    if (socket.sbAuthenticated) {
      socket.join('AUTHENTICATED');
    } else {
      _socketTxMsg(socket, {
        type: 'LOGIN_REQUIRED'
      });
    }
    return socket.on('MSG', function(msg) {
      return _socketRxMsg(socket, msg);
    });
  };

  _socketRxMsg = function(socket, msg) {
    var authenticate, credentials, data, hub, login, ref, story, type;
    type = msg.type, data = msg.data;
    ref = socket.sbConfig, story = ref.mainStory, hub = ref.hub;
    switch (type) {
      case 'LOGIN_REQUEST':
        authenticate = socket.sbConfig.authenticate;
        login = (credentials = data).login;
        Promise.resolve(socket.sbAuthenticated || (authenticate == null) || authenticate(credentials)).then(function(fAuthValid) {
          var rsp;
          rsp = {
            type: 'LOGIN_RESPONSE'
          };
          if (fAuthValid) {
            rsp.result = 'SUCCESS';
            story.info(LOG_SRC, "User '" + login + "' authenticated successfully");
            socket.sbAuthenticated = true;
            socket.join('AUTHENTICATED');
            rsp.data = {
              login: login,
              bufferedRecords: _getBufferedRecords(hub)
            };
          } else {
            rsp.result = 'ERROR';
            story.warn(LOG_SRC, "User '" + login + "' authentication failed");
          }
          return _socketTxMsg(socket, rsp);
        });
        break;
      default:
        story.warn(LOG_SRC, "Unknown message type '" + type + "'");
    }
  };

  _socketTxMsg = function(socket, msg) {
    return socket.emit('MSG', msg);
  };

  _socketBroadcast = function() {
    var msg;
    msg = {
      type: 'RECORDS',
      data: _broadcastBuf
    };
    if (_ioStandalone != null) {
      _ioStandalone.to('AUTHENTICATED').emit('MSG', msg);
    }
    if (_ioServerAdaptor != null) {
      _ioServerAdaptor.to('AUTHENTICATED').emit('MSG', msg);
    }
    _broadcastBuf.length = 0;
  };

  _getBufferedRecords = function(hub) {
    return hub.getBufferedRecords().map(_preprocessAttachments);
  };

  _broadcastBuf = [];

  _enqueueRecord = function(record, config) {
    return _broadcastBuf.push(_preprocessAttachments(record));
  };

  _preprocessAttachments = function(record) {
    if (!record.hasOwnProperty('obj')) {
      return record;
    }
    return timm.set(record, 'obj', treeLines(record.obj));
  };

  _process = function(config) {
    var finalBroadcast;
    if (config.throttle) {
      finalBroadcast = _.throttle(_socketBroadcast, config.throttle);
    } else {
      finalBroadcast = _socketBroadcast;
    }
    return function(record) {
      _enqueueRecord(record, config);
      return finalBroadcast();
    };
  };

  create = function(baseConfig) {
    var config, listener;
    config = timm.addDefaults(baseConfig, DEFAULT_CONFIG);
    listener = {
      type: 'WS_SERVER',
      init: function() {
        return _socketInit(config);
      },
      process: _process(config)
    };
    return listener;
  };

  module.exports = {
    create: create
  };

}).call(this);
