_           = require '../vendor/lodash'
path        = require 'path'
http        = require 'http'
express     = require 'express'
socketio    = require 'socket.io'
Promise     = require 'bluebird'
chalk       = require 'chalk'
timm        = require 'timm'
treeLines   = require 'storyboard-core/lib/treeLines'
k           = require '../gral/constants'

DEFAULT_CONFIG = 
  port: 8090
  throttle: 200
  authenticate: null

LOG_SRC = 'storyboard'
SOCKET_ROOM = 'authenticated'

_ioStandaloneServer = null
_ioStandaloneNamespace = null
_ioServerAdaptor = null

#-------------------------------------------------
# ## WebSocket I/O
#-------------------------------------------------
_socketInit = (config) ->
  return if _ioStandaloneNamespace   # only one server
  {port, mainStory} = config

  # Launch stand-alone log server
  if port?
    _httpInitError = (err) ->
      mainStory.error LOG_SRC, "Error initialising standalone server logs on port #{chalk.cyan port}:", attach: err
    try
      expressApp = express()
      expressApp.use express.static path.join(__dirname, '../../serverLogsApp')
      httpServer = http.createServer expressApp
      httpServer.on 'error', _httpInitError
      httpServer.on 'listening', ->
        mainStory.info LOG_SRC, "Server logs available on port #{chalk.cyan httpServer.address().port}"
      _ioStandaloneServer = socketio httpServer
      _ioStandaloneNamespace = _ioStandaloneServer.of k.WS_NAMESPACE
      _ioStandaloneNamespace.on 'connection', (socket) -> _socketOnConnection socket, config
      httpServer.listen port
    catch err
      _httpInitError err

  # If a main application server is also provided, 
  # launch another log server on the same application port
  if config.socketServer
    _ioServerAdaptor = config.socketServer.of k.WS_NAMESPACE
  else if config.httpServer
    _ioServerAdaptor = socketio(config.httpServer).of k.WS_NAMESPACE
  if _ioServerAdaptor
    _ioServerAdaptor.on 'connection', (socket) -> _socketOnConnection socket, config
    _http2InitError = (err) ->
      mainStory.error LOG_SRC, "Error initialising log server adaptor:", attach: err
    try
      httpServer2 = _ioServerAdaptor.server.httpServer
      httpServer2.on 'error', _http2InitError
      httpServer2.on 'listening', ->
        port2 = httpServer2.address().port
        mainStory.info LOG_SRC, "Server logs available through main HTTP server on port #{chalk.cyan port2}"
    catch err
      _http2InitError err
  return

_socketShutDown = (config) ->
  _ioStandaloneServer?.close()
  _ioStandaloneServer = _ioStandaloneNamespace = null
  _ioServerAdaptor?.close?()
  _ioServerAdaptor = null
  return

_socketOnConnection = (socket, config) ->
  socket.sbAuthenticated = not config.authenticate?
  socket.sbConfig = config
  if socket.sbAuthenticated
    socket.join SOCKET_ROOM
  socket.on 'MSG', (msg) -> _socketRxMsg socket, msg

_socketRxMsg = (socket, msg) ->
  {type, data} = msg
  {mainStory, hub} = socket.sbConfig
  switch type
    when 'LOGIN_REQUEST'
      {authenticate} = socket.sbConfig
      {login} = credentials = data
      Promise.resolve (socket.sbAuthenticated) \
        or (not authenticate?) or authenticate(credentials)
      .then (fAuthValid) ->
        rsp = {type: 'LOGIN_RESPONSE'}
        if fAuthValid
          rsp.result = 'SUCCESS'
          socket.sbAuthenticated = true
          socket.join SOCKET_ROOM
          rsp.data = 
            login: login
            bufferedRecords: _getBufferedRecords hub
          process.nextTick -> 
            mainStory.info LOG_SRC, "User '#{login}' authenticated successfully"
            mainStory.debug LOG_SRC, "Piggybacked #{chalk.cyan rsp.data.bufferedRecords.length} records"
        else
          rsp.result = 'ERROR'
          process.nextTick -> mainStory.warn LOG_SRC, "User '#{login}' authentication failed"
        _socketTxMsg socket, rsp
    ## when 'BUFFERED_RECORDS_REQUEST'
    ##   rsp = {type: 'BUFFERED_RECORDS_RESPONSE'}
    ##   if socket.sbAuthenticated
    ##     rsp.result = 'SUCCESS'
    ##     rsp.data = hub.getBufferedRecords()
    ##   else
    ##     rsp.result = 'ERROR'
    ##     rsp.error = 'AUTH_REQUIRED'
    ##   _socketTxMsg socket, rsp
    when 'LOG_OUT'
      {authenticate} = socket.sbConfig
      if authenticate?
        socket.sbAuthenticated = false
        socket.leave SOCKET_ROOM
    when 'LOGIN_REQUIRED_QUESTION'
      _socketTxMsg socket,
        type: 'LOGIN_REQUIRED_RESPONSE'
        result: 'SUCCESS'
        data: {fLoginRequired: socket.sbConfig.authenticate?}
    else
      process.nextTick -> mainStory.warn LOG_SRC, "Unknown message type '#{type}'"
  return

_socketTxMsg = (socket, msg) -> socket.emit 'MSG', msg

_socketBroadcast = ->
  msg = {type: 'RECORDS', data: _broadcastBuf}
  _ioStandaloneNamespace?.to(SOCKET_ROOM).emit 'MSG', msg
  _ioServerAdaptor?.to(SOCKET_ROOM).emit 'MSG', msg
  _broadcastBuf.length = 0
  return

# Get the (long) list of buffered records from the hub.
# Process their `obj` fields so that they don't include circular references
_getBufferedRecords = (hub) -> hub.getBufferedRecords().map _preprocessAttachments

# Manage the (short) broadcast buffer (note that `socketBroadcast` is 
# normally throttled)
_broadcastBuf = []
_enqueueRecord = (record, config) -> _broadcastBuf.push _preprocessAttachments record

_preprocessAttachments = (record) -> 
  return record if not record.hasOwnProperty 'obj'
  return timm.set record, 'obj', treeLines(record.obj, record.objOptions)

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
    ## config: (newConfig) -> config = timm.merge config, newConfig
    tearDown: -> _socketShutDown config
  listener

module.exports = {
  create,
}
