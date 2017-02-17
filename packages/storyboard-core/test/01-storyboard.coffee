{STORYBOARD_TYPE_ATTR} = require '../lib/gral/serialize'
hub = require '../lib/gral/hub'
k   = require '../lib/gral/constants'
filters = require '../lib/gral/filters'
mainStory = require('../lib/gral/stories').default

_spyListenerProcess = sinon.spy()
_listenerFactory = ->
  init: ->
  process: _spyListenerProcess
_listenerFactory.requiredCoreVersion = '^3.0.0-rc.2';

#-====================================================
# ## Tests
#-====================================================
describe 'storyboard', ->

  before ->
    hub.init({mainStory})
    hub.configure({ bufSize: 5 })
    filters.init({mainStory})
    filters.config '*:*'
    hub.addListener _listenerFactory
    expect(hub.getListeners()).to.have.length 1

  after ->
    hub.removeAllListeners()

  beforeEach -> _spyListenerProcess.reset()

  it 'sanity', ->
    expect(mainStory).to.exist

  describe 'using the main story', ->

    it 'should emit a record when logging', ->
      mainStory.info 'src1', 'msg1'
      expect(_spyListenerProcess).to.have.been.calledOnce
      msg = _spyListenerProcess.args[0][0]
      {data: records} = msg
      expect(records).to.have.length 1
      record = records[0]
      expect(record.src).to.equal 'src1'
      expect(record.msg).to.equal 'msg1'
      expect(record.level).to.equal k.LEVEL_STR_TO_NUM.INFO

    it 'should allow omitting the source', ->
      mainStory.info 'msg2'
      expect(_spyListenerProcess).to.have.been.calledOnce
      msg = _spyListenerProcess.args[0][0]
      record = msg.data[0]
      expect(record.msg).to.equal 'msg2'

    it 'should allow attaching an object', ->
      obj = {b: 3}
      mainStory.info 'msg3', {attach: obj}
      expect(_spyListenerProcess).to.have.been.calledOnce
      msg = _spyListenerProcess.args[0][0]
      record = msg.data[0]
      expect(record.msg).to.equal 'msg3'
      expect(record.obj).to.deep.equal obj

    it 'should allow attaching NO object', ->
      mainStory.info 'msg3'
      expect(_spyListenerProcess).to.have.been.calledOnce
      msg = _spyListenerProcess.args[0][0]
      record = msg.data[0]
      expect(record.obj).to.be.undefined

    it 'should allow attaching an UNDEFINED object', ->
      mainStory.info 'msg3', {attach: undefined}
      expect(_spyListenerProcess).to.have.been.calledOnce
      msg = _spyListenerProcess.args[0][0]
      record = msg.data[0]
      expect(record.obj).to.deep.equal {"#{STORYBOARD_TYPE_ATTR}": 'UNDEFINED'}

  describe 'creating a child story', ->

    childStory = null
    beforeEach ->
      childStory = mainStory.child()

    it 'should be correctly initialised', ->
      expect(childStory.parents).to.deep.equal [mainStory.storyId]
      expect(childStory.title).to.equal ''
      expect(childStory.fOpen).to.be.true
      expect(_spyListenerProcess).to.have.been.calledOnce
      msg = _spyListenerProcess.args[0][0]
      record = msg.data[0]
      expect(record.fStory).to.be.true
      expect(record.action).to.equal 'CREATED'

    it 'should have INFO level (default)', ->
      expect(childStory.level).to.equal k.LEVEL_STR_TO_NUM.INFO

    it 'should publish actions with the same level as the story itself', ->
      msg = _spyListenerProcess.args[0][0]
      record = msg.data[0]
      expect(record.fStory).to.be.true
      expect(record.action).to.equal 'CREATED'
      expect(record.level).to.equal k.LEVEL_STR_TO_NUM.INFO

    it 'should allow changing its title', ->
      childStory.changeTitle 'another title'
      expect(childStory.title).to.equal 'another title'

    it 'should allow setting a story status', ->
      childStory.changeStatus 'RUNNING'
      expect(childStory.status).to.equal 'RUNNING'

    it 'should allow closing a story', ->
      childStory.close()
      expect(childStory.fOpen).to.be.false
      expect(_spyListenerProcess).to.have.been.calledTwice
      msg = _spyListenerProcess.args[1][0]
      record = msg.data[0]
      expect(record.fStory).to.be.true
      expect(record.action).to.equal 'CLOSED'

  it 'should be possible to create stories directly with more than one parent', ->
    childStory = mainStory.child {title: 'title1', extraParents: 'foo'}
    expect(childStory.parents).to.deep.equal [mainStory.storyId, 'foo']

  describe 'getting the buffered records', ->

    before ->
      mainStory.info 'message1'
      mainStory.info 'message2'
      mainStory.info 'message3'
      mainStory.info 'message4'
      mainStory.info 'message5'
      mainStory.info 'message6'

    it 'should provide the latest records', ->
      buf = hub.getBufferedRecords()
      expect(buf.length).to.equal 5
      for idx in [0...5]
        expect(buf[idx].msg).to.equal "message#{idx+2}"

  describe 'for a filtered out story', ->

    foo = null
    beforeEach ->
      filters.config 'foo:INFO,*:*'
      _spyListenerProcess.reset() # Forget the 'filter changed' log
      foo = mainStory.child {src: 'foo', title: 'Foo', level: 'DEBUG'}

    afterEach ->
      filters.config '*:*'
      _spyListenerProcess.reset() # Forget the 'filter changed' log

    it 'should NOT emit action records', ->
      foo.close()
      expect(_spyListenerProcess).to.not.have.been.called

    it 'should NOT emit logs <= INFO', ->
      foo.debug "foo", "msg1"
      foo.info "foo", "msg2"
      foo.debug "interesting", "msg3"
      foo.info "interesting", "msg4"
      expect(_spyListenerProcess).to.not.have.been.called

    it 'should emit logs >= WARN (and make the story visible)', ->
      foo.warn 'whatever', 'Warning, warning!'
      expect(_spyListenerProcess).to.have.callCount 4
      record = _spyListenerProcess.args[0][0].data[0]
      expect(record.signalType).to.equal 'REVEAL_SEPARATOR'
      record = _spyListenerProcess.args[1][0].data[0]
      expect(record.src).to.equal 'foo'
      expect(record.action).to.equal 'CREATED'
      expect(record.level).to.equal k.LEVEL_STR_TO_NUM.DEBUG
      record = _spyListenerProcess.args[2][0].data[0]
      expect(record.signalType).to.equal 'REVEAL_SEPARATOR'
      record = _spyListenerProcess.args[3][0].data[0]
      expect(record.src).to.equal 'whatever'
      expect(record.level).to.equal k.LEVEL_STR_TO_NUM.WARN

    describe 'with a child', ->

      fooChild = null
      beforeEach ->
        fooChild = foo.child {src: 'child', title: 'Foo child'}

      it 'should NOT be visible (as a child of a hidden story)', ->
        expect(_spyListenerProcess).to.not.have.been.called

      it 'should NOT emit logs <= INFO', ->
        fooChild.debug "foo", "msg1"
        fooChild.info "foo", "msg2"
        fooChild.debug "interesting", "msg3"
        fooChild.info "interesting", "msg4"
        expect(_spyListenerProcess).to.not.have.been.called

      it 'should emit logs >= WARN (and make both ancestors visible)', ->
        fooChild.info 'whatever', 'Some operation'
        fooChild.warn 'whatever', 'Warning, warning!'
        expect(_spyListenerProcess).to.have.callCount 6
        record = _spyListenerProcess.args[0][0].data[0]
        expect(record.signalType).to.equal 'REVEAL_SEPARATOR'
        record = _spyListenerProcess.args[1][0].data[0]
        expect(record.src).to.equal 'foo'
        expect(record.action).to.equal 'CREATED'
        expect(record.level).to.equal k.LEVEL_STR_TO_NUM.DEBUG
        record = _spyListenerProcess.args[2][0].data[0]
        expect(record.src).to.equal 'child'
        expect(record.action).to.equal 'CREATED'
        expect(record.level).to.equal k.LEVEL_STR_TO_NUM.INFO
        record = _spyListenerProcess.args[3][0].data[0]
        expect(record.src).to.equal 'whatever'
        expect(record.level).to.equal k.LEVEL_STR_TO_NUM.INFO
        record = _spyListenerProcess.args[4][0].data[0]
        expect(record.signalType).to.equal 'REVEAL_SEPARATOR'
        record = _spyListenerProcess.args[5][0].data[0]
        expect(record.src).to.equal 'whatever'
        expect(record.level).to.equal k.LEVEL_STR_TO_NUM.WARN
