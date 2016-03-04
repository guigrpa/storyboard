{storyboard, expect, sinon} = require './imports'
hub = require '../../src/gral/hub'

_spy = sinon.spy()
_listenerFactory = 
  create: ->
    init: ->
    process: _spy
{mainStory} = storyboard

#-====================================================
# ## Tests
#-====================================================
describe 'storyboard', ->
  
  before -> 
    storyboard.removeAllListeners()
    storyboard.addListener _listenerFactory
    expect(storyboard.getListeners()).to.have.length 1
    hub.config {bufSize: 5}

  beforeEach -> _spy.reset()

  it 'sanity', ->
    expect(storyboard.mainStory).to.exist

  describe 'using the main story', ->
    
    it 'should emit a record when logging', ->
      mainStory.info 'src1', 'msg1'
      expect(_spy).to.have.been.calledOnce
      record = _spy.args[0][0]
      expect(record.src).to.equal 'src1'
      expect(record.msg).to.equal 'msg1'

    it 'should allow omitting the source', ->
      mainStory.info 'msg2'
      expect(_spy).to.have.been.calledOnce
      record = _spy.args[0][0]
      expect(record.msg).to.equal 'msg2'

    it 'should allow attaching an object', ->
      obj = {b: 3}
      mainStory.info 'msg3', {attach: obj}
      expect(_spy).to.have.been.calledOnce
      record = _spy.args[0][0]
      expect(record.msg).to.equal 'msg3'
      expect(record.obj).to.equal obj

  describe 'creating a child story', ->

    childStory = null
    beforeEach ->
      childStory = mainStory.child {title: 'childish title'}

    it 'should be correctly initialised', ->
      expect(childStory.parents).to.deep.equal [mainStory.storyId]
      expect(childStory.title).to.equal 'childish title'
      expect(childStory.fOpen).to.be.true
      expect(_spy).to.have.been.calledOnce
      record = _spy.args[0][0]
      expect(record.fStory).to.be.true
      expect(record.action).to.equal 'CREATED'

    it 'should allow changing its title', ->
      childStory.changeTitle 'another title'
      expect(childStory.title).to.equal 'another title'

    it 'should allow setting a story status', ->
      childStory.changeStatus 'RUNNING'
      expect(childStory.status).to.equal 'RUNNING'

    it 'should allow closing a story', ->
      childStory.close()
      expect(childStory.fOpen).to.be.false
      expect(_spy).to.have.been.calledTwice
      record = _spy.args[1][0]
      expect(record.fStory).to.be.true
      expect(record.action).to.equal 'CLOSED'

    it 'should allow adding parents after-the-fact', ->
      childStory.addParent 'parent2'
      expect(childStory.parents).to.deep.equal [mainStory.storyId, 'parent2']

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
