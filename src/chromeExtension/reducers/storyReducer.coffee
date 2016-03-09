_ = require '../../vendor/lodash'
timm = require 'timm'

_mainStoryPathStr = (fServer) -> "records/#{if fServer then 1 else 0}"
_mainStory = (fServer) ->
  idx = if fServer then 1 else 0
  id = "main_#{idx}"
  story = 
    id: id
    storyId: id
    pathStr: _mainStoryPathStr fServer
    fStoryObject: true
    t: new Date().getTime()
    src: 'main'
    title: if fServer then 'Server' else 'Client'
    fServer: fServer
    lastAction: 'CREATED'
    fOpen: true
    fMain: true
    status: undefined
    fExpanded: true
    fHierarchical: true
    records: []
  story

_buildInitialState = ->
  mainStory:
    fWrapper: true
    fOpen: true
    fExpanded: true
    fHierarchical: true
    records: [
      _mainStory false
      _mainStory true
    ]
  openStories: {}
  closedStories: {}
  quickFind: ''

INITIAL_STATE = _buildInitialState()

#-------------------------------------------------
# ## Reducer
#-------------------------------------------------
reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    # Clean up the main story after connecting
    # (we don't want to carry over logs from a previous page)
    when 'CX_SUCCEEDED', 'CLEAR_LOGS' then return _buildInitialState()

    when 'RECORDS_RECEIVED' then return _rxRecords state, action

    when 'TOGGLE_EXPANDED'
      {pathStr} = action
      return state if not pathStr?
      path = "mainStory/#{pathStr}/fExpanded".split '/'
      return timm.updateIn state, path, (fExpanded) -> not fExpanded

    when 'TOGGLE_HIERARCHICAL'
      {pathStr} = action
      return state if not pathStr?
      path = "mainStory/#{pathStr}/fHierarchical".split '/'
      return timm.updateIn state, path, (fHierarchical) -> not fHierarchical

    when 'TOGGLE_ATTACHMENT'
      {pathStr, recordId} = action
      return state if not(pathStr? and recordId?)
      pathStr = "mainStory/#{pathStr}"
      story = timm.getIn state, pathStr.split('/')
      return state if not story?
      recordPathStr = _findRecord story, recordId, not(story.fHierarchical), pathStr
      return state if not recordPathStr?
      recordPath = recordPathStr.split '/'
      record = timm.getIn state, recordPath
      recordPath.push 'objExpanded'
      return timm.setIn state, recordPath, not(record.objExpanded)

    when 'EXPAND_ALL_STORIES'   then return _expandCollapseAll state, true
    when 'COLLAPSE_ALL_STORIES' then return _expandCollapseAll state, false

    when 'QUICK_FIND' 
      {txt} = action
      if txt.length
        quickFind = txt.replace /([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1"
        quickFind = "(#{quickFind})"
      else
        quickFind = ''
      return timm.set state, 'quickFind', quickFind

    else return state

#-------------------------------------------------
# ## Adding records
#-------------------------------------------------
_rxRecords = (state, action) ->
  {records, fPastRecords} = action
  newStories = []
  for record in records
    if record.fStory 
      [state, pathStr] = _rxStory state, record, fPastRecords
      if pathStr then newStories.push pathStr
    else 
      state = _rxLog state, record, fPastRecords

  # Don't expand stories that are already closed upon reception
  for pathStr in newStories
    fOpen = timm.getIn state, "mainStory/#{pathStr}/fOpen".split('/')
    continue if fOpen
    state = timm.setIn state, "mainStory/#{pathStr}/fExpanded".split('/'), false
  state

_rxStory = (state, record, fPastRecords) ->
  {storyId} = record
  newStoryPathStr = null

  # We ignore root stories, both client- and server-side
  # (we have our own root stories)
  return [state, newStoryPathStr] if storyId is '*'

  # Check if we already have a story object for this `storyId`
  # and update it with this record. Normally we only
  # check in our list of open stories, except if we know
  # that we're receiving past records
  {openStories} = state
  pathStr = openStories[storyId]
  if (not pathStr?) and fPastRecords
    pathStr = state.closedStories[storyId]
  if pathStr?
    state = _updateStory state, pathStr, record
    state = _addLog state, pathStr, record

  # It's a new story. Look for the *most suitable parent* and create
  # a new child story object. The *most suitable parent* is
  # obtained as the first client-side parent, or otherwise the first
  # server-side parent
  else
    {parents, fServer} = record
    if parents?.length
      parentStoryId = _.find parents, (o) -> o[0] is 'c'
      parentStoryId ?= parents[0]
      pathStr = openStories[parentStoryId]
      if (not pathStr?) and fPastRecords
        pathStr = state.closedStories[parentStoryId]
    pathStr ?= _mainStoryPathStr fServer
    [state, newStoryPathStr] = _addStory state, pathStr, record
    state = _addLog state, newStoryPathStr, record

  # We return the new state, as well as the path of the new story (if any)
  return [state, newStoryPathStr]

_updateStory = (state, pathStr, record) ->
  {fOpen, title, status, action, storyId} = record
  path = "mainStory/#{pathStr}".split '/'
  prevStory = timm.getIn state, path
  nextStory = timm.merge prevStory, {fOpen, title, status, lastAction: action}
  state = timm.setIn state, path, nextStory
  if not nextStory.fOpen
    state = timm.setIn state, ['openStories',   storyId], undefined
    state = timm.setIn state, ['closedStories', storyId], pathStr
  state

_addStory = (state, parentStoryPathStr, record) ->
  parentRecordsPath = "mainStory/#{parentStoryPathStr}/records".split '/'
  parentRecords = timm.getIn state, parentRecordsPath
  pathStr = "#{parentStoryPathStr}/records/#{parentRecords.length}"
  story = timm.merge record, 
    pathStr: pathStr
    records: []
    fStoryObject: true
    lastAction: record.action
    fExpanded: true
    fHierarchical: true
  delete story.fStory
  delete story.action
  path = "mainStory/#{pathStr}".split '/'
  state = timm.setIn state, path, story
  pathSeg = if story.fOpen then 'openStories' else 'closedStories'
  state = timm.setIn state, [pathSeg, story.storyId], pathStr
  return [state, pathStr]

_rxLog = (state, record, fPastRecords) ->
  {storyId, fServer} = record
  pathStr = state.openStories[storyId] ? _mainStoryPathStr(fServer)
  state = _addLog state, pathStr, record, fPastRecords
  state

_addLog = (state, pathStr, record, fPastRecords) ->
  path = "mainStory/#{pathStr}/records".split '/'
  record = timm.set record, 'objExpanded', false
  return timm.updateIn state, path, (prevRecords) -> 
    if fPastRecords
      {id} = record
      if _.find(prevRecords, (o) -> o.id is id)?
        return prevRecords
    return timm.addLast prevRecords, record

#-------------------------------------------------
# ## Expand/collapse all
#-------------------------------------------------
_expandCollapseAll = (state, fExpanded) ->
  expandCollapse = (prevStory) ->
    nextRecords = prevStory.records.map expandCollapseRecord
    nextStory = timm.set prevStory, 'records', nextRecords
    if not(nextStory.fWrapper or nextStory.fMain)
      nextStory.fExpanded = fExpanded    # in-place since it is always a new object
    nextStory
  expandCollapseRecord = (prevRecord) ->
    return prevRecord if not prevRecord.fStoryObject
    return expandCollapse prevRecord
  newMainStory = expandCollapse state.mainStory, 0
  state = timm.set state, 'mainStory', newMainStory
  state

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
_findRecord = (story, recordId, fRecurse, pathStr) ->
  pathStr ?= story.pathStr
  for idx in [0...story.records.length]
    record = story.records[idx]
    if record.id is recordId
      return "#{pathStr}/records/#{idx}"
    if record.fStoryObject and fRecurse
      res = _findRecord record, recordId, fRecurse, "#{pathStr}/records/#{idx}"
      if res? then return res
  return null

module.exports = reducer
