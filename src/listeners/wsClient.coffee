socketio    = require 'socket.io-client'
timm        = require 'timm'
treeLines   = require '../gral/treeLines'
k           = require '../gral/constants'

DEFAULT_CONFIG = {}

_window = null

#-------------------------------------------------
# ## Extension I/O
#-------------------------------------------------
_fExtensionInitialised = false
_fExtensionReady = false

_extensionInit = (config) ->
  return if _fExtensionInitialised
  _fExtensionInitialised = true
  _window?.addEventListener 'message', (event) ->
    {source, data: msg} = event
    return if source isnt _window
    ## {data: {src, type, data}} = event
    _extensionRxMsg msg
  _extensionTxMsg {type: 'CONNECT_REQUEST'}

_extensionRxMsg = (msg) ->
  {src, type, data} = msg
  return if src isnt 'DT'
  ## console.log "[PG] RX #{src}/#{type}", data
  switch type
    when 'CONNECT_REQUEST', 'CONNECT_RESPONSE'
      _fExtensionReady = true
      if type is 'CONNECT_REQUEST' 
        _extensionTxMsg {type: 'CONNECT_RESPONSE'}
        if _fSocketConnected
          _extensionTxMsg {type: 'WS_CONNECTED'}
        else
          _extensionTxMsg {type: 'WS_DISCONNECTED'}
      _extensionTxPendingMsgs()
    else
      _socketTxMsg {type, data}
  return

_extensionMsgQueue = []
_extensionTxMsg = (msg) ->
  msg.src = 'PAGE'
  if _fExtensionReady or (msg.type is 'CONNECT_REQUEST')
    _extensionDoTxMsg msg
  else
    _extensionMsgQueue.push msg
_extensionTxPendingMsgs = ->
  return if not _fExtensionReady
  _extensionDoTxMsg msg for msg in _extensionMsgQueue
  _extensionMsgQueue.length = 0
_extensionDoTxMsg = (msg) -> _window?.postMessage msg, '*'

#-------------------------------------------------
# ## Websocket I/O
#-------------------------------------------------
_socketio = null
_fSocketConnected = false
_socketInit = (config) ->
  {mainStory: story} = config
  story.info 'storyboard', "Connecting to WebSocket server..."
  if not _socketio
    url = k.WS_NAMESPACE
    if process.env.TEST_BROWSER 
      url = "http://localhost:8090#{k.WS_NAMESPACE}"
    _socketio = socketio.connect url
    socketConnected = ->
      story.info 'storyboard', "WebSocket connected"
      _extensionTxMsg {type: 'WS_CONNECTED'}
      _fSocketConnected = true
    socketDisconnected = ->
      story.info 'storyboard', "WebSocket disconnected"
      _extensionTxMsg {type: 'WS_DISCONNECTED'}
      _fSocketConnected = false
    _socketio.on 'connect', socketConnected
    _socketio.on 'reconnect', socketConnected
    _socketio.on 'disconnect', socketDisconnected
    _socketio.on 'error', socketDisconnected
    _socketio.on 'MSG', _socketRxMsg
  _socketio.sbConfig = config

_socketRxMsg = (msg) -> _extensionTxMsg msg
_socketTxMsg = (msg) ->
  ### istanbul ignore if ###
  if not _socketio
    console.error "Cannot send '#{msg.type}' message to server: socket unavailable"
    return
  _socketio.emit 'MSG', msg

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
# Process client-side attachments, exactly the same
# way as in the WS Server listener
_preprocessAttachments = (record) -> 
  return record if not record.obj?
  return timm.set record, 'obj', treeLines(record.obj)

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (baseConfig) ->
  config = timm.addDefaults baseConfig, DEFAULT_CONFIG
  _window = if process.env.TEST_BROWSER then config._mockWindow else window
  listener =
    type: 'WS_CLIENT'
    init: -> 
      _extensionInit config
      _socketInit config
    # Relay records coming from local stories
    process: (record) -> 
      ## console.log "[PG] RX PAGE/RECORDS #{records.length} records"
      _extensionTxMsg {type: 'RECORDS', data: [_preprocessAttachments record]}
    ## config: (newConfig) -> config = timm.merge config, newConfig
  listener

module.exports = {
  create,
}
