/* eslint-disable no-constant-condition, no-console */

import Promise from 'bluebird';
import Saga from 'redux-saga/effects';
import { notify } from 'giu';

let sendMsg;
let lastCredentials = null;

// =============================================
// Init
// =============================================
const init = ({ sendMsg: sendMsg0 }) => {
  sendMsg = sendMsg0;
  if (!sendMsg) throw new Error('MISSING_DEPS');
};

// =============================================
// Connect saga
// =============================================
function* connect() {
  // Give the other party a chance at connecting
  yield Promise.delay(30);

  while (true) {
    if (!(yield Saga.call(isConnected))) {
      yield Saga.call(txMsg, 'CONNECT_REQUEST');
    }
    yield Promise.delay(2000);
  }
}

function* isConnected() {
  const cxState = yield Saga.select((state) => state.cx.cxState);
  return cxState === 'CONNECTED';
}

// =============================================
// Rx message saga
// =============================================
function* rxMsg() {
  while (true) {
    const { msg } = yield Saga.take('MSG_RECEIVED');
    const { src, type, result, data, hubId } = msg;
    console.log(`[DT] RX ${src}/${type}`, data);
    let fLoginRequired;
    let filter;
    let login;
    let bufferedRecords;
    switch (type) {
      // Page-extension connection
      case 'CX_DISCONNECTED':
        yield Saga.put({ type: 'CX_DISCONNECTED' });
        yield Saga.put({ type: 'WS_DISCONNECTED' });
        break;
      case 'CONNECT_REQUEST':
      case 'CONNECT_RESPONSE':
        if (type === 'CONNECT_REQUEST') {
          yield Saga.call(txMsg, 'CONNECT_RESPONSE');
        }
        yield Saga.put({ type: 'CX_CONNECTED', hubId });
        break;

      // WebSocket connection
      case 'WS_CONNECTED':
        if (!(yield Saga.call(isWsConnected))) {
          yield Saga.put({ type: 'WS_CONNECTED' });
          yield Saga.call(txMsg, 'LOGIN_REQUIRED_QUESTION');
          yield Saga.call(txMsg, 'GET_SERVER_FILTER');
          yield Saga.call(txMsg, 'GET_LOCAL_CLIENT_FILTER');
        }
        break;
      case 'WS_DISCONNECTED':
        yield Saga.put({ type: 'WS_DISCONNECTED' });
        break;

      // Logging in
      case 'LOGIN_REQUIRED_RESPONSE':
        fLoginRequired = data.fLoginRequired;
        yield Saga.put({ type: 'LOGIN_REQUIRED', fLoginRequired });
        if (fLoginRequired && lastCredentials) {
          yield Saga.put({ type: 'LOGIN_STARTED' });
          yield Saga.call(txMsg, 'LOGIN_REQUEST', lastCredentials);
        } else if (!fLoginRequired) {
          yield Saga.put({ type: 'LOGIN_STARTED' });
          yield Saga.call(txMsg, 'LOGIN_REQUEST', { login: '', password: '' });
        }
        break;
      case 'SERVER_FILTER':
      case 'LOCAL_CLIENT_FILTER':
        filter = data.filter;
        yield Saga.put({ type, filter });
        break;
      case 'LOGIN_RESPONSE':
        if (result === 'SUCCESS') {
          login = data.login;
          bufferedRecords = data.bufferedRecords;
          yield Saga.put({ type: 'LOGIN_SUCCEEDED', login });
          if (bufferedRecords && bufferedRecords.length) {
            yield Saga.put({
              type: 'RECORDS_RECEIVED',
              records: bufferedRecords,
              fPastRecords: true,
            });
          }
        } else {
          notify({
            title: 'Log-in failed',
            msg: 'Please try again',
            type: 'error',
            icon: 'user',
          });
          yield Saga.put({ type: 'LOGGED_OUT' });
          lastCredentials = null;
        }
        break;

      // Records
      case 'RECORDS':
        yield Saga.put({ type: 'RECORDS_RECEIVED', records: data });
        break;

      default: break;
    }
  }
}

function* isWsConnected() {
  const wsState = yield Saga.select((state) => state.cx.wsState);
  return wsState === 'CONNECTED';
}

// =============================================
// Login/logout actions
// =============================================
const logIn = (credentials) => {
  lastCredentials = credentials;
  txMsg('LOGIN_REQUEST', credentials);
  return { type: 'LOGIN_STARTED' };
};

const logOut = () => (dispatch) => {
  lastCredentials = null;
  txMsg('LOG_OUT');
  dispatch({ type: 'LOGGED_OUT' });
};

// =============================================
// Filters
// =============================================
const setServerFilter = (filter) => () => {
  txMsg('SET_SERVER_FILTER', filter);
};

const setLocalClientFilter = (filter) => () => {
  txMsg('SET_LOCAL_CLIENT_FILTER', filter);
};

// =============================================
// Helpers
// =============================================
const txMsg = (type, data) => {
  sendMsg({ src: 'DT', type, data });
};

// =============================================
// API
// =============================================
const sagas = [connect, rxMsg];
export default sagas;
export {
  init as _cxInit,
  logIn, logOut,
  setServerFilter,
  setLocalClientFilter,
};
