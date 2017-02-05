import socketio from 'socket.io-client';
import ms from 'ms';
import { merge, addDefaults, setIn, set as timmSet } from 'timm';
import { ClocksyClient } from 'clocksy';
import { chalk, _, constants } from 'storyboard-core';

const { WS_NAMESPACE } = constants;
const DEFAULT_CONFIG = {
  uploadClientStories: false,
  throttleUpload: null,
  clockSync: false,
};
const BUF_UPLOAD_LENGTH = 2000;

// -----------------------------------------
// Listener
// -----------------------------------------
class WsClientListener {
  constructor(config, { hub, mainStory }) {
    this.type = 'WS_CLIENT';
    this.config = config;
    this.hub = hub;
    this.hubId = hub.getHubId();
    this.mainStory = mainStory;
    this.socket = null;
    this.fSocketConnected = false;
    this.clocksy = new ClocksyClient({
      sendRequest: (req) => this.socketTx('CLOCKSY', req),
    });
    this.tDelta = null;
    // Short buffer for records to be uploaded
    // (accumulated during the throttle period)
    this.bufUpload = [];
    const { throttleUpload: throttlePeriod } = config;
    if (throttlePeriod) {
      this.socketUploadRecords = _.throttle(this.socketUploadRecords, throttlePeriod).bind(this);
    }
  }

  configure(config) {
    this.config = merge(this.config, config);
  }

  getConfig() {
    return this.config;
  }

  init() {
    if (this.socket) return;
    let url = WS_NAMESPACE;
    if (process.env.TEST_BROWSER) {
      url = `http://localhost:8090${WS_NAMESPACE}`;
    }
    this.socket = socketio.connect(url);
    this.socket.on('connect', () => this.socketDidConnect());
    this.socket.on('disconnect', () => this.socketDidDisconnect());
    this.socket.on('error', () => this.socketDidDisconnect());
    this.socket.on('MSG', (msg) => this.socketRx(msg));
  }

  // -----------------------------------------
  // Websocket I/O
  // -----------------------------------------
  socketDidConnect() {
    if (this.config.clockSync) {
      // Starting clocksy also immediately sends a clock sync request.
      this.clocksy.start();
    } else {
      this.socketDidSynchronize();
    }
  }

  socketDidSynchronize() {
    this.fSocketConnected = true;
    this.hubTx('WS_CONNECTED');
  }

  socketDidDisconnect() {
    this.fSocketConnected = false;
    this.clocksy.stop();
    this.hubTx('WS_DISCONNECTED');
  }

  socketRx(msg) {
    const { type: msgType } = msg;

    // Process clock sync messages
    if (this.config.clockSync && msgType === 'CLOCKSY') {
      this.tDelta = this.clocksy.processResponse(msg.data);
      if (!this.fSocketConnected) this.socketDidSynchronize();
      const tDelta = Math.round(this.tDelta * 10) / 10;
      const rtt = this.clocksy.getRtt();
      const logLevel = this.fFirstDeltaShown ? 'trace' : 'debug';
      this.fFirstDeltaShown = true;
      this.mainStory[logLevel]('storyboard',
        `Clock sync delta: ${chalk.blue(ms(tDelta))}, rtt: ${chalk.blue(ms(rtt))}`);
      return;
    }

    // Discard messages that originate from our own hub
    if (msg.hubId === this.hubId) return;

    // Correct timestamps in downloaded records
    let finalMsg = msg;
    if (this.config.clockSync && this.tDelta) {
      const tCorrection = -this.tDelta;
      if (msgType === 'RECORDS') {
        const records = msg.data;
        const correctedRecords = this.applyTimeDelta(records, tCorrection);
        finalMsg = timmSet(msg, 'data', correctedRecords);
      } else if (msgType === 'LOGIN_RESPONSE' && msg.data && msg.data.bufferedRecords) {
        const records = msg.data.bufferedRecords;
        const correctedRecords = this.applyTimeDelta(records, tCorrection);
        finalMsg = setIn(msg, ['data', 'bufferedRecords'], correctedRecords);
      }
    }

    // Relay all other messages to the hub
    this.hub.emitMsg(finalMsg, this);
  }

  socketTx(type, data) {
    /* istanbul ignore next */
    if (!this.socket) {
      this.mainStory.error('storyboard',
        `Cannot send '${msg.type}' message to server: socket unavailable`);
      return;
    }
    const msg = { src: 'WS_CLIENT', hubId: this.hubId, type, data };
    this.socket.emit('MSG', msg);
  }

  addToUploadBuffer(records0) {
    const records = this.config.clockSync && this.tDelta ?
      this.applyTimeDelta(records0, this.tDelta) :
      records0;
    this.bufUpload = this.bufUpload.concat(records);
    if (this.bufUpload.length > BUF_UPLOAD_LENGTH) {
      this.bufUpload = this.bufUpload.slice(-BUF_UPLOAD_LENGTH);
    }
  }

  socketUploadRecords() {
    /* istanbul ignore next */
    if (!this.fSocketConnected) return;
    this.socketTx('RECORDS', this.bufUpload);
    this.bufUpload.length = 0;
  }

  // -----------------------------------------
  // Main processing function
  // -----------------------------------------
  process(msg) {
    switch (msg.type) {

      // Depending on the configuration, we may upload the records
      case 'RECORDS':
        this.processRecords(msg);
        break;

      // We are not handling the connection with the extension,
      // but we will report on the WS connection
      case 'CONNECT_REQUEST':
        this.processExtensionCxRequest();
        break;

      // Messages to the WS Server
      case 'LOGIN_REQUEST':
      case 'LOG_OUT':
      case 'LOGIN_REQUIRED_QUESTION':
      case 'GET_SERVER_FILTER':
      case 'SET_SERVER_FILTER':
        this.socketTx(msg.type, msg.data);
        break;

      default:
        break;
    }
  }

  processRecords(msg) {
    if (!this.config.uploadClientStories) return;
    const { data: records } = msg;
    this.addToUploadBuffer(records);
    this.socketUploadRecords(); // may be throttled
  }

  processExtensionCxRequest() {
    this.hubTx(this.fSocketConnected ? 'WS_CONNECTED' : 'WS_DISCONNECTED');
  }

  hubTx(type, data) {
    this.hub.emitMsgWithFields('WS_CLIENT', type, data, this);
  }

  // -----------------------------------------
  // Helpers
  // -----------------------------------------
  applyTimeDelta(records, tDelta) {
    /* istanbul ignore next */
    if (!records) return records;
    return records.map((record) => timmSet(record, 't', record.t + tDelta));
  }
}

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new WsClientListener(addDefaults(userConfig, DEFAULT_CONFIG), context);

export default create;
