{storyboard, expect, sinon, Promise, h} = require './imports'
chalk             = require 'chalk'
http              = require 'http'
socketio          = require 'socket.io'
wsClientListener  = require '../../lib/listeners/wsClient'
k                 = require '../../lib/gral/constants'

{mainStory} = storyboard

#-====================================================
# ## Tests
#-====================================================
if not process.env.TEST_BROWSER
  console.log "Skipping #{chalk.cyan.bold 'wsClientListener'} tests in #{chalk.cyan.bold 'non-browser environment'}..."
  return

describe "wsClientListener", ->

  _spyServerRxMsg = _spyClientWinTxMsg = null
  _clientWinRxEvent = null
  _listener = null
  _httpServer = null
  _io = _ioNamespace = null
  _mockWindow = null
  _serverSocket = null
  before -> 
    storyboard.removeAllListeners()
    storyboard.config {filter: '*:*'}
    _spyServerRxMsg = sinon.spy()
    _spyClientWinTxMsg = sinon.spy()
    _mockWindow = 
      postMessage: _spyClientWinTxMsg
      addEventListener: (evType, listener) -> _clientWinRxEvent = listener
    return new Promise (resolve, reject) ->
      _httpServer = http.createServer(->)
      _httpServer.on 'listening', resolve
      _httpServer.listen 8090
    .then -> new Promise (resolve, reject) ->
      _io = socketio _httpServer
      _ioNamespace = _io.of k.WS_NAMESPACE
      _ioNamespace.on 'connection', (socket) ->
        _serverSocket = socket
        _serverSocket.on 'MSG', _spyServerRxMsg
        resolve()
      _listener = storyboard.addListener wsClientListener, {_mockWindow}

    # Make WsServerListener think that the extension is ready
    .then ->
      _clientWinRxEvent
        source: _mockWindow
        data: {src: 'DT', type: 'CONNECT_RESPONSE'}

  after -> 
    storyboard.removeListener _listener
    _httpServer.close()
    _io.close()

  #-====================================================
  # ### Transparent relay between socket and extension interface
  #-====================================================
  it "transparent socket -> extension relay", ->
    _spyClientWinTxMsg.reset()
    _serverSocket.emit 'MSG', {type: 'EXAMPLE_RESPONSE', result: 'success', data: {b: 4}}
    h.waitUntil(1000, -> _spyClientWinTxMsg.callCount > 0)
    .then ->
      msg = _spyClientWinTxMsg.args[0][0]
      expect(msg.type).to.equal 'EXAMPLE_RESPONSE'
      expect(msg.data).to.deep.equal {b: 4}

  it "transparent socket <- extension relay", ->
    _spyServerRxMsg.reset()
    _clientWinRxEvent 
      source: _mockWindow
      data: {src: 'DT', type: 'EXAMPLE_REQUEST', data: {a: 3}}
    h.waitUntil(1000, -> _spyServerRxMsg.callCount > 0)
    .then ->
      msg = _spyServerRxMsg.args[0][0]
      expect(msg.type).to.equal 'EXAMPLE_REQUEST'
      expect(msg.data).to.deep.equal {a: 3}
