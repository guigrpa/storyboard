socketio = require 'socket.io-client'
timm = require 'timm'

DEFAULTS = {}

_sendMsgToExtension = (type, data) ->
  window.postMessage {src: 'PAGE', type, data}, '*'

#-------------------------------------------------
# ## I/O
#-------------------------------------------------
_ioInit = (options) ->
  {story} = options
  story.info "Connecting to WebSocket server..."
  socket = socketio.connect()
  socket.on 'REC', _process
  socket.on 'AUTH_REQUIRED', -> _sendMsgToExtension 'AUTH_REQUIRED'
  socket.on 'connect', -> story.info "WebSocket connected"
  window.addEventListener 'message', (event) ->
    return if event.source isnt window
    {data: {src, type, data}} = event
    return if src is 'PAGE'
    ## console.log "[PG] RX #{src}/#{type}", data
  _sendMsgToExtension 'INIT'

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
_process = (record, options) ->
  ## console.log "[PG] RX PAGE/REC #{record.src} #{record.msg}"
  _sendMsgToExtension 'REC', record

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (story, options = {}) ->
  _options = timm.addDefaults options, DEFAULTS, {story}
  listener =
    type: 'WS_CLIENT'
    init: -> _ioInit _options
    process: (record) -> _process record, _options
    config: (options) -> _options = timm.merge _options, options
  listener

module.exports = {
  create,
}
