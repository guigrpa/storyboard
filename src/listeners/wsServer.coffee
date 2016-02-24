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
# ## WebSocket I/O
#-------------------------------------------------
_socketInit = (config) ->
  return if io   # only one server
  {authenticate, port, story} = config
  expressApp = express()
  expressApp.use express.static path.join(__dirname, '../../serverLogsApp')
  httpServer = http.createServer expressApp
  io = socketio httpServer
  io.on 'connection', (socket) ->
    socket.sbAuthenticated = not authenticate?
    socket.sbConfig = config
    if socket.sbAuthenticated
      socket.join 'AUTHENTICATED'
    else
      _socketTxMsg socket, {type: 'LOGIN_REQUIRED'}
    socket.on 'MSG', (msg) -> _socketRxMsg socket, msg
  httpServer.listen port
  story.info "Listening on port #{chalk.cyan port}..."
  return

_socketRxMsg = (socket, msg) ->
  {type, data} = msg
  switch type
    when 'LOGIN_REQUEST'
      authenticate = socket.sbConfig.authenticate
      credentials = data
      Promise.resolve (socket.sbAuthenticated) \
        or (not authenticate?) or authenticate(credentials)
      .then (fAuthValid) ->
        if fAuthValid
          _socketTxMsg socket, {type: 'LOGIN_SUCCEEDED'}
          socket.sbAuthenticated = true
          socket.join 'AUTHENTICATED'
        else
          _socketTxMsg socket, {type: 'LOGIN_FAILED'}
      return

_socketTxMsg = (socket, msg) -> socket.emit 'MSG', msg

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
_queue = []
_process = (record, config, emit) ->
  _queue.push record
  emit()

_emit = ->
  ## console.log "#{new Date().toISOString()} Flushing #{_queue.length} records..."
  io?.to('AUTHENTICATED').emit 'MSG', 
    type: 'RECORDS'
    data: [].concat(_queue)
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
    init: -> _socketInit config
    process: (record) -> _process record, config, _finalEmit
    config: (newConfig) -> config = timm.merge config, newConfig
  listener

module.exports = {
  create,
}
