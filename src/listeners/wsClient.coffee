socketio = require 'socket.io-client'
timm = require 'timm'

DEFAULT_CONFIG = {}

#-------------------------------------------------
# ## Extension I/O
#-------------------------------------------------
_fExtensionReady = false
_pendingMsgs = []
_sendMsgToExtension = (type, data) ->
  msg = {src: 'PAGE', type, data}
  if _fExtensionReady
    _doSendMsg msg
  else
    _pendingMsgs.push msg
_sendPendingMsgsToExtension = ->
  return if not _fExtensionReady
  _doSendMsg msg for msg in _pendingMsgs
  _pendingMsgs.length = 0
_doSendMsg = (msg) -> window.postMessage msg, '*'

_initExtensionIo = (config) ->
  window.addEventListener 'message', (event) ->
    return if event.source isnt window
    {data: {src, type, data}} = event
    return if src isnt 'DT'
    console.log "[PG] RX #{src}/#{type}", data
    switch type
      when 'INIT_E2E_REQ' 
        _fExtensionReady = true
        _sendMsgToExtension 'INIT_E2E_RSP'
        _sendPendingMsgsToExtension()
    return
  _sendMsgToExtension 'CONNECT_LINK'

#-------------------------------------------------
# ## Websocket I/O
#-------------------------------------------------
_initSocketIo = (config) ->
  {story} = config
  story.info "Connecting to WebSocket server..."
  socket = socketio.connect()
  socket.on 'RECORDS', _process
  socket.on 'AUTH_REQUIRED', -> _sendMsgToExtension 'SERVER_REQUIRES_AUTH'
  socket.on 'connect', -> story.info "WebSocket connected"

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
# Relay records coming from local stories
_process = (records, config) ->
  ## console.log "[PG] RX PAGE/RECORDS #{records.length} records"
  _sendMsgToExtension 'RECORDS', records

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (story, baseConfig = {}) ->
  config = timm.addDefaults baseConfig, DEFAULT_CONFIG, {story}
  listener =
    type: 'WS_CLIENT'
    init: -> 
      _initExtensionIo config
      _initSocketIo config
    process: (record) -> _process [record], config
    config: (newConfig) -> config = timm.merge config, newConfig
  listener

module.exports = {
  create,
}
