Promise = require 'bluebird'
Saga    = require 'redux-saga/effects'
actions = require './actions'

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
  return if yield Saga.call _isConnected

  # If the other party hasn't started, we try to establish
  yield Saga.call _txMsg, 'CONNECT_REQUEST'

  # If it's taking long, issue a warning to the user
  yield Promise.delay 2000
  return if yield Saga.call _isConnected
  yield Saga.put {type: 'CX_TAKING_LONG'}

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
    ## console.log "[DT-SAGA] RX #{src}/#{type}", data
    switch type
      when 'CONNECT_REQUEST', 'CONNECT_RESPONSE'
        if type is 'CONNECT_REQUEST' 
          yield Saga.call _txMsg, 'CONNECT_RESPONSE'
        yield Saga.put {type: 'CX_SUCCEEDED', records: data}
      when 'LOGIN_REQUIRED'
        yield Saga.put {type: 'LOGIN_REQUIRED'}
        if _lastCredentials
          yield Saga.put {type: 'LOGIN_STARTED'}
          yield Saga.call _txMsg, 'LOGIN_REQUEST', _lastCredentials
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
          yield Saga.put {type: 'LOGIN_FAILED'}
          _lastCredentials = null
      when 'RECORDS' 
        yield Saga.put {type: 'RECORDS_RECEIVED', records: data}
  return

#-------------------------------------------------
# ## Login/logout actions
#-------------------------------------------------
logIn = (credentials) ->
  _lastCredentials = credentials
  _txMsg 'LOGIN_REQUEST', credentials
  return {type: 'LOGIN_STARTED'}

# TODO
logOut = ->

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
  }
  sagas: [
    connect
    rxMsg
  ]
}