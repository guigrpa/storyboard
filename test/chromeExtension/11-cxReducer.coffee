_         = require 'lodash'
timm      = require 'timm'
{expect}  = require './imports'
reducer   = require '../../lib/chromeExtension/reducers/cxReducer'

#-------------------------------------------------
# ## Tests
#-------------------------------------------------
describe 'cxReducer', ->
  
  state = null
  beforeEach -> state = reducer undefined, {type: ''}

  describe 'connection state btw. DevTools and WsClient listener', ->

    it 'should have a correct initial state', ->
      expect(state.cxState).to.equal 'DISCONNECTED'

    it 'should process CX_CONNECTED', ->
      state = reducer state, {type: 'CX_CONNECTED'}
      expect(state.cxState).to.equal 'CONNECTED'

    it 'should process CX_DISCONNECTED', ->
      state = reducer state, {type: 'CX_CONNECTED'}
      state = reducer state, {type: 'CX_DISCONNECTED'}
      expect(state.cxState).to.equal 'DISCONNECTED'

  describe 'connection state btw. WsClient and WsServer listeners', ->

    it 'should have a correct initial state', ->
      expect(state.wsState).to.equal 'DISCONNECTED'

    it 'should process WS_CONNECTED', ->
      state = reducer state, {type: 'WS_CONNECTED'}
      expect(state.wsState).to.equal 'CONNECTED'

    it 'should process WS_DISCONNECTED', ->
      state = reducer state, {type: 'WS_CONNECTED'}
      state = reducer state, {type: 'WS_DISCONNECTED'}
      expect(state.wsState).to.equal 'DISCONNECTED'

  describe 'login state', ->

    it 'should have a correct initial state', ->
      expect(state.loginState).to.equal 'LOGGED_OUT'
      expect(state.fLoginRequired).to.be.null
      expect(state.login).to.be.null

    it 'should process LOGIN_REQUIRED', ->
      state = reducer state, {type: 'LOGIN_REQUIRED', fLoginRequired: false}
      expect(state.fLoginRequired).to.be.false

    it 'should process LOGIN_REQUIRED', ->
      state = reducer state, {type: 'LOGIN_REQUIRED', fLoginRequired: true}
      expect(state.fLoginRequired).to.be.true

    it 'should process LOGIN_STARTED', ->
      state = reducer state, {type: 'LOGIN_STARTED'}
      expect(state.loginState).to.equal 'LOGGING_IN'

    it 'should process LOGIN_SUCCEEDED', ->
      state = reducer state, {type: 'LOGIN_SUCCEEDED', login: 'John'}
      expect(state.loginState).to.equal 'LOGGED_IN'
      expect(state.login).to.equal 'John'

    it 'should process LOGGED_OUT', ->
      state = reducer state, {type: 'LOGIN_SUCCEEDED', login: 'John'}
      state = reducer state, {type: 'LOGGED_OUT'}
      expect(state.loginState).to.equal 'LOGGED_OUT'
      expect(state.login).to.be.null

  describe 'filters', ->

    it 'should process SERVER_FILTER', ->
      state = reducer state, {type: 'SERVER_FILTER', filter: 'abcd:*'}
      expect(state.serverFilter).to.equal 'abcd:*'

    it 'should process LOCAL_CLIENT_FILTER', ->
      state = reducer state, {type: 'LOCAL_CLIENT_FILTER', filter: 'dcba:*'}
      expect(state.localClientFilter).to.equal 'dcba:*'
