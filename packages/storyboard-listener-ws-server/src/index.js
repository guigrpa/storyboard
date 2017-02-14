import path from 'path';
import http from 'http';
import express from 'express';
import socketio from 'socket.io';
import Promise from 'bluebird';
import { addDefaults } from 'timm';
import { ClocksyServer } from 'clocksy';
import throttle from 'lodash/throttle';

const REQUIRED_CORE_VERSION = '^3.0.0-rc.2';
const WS_NAMESPACE = '/STORYBOARD';
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
class WsServerListener {
  constructor(config, { hub, mainStory, chalk, filters }) {
    this.type = 'WS_SERVER';
    this.config = config;
    this.hub = hub;
    this.hubId = hub.getHubId();
    this.mainStory = mainStory;
    this.chalk = chalk;
    this.filters = filters;
    this.ioStandaloneServer = null;
    this.ioStandaloneNamespace = null;
    this.ioServerAdaptor = null;
    this.clocksy = new ClocksyServer();
    // Short buffer for records to be broadcast
    // (accumulated during the throttle period)
    this.bufBroadcast = [];
    const { throttle: throttlePeriod } = config;
    if (throttlePeriod) {
      this.socketBroadcast = throttle(this.socketBroadcast, throttlePeriod).bind(this);
    }
  }

  init() {
    const { config, mainStory } = this;
    const { port } = config;

    // Launch stand-alone log server
    if (port != null) {
      const httpInitError = logError(mainStory,
        `Error initialising standalone server logs on port ${this.chalk.cyan.bold(port)}`);
      try {
        const expressApp = express();
        expressApp.use(express.static(path.join(__dirname, './public')));
        const httpServer = http.createServer(expressApp);
        httpServer.on('error', httpInitError);
        httpServer.on('listening', () => {
          const tmpPort = httpServer.address().port;
          mainStory.info(LOG_SRC, `Logs available via web on port ${this.chalk.cyan.bold(tmpPort)}`);
        });
        this.ioStandaloneServer = socketio(httpServer);
        this.ioStandaloneNamespace = this.ioStandaloneServer.of(WS_NAMESPACE);
        this.ioStandaloneNamespace.on('connection', (socket) => this.socketConnect(socket));
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
      this.ioServerAdaptor.on('connection', (socket) => this.socketConnect(socket));
      const httpInitError = logError(mainStory, 'Error initialising log server adaptor');
      try {
        const httpServer = this.ioServerAdaptor.server.httpServer;
        httpServer.on('error', httpInitError);
        httpServer.on('listening', () => {
          const tmpPort = httpServer.address().port;
          mainStory.info(LOG_SRC,
            `Logs available through main HTTP server on port ${this.chalk.cyan.bold(tmpPort)}`);
        });
      } catch (err) { httpInitError(err); }
    }
  }

  tearDown() {
    if (this.ioStandaloneServer) {
      this.ioStandaloneServer.close();
      this.ioStandaloneServer = null;
    }
    this.ioStandaloneNamespace = null;
    if (this.ioServerAdaptor) {
      if (this.ioServerAdaptor.close) this.ioServerAdaptor.close();
      this.ioServerAdaptor = null;
    }
  }

  getConfig() {
    return this.config;
  }

  socketConnect(socket) {
    /* eslint-disable no-param-reassign */
    socket.sbAuthenticated = (this.config.authenticate == null);
    /* eslint-enable no-param-reassign */
    if (socket.sbAuthenticated) socket.join(SOCKET_ROOM);
    socket.on('MSG', (msg) => this.socketRx(socket, msg));
  }

  socketRx(socket, msg) {
    // Clock sync requests must be handled as fast as possible
    if (msg.type === 'CLOCKSY') {
      this.socketTx(socket, 'CLOCKSY', 'SUCCESS',
        this.clocksy.processRequest(msg.data));
      return;
    }
    const { type, data } = msg;
    const { hub, config } = this;
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
        if (type === 'SET_SERVER_FILTER') this.filters.config(data);
        this.socketTx(socket, 'SERVER_FILTER', 'SUCCESS', { filter: this.filters.getConfig() });
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
  }

  socketLogin(socket, msg) {
    const { hub, config } = this;
    const { authenticate } = config;
    const { data: credentials } = msg;
    const { login } = credentials;
    const fPreAuthenticated = socket.sbAuthenticated || authenticate == null;
    Promise.resolve(fPreAuthenticated || authenticate(credentials))
    .then((fAuthValid) => {
      let result;
      let rspData;
      let bufferedRecords;
      if (fAuthValid) {
        result = 'SUCCESS';
        /* eslint-disable no-param-reassign */
        socket.sbAuthenticated = true;
        /* eslint-enable no-param-reassign */
        socket.join(SOCKET_ROOM);
        bufferedRecords = hub.getBufferedRecords();
        rspData = { login, bufferedRecords };
      } else {
        result = 'ERROR';
      }
      this.socketTx(socket, 'LOGIN_RESPONSE', result, rspData);
      if (result === 'SUCCESS') {
        this.log('info', `User '${login}' authenticated successfully`);
        // this.log('debug', `Piggybacked ${this.chalk.cyan(bufferedRecords.length)} records`);
      } else {
        this.log('warn', `User '${login}' authentication failed`);
      }
    });
  }

  socketLogout(socket) {
    const { authenticate } = this.config;
    if (authenticate != null) {
        /* eslint-disable no-param-reassign */
      socket.sbAuthenticated = false;
        /* eslint-enable no-param-reassign */
      socket.leave(SOCKET_ROOM);
    }
  }

  socketTx(socket, type, result, data) {
    const msg = this.buildMsg(type, result, data);
    socket.emit('MSG', msg);
  }

  addToBroadcastBuffer(records) {
    this.bufBroadcast = this.bufBroadcast.concat(records);
  }

  // Send records (buffered since the last call to this function)
  // both through the standalone server and the piggybacked one
  socketBroadcast() {
    const msg = this.buildMsg('RECORDS', undefined, this.bufBroadcast);
    this.socketDoBroadcast(msg);
    this.bufBroadcast.length = 0;
  }

  socketDoBroadcast(msg) {
    const { ioStandaloneNamespace, ioServerAdaptor } = this;
    if (ioStandaloneNamespace) ioStandaloneNamespace.to(SOCKET_ROOM).emit('MSG', msg);
    if (ioServerAdaptor) ioServerAdaptor.to(SOCKET_ROOM).emit('MSG', msg);
  }

  buildMsg(type, result, data) {
    return { src: 'WS_SERVER', hubId: this.hubId, type, result, data };
  }

  log(logLevel, msg) {
    // process.nextTick(() => this.mainStory[logLevel](LOG_SRC, msg));
    this.mainStory[logLevel](LOG_SRC, msg);
  }

  // -----------------------------------------
  // Main processing function
  // -----------------------------------------
  process(msg) {
    if (msg.type !== 'RECORDS') return;
    const { data: records } = msg;
    this.addToBroadcastBuffer(records);
    this.socketBroadcast(); // may be throttled
  }
}

// -----------------------------------------
// Helpers
// -----------------------------------------
const logError = (mainStory, msg) => (err) => {
  mainStory.error(LOG_SRC, msg, { attach: err });
};

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new WsServerListener(addDefaults(userConfig, DEFAULT_CONFIG), context);
create.requiredCoreVersion = REQUIRED_CORE_VERSION;

export default create;
