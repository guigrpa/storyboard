import socketio from 'socket.io-client';
import { merge, addDefaults, set as timmSet } from 'timm';
import { throttle } from '../vendor/lodash';
import { WS_NAMESPACE } from '../gral/constants';
import ifExtension from './helpers/interfaceExtension';

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
  this.uploaderId = mainStory.storyId || '_SOMEBODY_';
  this.socket = null;
  this.fSocketConnected = false;
  // Short buffer for records to be uploaded
  // (accumulated during the throttle period)
  this.bufUpload = [];
  const { throttleUpload: throttlePeriod } = config;
  if (throttlePeriod) {
    this.socketUpload = throttle(this.socketUpload, throttlePeriod).bind(this);
  }
}

WsClientListener.prototype.configure = function(config) {
  this.config = merge(this.config, config);
};

WsClientListener.prototype.init = function() {
  this.socketInit();
  ifExtension.rx(msg => this.extensionRx(msg));
};

// -----------------------------------------
// Extension I/O
// -----------------------------------------
WsClientListener.prototype.extensionRx = function(msg) {
  const { type, data } = msg;
  if (type === 'CONNECT_REQUEST') {
    const rspType = this.fSocketConnected ? 'WS_CONNECTED' : 'WS_DISCONNECTED';
    ifExtension.tx({ type: rspType });
  }
  if (!(type === 'CONNECT_REQUEST' || type === 'CONNECT_RESPONSE' ||
        type === 'GET_LOCAL_CLIENT_FILTER' || type === 'SET_LOCAL_CLIENT_FILTER')) {
    this.socketTx({ type, data });
  }
};

// -----------------------------------------
// Websocket I/O
// -----------------------------------------
WsClientListener.prototype.socketInit = function() {
  if (this.socket) return;
  let url = WS_NAMESPACE;
  if (process.env.TEST_BROWSER) {
    url = `http://localhost:8090${WS_NAMESPACE}`;
  }
  this.socket = socketio.connect(url);
  const socketConnected = () => {
    ifExtension.tx({ type: 'WS_CONNECTED' });
    this.fSocketConnected = true;
  };
  const socketDisconnected = () => {
    ifExtension.tx({ type: 'WS_DISCONNECTED' });
    this.fSocketConnected = false;
  };
  this.socket.on('connect', socketConnected);
  this.socket.on('disconnect', socketDisconnected);
  this.socket.on('error', socketDisconnected);
  this.socket.on('MSG', this.socketRx);
};

// Mutates the message: filters out records that we have uploaded ourselves
WsClientListener.prototype.socketRx = function(msg) {
  if (msg.type === 'RECORDS') {
    msg.data = msg.data.filter(o => o.uploadedBy !== this.uploaderId);
  }
  ifExtension.tx(msg);
};

WsClientListener.prototype.socketTx = function(msg) {
  /* istanbul ignore next */
  if (!this.socket) {
    console.error(`Cannot send '${msg.type}' message to server: socket unavailable`);
    return;
  }
  this.socket.emit('MSG', msg);
};

WsClientListener.prototype.addToUploadBuffer = function(record0) {
  if (this.bufUpload.length < BUF_UPLOAD_LENGTH) {
    const record = timmSet(record0, 'uploadedBy', this.uploaderId);
    this.bufUpload.push(record);
  }
};

WsClientListener.prototype.socketUpload = function() {
  /* istanbul ignore next */
  if (!this.fSocketConnected) return;
  this.socketTx({ type: 'UPLOAD_RECORDS', data: this.bufUpload });
  this.bufUpload.length = 0;
};

// -----------------------------------------
// Main processing function
// -----------------------------------------
WsClientListener.prototype.process = function(record) {
  if (!this.config.uploadClientStories) return;
  this.addToUploadBuffer(record);
  this.socketUpload(); // may be throttled
};

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new WsClientListener(addDefaults(userConfig, DEFAULT_CONFIG), context);

export default create;
