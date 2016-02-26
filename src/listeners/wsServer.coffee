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
  longTermBufferLength: 1000
LOG_SRC = 'storyboard'
_ioStandalone = null
_ioServerAdaptor = null

#-------------------------------------------------
# ## WebSocket I/O
#-------------------------------------------------
_socketInit = (config) ->
  return if _ioStandalone   # only one server
  {port, mainStory: story} = config

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
  {mainStory: story} = socket.sbConfig
  switch type
    when 'LOGIN_REQUEST'
      {authenticate} = socket.sbConfig
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
    when 'BUFFERED_RECORDS_REQUEST'
      if not socket.sbAuthenticated
        _socketTxMsg socket, {type: 'BUFFERED_RECORDS_RESPONSE', error: 'AUTH_REQUIRED'}
        return
      {hub} = socket.sbConfig
      _socketTxMsg socket, {type: 'BUFFERED_RECORDS_RESPONSE', data: hub.getBufferedRecords()}
    else
      story.warn LOG_SRC, "Unknown message type '#{type}'"
  return

_socketTxMsg = (socket, msg) -> socket.emit 'MSG', msg

_broadcastBuf = []
_enqueueRecord = (record, config) -> _broadcastBuf.push record

_socketBroadcast = ->
  ## console.log "#{new Date().toISOString()} Flushing #{_broadcastBuf.length} records..."
  msg = {type: 'RECORDS', data: _broadcastBuf}
  _ioStandalone?.to('AUTHENTICATED').emit 'MSG', msg
  _ioServerAdaptor?.to('AUTHENTICATED').emit 'MSG', msg
  _broadcastBuf.length = 0
  return

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
_process = (config) -> 
  if config.throttle
    finalBroadcast = _.throttle _socketBroadcast, config.throttle
  else
    finalBroadcast = _socketBroadcast
  return (record) ->
    _enqueueRecord record, config
    finalBroadcast()

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (baseConfig) ->
  config = timm.addDefaults baseConfig, DEFAULT_CONFIG
  listener =
    type: 'WS_SERVER'
    init: -> _socketInit config
    process: _process config
    config: (newConfig) -> config = timm.merge config, newConfig
  listener

module.exports = {
  create,
}
