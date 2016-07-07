var DEFAULT_CONFIG, LOG_SRC, Promise, SOCKET_ROOM, _, _broadcastBuf, _enqueueRecord, _getBufferedRecords, _ioServerAdaptor, _ioStandaloneNamespace, _ioStandaloneServer, _process, _socketBroadcast, _socketInit, _socketOnConnection, _socketRxMsg, _socketShutDown, _socketTxMsg, chalk, create, express, filters, http, k, path, socketio, timm;

_ = require('../vendor/lodash');

path = require('path');

http = require('http');

express = require('express');

socketio = require('socket.io');

Promise = require('bluebird');

chalk = require('chalk');

timm = require('timm');

filters = require('../gral/filters');

k = require('../gral/constants');

DEFAULT_CONFIG = {
  port: 8090,
  throttle: 200,
  authenticate: null
};

LOG_SRC = 'storyboard';

SOCKET_ROOM = 'authenticated';

_ioStandaloneServer = null;

_ioStandaloneNamespace = null;

_ioServerAdaptor = null;

// -----------------------------------------
// WebSocket I/O
// -----------------------------------------
_socketInit = function(config) {
  var _http2InitError, _httpInitError, err, error, error1, expressApp, httpServer, httpServer2, mainStory, port;
  if (_ioStandaloneNamespace) {
    return;
  }
  port = config.port, mainStory = config.mainStory;
  if (port != null) {
    _httpInitError = function(err) {
      return mainStory.error(LOG_SRC, "Error initialising standalone server logs on port " + (chalk.cyan(port)) + ":", {
        attach: err
      });
    };
    try {
      expressApp = express();
      expressApp.use(express["static"](path.join(__dirname, '../../serverLogsApp')));
      httpServer = http.createServer(expressApp);
      httpServer.on('error', _httpInitError);
      httpServer.on('listening', function() {
        return mainStory.info(LOG_SRC, "Server logs available on port " + (chalk.cyan(httpServer.address().port)));
      });
      _ioStandaloneServer = socketio(httpServer);
      _ioStandaloneNamespace = _ioStandaloneServer.of(k.WS_NAMESPACE);
      _ioStandaloneNamespace.on('connection', function(socket) {
        return _socketOnConnection(socket, config);
      });
      httpServer.listen(port);
    } catch (error) {
      err = error;
      _httpInitError(err);
    }
  }
  if (config.socketServer) {
    _ioServerAdaptor = config.socketServer.of(k.WS_NAMESPACE);
  } else if (config.httpServer) {
    _ioServerAdaptor = socketio(config.httpServer).of(k.WS_NAMESPACE);
  }
  if (_ioServerAdaptor) {
    _ioServerAdaptor.on('connection', function(socket) {
      return _socketOnConnection(socket, config);
    });
    _http2InitError = function(err) {
      return mainStory.error(LOG_SRC, "Error initialising log server adaptor:", {
        attach: err
      });
    };
    try {
      httpServer2 = _ioServerAdaptor.server.httpServer;
      httpServer2.on('error', _http2InitError);
      httpServer2.on('listening', function() {
        var port2;
        port2 = httpServer2.address().port;
        return mainStory.info(LOG_SRC, "Server logs available through main HTTP server on port " + (chalk.cyan(port2)));
      });
    } catch (error1) {
      err = error1;
      _http2InitError(err);
    }
  }
};

_socketShutDown = function(config) {
  if (_ioStandaloneServer != null) {
    _ioStandaloneServer.close();
  }
  _ioStandaloneServer = _ioStandaloneNamespace = null;
  if (_ioServerAdaptor != null) {
    if (typeof _ioServerAdaptor.close === "function") {
      _ioServerAdaptor.close();
    }
  }
  _ioServerAdaptor = null;
};

_socketOnConnection = function(socket, config) {
  socket.sbAuthenticated = config.authenticate == null;
  socket.sbConfig = config;
  if (socket.sbAuthenticated) {
    socket.join(SOCKET_ROOM);
  }
  return socket.on('MSG', function(msg) {
    return _socketRxMsg(socket, msg);
  });
};

_socketRxMsg = function(socket, msg) {
  var authenticate, credentials, data, hub, login, mainStory, newFilter, ref, type;
  type = msg.type, data = msg.data;
  ref = socket.sbConfig, mainStory = ref.mainStory, hub = ref.hub;
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
          socket.sbAuthenticated = true;
          socket.join(SOCKET_ROOM);
          rsp.data = {
            login: login,
            bufferedRecords: _getBufferedRecords(hub)
          };
          process.nextTick(function() {
            mainStory.info(LOG_SRC, "User '" + login + "' authenticated successfully");
            return mainStory.debug(LOG_SRC, "Piggybacked " + (chalk.cyan(rsp.data.bufferedRecords.length)) + " records");
          });
        } else {
          rsp.result = 'ERROR';
          process.nextTick(function() {
            return mainStory.warn(LOG_SRC, "User '" + login + "' authentication failed");
          });
        }
        return _socketTxMsg(socket, rsp);
      });
      break;
    case 'LOG_OUT':
      authenticate = socket.sbConfig.authenticate;
      if (authenticate != null) {
        socket.sbAuthenticated = false;
        socket.leave(SOCKET_ROOM);
      }
      break;
    case 'LOGIN_REQUIRED_QUESTION':
      _socketTxMsg(socket, {
        type: 'LOGIN_REQUIRED_RESPONSE',
        result: 'SUCCESS',
        data: {
          fLoginRequired: socket.sbConfig.authenticate != null
        }
      });
      break;
    case 'GET_SERVER_FILTER':
    case 'SET_SERVER_FILTER':
      if (type === 'SET_SERVER_FILTER') {
        newFilter = msg.data;
        filters.config(newFilter);
        process.nextTick(function() {
          return mainStory.info(LOG_SRC, "Server filter changed to: " + (chalk.cyan.bold(newFilter)));
        });
      }
      _socketTxMsg(socket, {
        type: 'SERVER_FILTER',
        result: 'SUCCESS',
        data: {
          filter: filters.getConfig()
        }
      });
      break;
    case 'UPLOAD_RECORDS':
      process.nextTick(function() {
        var i, len, record, ref1;
        ref1 = msg.data;
        for (i = 0, len = ref1.length; i < len; i++) {
          record = ref1[i];
          hub.emit(record);
        }
      });
      break;
    default:
      process.nextTick(function() {
        return mainStory.warn(LOG_SRC, "Unknown message type '" + type + "'");
      });
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
  if (_ioStandaloneNamespace != null) {
    _ioStandaloneNamespace.to(SOCKET_ROOM).emit('MSG', msg);
  }
  if (_ioServerAdaptor != null) {
    _ioServerAdaptor.to(SOCKET_ROOM).emit('MSG', msg);
  }
  _broadcastBuf.length = 0;
};

_getBufferedRecords = function(hub) {
  return hub.getBufferedRecords();
};

_broadcastBuf = [];

_enqueueRecord = function(record, config) {
  return _broadcastBuf.push(record);
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

// -----------------------------------------
// API
// -----------------------------------------
create = function(baseConfig) {
  var config, listener;
  config = timm.addDefaults(baseConfig, DEFAULT_CONFIG);
  listener = {
    type: 'WS_SERVER',
    init: function() {
      return _socketInit(config);
    },
    process: _process(config),
    tearDown: function() {
      return _socketShutDown(config);
    }
  };
  return listener;
};

module.exports = create;
