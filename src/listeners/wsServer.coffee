_ = require '../vendor/lodash'
path = require 'path'
http = require 'http'
express = require 'express'
socketio = require 'socket.io'
Promise = require 'bluebird'
chalk = require 'chalk'
timm = require 'timm'

DEFAULT_CONFIG = 
  port: 8090
  throttle: 200
  authenticate: null
io = null

#-------------------------------------------------
# ## I/O
#-------------------------------------------------
_initSocketIo = (config) ->
  return if io   # only one server
  {authenticate, port, story} = config
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
_process = (record, config, emit) ->
  _queue.push record
  emit()

_emit = ->
  ## console.log "#{new Date().toISOString()} Flushing..."
  io?.to('AUTHENTICATED').emit 'RECORDS', [].concat(_queue)
  _queue.length = 0
  return

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (story, baseConfig = {}) ->
  config = timm.addDefaults baseConfig, DEFAULT_CONFIG, {story}
  if config.throttle
    _finalEmit = _.throttle _emit, config.throttle
  else
    _finalEmit = _emit
  listener =
    type: 'WS_SERVER'
    init: -> _initSocketIo config
    process: (record) -> _process record, config, _finalEmit
    config: (newConfig) -> config = timm.merge config, newConfig
  listener

module.exports = {
  create,
}
