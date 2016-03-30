_         = require 'lodash'
timm      = require 'timm'
{expect}  = require './imports'
reducer   = require '../../lib/chromeExtension/reducers/storyReducer'
treeLines = require '../../lib/gral/treeLines'

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
_settings = (settings = {}) -> timm.addDefaults settings,
  maxRecords: 50
  forgetHysteresis: 0.25

_recordsReceived = (records, fPastRecords = false) -> 
 return {type: 'RECORDS_RECEIVED', records, fPastRecords}

_forget = (action = {}) -> timm.addDefaults action, 
  type: 'FORGET'
  pathStr: "records/0"

_seqId = 0
_log = (record) -> timm.addDefaults record,
  fStory: false
  fServer: false
  src: 'main'
  level: 30
  storyId: '*'
  id: "llll#{_seqId++}"

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
      state = reducer state, _forget(), _settings({maxRecords: 4})
      topStory = state.mainStory.records[0]
      expect(topStory.records.length).to.equal 3    # forget: (8-4) + 0.25*4 = 5
      expect(topStory.records[0].msg).to.equal 'msg5'
      expect(topStory.records[1].msg).to.equal 'msg6'
      expect(topStory.records[2].msg).to.equal 'msg7'
      expect(topStory.numRecords).to.equal 3

    it 'closed stories should be forgotten', ->
      openStoryRecord0 = _openStory {title: 'story0'}
      openStoryRecord1 = _openStory {title: 'story1', parents: [openStoryRecord0.storyId]}
      state = reducer state, _recordsReceived [
        _log {msg: "msg0"}
        openStoryRecord0
        _log {msg: "story log", storyId: openStoryRecord0.storyId}
        openStoryRecord1
        _closeStory openStoryRecord1.storyId
        _closeStory openStoryRecord0.storyId
        _log {msg: "msg1"}
      ]
      ## console.log JSON.stringify state.mainStory.records[0], null, '  '
      expect(state.mainStory.records[0].numRecords).to.equal 7
      state = reducer state, _forget(), _settings({maxRecords: 4})
      topStory = state.mainStory.records[0]
      expect(topStory.records.length).to.equal 1
      expect(topStory.records[0].msg).to.equal 'msg1'
      expect(topStory.numRecords).to.equal 1
      expect(state.closedStories[openStoryRecord0.storyId]).to.be.undefined
      expect(state.closedStories[openStoryRecord1.storyId]).to.be.undefined

    it 'the pathStr of open stories should be updated if necessary', ->
      openStoryRecord0 = _openStory {title: 'story0'}
      openStoryRecord1 = _openStory {title: 'story1', parents: [openStoryRecord0.storyId]}
      openStoryRecord2 = _openStory {title: 'story2', parents: [openStoryRecord1.storyId]}
      state = reducer state, _recordsReceived [
        _log {msg: "msg0"}
        _log {msg: "msg1"}
        openStoryRecord0
        openStoryRecord1
        openStoryRecord2
      ]
      expect(state.mainStory.records[0].numRecords).to.equal 5
      state = reducer state, _forget(), _settings({maxRecords: 1})
      topStory = state.mainStory.records[0]
      expect(topStory.records.length).to.equal 1
      expect(topStory.records[0].title).to.equal 'story0'
      expect(topStory.records[0].pathStr).to.equal 'records/0/records/0'
      expect(topStory.records[0].records.length).to.equal 2
      expect(topStory.records[0].records[0].action).to.equal 'CREATED'
      expect(topStory.records[0].records[1].title).to.equal 'story1'
      expect(topStory.records[0].records[1].pathStr).to.equal 'records/0/records/0/records/1'
      expect(topStory.records[0].records[1].records.length).to.equal 2
      expect(topStory.records[0].records[1].records[0].action).to.equal 'CREATED'
      expect(topStory.records[0].records[1].records[1].title).to.equal 'story2'
      expect(topStory.records[0].records[1].records[1].pathStr).to.equal 'records/0/records/0/records/1/records/1'
      expect(topStory.numRecords).to.equal 3
      expect(state.openStories[openStoryRecord0.storyId]).to.equal 'records/0/records/0'
      expect(state.openStories[openStoryRecord1.storyId]).to.equal 'records/0/records/0/records/1'
      expect(state.openStories[openStoryRecord2.storyId]).to.equal 'records/0/records/0/records/1/records/1'

  describe 'multiple actions', ->
    beforeEach ->
      openStoryRecord0 = _openStory {title: 'story0'}
      openStoryRecord1 = _openStory {title: 'story1', parents: [openStoryRecord0.storyId]}
      attachment = {a: 1, b: 2, c: 3}
      logRecord = _log
        id: 'logWithAttachment' 
        storyId: openStoryRecord1.storyId
        msg: "log with attachment"
        obj: treeLines attachment
        objExpanded: false 
      state = reducer state, _recordsReceived [
        openStoryRecord0
        openStoryRecord1
        logRecord
      ]
      expect(state.mainStory.records[0].records[0].fExpanded).to.be.true
      expect(state.mainStory.records[0].records[0].records[1].fExpanded).to.be.true

    it 'should allow expanding/collapsing all stories', ->
      state = reducer state, {type: 'COLLAPSE_ALL_STORIES'}
      expect(state.mainStory.records[0].records[0].fExpanded).to.be.false
      expect(state.mainStory.records[0].records[0].records[1].fExpanded).to.be.false
      state = reducer state, {type: 'EXPAND_ALL_STORIES'}
      expect(state.mainStory.records[0].records[0].fExpanded).to.be.true
      expect(state.mainStory.records[0].records[0].records[1].fExpanded).to.be.true

    it 'should allow expanding/collapsing an individual story', ->
      state = reducer state, {type: 'TOGGLE_EXPANDED', pathStr: 'records/0/records/0'}
      expect(state.mainStory.records[0].records[0].fExpanded).to.be.false
      state = reducer state, {type: 'TOGGLE_EXPANDED', pathStr: 'records/0/records/0'}
      expect(state.mainStory.records[0].records[0].fExpanded).to.be.true
      state2 = reducer state, {type: 'TOGGLE_EXPANDED'}
      expect(state2).to.equal state

    it 'should allow showing stories in a flat/hierarchical way', ->
      state = reducer state, {type: 'TOGGLE_HIERARCHICAL', pathStr: 'records/0/records/0'}
      expect(state.mainStory.records[0].records[0].fHierarchical).to.be.false
      state = reducer state, {type: 'TOGGLE_HIERARCHICAL', pathStr: 'records/0/records/0'}
      expect(state.mainStory.records[0].records[0].fHierarchical).to.be.true
      state2 = reducer state, {type: 'TOGGLE_HIERARCHICAL'}
      expect(state2).to.equal state

    it 'should store quick-find info', ->
      state = reducer state, {type: 'QUICK_FIND', txt: 'hello'}
      expect(state.quickFind).to.equal '(hello)'
      state = reducer state, {type: 'QUICK_FIND', txt: ''}
      expect(state.quickFind).to.equal ''
      state = reducer state, {type: 'QUICK_FIND', txt: '.+*'}
      expect(state.quickFind).to.equal '(\\.\\+\\*)'

    it 'should clear the state when receiving a CX_CONNECTED action', ->
      state = reducer state, {type: 'CX_CONNECTED'}
      expect(state.mainStory.records[0].records).to.have.length 0
      expect(state.mainStory.records[1].records).to.have.length 0

    it 'should clear the state when receiving a CLEAR_LOGS action', ->
      state = reducer state, {type: 'CLEAR_LOGS'}
      expect(state.mainStory.records[0].records).to.have.length 0
      expect(state.mainStory.records[1].records).to.have.length 0

    describe 'expanding attachments', ->
      it 'in a hierarchical story', ->
        expect(state.mainStory.records[0].records[0].records[1].records[1].msg).to.contain 'with attachment'
        expect(state.mainStory.records[0].records[0].records[1].records[1].objExpanded).to.be.false
        pathStr = "records/0/records/0/records/1"
        state = reducer state, {type: 'TOGGLE_ATTACHMENT', pathStr, recordId: 'logWithAttachment'}
        expect(state.mainStory.records[0].records[0].records[1].records[1].objExpanded).to.be.true
        state = reducer state, {type: 'TOGGLE_ATTACHMENT', pathStr, recordId: 'logWithAttachment'}
        expect(state.mainStory.records[0].records[0].records[1].records[1].objExpanded).to.be.false

      it 'in a flat story', ->
        pathStr = "records/0"
        state = reducer state, {type: 'TOGGLE_HIERARCHICAL', pathStr}
        expect(state.mainStory.records[0].fHierarchical).to.be.false
        state = reducer state, {type: 'TOGGLE_ATTACHMENT', pathStr, recordId: 'logWithAttachment'}
        expect(state.mainStory.records[0].records[0].records[1].records[1].objExpanded).to.be.true
        state = reducer state, {type: 'TOGGLE_ATTACHMENT', pathStr, recordId: 'logWithAttachment'}
        expect(state.mainStory.records[0].records[0].records[1].records[1].objExpanded).to.be.false

      it 'with incorrect arguments', ->
        pathStr = "records/0"
        state2 = reducer state, {type: 'TOGGLE_ATTACHMENT', pathStr, recordId: 'xxx'}
        expect(state2).to.equal state
        state2 = reducer state, {type: 'TOGGLE_ATTACHMENT', pathStr: null, recordId: 'xxx'}
        expect(state2).to.equal state
        state2 = reducer state, {type: 'TOGGLE_ATTACHMENT', pathStr: 'unknown/path', recordId: 'xxx'}
        expect(state2).to.equal state

  describe 'adding a new story to a closed story', ->

    _storyId = null
    beforeEach ->
      openStoryRecord = _openStory {title: 'story0'}
      _storyId = openStoryRecord.storyId
      state = reducer state, _recordsReceived [
        openStoryRecord
        _closeStory _storyId
      ]

    it 'with fPastRecords: false (should NOT include it in the closed story)', ->
      state = reducer state, _recordsReceived([_openStory {title: "child", parents: [_storyId]}], false)
      expect(state.mainStory.records[0].records[0].records.length).to.equal 2 # CREATED and CLOSED
      expect(state.mainStory.records[0].records[1].title).to.equal 'child'

    it 'with fPastRecords: true (should include it in the closed story)', ->
      state = reducer state, _recordsReceived([_openStory {title: "child", parents: [_storyId]}], true)
      expect(state.mainStory.records[0].records[0].records.length).to.equal 3
      expect(state.mainStory.records[0].records[0].records[2].title).to.equal 'child'

  it 'adding a root story should be ignored', ->
    state2 = reducer state, _recordsReceived [_openStory {title: 'rootStory23', storyId: '*'}]
    expect(state2).to.equal state

  describe 'showing identical consecutive logs', ->

    it 'by default, should use shorthand notation', ->
      state = reducer state, _recordsReceived [
        _log msg: "msg23"
        _log msg: "msg23"
        _log msg: "msg23"
      ]
      expect(state.mainStory.records[0].records).to.have.length 1
      record = state.mainStory.records[0].records[0]
      expect(record.repetitions).to.equal 2
      expect(record.tLastRepetition).not.to.be.null

    it 'with fShorthandForDuplicates=false, should include all logs', ->
      state = reducer state, _recordsReceived([
        _log msg: "msg23"
        _log msg: "msg23"
        _log msg: "msg23"
      ]), {fShorthandForDuplicates: false}
      expect(state.mainStory.records[0].records).to.have.length 3

    it 'should detect when attachments are equal', ->
      state = reducer state, _recordsReceived [
        _log msg: "msg45", obj: ['line1', 'line2']
        _log msg: "msg45", obj: ['line1', 'line2']
      ]
      expect(state.mainStory.records[0].records).to.have.length 1

    it 'should detect when attachments are different', ->
      state = reducer state, _recordsReceived [
        _log msg: "msg45", obj: ['line1', 'line2']
        _log msg: "msg45", obj: ['line1', 'DIFFERENT']
      ]
      expect(state.mainStory.records[0].records).to.have.length 2

  it 'should remove duplicates when using fPastRecords', ->
    state = reducer state, _recordsReceived [
      _log {msg: 'msg0', id: 'id0'}
      _log {msg: 'msg1', id: 'id1'}
    ]
    state = reducer state, _recordsReceived([
      _log {msg: 'msg0', id: 'id0'}
    ], true)
    expect(state.mainStory.records[0].records).to.have.length 2
    expect(state.mainStory.records[0].records[0].id).to.equal 'id0'
    expect(state.mainStory.records[0].records[1].id).to.equal 'id1'
