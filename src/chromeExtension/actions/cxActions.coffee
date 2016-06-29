Promise = require 'bluebird'
Saga    = require 'redux-saga/effects'
{notify} = require 'giu'
actions = require './actions'
require 'babel-polyfill'

_sendMsg = null
_lastCredentials = null

#-------------------------------------------------
# ## Init
#-------------------------------------------------
init = (deps) ->
  {sendMsg: _sendMsg} = deps
  if not(_sendMsg?)
    throw new Error "MISSING_DEPS"

#-------------------------------------------------
# ## Connect saga
#-------------------------------------------------
connect = ->

  # Give the other party a chance at connecting
  yield Promise.delay 30

  while true
    if not yield Saga.call _isConnected
      yield Saga.call _txMsg, 'CONNECT_REQUEST'
    yield Promise.delay 2000

_isConnected = -> 
  cxState = yield Saga.select (state) -> state.cx.cxState
  return cxState is 'CONNECTED'

#-------------------------------------------------
# ## Rx message saga
#-------------------------------------------------
rxMsg = ->
  while true
    {msg} = yield Saga.take 'MSG_RECEIVED'
    {src, type, result, data} = msg
    console.log "[DT] RX #{src}/#{type}", data
    switch type
      # Page-extension connection
      when 'CX_DISCONNECTED'
        yield Saga.put {type: 'CX_DISCONNECTED'}
        yield Saga.put {type: 'WS_DISCONNECTED'}
      when 'CONNECT_REQUEST', 'CONNECT_RESPONSE'
        if type is 'CONNECT_REQUEST' 
          yield Saga.call _txMsg, 'CONNECT_RESPONSE'
        yield Saga.put {type: 'CX_CONNECTED', records: data}

      # WebSocket connection
      when 'WS_CONNECTED'
        if not yield Saga.call _isWsConnected
          yield Saga.put {type: 'WS_CONNECTED'}
          yield Saga.call _txMsg, 'LOGIN_REQUIRED_QUESTION'
          yield Saga.call _txMsg, 'GET_SERVER_FILTER'
          yield Saga.call _txMsg, 'GET_LOCAL_CLIENT_FILTER'
      when 'WS_DISCONNECTED'
        yield Saga.put {type: 'WS_DISCONNECTED'}

      # Logging in
      when 'LOGIN_REQUIRED_RESPONSE'
        {fLoginRequired} = data
        yield Saga.put {type: 'LOGIN_REQUIRED', fLoginRequired}
        if fLoginRequired and _lastCredentials
          yield Saga.put {type: 'LOGIN_STARTED'}
          yield Saga.call _txMsg, 'LOGIN_REQUEST', _lastCredentials
        else if not fLoginRequired
          yield Saga.put {type: 'LOGIN_STARTED'}
          yield Saga.call _txMsg, 'LOGIN_REQUEST', {login: '', password: ''}
      when 'SERVER_FILTER', 'LOCAL_CLIENT_FILTER'
        {filter} = data
        yield Saga.put {type, filter}
      when 'LOGIN_RESPONSE' 
        if result is 'SUCCESS'
          {login, bufferedRecords} = data
          yield Saga.put {type: 'LOGIN_SUCCEEDED', login}
          if bufferedRecords?.length 
            yield Saga.put 
              type: 'RECORDS_RECEIVED' 
              records: bufferedRecords
              fPastRecords: true
        else
          notify
            title: 'Log-in failed'
            msg: 'Please try again'
            type: 'error'
            icon: 'user'
          yield Saga.put {type: 'LOGGED_OUT'}
          _lastCredentials = null

      # Records
      when 'RECORDS' 
        yield Saga.put {type: 'RECORDS_RECEIVED', records: data}
  return

_isWsConnected = -> 
  wsState = yield Saga.select (state) -> state.cx.wsState
  return wsState is 'CONNECTED'

#-------------------------------------------------
# ## Login/logout actions
#-------------------------------------------------
logIn = (credentials) ->
  _lastCredentials = credentials
  _txMsg 'LOGIN_REQUEST', credentials
  return {type: 'LOGIN_STARTED'}

logOut = -> (dispatch) ->
  _lastCredentials = null
  _txMsg 'LOG_OUT'
  dispatch {type: 'LOGGED_OUT'}

#-------------------------------------------------
# ## Filters
#-------------------------------------------------
setServerFilter = (filter) -> -> _txMsg 'SET_SERVER_FILTER', filter
setLocalClientFilter = (filter) -> -> _txMsg 'SET_LOCAL_CLIENT_FILTER', filter

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
_txMsg = (type, data) -> _sendMsg {src: 'DT', type, data}

#-------------------------------------------------
# ## API
#-------------------------------------------------
module.exports = {
  init,
  actions: {
    logIn, logOut,
    setServerFilter, setLocalClientFilter,
  }
  sagas: [
    connect
    rxMsg
  ]
}