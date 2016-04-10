socketio    = require 'socket.io-client'
timm        = require 'timm'
treeLines   = require 'storyboard-core/lib/treeLines'
ifExtension = require './interfaceExtension'
k           = require '../gral/constants'

DEFAULT_CONFIG = {}

#-------------------------------------------------
# ## Extension I/O
#-------------------------------------------------
_extensionRxMsg = (msg) ->
  {type, data} = msg
  if type is 'CONNECT_REQUEST'
    rspType = if _fSocketConnected then 'WS_CONNECTED' else 'WS_DISCONNECTED'
    ifExtension.tx {type: rspType}
  if not((type is 'CONNECT_REQUEST') or (type is 'CONNECT_RESPONSE'))
    _socketTxMsg {type, data}
  return

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
      ifExtension.tx {type: 'WS_CONNECTED'}
      _fSocketConnected = true
    socketDisconnected = ->
      story.info 'storyboard', "WebSocket disconnected"
      ifExtension.tx {type: 'WS_DISCONNECTED'}
      _fSocketConnected = false
    _socketio.on 'connect', socketConnected
    _socketio.on 'reconnect', socketConnected
    _socketio.on 'disconnect', socketDisconnected
    _socketio.on 'error', socketDisconnected
    _socketio.on 'MSG', _socketRxMsg
  _socketio.sbConfig = config

_socketRxMsg = (msg) -> ifExtension.tx msg
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
  listener =
    type: 'WS_CLIENT'
    init: -> 
      _socketInit config
      ifExtension.rx _extensionRxMsg
    # Nothing to be done with hub records; we're just
    # concerned with relaying records from WS
    process: (record) -> 
  listener

module.exports = {
  create,
}
