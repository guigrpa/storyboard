actions = require './actions'
Saga    = require 'redux-saga/effects'

_sendMsg = null
_store = null

init = (deps) ->
  {sendMsg: _sendMsg} = deps
  if not(_sendMsg?)
    throw new Error "MISSING_DEPS"
  #setTimeout => 
  #  return if _store.getState().cx.fConnected
  #  _txMsg 'CONNECT_REQUEST'
  #, 30

sagaWatchMsgReceived = ->
  while true
    {msg} = yield Saga.take 'MSG_RECEIVED'
    yield _rxMsg msg

_rxMsg = (msg) ->
  {src, type, result, data} = msg
  console.log "[DT-SAGA] RX #{src}/#{type}", data
  switch type
    when 'CONNECT_REQUEST', 'CONNECT_RESPONSE'
      if type is 'CONNECT_REQUEST' then _txMsg 'CONNECT_RESPONSE'
      yield Saga.put {type: 'CONNECTED', records: data}
    when 'RECORDS' 
      yield Saga.put {type: 'RECORDS_RECEIVED', records: data}
  return

_txMsg = (type, data) ->
  _sendMsg {src: 'DT', type, data}

module.exports = {
  init,
  sagaWatchMsgReceived,
}