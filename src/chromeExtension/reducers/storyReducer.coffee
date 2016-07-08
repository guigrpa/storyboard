_ = require '../../vendor/lodash'
k = require '../../gral/constants'
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
    numRecords: 0
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

#-------------------------------------------------
# ## Reducer
#-------------------------------------------------
reducer = (state = _buildInitialState(), action, settings = {}) ->
  switch action.type

    # Clean up the main story after connecting
    # (we don't want to carry over logs from a previous page)
    when 'CX_CONNECTED', 'CLEAR_LOGS' then return _buildInitialState()

    when 'RECORDS_RECEIVED' then return _rxRecords state, action, settings

    when 'FORGET' then return _forgetRecords state, action, settings

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
_rxRecords = (state, action, settings) ->
  {records, fPastRecords, fShorthandForDuplicates} = action
  options = timm.merge settings, {fPastRecords, fShorthandForDuplicates}
  newStories = []
  for record in records
    if record.fStory 
      [state, pathStr] = _rxStory state, record, options
      if pathStr then newStories.push pathStr
    else 
      state = _rxLog state, record, options

  # Don't expand stories that are already closed upon reception
  for pathStr in newStories
    fOpen = timm.getIn state, "mainStory/#{pathStr}/fOpen".split('/')
    continue if fOpen
    state = timm.setIn state, "mainStory/#{pathStr}/fExpanded".split('/'), false
  state

_rxStory = (state, record, options) ->
  {fPastRecords, fDiscardRemoteClientLogs} = options
  {storyId} = record
  newStoryPathStr = null

  # We ignore root stories (beginning by '*') always when they are not
  # flagged as uploaded, i.e. server root stories and the local client root story
  if (storyId[0] is '*') 
    if not record.uploadedBy
      return [state, newStoryPathStr]
    title = record.title.replace 'ROOT STORY', 'REMOTE CLIENT'
    record = timm.set record, 'title', title

  # We also ignore stories (not only root ones) when they have been
  # uploaded and the user doesn't want to see them
  if fDiscardRemoteClientLogs and record.uploadedBy
    return [state, newStoryPathStr]

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
    {state} = _addLog state, pathStr, record, options
    rootStoryIdx = pathStr.split('/')[1]

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
    [state, newStoryPathStr] = _addStory state, pathStr, record, options
    {state} = _addLog state, newStoryPathStr, record, options
    rootStoryIdx = newStoryPathStr.split('/')[1]

  # Increment counter
  state = timm.updateIn state, ['mainStory', 'records', rootStoryIdx, 'numRecords'], (o) -> o + 1

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

_addStory = (state, parentStoryPathStr, record, options) ->
  {fCollapseAllNewStories} = options
  parentRecordsPath = "mainStory/#{parentStoryPathStr}/records".split '/'
  parentRecords = timm.getIn state, parentRecordsPath
  pathStr = "#{parentStoryPathStr}/records/#{parentRecords.length}"
  story = timm.merge record, 
    pathStr: pathStr
    records: []
    fStoryObject: true
    lastAction: record.action
    fExpanded: not fCollapseAllNewStories
    fHierarchical: true
  delete story.fStory
  delete story.action
  path = "mainStory/#{pathStr}".split '/'
  state = timm.setIn state, path, story
  pathSeg = if story.fOpen then 'openStories' else 'closedStories'
  state = timm.setIn state, [pathSeg, story.storyId], pathStr
  return [state, pathStr]

_rxLog = (state, record, options) ->
  {storyId, fServer, uploadedBy} = record
  {fDiscardRemoteClientLogs} = options
  return state if fDiscardRemoteClientLogs and uploadedBy
  pathStr = state.openStories[storyId] ? _mainStoryPathStr(fServer)
  {state, fDuplicate} = _addLog state, pathStr, record, options
  if not fDuplicate
    rootStoryIdx = pathStr.split('/')[1]
    state = timm.updateIn state, ['mainStory', 'records', rootStoryIdx, 'numRecords'], (o) -> o + 1
  state

_addLog = (state, pathStr, record, options) ->
  {fPastRecords, fExpandAllNewAttachments, fShorthandForDuplicates} = options
  path = "mainStory/#{pathStr}/records".split '/'
  record = timm.set record, 'objExpanded', (fExpandAllNewAttachments ? false)
  fDuplicate = false
  state = timm.updateIn state, path, (prevRecords) -> 
    # Handle duplicates when including past records
    if fPastRecords
      {storyId, id} = record
      if _.find(prevRecords, (o) -> (o.storyId is storyId) and (o.id is id))?
        return prevRecords

    # Handle consecutive repetitions
    if (fShorthandForDuplicates ? true) and (not record.fStory)
      idx = prevRecords.length - 1
      prevLastRecord = prevRecords[idx]
      if prevLastRecord? and 
          (prevLastRecord.msg is record.msg) and 
          (prevLastRecord.src is record.src) and
          _.isEqual(prevLastRecord.obj, record.obj)
        fDuplicate = true
        repetitions = prevLastRecord.repetitions ? 0
        nextLastRecord = timm.merge prevLastRecord,
          repetitions: repetitions + 1
          tLastRepetition: record.t
        nextRecords = timm.replaceAt prevRecords, idx, nextLastRecord

    # Normal case
    nextRecords ?= timm.addLast prevRecords, record
    nextRecords

  # Flag stories containing warnings and errors
  fWarn = record.level is k.LEVEL_STR_TO_NUM.WARN
  fError = record.level >= k.LEVEL_STR_TO_NUM.ERROR
  if fWarn or fError
    recurPath = [].concat path
    while true
      recurPath.pop()    # recurPath is now the story path
      story = timm.getIn state, recurPath
      break if story.fMain
      if fWarn and not(story.fHasWarning)
        state = timm.setIn(state, recurPath.concat(['fHasWarning']), true)
      if fError and not(story.fHasError)
        state = timm.setIn(state, recurPath.concat(['fHasError']), true)
      recurPath.pop()

  return {state, fDuplicate}

#-------------------------------------------------
# ## Forgetting records
#-------------------------------------------------
_forgetRecords = (state, action, settings) ->
  {pathStr} = action
  {maxRecords, forgetHysteresis} = settings
  {mainStory} = state
  path = "mainStory/#{pathStr}".split '/'
  prevStory = timm.getIn state, path
  {numRecords} = prevStory
  targetForget = Math.ceil((numRecords - maxRecords) + (maxRecords * forgetHysteresis))
  result = _forgetRecursively prevStory, targetForget, {}, prevStory.pathStr
  {nextStory, numForgotten, updatedStoryPaths} = result
  nextStory.numRecords = numRecords - numForgotten
  state = timm.setIn state, path, nextStory
  openStories = _updateStoryPaths state.openStories, updatedStoryPaths
  closedStories = _updateStoryPaths state.closedStories, updatedStoryPaths
  state = timm.merge state, {openStories, closedStories}
  state

_forgetRecursively = (prevStory, targetForget, updatedStoryPaths, storyPathStr) ->
  numForgotten = 0
  nextRecords = []
  prevRecords = prevStory.records
  prevRecordsLen = prevRecords.length

  # Forget records
  idx = 0
  while idx < prevRecordsLen
    prevRecord = prevRecords[idx]
    fEnoughForgotten = (numForgotten >= targetForget)

    # Action records are never forgotten
    if prevRecord.fStory
      nextRecords.push prevRecord

    # Stories
    else if prevRecord.fStoryObject

      # Closed story objects are forgotten as a whole
      if (not fEnoughForgotten) and (not prevRecord.fOpen)
        numForgotten += _numStoryRecords prevRecord
        for storyId in _collectChildStoryIds prevRecord
          updatedStoryPaths[storyId] = null
        updatedStoryPaths[prevRecord.storyId] = null

      # Other cases: open stories, or enough forgotten. Copy at least some records
      else
        childPathStr = "#{storyPathStr}/records/#{nextRecords.length}"
        targetChildForget = if fEnoughForgotten then 0 else targetForget - numForgotten
        result = _forgetRecursively prevRecord, targetChildForget, \
          updatedStoryPaths, childPathStr
        nextChildStory = timm.set result.nextStory, 'pathStr', childPathStr
        nextRecords.push nextChildStory
        numForgotten += result.numForgotten
        updatedStoryPaths[prevRecord.storyId] = childPathStr

    # Normal logs
    else
      if fEnoughForgotten
        nextRecords.push prevRecord
      else
        numForgotten++

    idx++

  nextStory = timm.set prevStory, 'records', nextRecords
  return {nextStory, numForgotten, updatedStoryPaths}

_numStoryRecords = (story) ->
  num = 0
  for record in story.records
    if record.fStoryObject
      num += _numStoryRecords record
    else
      num++
  num

_collectChildStoryIds = (story, storyIds = []) ->
  for record in story.records when record.fStoryObject
    storyIds.push record.storyId
    _collectChildStoryIds record, storyIds
  storyIds

_updateStoryPaths = (storyHash, updatedStoryPaths) ->
  for storyId, pathStr of updatedStoryPaths
    if storyHash[storyId]?
      if pathStr is null then pathStr = undefined
      storyHash = timm.set storyHash, storyId, pathStr
  storyHash

#-------------------------------------------------
# ## Expand/collapse all
#-------------------------------------------------
_expandCollapseAll = (state, fExpanded) ->

  # Returns a new subtree, expanding/collapsing child stories
  expandCollapse = (prevStory) ->
    nextRecords = prevStory.records.map expandCollapseRecord  # new array always!
    nextStory = timm.set prevStory, 'records', nextRecords
    if not(nextStory.fWrapper or nextStory.fMain)
      nextStory.fExpanded = fExpanded    # in-place since it is always a new object
    nextStory

  # Returns:
  # - For normal records (logs): the same record
  # - For story objects: the expanded/collapsed record
  expandCollapseRecord = (prevRecord) ->
    return prevRecord if not prevRecord.fStoryObject
    return expandCollapse prevRecord

  # Run recursive algorithm
  newMainStory = expandCollapse state.mainStory
  state = timm.set state, 'mainStory', newMainStory
  state

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
_findRecord = (story, recordId, fRecurse, pathStr) ->
  for idx in [0...story.records.length] by +1
    record = story.records[idx]
    if record.id is recordId
      return "#{pathStr}/records/#{idx}"
    if record.fStoryObject and fRecurse
      res = _findRecord record, recordId, fRecurse, "#{pathStr}/records/#{idx}"
      if res? then return res
  return null

module.exports = reducer
