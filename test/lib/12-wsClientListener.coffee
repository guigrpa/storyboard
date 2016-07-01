{storyboard, expect, sinon, Promise, h} = require './imports'
chalk             = require 'chalk'
http              = require 'http'
socketio          = require 'socket.io'
wsClientListener  = require '../../lib/listeners/wsClient'
ifExtension       = require '../../lib/listeners/interfaceExtension'
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
    ifExtension._setWindow _mockWindow
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
      _listener = storyboard.addListener wsClientListener

    # Make WsServerListener think that the extension is ready
    .then ->
      _clientWinRxEvent
        source: _mockWindow
        data: {src: 'DT', type: 'CONNECT_RESPONSE'}

    # Prevent setup from possibly interfering with tests
    .delay 250

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

  #-====================================================
  # ### Upload mechanism
  #-====================================================
  it "should allow uploading client logs (and not relay them to the extension)", ->
    _spyServerRxMsg.reset()
    _spyClientWinTxMsg.reset()
    Promise.resolve()
    .then -> mainStory.info 'foo0'
    .delay 200
    .then -> expect(_spyServerRxMsg).not.to.have.been.called
    .then ->
      _listener.config {uploadClientStories: true}
      mainStory.info 'foo1'
      return h.waitUntil(1000, -> _spyServerRxMsg.callCount > 0)
    .then ->
      msg = _spyServerRxMsg.args[0][0]
      expect(msg.type).to.equal 'UPLOAD_RECORDS'
      expect(msg.data).to.have.length 1
      expect(msg.data[0].msg).to.equal 'foo1'
    .delay 100
    # uploaded message should not be relayed by this listener to the browser extension
    # (that will be handled by the Browser Extension listener, if enabled)
    .then -> expect(_spyClientWinTxMsg).not.to.have.been.called

  it "should relay records from other clients to the extension", ->
    _spyServerRxMsg.reset()
    _serverSocket.emit 'MSG', 
      type: 'RECORDS'
      data: [
        {src: 'fontana di trevi', msg: 'water1', uploadedBy: 'unga'}
        {src: 'fontana di neptuno', msg: 'water2', uploadedBy: 'graorg'}
      ]
    h.waitUntil(1000, -> _spyClientWinTxMsg.callCount > 0)
    .then ->
      msg = _spyClientWinTxMsg.args[0][0]
      expect(msg.type).to.equal 'RECORDS'
      expect(msg.data).to.have.length 2

  #-====================================================
  # ### Low-level tests for the extension interface
  #-====================================================
  describe "extension interface", ->

    it "should ignore messages from sources other than our window", ->
      _spyServerRxMsg.reset()
      _clientWinRxEvent 
        source: null
        data: {src: 'DT', type: 'EXAMPLE_REQUEST', data: {a: 3}}
      Promise.delay(200)
      .then -> expect(_spyServerRxMsg).not.to.have.been.called

    it "should ignore messages from sources other than the DevTools", ->
      _spyServerRxMsg.reset()
      _clientWinRxEvent 
        source: _mockWindow
        data: {src: 'INCORRECT_SRC', type: 'EXAMPLE_REQUEST', data: {a: 3}}
      Promise.delay(200)
      .then -> expect(_spyServerRxMsg).not.to.have.been.called

    it "should reply to a CONNECT_REQUEST with a CONNECT_RESPONSE and WS_(DIS)CONNECTED", ->
      _spyServerRxMsg.reset()
      _spyClientWinTxMsg.reset()
      _clientWinRxEvent 
        source: _mockWindow
        data: {src: 'DT', type: 'CONNECT_REQUEST'}
      h.waitUntil(1000, -> _spyClientWinTxMsg.callCount >= 2)
      .then ->
        expect(_spyClientWinTxMsg.args[0][0].type).to.equal 'CONNECT_RESPONSE'
        expect(_spyClientWinTxMsg.args[1][0].type).to.equal 'WS_CONNECTED'
        expect(_spyServerRxMsg).not.to.have.been.called
      .delay 50  # the listener would now send pending messages, if any

