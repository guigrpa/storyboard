{storyboard, expect, sinon, Promise, h} = require './imports'
chalk = require 'chalk'
http = require 'http'
socketio = require 'socket.io-client'
wsServerListener = require '../../lib/listeners/wsServer'
k = require '../../lib/gral/constants'

{mainStory} = storyboard

#-====================================================
# ## Tests
#-====================================================
if process.env.TEST_BROWSER
  console.log "Skipping #{chalk.cyan.bold 'wsServerListener'} tests in the #{chalk.cyan.bold 'browser'}..."
  return

describe "wsServerListener", ->

  _spy = null
  before -> 
    storyboard.removeAllListeners()
    storyboard.config {filter: '*:*'}
    _spy = sinon.spy()

  beforeEach -> _spy.reset()

  #-====================================================
  # ### Server without auth
  #-====================================================
  describe "standalone server without authentication", ->

    _listener = null
    _socket = null
    before -> 
      _listener = storyboard.addListener wsServerListener, {throttle: 0}
      return new Promise (resolve, reject) ->
        _socket = socketio "http://localhost:8090#{k.WS_NAMESPACE}"
        _socket.on 'MSG', _spy
        _socket.on 'connect', resolve

    after -> storyboard.removeListener _listener

    it "should not require a log in", ->
      _socket.emit 'MSG', {type: 'LOGIN_REQUIRED_QUESTION'}
      h.waitUntil(1000, -> _spy.callCount > 0)
      .then (res) ->
        expect(_spy).to.have.been.calledOnce
        msg = _spy.args[0][0]
        expect(msg.type).to.equal 'LOGIN_REQUIRED_RESPONSE'
        expect(msg.data.fLoginRequired).to.be.false

    it "should receive log records", ->
      mainStory.info "Msg through web sockets"
      h.waitUntil(1000, -> _spy.callCount > 0)
      .then (res) ->
        expect(_spy).to.have.been.calledOnce
        msg = _spy.args[0][0]
        expect(msg.type).to.equal 'RECORDS'
        expect(msg.data).to.have.length 1
        expect(msg.data[0].msg).to.contain 'Msg through web sockets'

    it "should ignore a log out", ->
      _socket.emit 'MSG', {type: 'LOG_OUT'}
      Promise.delay(200)
      .then -> mainStory.info "This message should be received by the client"
      .then -> h.waitUntil(1000, -> _spy.callCount > 0)
      .then -> 
        expect(_spy).to.have.been.calledOnce
        msg = _spy.args[0][0]
        expect(msg.type).to.equal 'RECORDS'


  #-====================================================
  # ### Server with auth
  #-====================================================
  describe "standalone server with authentication", ->
    describe "without throttling", ->

      _listener = null
      _socket = null
      before -> 
        _listener = storyboard.addListener wsServerListener, 
          throttle: 0
          authenticate: ({login, password}) -> login is 'admin'
        return new Promise (resolve, reject) ->
          _socket = socketio "http://localhost:8090#{k.WS_NAMESPACE}"
          _socket.on 'MSG', _spy
          _socket.on 'connect', resolve

      after -> storyboard.removeListener _listener

      it "should require a log in", ->
        _socket.emit 'MSG', {type: 'LOGIN_REQUIRED_QUESTION'}
        h.waitUntil(1000, -> _spy.callCount > 0)
        .then (res) ->
          expect(_spy).to.have.been.calledOnce
          msg = _spy.args[0][0]
          expect(msg.type).to.equal 'LOGIN_REQUIRED_RESPONSE'
          expect(msg.data.fLoginRequired).to.be.true

      it "should reject invalid credentials", ->
        _socket.emit 'MSG', {type: 'LOGIN_REQUEST', data: {login: 'pepinillo', password: 'b'}}
        h.waitUntil(1000, -> _spy.callCount > 0)
        .then (res) ->
          expect(_spy).to.have.been.called
          msg = _spy.args[0][0]
          expect(msg.type).to.equal 'LOGIN_RESPONSE'
          expect(msg.result).to.equal 'ERROR'
          expect(msg.data?.bufferedRecords).to.be.undefined

      it "should accept a log in (and reply with buffered records)", ->
        _socket.emit 'MSG', {type: 'LOGIN_REQUEST', data: {login: 'admin', password: 'b'}}
        h.waitUntil(1000, -> _spy.callCount > 0)
        .then (res) ->
          expect(_spy).to.have.been.called
          msg = _spy.args[0][0]
          expect(msg.type).to.equal 'LOGIN_RESPONSE'
          expect(msg.result).to.equal 'SUCCESS'
          expect(msg.data.bufferedRecords).to.be.instanceOf Array

      it "should receive log records", ->
        mainStory.info "Msg through web sockets"
        h.waitUntil(1000, -> _spy.callCount > 0)
        .then (res) ->
          expect(_spy).to.have.been.calledOnce
          msg = _spy.args[0][0]
          expect(msg.type).to.equal 'RECORDS'
          expect(msg.data).to.have.length 1
          expect(msg.data[0].msg).to.contain 'Msg through web sockets'

      it "should receive log records with attachments", ->
        mainStory.info "Msg with object", attach: {a: 4, b: 3}
        h.waitUntil(1000, -> _spy.callCount > 0)
        .then (res) ->
          expect(_spy).to.have.been.calledOnce
          msg = _spy.args[0][0]
          expect(msg.type).to.equal 'RECORDS'
          expect(msg.data).to.have.length 1
          expect(msg.data[0].obj).to.have.length 2

      it "should report invalid messages", ->
        _socket.emit 'MSG', {type: 'INVALID_MSG_TYPE'}
        h.waitUntil(1000, -> _spy.callCount > 0)
        .then (res) ->
          expect(_spy).to.have.been.calledOnce
          msg = _spy.args[0][0]
          expect(msg.type).to.equal 'RECORDS'
          expect(msg.data).to.have.length 1
          expect(msg.data[0].msg).to.contain 'Unknown message type'

      it "should accept a log out", ->
        _socket.emit 'MSG', {type: 'LOG_OUT'}
        Promise.delay(200)
        .then -> mainStory.info "This message should not be received by the client"
        .delay 200
        .then -> expect(_spy).to.not.have.been.called


    describe "with throttling", ->

      _listener = null
      _socket = null
      before -> 
        _listener = storyboard.addListener wsServerListener, 
          throttle: 50
          authenticate: (o) -> true
        return new Promise (resolve, reject) ->
          _socket = socketio "http://localhost:8090#{k.WS_NAMESPACE}"
          _socket.on 'connect', resolve
          _socket.on 'MSG', _spy
        .then ->
          _socket.emit 'MSG', {type: 'LOGIN_REQUEST', data: {login: 'a', password: 'b'}}
        .then -> h.waitUntil(1000, -> _spy.callCount > 1)  # LOGIN_RESPONSE, initial RECORDS

      after -> storyboard.removeListener _listener

      it "should still receive log records", ->
        mainStory.info "Msg2 through web sockets"
        h.waitUntil(1000, -> _spy.callCount > 0)
        .then (res) ->
          expect(_spy).to.have.been.calledOnce
          msg = _spy.args[0][0]
          expect(msg.type).to.equal 'RECORDS'
          expect(msg.data).to.have.length 1
          expect(msg.data[0].msg).to.contain 'Msg2 through web sockets'

  #-====================================================
  # ### Attached server
  #-====================================================
  describe "attached server", ->

    _socket = null
    _spy = null
    _listener = null
    _httpServer = null
    before -> 
      _httpServer = http.createServer(->)
      _spy = sinon.spy()
      _listener = storyboard.addListener wsServerListener, 
        throttle: 0
        httpServer: _httpServer
      return new Promise (resolve, reject) ->
        _httpServer.on 'listening', resolve
        _httpServer.listen 3000
      .then -> return new Promise (resolve, reject) ->
        _socket = socketio "http://localhost:3000#{k.WS_NAMESPACE}"
        _socket.on 'MSG', _spy
        _socket.on 'connect', resolve

    after -> 
      storyboard.removeListener _listener
      _httpServer.close()

    beforeEach -> _spy.reset()

    it "should receive log records", ->
      mainStory.info "Msg through web sockets"
      h.waitUntil(1000, -> _spy.callCount > 0)
      .then (res) ->
        expect(_spy).to.have.been.calledOnce
        msg = _spy.args[0][0]
        expect(msg.type).to.equal 'RECORDS'
        expect(msg.data).to.have.length 1
        expect(msg.data[0].msg).to.contain 'Msg through web sockets'
