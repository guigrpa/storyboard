_           = require '../vendor/lodash'
path        = require 'path'
http        = require 'http'
express     = require 'express'
socketio    = require 'socket.io'
Promise     = require 'bluebird'
chalk       = require 'chalk'
timm        = require 'timm'
treeLines   = require '../gral/treeLines'
k           = require '../gral/constants'

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
    _ioServerAdaptor = socketio(config.httpServer).of k.WS_NAMESPACE
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
  {mainStory: story, hub} = socket.sbConfig
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
          story.info LOG_SRC, "User '#{login}' authenticated successfully"
          socket.sbAuthenticated = true
          socket.join 'AUTHENTICATED'
          rsp.data = 
            login: login
            bufferedRecords: _getBufferedRecords hub
        else
          rsp.result = 'ERROR'
          story.warn LOG_SRC, "User '#{login}' authentication failed"
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
    else
      story.warn LOG_SRC, "Unknown message type '#{type}'"
  return

_socketTxMsg = (socket, msg) -> socket.emit 'MSG', msg

_socketBroadcast = ->
  msg = {type: 'RECORDS', data: _broadcastBuf}
  _ioStandalone?.to('AUTHENTICATED').emit 'MSG', msg
  _ioServerAdaptor?.to('AUTHENTICATED').emit 'MSG', msg
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
  return timm.set record, 'obj', treeLines(record.obj)

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
  listener

module.exports = {
  create,
}
