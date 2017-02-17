import { merge, set as timmSet } from 'timm';

const INITIAL_STATE = {
  cxState: 'DISCONNECTED',  // connection with the WsClient listener ("the" page)
  fLoginRequired: null,
  serverFilter: null,
  localClientFilter: null,
  loginState: 'LOGGED_OUT',
  wsState: 'DISCONNECTED',  // connection btw WsClient listener and WsServer listener
  login: null,
};

const reducer = (state = INITIAL_STATE, action) => {
  switch (action.type) {
    // -------------------------------------------------
    // Connection-related actions (page-extension connection)
    // -------------------------------------------------
    case 'CX_CONNECTED': return timmSet(state, 'cxState', 'CONNECTED');
    case 'CX_DISCONNECTED': return timmSet(state, 'cxState', 'DISCONNECTED');

    // -------------------------------------------------
    // WebSocket-related actions
    // -------------------------------------------------
    case 'WS_CONNECTED': return timmSet(state, 'wsState', 'CONNECTED');
    case 'WS_DISCONNECTED': return timmSet(state, 'wsState', 'DISCONNECTED');

    // -------------------------------------------------
    // Login-related actions
    // -------------------------------------------------
    case 'LOGIN_REQUIRED': return timmSet(state, 'fLoginRequired', action.fLoginRequired);
    case 'LOGIN_STARTED': return timmSet(state, 'loginState', 'LOGGING_IN');
    case 'LOGIN_SUCCEEDED':
      return merge(state, {
        login: action.login,
        loginState: 'LOGGED_IN',
      });
    case 'LOGGED_OUT':
      return merge(state, {
        login: null,
        loginState: 'LOGGED_OUT',
      });

    // -------------------------------------------------
    // Filters
    // -------------------------------------------------
    case 'SERVER_FILTER': return timmSet(state, 'serverFilter', action.filter);
    case 'LOCAL_CLIENT_FILTER': return timmSet(state, 'localClientFilter', action.filter);
    default:
      return state;
  }
};

export default reducer;
