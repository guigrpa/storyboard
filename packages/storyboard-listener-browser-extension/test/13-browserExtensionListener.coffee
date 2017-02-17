Promise = require 'bluebird'
{merge} = require 'timm'
{removeAllListeners, addListener, config, mainStory, chalk} = require 'storyboard'
browserExtensionListener = require('../lib').default
setMockWindow = require('../lib')._setWindow

#-====================================================
# ## Tests
#-====================================================
if not process.env.TEST_BROWSER
  console.log "Skipping #{chalk.cyan.bold 'browserExtensionListener'} tests in #{chalk.cyan.bold 'non-browser environment'}..."
  return

describe "browserExtensionListener", ->

  _spyClientWinTxMsg = _spyClientHub = null
  _clientWinRxEvent = null
  _listener = null
  _mockWindow = null
  _extensionTxMsg = (msg) ->
    _clientWinRxEvent
      source: _mockWindow
      data: merge msg, {src: 'DT'}

  before ->
    # Reset Storyboard and spies
    removeAllListeners()
    config filter: '*:*'
    _spyClientWinTxMsg = sinon.spy() # (ev) -> console.log ev
    _spyClientHub = sinon.spy() # (msg) -> console.log msg.type

    # Set up mock window
    _mockWindow =
      postMessage: _spyClientWinTxMsg
      addEventListener: (evType, listener) -> _clientWinRxEvent = listener
      removeEventListener: (evType, listener) ->
    setMockWindow _mockWindow

    # Create listener, and make it believe that the extension is ready
    _listener = addListener browserExtensionListener
    addListener -> {process: _spyClientHub}
    _extensionTxMsg {type: 'CONNECT_RESPONSE'}

    # Prevent setup from possibly interfering with tests
    return Promise.delay 250

  after ->
    removeAllListeners()

  beforeEach ->
    _spyClientWinTxMsg.reset()
    _spyClientHub.reset()

  it "sanity", ->
    expect(_listener.getConfig()).to.deep.equal {}

  describe 'extension <- hub', ->
    it "should relay all messages in this direction", ->
      _listener.process {type: 'WHATEVER', data: {b: 4}}
      waitUntil(1000, -> _spyClientWinTxMsg.callCount > 0)
      .then ->
        msg = _spyClientWinTxMsg.args[0][0]
        expect(msg.type).to.equal 'WHATEVER'
        expect(msg.data).to.deep.equal {b: 4}

  describe 'extension -> hub', ->
    it "should relay messages by default", ->
      _extensionTxMsg {type: 'WHATEVER', data: {b: 4}}
      waitUntil(1000, -> _spyClientHub.callCount > 0)
      .then ->
        msg = _spyClientHub.args[0][0]
        expect(msg.type).to.equal 'WHATEVER'
        expect(msg.data).to.deep.equal {b: 4}

    it "should respond to GET/SET_LOCAL_CLIENT_FILTER messages but not relay them", ->
      _extensionTxMsg {type: 'GET_LOCAL_CLIENT_FILTER'}
      Promise.delay(200)
      .then -> expect(_spyClientHub).not.to.have.been.called
      .then -> waitUntil(1000, -> _spyClientWinTxMsg.callCount > 0)
      .then ->
        msg = _spyClientWinTxMsg.args[0][0]
        expect(msg.type).to.equal 'LOCAL_CLIENT_FILTER'
        expect(msg.result).to.equal 'SUCCESS'

    it "should respond to CONNECT_REQUEST messages with its hub ID; AND ALSO relay them", ->
      _extensionTxMsg {type: 'CONNECT_REQUEST'}
      Promise.resolve()
      .then -> waitUntil(1000, -> _spyClientHub.callCount > 0)
      .then ->
        msg = _spyClientHub.args[0][0]
        expect(msg.type).to.equal 'CONNECT_REQUEST'
      .then -> waitUntil(1000, -> _spyClientWinTxMsg.callCount > 0)
      .then ->
        msg = _spyClientWinTxMsg.args[0][0]
        expect(msg.type).to.equal 'CONNECT_RESPONSE'
        expect(msg.result).to.equal 'SUCCESS'
        expect(msg.data.hubId).to.not.be.null
