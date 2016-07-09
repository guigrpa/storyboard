{storyboard, expect, sinon, Promise, h} = require './imports'
chalk             = require 'chalk'
http              = require 'http'
socketio          = require 'socket.io'
wsClientListener  = require('../../lib/listeners/wsClient').default
k                 = require '../../lib/gral/constants'

{mainStory} = storyboard

#-====================================================
# ## Tests
#-====================================================
if not process.env.TEST_BROWSER
  console.log "Skipping #{chalk.cyan.bold 'wsClientListener'} tests in #{chalk.cyan.bold 'non-browser environment'}..."
  return

describe "wsClientListener", ->

  _spyServerRxMsg = _spyClientHub = null
  _listener = null
  _httpServer = null
  _io = _ioNamespace = null
  _serverSocket = null

  before -> 
    # Reset Storyboard and spies
    storyboard.removeAllListeners()
    storyboard.config {filter: '*:*'}
    _spyServerRxMsg = sinon.spy()
    _spyClientHub = sinon.spy()

    # Set up mock HTTP + SocketIO server
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

      # Set up the WsClient listener (under test),
      # as well as a fake listener to serve as a spy
      Promise.delay 100
      .then ->
        _listener = storyboard.addListener wsClientListener
        storyboard.addListener -> {process: _spyClientHub}

    # Prevent setup from possibly interfering with tests
    .delay 250

  after -> 
    storyboard.removeAllListeners()
    _httpServer.close()
    _io.close()

  beforeEach ->
    _spyServerRxMsg.reset()
    _spyClientHub.reset()

  describe "socket -> hub", ->
  it "should relay all messages in this direction", ->
    _serverSocket.emit 'MSG', {type: 'EXAMPLE_RESPONSE', result: 'success', data: {b: 4}}
    h.waitUntil(1000, -> _spyClientHub.callCount > 0)
    .then ->
      msg = _spyClientHub.args[0][0]
      expect(msg.type).to.equal 'EXAMPLE_RESPONSE'
      expect(msg.data).to.deep.equal {b: 4}

  describe "socket <- hub", ->
    it "should report on its connection status when a CONNECT_REQUEST reaches it", ->
      _listener.process {type: 'CONNECT_REQUEST'}
      h.waitUntil(1000, -> _spyClientHub.callCount >= 1)
      .then ->
        msg = _spyClientHub.args[0][0]
        expect(msg.type).to.equal 'WS_CONNECTED'

    it "should relay login/logout and filter messages transparently", ->
      _listener.process {type: 'LOGIN_REQUEST', data: 'foo'}
      _listener.process {type: 'LOG_OUT'}
      _listener.process {type: 'LOGIN_REQUIRED_QUESTION'}
      _listener.process {type: 'GET_SERVER_FILTER'}
      _listener.process {type: 'SET_SERVER_FILTER'}
      h.waitUntil(1000, -> _spyServerRxMsg.callCount >= 5)
      .then ->
        msg = _spyServerRxMsg.args[0][0]
        expect(msg.type).to.equal 'LOGIN_REQUEST'
        expect(msg.data).to.equal 'foo'
        expect(_spyServerRxMsg.args[1][0].type).to.equal 'LOG_OUT'
        expect(_spyServerRxMsg.args[2][0].type).to.equal 'LOGIN_REQUIRED_QUESTION'
        expect(_spyServerRxMsg.args[3][0].type).to.equal 'GET_SERVER_FILTER'
        expect(_spyServerRxMsg.args[4][0].type).to.equal 'SET_SERVER_FILTER'

    it "should not upload records if this function is disabled", ->
      _listener.configure uploadClientStories: false # this is the default
      _listener.process {type: 'RECORDS', data: [{msg: 'record 1'}, {msg: 'record2'}]}
      Promise.delay(200)
      .then -> expect(_spyServerRxMsg).not.to.have.been.called

    it "should upload records if this function is enabled", ->
      _listener.configure uploadClientStories: true
      _listener.process {type: 'RECORDS', data: [{msg: 'record 1'}, {msg: 'record2'}]}
      h.waitUntil(1000, -> _spyServerRxMsg.callCount >= 1)
      .then ->
        msg = _spyServerRxMsg.args[0][0]
        expect(msg.type).to.equal 'RECORDS'
        expect(msg.data).to.have.length 2
        _listener.configure uploadClientStories: false
