{storyboard, expect, sinon, Promise, h} = require './imports'
chalk             = require 'chalk'
browserExtensionListener = require '../../lib/listeners/browserExtension'
ifExtension       = require '../../lib/listeners/helpers/interfaceExtension'
k                 = require '../../lib/gral/constants'

{mainStory} = storyboard

#-====================================================
# ## Tests
#-====================================================
if not process.env.TEST_BROWSER
  console.log "Skipping #{chalk.cyan.bold 'browserExtensionListener'} tests in #{chalk.cyan.bold 'non-browser environment'}..."
  return

describe "browserExtensionListener", ->

  _spyClientWinTxMsg = null
  _clientWinRxEvent = null
  _listener = null
  _mockWindow = null

  before -> 
    storyboard.removeAllListeners()
    storyboard.config {filter: '*:*'}
    _spyClientWinTxMsg = sinon.spy()
    _mockWindow = 
      postMessage: _spyClientWinTxMsg
      addEventListener: (evType, listener) -> _clientWinRxEvent = listener
    ifExtension._setWindow _mockWindow
    _listener = storyboard.addListener browserExtensionListener
    # Make the listener think that the extension is ready
    _clientWinRxEvent
      source: _mockWindow
      data: {src: 'DT', type: 'CONNECT_RESPONSE'}

  after -> 
    storyboard.removeListener _listener

  describe "client stories -> extension relay", ->

    it "should relay simple logs", ->
      _spyClientWinTxMsg.reset()
      mainStory.info "Somewhere over the rainbow..."
      h.waitUntil(1000, -> _spyClientWinTxMsg.callCount > 0)
      .then ->
        msg = _spyClientWinTxMsg.args[0][0]
        expect(msg.type).to.equal 'RECORDS'
        expect(msg.data[0].msg).to.contain 'rainbow'

    it "should not preprocess attachments", ->
      _spyClientWinTxMsg.reset()
      mainStory.info "We can be heroes...", attach: just: "for one day"
      h.waitUntil(1000, -> _spyClientWinTxMsg.callCount > 0)
      .then ->
        record = _spyClientWinTxMsg.args[0][0].data[0]
        expect(record.msg).to.contain 'heroes'
        expect(record.obj).to.deep.equal {just: 'for one day'}
