timm = require 'timm'
{expect} = require './imports'
reducer = require '../../lib/chromeExtension/reducers/storyReducer'
_ = require 'lodash'

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
_recordsReceived = (records) -> {type: 'RECORDS_RECEIVED', records}
_forget = (action) -> timm.merge action, 
  type: 'FORGET'
  forgetHysteresis: 0.25
  pathStr: "records/0"

_log = (record) -> timm.addDefaults record,
  fStory: false
  fServer: false
  src: 'main'
  level: 30
  storyId: '*'

_actionRecord = (record) -> timm.addDefaults record,
  fStory: true
  fServer: false
  fOpen: true
  src: 'main'
  level: 30

_seqStoryId = 0
_openStory = (record) -> _actionRecord timm.addDefaults record,
  action: 'CREATED'
  storyId: "ssss#{_seqStoryId++}"
  parents: []
_closeStory = (storyId) -> _actionRecord {storyId, action: 'CLOSED', fOpen: false}
_storyAction = (storyId, action) -> _actionRecord {storyId}

#-------------------------------------------------
# ## Tests
#-------------------------------------------------
describe 'storyReducer', ->
  
  state = null
  beforeEach -> state = reducer undefined, {type: ''}

  it 'should have correct initial state', ->
    {mainStory, openStories, closedStories, quickFind} = state
    expect(mainStory.records).to.have.length 2
    expect(mainStory.fExpanded).to.be.true
    expect(mainStory.fHierarchical).to.be.true
    expect(mainStory.fOpen).to.be.true
    expect(mainStory.records[0].numRecords).to.equal 0
    expect(mainStory.records[1].numRecords).to.equal 0
    expect(openStories).to.deep.equal {}
    expect(closedStories).to.deep.equal {}
    expect(quickFind).to.equal ''

  describe 'forgetting', ->

    it 'normal logs should be forgotten', ->
      records = _.map [0...8], (idx) -> _log msg: "msg#{idx}"
      state = reducer state, _recordsReceived records
      expect(state.mainStory.records[0].numRecords).to.equal 8
      state = reducer state, _forget({maxRecords: 4})
      topStory = state.mainStory.records[0]
      expect(topStory.records.length).to.equal 3    # forget: (8-4) + 0.25*4 = 5
      expect(topStory.records[0].msg).to.equal 'msg5'
      expect(topStory.records[1].msg).to.equal 'msg6'
      expect(topStory.records[2].msg).to.equal 'msg7'
      expect(topStory.numRecords).to.equal 3

    it 'closed stories should be forgotten', ->
      openStoryRecord = _openStory {title: 'story0'}
      state = reducer state, _recordsReceived [
        _log {msg: "msg0"}
        openStoryRecord
        _log {msg: "story log", storyId: openStoryRecord.storyId}
        _closeStory openStoryRecord.storyId
        _log {msg: "msg1"}
      ]
      ## console.log JSON.stringify state.mainStory.records[0], null, '  '
      expect(state.mainStory.records[0].numRecords).to.equal 5
      state = reducer state, _forget {maxRecords: 4}
      topStory = state.mainStory.records[0]
      expect(topStory.records.length).to.equal 1
      expect(topStory.records[0].msg).to.equal 'msg1'
      expect(topStory.numRecords).to.equal 1

    it 'the pathStr of open stories should be updated if necessary', ->
      openStoryRecord0 = _openStory {title: 'story0'}
      openStoryRecord1 = _openStory {title: 'story1', parents: [openStoryRecord0.storyId]}
      state = reducer state, _recordsReceived [
        _log {msg: "msg0"}
        _log {msg: "msg1"}
        openStoryRecord0
        openStoryRecord1
      ]
      expect(state.mainStory.records[0].numRecords).to.equal 4
      state = reducer state, _forget({maxRecords: 1})
      topStory = state.mainStory.records[0]
      expect(topStory.records.length).to.equal 1
      expect(topStory.records[0].title).to.equal 'story0'
      expect(topStory.records[0].pathStr).to.equal 'records/0/records/0'
      expect(topStory.records[0].records.length).to.equal 2
      expect(topStory.records[0].records[0].action).to.equal 'CREATED'
      expect(topStory.records[0].records[1].title).to.equal 'story1'
      expect(topStory.records[0].records[1].pathStr).to.equal 'records/0/records/0/records/1'
      expect(topStory.numRecords).to.equal 2
      expect(state.openStories[openStoryRecord0.storyId]).to.equal 'records/0/records/0'
      expect(state.openStories[openStoryRecord1.storyId]).to.equal 'records/0/records/0/records/1'
