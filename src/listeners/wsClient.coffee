socketio = require 'socket.io-client'
timm = require 'timm'

DEFAULTS = {}

#-------------------------------------------------
# ## I/O
#-------------------------------------------------
_ioInit = (options) ->
  {story} = options
  story.info "Connecting to WebSocket server..."
  socket = socketio.connect()
  socket.on 'REC', _process
  socket.on 'AUTH_REQUIRED', ->
    window.postMessage {src: 'PAGE', type: 'AUTH_REQUIRED'}, '*'
  socket.on 'connect', -> story.info "WebSocket connected"
  window.addEventListener 'message', (event) ->
    return if event.source isnt window
    {data: {src, type, data}} = event
    return if src is 'PAGE'
    console.log "[PG] #{src}/#{type}", data

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
_process = (record, options) ->
  console.log "#{record.src} #{record.msg}"
  window.postMessage {src: 'PAGE', type: 'REC', data: record}, '*'

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
