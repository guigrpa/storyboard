socketio = require 'socket.io-client'
timm = require 'timm'

DEFAULT_CONFIG = {}

#-------------------------------------------------
# ## Extension I/O
#-------------------------------------------------
_fExtensionReady = false
_extensionMsgQueue = []

_extensionInit = (config) ->
  window.addEventListener 'message', (event) ->
    {source, data: msg} = event
    return if source isnt window
    {data: {src, type, data}} = event
    _extensionRxMsg msg
  _extensionTxMsg 'CONNECT_LINK'

_extensionRxMsg = (msg) ->
  {src, type, data} = msg
  return if src isnt 'DT'
  console.log "[PG] RX #{src}/#{type}", data
  switch type
    when 'INIT_E2E_REQUEST' 
      _fExtensionReady = true
      _extensionTxMsg 'INIT_E2E_RESPONSE'
      _extensionTxPendingMsgs()
    when 'LOGIN_REQUEST'
      _socketTxMsg {type, data}
  return

_extensionTxMsg = (type, data) ->
  msg = {src: 'PAGE', type, data}
  if _fExtensionReady or (type is 'CONNECT_LINK')
    _extensionDoTxMsg msg
  else
    _extensionMsgQueue.push msg
_extensionTxPendingMsgs = ->
  return if not _fExtensionReady
  _extensionDoTxMsg msg for msg in _extensionMsgQueue
  _extensionMsgQueue.length = 0
_extensionDoTxMsg = (msg) -> window.postMessage msg, '*'

#-------------------------------------------------
# ## Websocket I/O
#-------------------------------------------------
_socket = null
_socketInit = (config) ->
  {story} = config
  story.info "Connecting to WebSocket server..."
  _socket = socketio.connect()
  _socket.sbConfig = config
  _socket.on 'connect', -> story.info "WebSocket connected"
  _socket.on 'MSG', _socketRxMsg

_socketRxMsg = (msg) ->
  {type, data} = msg
  switch type
    when 'LOGIN_REQUIRED', 'LOGIN_SUCCEEDED', 'LOGIN_FAILED', \
         'RECORDS'
      _extensionTxMsg type, data
    else
      console.warn "Unknown message from server: '#{type}'"

_socketTxMsg = (msg) ->
  if not _socket
    console.error "Cannot send '#{msg.type}' message to server: socket unavailable"
    return
  _socket.emit 'MSG', msg

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (story, baseConfig = {}) ->
  config = timm.addDefaults baseConfig, DEFAULT_CONFIG, {story}
  listener =
    type: 'WS_CLIENT'
    init: -> 
      _extensionInit config
      _socketInit config
    # Relay records coming from local stories
    process: (record) -> 
      ## console.log "[PG] RX PAGE/RECORDS #{records.length} records"
      _extensionTxMsg 'RECORDS', [record]
    config: (newConfig) -> config = timm.merge config, newConfig
  listener

module.exports = {
  create,
}
