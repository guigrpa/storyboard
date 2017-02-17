import * as Redux from 'redux';
import thunk from 'redux-thunk';
import sagaInit from 'redux-saga';
import appReducer from '../reducers/appReducer';  // eslint-disable-line
// DevTools = require '../components/990-reduxDevTools'
import cxSagas from '../actions/cxActions';
import storySagas from '../actions/storyActions';

const createStore = () => {
  const allSagas = []
    .concat(cxSagas)
    .concat(storySagas);
  const saga = sagaInit(...allSagas);
  const addMiddlewares = Redux.applyMiddleware(thunk, saga);
  const storeEnhancers = addMiddlewares;

  // # if process.env.NODE_ENV isnt 'production'
  // #   devToolsEnhancer = DevTools.instrument()

  // ##   createLogger = require 'redux-logger'
  // ##   logger = createLogger
  // ##     predicate: (getState, action) ->
  // ##       return not(action.type in ['EFFECT_TRIGGERED', 'EFFECT_RESOLVED', 'MSG_RECEIVED'])
  // ##   addMiddlewares = Redux.applyMiddleware thunk, saga, logger

  // ##   # Use Chrome extension "Redux DevTools", if available
  // ##   devToolsEnhancer = window?.devToolsExtension?() ? ((o) -> o)

  // #  storeEnhancers = Redux.compose addMiddlewares, devToolsEnhancer

  const store = Redux.createStore(appReducer, storeEnhancers);
  return store;
};

export default createStore;
