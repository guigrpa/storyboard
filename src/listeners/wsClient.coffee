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
    story.warn "TODO: Authenticate the user when the server requires it"
  socket.on 'connect', -> story.info "WebSocket connected"
  window.addEventListener 'message', (event) ->
    return if event.source isnt window
    {data: {type, subtype, data}} = event
    return if type isnt 'FROM_CONTENT_SCRIPT'
    console.log "#{type}/#{subtype}"

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
_process = (record, options) ->
  console.log "#{record.src} #{record.msg}"
  window.postMessage {type: 'FROM_PAGE', subtype: 'REC', data: record}, '*'

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
