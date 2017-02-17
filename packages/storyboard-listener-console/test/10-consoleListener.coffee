Promise = require 'bluebird'
consoleListener = require('../lib').default
{getListeners, removeAllListeners, addListener, config, mainStory} = require 'storyboard'

CIRCULAR_REF = '__SB_CIRCULAR__';

_isMochaOutput = (txt) ->
  if txt.length is 0 then return false
  if txt[0] isnt ' ' then return false
  if txt.match(/^\s+\.\.\./) then return false
  if txt.indexOf('THIS_AINT_NO_MOCHA_OUTPUT') >= 0 then return false
  if txt.indexOf('%c') >= 0 then return false
  return true

#-====================================================
# ## Tests
#-====================================================
IS_BROWSER = process.env.TEST_BROWSER

describe "consoleListener", ->

  _listener = null
  _spyLog   = null
  _spyWarn  = null
  _spyError = null
  before ->
    removeAllListeners()

    sinon.stub console, 'log'
    addListener consoleListener
    config filter: '*:*'
    console.log.restore()

    _listener = getListeners()[0]

  beforeEach ->
    _listener.configure useStderr: false
    consoleLog = console.log
    consoleError = console.error
    _spyLog   = sinon.stub console, 'log', (txt) ->
      if _isMochaOutput(txt) then consoleLog.apply console, arguments
      # consoleLog.apply console, arguments
    _spyError = sinon.stub console, 'error', (txt) ->
      if _isMochaOutput(txt) then consoleError.apply console, arguments
      # consoleError.apply console, arguments
    _spyWarn = sinon.stub console, 'warn'

  afterEach ->
    _listener.configure useStderr: false
    console.log.restore()
    console.error.restore()
    console.warn.restore()

  after -> removeAllListeners()

  it "sanity", ->
    expect(_listener.getConfig().hasOwnProperty('moduleNameLength')).to.be.true

  it "should output log lines", ->
    mainStory.info "testSrc", "Test message"
    expect(_spyLog).to.have.been.calledOnce
    msg = _spyLog.args[0][0]
    expect(msg).to.contain 'testSrc'
    expect(msg).to.contain 'INFO'
    expect(msg).to.contain 'Test message'

  if IS_BROWSER
    describe "at the browser", ->
      it "should always use console.error for errors", ->
        mainStory.error "testSrc", "Test error"
        expect(_spyError).to.have.been.calledOnce
        expect(_spyLog).not.to.have.been.called
        expect(_spyWarn).not.to.have.been.called
        _listener.configure useStderr: true
        mainStory.error "testSrc", "Test error"
        expect(_spyError).to.have.been.calledTwice
        expect(_spyLog).not.to.have.been.called
        expect(_spyWarn).not.to.have.been.called
      it "should always use console.warn for warnings", ->
        mainStory.warn "testSrc", "Test warning"
        expect(_spyWarn).to.have.been.calledOnce
        expect(_spyLog).not.to.have.been.called
        expect(_spyError).not.to.have.been.called
        _listener.configure useStderr: true
        mainStory.warn "testSrc", "Test warning"
        expect(_spyWarn).to.have.been.calledTwice
        expect(_spyLog).not.to.have.been.called
        expect(_spyError).not.to.have.been.called

  if not IS_BROWSER
    describe "at the server", ->
      it "should use stdout (console.log) for errors by default", ->
        mainStory.error "testSrc", "Test error"
        expect(_spyLog).to.have.been.calledOnce
        expect(_spyError).not.to.have.been.called
      it "should allow enabling stderr (console.error) for errors", ->
        _listener.configure useStderr: true
        mainStory.error "testSrc", "Test error"
        expect(_spyError).to.have.been.calledOnce
        expect(_spyLog).not.to.have.been.called

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

    it "when attachments have circular refs, they should still be inlined", ->
      obj = {oneAttr: 5}
      obj.b = obj
      mainStory.info "Inline attachment with circular ref", {attachInline: obj}
      expect(_spyLog).to.have.been.calledOnce
      expect(_spyLog.args[0][0]).to.contain "circular ref"
      expect(_spyLog.args[0][0]).to.contain "oneAttr"
      expect(_spyLog.args[0][0]).to.contain CIRCULAR_REF

    it "should also allow the user to always expand an attachment", ->
      obj = {THIS_AINT_NO_MOCHA_OUTPUT: 8}
      mainStory.info "Expanded attachment", {attach: obj, attachLevel: 'TRACE', attachExpanded: true}
      expect(_spyLog).to.have.been.calledTwice
      expect(_spyLog.args[0][0]).to.contain "INFO"
      expect(_spyLog.args[0][0]).to.contain "Expanded attachment"
      expect(_spyLog.args[1][0]).to.contain "TRACE"
      expect(_spyLog.args[1][0]).to.contain "THIS_AINT_NO_MOCHA_OUTPUT"

  describe "in relative-time mode", ->

    before -> _listener.configure relativeTime: true
    after  -> _listener.configure relativeTime: false

    it "should include an ellipsis when more than 1s ellapses between lines", ->
      mainStory.info "THIS_AINT_NO_MOCHA_OUTPUT A"
      Promise.delay 1100
      .then ->
        mainStory.info "THIS_AINT_NO_MOCHA_OUTPUT B"
        expect(_spyLog).to.have.callCount 3
        args = _spyLog.args
        expect(args[0][0]).to.contain "THIS_AINT_NO_MOCHA_OUTPUT A"
        expect(args[1][0]).to.contain "..."
        expect(args[2][0]).to.contain "THIS_AINT_NO_MOCHA_OUTPUT B"

  it "should highlight warning logs in yellow", ->
    mainStory.warn "Warning!"
    mySpy = if IS_BROWSER then _spyWarn else _spyLog
    expect(mySpy).to.have.been.calledOnce
    if IS_BROWSER
      expect(mySpy.args[0][0]).to.contain '%c%cWarning!'
      expect(mySpy.args[0]).to.contain 'color: #ff6600;font-weight: bold'
    else
      expect(mySpy.args[0][0]).to.contain '\u001b[33m\u001b[1mWarning!'

  it "should highlight error logs in red", ->
    mainStory.error "Error!"
    mySpy = if IS_BROWSER then _spyError else _spyLog
    expect(mySpy).to.have.been.calledOnce
    if IS_BROWSER
      expect(mySpy.args[0][0]).to.contain '%c%cError!'
      expect(mySpy.args[0]).to.contain 'color: #cc0000;font-weight: bold'
    else
      expect(mySpy.args[0][0]).to.contain '\u001b[31m\u001b[1mError!'

  it "should not show uploaded client logs at the server", ->
    return if IS_BROWSER
    _listener.process
      src: 'any'
      storyId: '*'
      level: 70
      fStory: false
      fServer: false
      msg: 'testMsg'
      uploadedBy: 'client-side'
    expect(_spyLog).not.to.have.been.called
