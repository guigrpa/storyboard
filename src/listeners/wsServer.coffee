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
LOG_SRC = 'storyboard'
_ioStandalone = null
_ioServerAdaptor = null

#-------------------------------------------------
# ## WebSocket I/O
#-------------------------------------------------
_socketInit = (config) ->
  return if _ioStandalone   # only one server
  {port, story} = config

  # Launch stand-alone log server
  expressApp = express()
  expressApp.use express.static path.join(__dirname, '../../serverLogsApp')
  httpServer = http.createServer expressApp
  _ioStandalone = socketio httpServer
  _ioStandalone.on 'connection', (socket) -> _socketOnConnection socket, config
  httpServer.listen port
  story.info LOG_SRC, "Server logs available on port #{chalk.cyan port}"

  # If a main application server is also provided, 
  # launch another log server on the same application port
  if config.httpServer
    _ioServerAdaptor = socketio config.httpServer
    _ioServerAdaptor.on 'connection', (socket) -> _socketOnConnection socket, config
    port2 = config.httpServer.address().port
    story.info LOG_SRC, "Server logs also available through main HTTP server on port #{chalk.cyan port2}"
  return

_socketOnConnection = (socket, config) ->
  socket.sbAuthenticated = not config.authenticate?
  socket.sbConfig = config
  if socket.sbAuthenticated
    socket.join 'AUTHENTICATED'
  else
    _socketTxMsg socket, {type: 'LOGIN_REQUIRED'}
  socket.on 'MSG', (msg) -> _socketRxMsg socket, msg

_socketRxMsg = (socket, msg) ->
  {type, data} = msg
  switch type
    when 'LOGIN_REQUEST'
      {authenticate, story} = socket.sbConfig
      {login} = credentials = data
      Promise.resolve (socket.sbAuthenticated) \
        or (not authenticate?) or authenticate(credentials)
      .then (fAuthValid) ->
        if fAuthValid
          _socketTxMsg socket, {type: 'LOGIN_SUCCEEDED'}
          story.info LOG_SRC, "User '#{login}' authenticated successfully"
          socket.sbAuthenticated = true
          socket.join 'AUTHENTICATED'
        else
          story.warn LOG_SRC, "User '#{login}' authentication failed"
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
  msg = {type: 'RECORDS', data: [].concat(_queue)}
  _ioStandalone?.to('AUTHENTICATED').emit 'MSG', msg
  _ioServerAdaptor?.to('AUTHENTICATED').emit 'MSG', msg
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
