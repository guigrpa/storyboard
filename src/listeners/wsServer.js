import path from 'path';
import http from 'http';
import express from 'express';
import socketio from 'socket.io';
import Promise from 'bluebird';
import chalk from 'chalk';
import { addDefaults } from 'timm';
import { throttle } from '../vendor/lodash';
import filters from '../gral/filters';
import { WS_NAMESPACE } from '../gral/constants';

const DEFAULT_CONFIG = {
  port: 8090,
  throttle: 200,
  authenticate: null,
  broadcastUploaded: true,
};

const LOG_SRC = 'storyboard';
const SOCKET_ROOM = 'authenticated';

// -----------------------------------------
// Listener
// -----------------------------------------
function WsServerListener(config, { hub, mainStory }) {
  this.type = 'WS_SERVER';
  this.config = config;
  this.hub = hub;
  this.hubId = hub.getHubId();
  this.mainStory = mainStory;
  this.ioStandaloneServer = null;
  this.ioStandaloneNamespace = null;
  this.ioServerAdaptor = null;
  // Short buffer for records to be broadcast
  // (accumulated during the throttle period)
  this.bufBroadcast = [];
  const { throttle: throttlePeriod } = config;
  if (throttlePeriod) {
    this.socketBroadcast = throttle(this.socketBroadcast, throttlePeriod).bind(this);
  }
}

WsServerListener.prototype.init = function() {
  const { config, mainStory } = this;
  const { port } = config;

  // Launch stand-alone log server
  if (port != null) {
    const httpInitError = logError(mainStory, 
      `Error initialising standalone server logs on port ${chalk.cyan(port)}`);
    try {
      const expressApp = express();
      expressApp.use(express["static"](path.join(__dirname, '../../serverLogsApp')));
      const httpServer = http.createServer(expressApp);
      httpServer.on('error', httpInitError);
      httpServer.on('listening', () => {
        const tmpPort = httpServer.address().port;
        mainStory.info(LOG_SRC, `Server logs available on port ${chalk.cyan(tmpPort)}`);
      });
      this.ioStandaloneServer = socketio(httpServer);
      this.ioStandaloneNamespace = this.ioStandaloneServer.of(WS_NAMESPACE);
      this.ioStandaloneNamespace.on('connection', socket => this.socketConnect(socket));
      httpServer.listen(port);
    } catch (err) { httpInitError(err); }
  }

  // If a main application server is also provided, 
  // launch another log server on the same application port
  if (config.socketServer) {
    this.ioServerAdaptor = config.socketServer.of(WS_NAMESPACE);
  } else if (config.httpServer) {
    this.ioServerAdaptor = socketio(config.httpServer).of(WS_NAMESPACE);
  }
  if (this.ioServerAdaptor) {
    this.ioServerAdaptor.on('connection', socket => this.socketConnect(socket));
    const httpInitError = logError(mainStory, `Error initialising log server adaptor`);
    try {
      const httpServer = this.ioServerAdaptor.server.httpServer;
      httpServer.on('error', httpInitError);
      httpServer.on('listening', () => {
        const tmpPort = httpServer.address().port;
        mainStory.info(LOG_SRC,
          `Server logs available through main HTTP server on port ${chalk.cyan(tmpPort)}`);
      });
    } catch (err) { httpInitError(err); }
  }
};

WsServerListener.prototype.tearDown = function() {
  if (this.ioStandaloneServer) {
    this.ioStandaloneServer.close();
    this.ioStandaloneServer = null;
  }
  this.ioStandaloneNamespace = null;
  if (this.ioServerAdaptor) {
    if (this.ioServerAdaptor.close) this.ioServerAdaptor.close();
    this.ioServerAdaptor = null;
  }
};

WsServerListener.prototype.socketConnect = function(socket) {
  socket.sbAuthenticated = (this.config.authenticate == null);
  if (socket.sbAuthenticated) socket.join(SOCKET_ROOM);
  socket.on('MSG', msg => this.socketRx(socket, msg));
};

WsServerListener.prototype.socketRx = function(socket, msg) {
  const { type, data } = msg;
  const { mainStory, hub, config } = this;
  let newFilter;
  switch (type) {
    case 'LOGIN_REQUEST':
      this.socketLogin(socket, msg);
      break;
    case 'LOG_OUT':
      this.socketLogout(socket);
      break;
    case 'LOGIN_REQUIRED_QUESTION':
      this.socketTx(socket, 'LOGIN_REQUIRED_RESPONSE', 'SUCCESS',
        { fLoginRequired: config.authenticate != null });
      break;
    case 'GET_SERVER_FILTER':
    case 'SET_SERVER_FILTER':
      if (type === 'SET_SERVER_FILTER') {
        newFilter = msg.data;
        filters.config(newFilter);
      }
      this.socketTx(socket, 'SERVER_FILTER', 'SUCCESS', { filter: filters.getConfig() });
      if (type === 'SET_SERVER_FILTER') {
        this.log('info', `Server filter changed to: ${chalk.cyan.bold(newFilter)}`);
      }
      break;

    // Uploaded records:
    // - Relay to the hub (some listeners may be interested)
    // - Re-broadcast (for other clients)
    case 'RECORDS':
      // process.nextTick(() => { hub.emitMsg(msg, this); });
      hub.emitMsg(msg, this);
      if (config.broadcastUploaded) this.socketDoBroadcast(msg);
      break;
    default:
      this.log('warn', `Unknown message type '${type}'`);
  }
};

WsServerListener.prototype.socketLogin = function(socket, msg) {
  const { mainStory, hub, config } = this;
  const { authenticate } = config;
  const { data: credentials } = msg;
  const { login } = credentials;
  const fPreAuthenticated = socket.sbAuthenticated || authenticate == null;
  Promise.resolve(fPreAuthenticated || authenticate(credentials))
  .then(fAuthValid => {
    let result;
    let rspData;
    let bufferedRecords;
    if (fAuthValid) {
      result = 'SUCCESS';
      socket.sbAuthenticated = true;
      socket.join(SOCKET_ROOM);
      bufferedRecords = hub.getBufferedRecords();
      rspData = { login, bufferedRecords };
    } else {
      result = 'ERROR';
    }
    this.socketTx(socket, 'LOGIN_RESPONSE', result, rspData);
    if (result === 'SUCCESS') {
      this.log('info', `User '${login}' authenticated successfully`);
      // this.log('debug', `Piggybacked ${chalk.cyan(bufferedRecords.length)} records`);
    } else {
      this.log('warn', `User '${login}' authentication failed`);
    }
  });
};

WsServerListener.prototype.socketLogout = function(socket) {
  const { authenticate } = this.config;
  if (authenticate != null) {
    socket.sbAuthenticated = false;
    socket.leave(SOCKET_ROOM);
  }
};

WsServerListener.prototype.socketTx = function(socket, type, result, data) {
  const msg = this.buildMsg(type, result, data);
  socket.emit('MSG', msg);
};


WsServerListener.prototype.addToBroadcastBuffer = function(records) {
  this.bufBroadcast = this.bufBroadcast.concat(records);
};

// Send records (buffered since the last call to this function)
// both through the standalone server and the piggybacked one
WsServerListener.prototype.socketBroadcast = function() {
  const { ioStandaloneNamespace, ioServerAdaptor } = this;
  const msg = this.buildMsg('RECORDS', undefined, this.bufBroadcast);
  this.socketDoBroadcast(msg);
  this.bufBroadcast.length = 0;
};

WsServerListener.prototype.socketDoBroadcast = function(msg) {
  const { ioStandaloneNamespace, ioServerAdaptor } = this;
  if (ioStandaloneNamespace) ioStandaloneNamespace.to(SOCKET_ROOM).emit('MSG', msg);
  if (ioServerAdaptor) ioServerAdaptor.to(SOCKET_ROOM).emit('MSG', msg);
};

WsServerListener.prototype.buildMsg = function(type, result, data) {
  return { src: 'WS_SERVER', hubId: this.hubId, type, result, data };
};

WsServerListener.prototype.log = function(logLevel, msg) {
  // process.nextTick(() => this.mainStory[logLevel](LOG_SRC, msg));
  this.mainStory[logLevel](LOG_SRC, msg);
};

// -----------------------------------------
// Main processing function
// -----------------------------------------
WsServerListener.prototype.process = function(msg) {
  if (msg.type !== 'RECORDS') return;
  const { data: records } = msg;
  this.addToBroadcastBuffer(records);
  this.socketBroadcast(); // may be throttled
};

// -----------------------------------------
// Helpers
// -----------------------------------------
const logError = (mainStory, msg) => err => {
  mainStory.error(LOG_SRC, msg, { attach: err });
};

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new WsServerListener(addDefaults(userConfig, DEFAULT_CONFIG), context);

export default create;
