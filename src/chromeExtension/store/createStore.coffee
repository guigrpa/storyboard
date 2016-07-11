_                     = require 'lodash'
Redux                 = require 'redux'
thunk                 = require('redux-thunk').default
Saga                  = require('redux-saga').default
appReducer            = require '../reducers/appReducer'
DevTools              = require '../components/990-reduxDevTools'

createStore = ->
  allSagas = _.flatten [
    require('../actions/cxActions').sagas
    require('../actions/storyActions').sagas
  ]
  saga = Saga allSagas...
  addMiddlewares = Redux.applyMiddleware thunk, saga
  storeEnhancers = addMiddlewares

  if process.env.NODE_ENV isnt 'production'
    devToolsEnhancer = DevTools.instrument()

  ##   createLogger = require 'redux-logger'
  ##   logger = createLogger
  ##     predicate: (getState, action) -> 
  ##       return not(action.type in ['EFFECT_TRIGGERED', 'EFFECT_RESOLVED', 'MSG_RECEIVED'])
  ##   addMiddlewares = Redux.applyMiddleware thunk, saga, logger
  ## 
  ##   # Use Chrome extension "Redux DevTools", if available
  ##   devToolsEnhancer = window?.devToolsExtension?() ? ((o) -> o)

    storeEnhancers = Redux.compose addMiddlewares, devToolsEnhancer

  store = Redux.createStore appReducer, storeEnhancers
  store

module.exports = createStore
