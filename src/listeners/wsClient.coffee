socketio = require 'socket.io-client'
timm = require 'timm'

DEFAULT_CONFIG = {}

#-------------------------------------------------
# ## Extension I/O
#-------------------------------------------------
_sendMsgToExtension = (type, data) ->
  window.postMessage {src: 'PAGE', type, data}, '*'
_initExtensionIo = (config) ->
  window.addEventListener 'message', (event) ->
    return if event.source isnt window
    {data: {src, type, data}} = event
    return if src is 'PAGE'
    ## console.log "[PG] RX #{src}/#{type}", data
  _sendMsgToExtension 'INIT'

#-------------------------------------------------
# ## Websocket I/O
#-------------------------------------------------
_initSocketIo = (config) ->
  {story} = config
  story.info "Connecting to WebSocket server..."
  socket = socketio.connect()
  socket.on 'RECORDS', _process
  socket.on 'AUTH_REQUIRED', -> _sendMsgToExtension 'AUTH_REQUIRED'
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
