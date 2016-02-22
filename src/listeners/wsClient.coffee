socketio = require 'socket.io-client'
timm = require 'timm'

DEFAULTS = {}

#-------------------------------------------------
# ## I/O
#-------------------------------------------------
_ioInit = (options) ->
  {story} = options
  story.info "Connecting to web-socket server..."
  socket = socketio.connect()
  socket.on 'connect', -> story.info "Connected"
  socket.on 'AUTH_REQUIRED', ->
    story.warn "TODO: Authenticate the user when the server requires it"
  socket.on 'REC', _process

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
_process = (record, options) ->
  console.log "#{record.src} #{record.msg}"

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (story, options = {}) ->
  _options = timm.addDefaults options, DEFAULTS, {story}
  _ioInit _options
  listener =
    type: 'WS_CLIENT'
    process: (record) -> _process record, _options
    config: (options) -> _options = timm.merge _options, options
  listener

module.exports = {
  create,
}
