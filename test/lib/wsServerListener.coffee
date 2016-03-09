{storyboard, expect, sinon, Promise} = require './imports'
socketio = require 'socket.io-client'
wsServerListener = require '../../lib/listeners/wsServer'
k = require '../../lib/gral/constants'

{mainStory} = storyboard

# From: https://www.promisejs.org/generators/
async = (makeGenerator) ->
  ->
    generator = makeGenerator arguments...
    handle = (result) ->
      # result => { done: [Boolean], value: [Object] }
      if result.done then return Promise.resolve result.value
      p = Promise.resolve result.value
      .then ((res) -> handle generator.next res), \
        ((err) -> handle generator.throw err)
      p
    try 
      return handle generator.next()
    catch ex
      return Promise.reject ex

_waitUntil = async (timeout, fn) ->
  t0 = new Date().getTime()
  while true
    t1 = new Date().getTime()
    if t1 - t0 > timeout
      return false
    if fn() then return true
    yield Promise.delay 20

#-====================================================
# ## Tests
#-====================================================
describe "wsServerListener", ->

  describe "without throttling", ->

    _listener = null
    _socket = null
    _spy = null
    before -> 
      storyboard.removeAllListeners()
      storyboard.addListener wsServerListener, {throttle: 0, authenticate: (o) -> true}
      storyboard.config {filter: '*:*'}
      _listener = storyboard.getListeners()[0]
      _spy = sinon.spy()
      return new Promise (resolve, reject) ->
        _socket = socketio("http://localhost:8090#{k.WS_NAMESPACE}")
        _socket.on 'connect', resolve
        _socket.on 'MSG', _spy

    it "should require a log in", ->
      _waitUntil(1000, -> _spy.callCount > 0)
      .then (res) ->
        expect(_spy).to.have.been.calledOnce
        msg = _spy.args[0][0]
        expect(msg.type).to.equal 'LOGIN_REQUIRED'

    it "should accept a log in", ->
      _spy.reset()
      _socket.emit 'MSG', {type: 'LOGIN_REQUEST', data: {login: 'a', password: 'b'}}
      _waitUntil(1000, -> _spy.callCount > 1)
      .then (res) ->
        expect(_spy).to.have.been.calledTwice # second time: logging the successful login
        msg = _spy.args[0][0]
        expect(msg.type).to.equal 'LOGIN_RESPONSE'
        expect(msg.result).to.equal 'SUCCESS'

    it "should receive log records", ->
      _spy.reset()
      mainStory.info "Msg through web sockets"
      _waitUntil(1000, -> _spy.callCount > 0)
      .then (res) ->
        expect(_spy).to.have.been.calledOnce
        msg = _spy.args[0][0]
        expect(msg.type).to.equal 'RECORDS'
        expect(msg.data).to.have.length 1
        expect(msg.data[0].msg).to.contain 'Msg through web sockets'

    it "should receive log records with attachments", ->
      _spy.reset()
      mainStory.info "Msg with object", attach: {a: 4, b: 3}
      _waitUntil(1000, -> _spy.callCount > 0)
      .then (res) ->
        expect(_spy).to.have.been.calledOnce
        msg = _spy.args[0][0]
        expect(msg.type).to.equal 'RECORDS'
        expect(msg.data).to.have.length 1
        expect(msg.data[0].obj).to.have.length 2


  describe "with throttling", ->

    _listener = null
    _socket = null
    _spy = null
    before -> 
      storyboard.removeAllListeners()
      storyboard.addListener wsServerListener, {throttle: 50, authenticate: (o) -> true}
      _listener = storyboard.getListeners()[0]
      _spy = sinon.spy()
      return new Promise (resolve, reject) ->
        _socket = socketio("http://localhost:8090#{k.WS_NAMESPACE}")
        _socket.on 'connect', resolve
        _socket.on 'MSG', _spy
      .then ->
        _socket.emit 'MSG', {type: 'LOGIN_REQUEST', data: {login: 'a', password: 'b'}}
      .then -> _waitUntil(1000, -> _spy.callCount > 1)  # LOGIN_REQUIRED, LOGIN_RESPONSE
      .then -> _spy.reset()

    it "should still receive log records", ->
      mainStory.info "Msg2 through web sockets"
      _waitUntil(1000, -> _spy.callCount > 0)
      .then (res) ->
        expect(_spy).to.have.been.calledOnce
        msg = _spy.args[0][0]
        expect(msg.type).to.equal 'RECORDS'
        expect(msg.data).to.have.length 1
        expect(msg.data[0].msg).to.contain 'Msg2 through web sockets'
