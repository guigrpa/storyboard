import socketio from 'socket.io-client';
import { merge, addDefaults, set as timmSet } from 'timm';
import { throttle } from '../vendor/lodash';
import { WS_NAMESPACE } from '../gral/constants';

const DEFAULT_CONFIG = {
  uploadClientStories: false,
  throttleUpload: null,
};
const BUF_UPLOAD_LENGTH = 2000;

// -----------------------------------------
// Listener
// -----------------------------------------
function WsClientListener(config, { hub, mainStory }) {
  this.type = 'WS_CLIENT';
  this.config = config;
  this.hub = hub;
  this.hubId = hub.getHubId();
  this.socket = null;
  this.fSocketConnected = false;
  // Short buffer for records to be uploaded
  // (accumulated during the throttle period)
  this.bufUpload = [];
  const { throttleUpload: throttlePeriod } = config;
  if (throttlePeriod) {
    this.socketUploadRecords = throttle(this.socketUploadRecords, throttlePeriod).bind(this);
  }
}

WsClientListener.prototype.configure = function(config) {
  this.config = merge(this.config, config);
};

WsClientListener.prototype.init = function() {
  if (this.socket) return;
  let url = WS_NAMESPACE;
  if (process.env.TEST_BROWSER) {
    url = `http://localhost:8090${WS_NAMESPACE}`;
  }
  this.socket = socketio.connect(url);
  const socketConnected = () => {
    this.hubTx('WS_CONNECTED');
    this.fSocketConnected = true;
  };
  const socketDisconnected = () => {
    this.hubTx('WS_DISCONNECTED');
    this.fSocketConnected = false;
  };
  this.socket.on('connect', socketConnected);
  this.socket.on('disconnect', socketDisconnected);
  this.socket.on('error', socketDisconnected);
  this.socket.on('MSG', msg => this.socketRx(msg));
};

// -----------------------------------------
// Websocket I/O
// -----------------------------------------
// Ignore messages that originate from our own hub.
// Relay others to the hub, untouched
WsClientListener.prototype.socketRx = function(msg) {
  if (msg.hubId === this.hubId) return;
  this.hub.emitMsg(msg, this);
};

WsClientListener.prototype.socketTx = function(type, data) {
  /* istanbul ignore next */
  if (!this.socket) {
    console.error(`Cannot send '${msg.type}' message to server: socket unavailable`);
    return;
  }
  const msg = { src: 'WS_CLIENT', hubId: this.hubId, type, data };
  this.socket.emit('MSG', msg);
};

WsClientListener.prototype.addToUploadBuffer = function(records) {
  this.bufUpload = this.bufUpload.concat(records);
  if (this.bufUpload.length > BUF_UPLOAD_LENGTH) {
    this.bufUpload = this.bufUpload.slice(-BUF_UPLOAD_LENGTH);
  }
};

WsClientListener.prototype.socketUploadRecords = function() {
  /* istanbul ignore next */
  if (!this.fSocketConnected) return;
  this.socketTx('RECORDS', this.bufUpload);
  this.bufUpload.length = 0;
};

// -----------------------------------------
// Main processing function
// -----------------------------------------
WsClientListener.prototype.process = function(msg) {
  switch (msg.type) {

    // Depending on the configuration, we may upload the records
    case 'RECORDS':
      this.processRecords(msg);
      break;

    // We are not handling the connection with the extension,
    // but we will report on the WS connection
    case 'CONNECT_REQUEST':
      this.processExtensionCxRequest(msg);
      break;

    // Messages to the WS Server
    case 'LOGIN_REQUEST':
    case 'LOG_OUT':
    case 'LOGIN_REQUIRED_QUESTION':
    case 'GET_SERVER_FILTER':
    case 'GET_SERVER_FILTER':
      this.socketTx(msg.type, msg.data);
      break;
    default:
      break;
  }
};

WsClientListener.prototype.processRecords = function(msg) {
  if (!this.config.uploadClientStories) return;
  const { data: records } = msg;
  this.addToUploadBuffer(records);
  this.socketUploadRecords(); // may be throttled
};

WsClientListener.prototype.processExtensionCxRequest = function(msg) {
  this.hubTx(this.fSocketConnected ? 'WS_CONNECTED' : 'WS_DISCONNECTED');
};

WsClientListener.prototype.hubTx = function(type, data) {
  this.hub.emitMsgWithFields('WS_CLIENT', type, data, this);
};

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new WsClientListener(addDefaults(userConfig, DEFAULT_CONFIG), context);

export default create;
