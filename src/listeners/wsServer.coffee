_ = require '../vendor/lodash'
path = require 'path'
http = require 'http'
express = require 'express'
socketio = require 'socket.io'
Promise = require 'bluebird'
chalk = require 'chalk'
timm = require 'timm'

DEFAULTS = 
  port: 8090
  throttle: 200
  authenticate: null
io = null

#-------------------------------------------------
# ## I/O
#-------------------------------------------------
_ioInit = (options) ->
  return if io   # only one server
  {authenticate, port, story} = options
  expressApp = express()
  expressApp.use express.static path.join(__dirname, '../../serverLogsApp')
  httpServer = http.createServer expressApp
  io = socketio httpServer
  io.on 'connection', (socket) ->
    socket.sbAuthenticated = not authenticate?
    if socket.sbAuthenticated
      socket.join 'AUTHENTICATED'
    else
      socket.emit 'AUTH_REQUIRED'
    socket.on 'AUTH', ({login, password}, fnReply) ->
      return if socket.sbAuthenticated
      return if not authenticate?
      Promise.resolve authenticate login, password
      .then (fAuth) ->
        if fAuth
          fnReply {result: 'SUCCESS'}
          socket.sbAuthenticated = true
          socket.join 'AUTHENTICATED'
        else
          fnReply {result: 'ERROR', error: 'AUTH_FAILED'}
      return
  httpServer.listen port
  story.info "Listening on port #{chalk.cyan port}..."
  return

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
_queue = []
_process = (record, options, emit) ->
  _queue.push record
  emit()

_emit = ->
  ## console.log "#{new Date().toISOString()} Flushing..."
  if io
    for record in _queue
      io.to('AUTHENTICATED').emit 'REC', record
  _queue.length = 0
  return

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (story, options = {}) ->
  _options = timm.addDefaults options, DEFAULTS, {story}
  _throttledEmit = _.throttle _emit, _options.throttle
  _ioInit _options
  listener =
    type: 'WS_SERVER'
    process: (record) -> _process record, _options, _throttledEmit
    config: (options) -> _options = timm.merge _options, options
  listener

module.exports = {
  create,
}
