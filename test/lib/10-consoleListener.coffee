{storyboard, expect, sinon, Promise} = require './imports'
consoleListener = require '../../lib/listeners/console'

{mainStory} = storyboard

#-====================================================
# ## Tests
#-====================================================
describe "consoleListener", ->

  _listener = null
  _spyLog   = null
  _spyError = null
  before -> 
    storyboard.removeAllListeners()
    storyboard.addListener consoleListener
    storyboard.config filter: '*:*'
    _listener = storyboard.getListeners()[0]
    sinon.spy console, 'log'
    sinon.spy console, 'error'
    _spyLog   = console.log
    _spyError = console.error

  after ->
    console.log.restore()
    console.error.restore()

  beforeEach -> 
    _spyLog.reset()
    _spyError.reset()

  it "should output log lines", ->
    mainStory.info "testSrc", "Test message"
    expect(_spyLog).to.have.been.calledOnce
    msg = _spyLog.args[0][0]
    expect(msg).to.contain 'testSrc'
    expect(msg).to.contain 'INFO'
    expect(msg).to.contain 'Test message'

  it "should use console.error for errors", ->
    mainStory.error "testSrc", "Test error"
    expect(_spyLog).not.to.have.been.called
    expect(_spyError).to.have.been.calledOnce
    msg = _spyError.args[0][0]
    expect(msg).to.contain 'ERROR'
    expect(msg).to.contain 'Test error'

  it "should report creation of a story", ->
    childStory = mainStory.child {title: "Three piggies"}
    expect(_spyLog).to.have.been.calledOnce
    msg = _spyLog.args[0][0]
    expect(msg).to.contain 'CREATED'

  it "should report closure of a story", ->
    childStory = mainStory.child {title: "Simbad the Sailor"}
    childStory.close()
    expect(_spyLog).to.have.been.calledTwice
    msg = _spyLog.args[0][0]
    expect(msg).to.contain 'CREATED'
    msg = _spyLog.args[1][0]
    expect(msg).to.contain 'CLOSED'

  it "should report changes of state in a story", ->
    childStory = mainStory.child {title: "The Little Mermaid"}
    childStory.changeStatus('UNDER_THE_SEA')
    expect(_spyLog).to.have.been.calledTwice
    msg = _spyLog.args[0][0]
    expect(msg).to.contain 'CREATED'
    msg = _spyLog.args[1][0]
    expect(msg).to.contain 'STATUS_CHANGED'

  describe "object attachments", ->

    it "should use JSON.stringify with inline attachments", ->
      obj = {a: 5}
      mainStory.info "Inline attachment", {attachInline: obj}
      expect(_spyLog).to.have.been.calledOnce
      msg = _spyLog.args[0][0]
      expect(msg).to.contain JSON.stringify obj

    it "when JSON.stringify is impossible, it should expand the object tree", ->
      obj = {oneAttr: 5}
      obj.b = obj
      mainStory.info "Inline attachment with circular ref", {attachInline: obj}
      expect(_spyLog).to.have.been.calledThrice
      expect(_spyLog.args[0][0]).to.contain "circular ref"
      expect(_spyLog.args[1][0]).to.contain "oneAttr"
      expect(_spyLog.args[2][0]).to.contain "[CIRCULAR]"

    it "should also allow the user to always expand an attachment", ->
      obj = {attr1: 8}
      mainStory.info "Expanded attachment", {attach: obj, attachLevel: 'TRACE', attachExpanded: true}
      expect(_spyLog).to.have.been.calledTwice
      expect(_spyLog.args[0][0]).to.contain "INFO"
      expect(_spyLog.args[0][0]).to.contain "Expanded attachment"
      expect(_spyLog.args[1][0]).to.contain "TRACE"
      expect(_spyLog.args[1][0]).to.contain "attr1"

  describe "in relative-time mode", ->

    before -> _listener.config relativeTime: true
    after  -> _listener.config relativeTime: false

    it "should include an ellipsis when more than 1s ellapses between lines", ->
      mainStory.info "Msg A"
      Promise.delay 1100
      .then ->
        mainStory.info "Msg B"
        expect(_spyLog).to.have.callCount 3
        args = _spyLog.args
        expect(args[0][0]).to.contain "Msg A"
        expect(args[1][0]).to.contain "..."
        expect(args[2][0]).to.contain "Msg B"

  it "should highlight warning logs in yellow", ->
    mainStory.warn "Warning!"
    expect(_spyLog).to.have.been.calledOnce
    if process.env.TEST_BROWSER
      expect(_spyLog.args[0][0]).to.contain '%c%cWarning!'
      expect(_spyLog.args[0]).to.contain 'color: #ff6600;font-weight: bold'
    else
      expect(_spyLog.args[0][0]).to.contain '\u001b[33m\u001b[1mWarning!'

  it "should highlight error logs in red", ->
    mainStory.error "Error!"
    expect(_spyError).to.have.been.calledOnce
    if process.env.TEST_BROWSER
      expect(_spyError.args[0][0]).to.contain '%c%cError!'
      expect(_spyError.args[0]).to.contain 'color: #cc0000;font-weight: bold'
    else
      expect(_spyError.args[0][0]).to.contain '\u001b[31m\u001b[1mError!'

  it "should not show uploaded client logs at the server", ->
    return if process.env.TEST_BROWSER
    _listener.process
      src: 'any'
      storyId: '*'
      level: 70
      fStory: false
      fServer: false
      msg: 'testMsg'
      uploadedBy: 'client-side'
    expect(_spyLog).not.to.have.been.called
