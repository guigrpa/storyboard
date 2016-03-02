timm = require 'timm'

_mainStoryPathStr = (fServer) -> "records/#{if fServer then 1 else 0}"
_mainStory = (fServer) ->
  idx = if fServer then 1 else 0
  id = "main_#{idx}"
  story = 
    id: id
    storyId: id
    pathStr: _mainStoryPathStr fServer
    fStory: true
    t: new Date().getTime()
    src: 'main'
    title: if fServer then 'Server' else 'Client'
    fServer: fServer
    action: 'CREATED'
    fOpen: true
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

INITIAL_STATE = _buildInitialState()

#-------------------------------------------------
# ## Reducer
#-------------------------------------------------
reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    # Clean up the main story after connecting
    # (we don't want to carry over logs from a previous page)
    when 'CX_SUCCEEDED' then return _buildInitialState()

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

    else return state

#-------------------------------------------------
# ## Processing records
#-------------------------------------------------
_rxRecords = (state, action) ->
  {records, fPastRecords} = action
  for record in records
    console.groupCollapsed "#{if record.fStory then record.title else record.msg}#{if record.action then ' - '+record.action else ''}"
    console.log "Story ID: #{record.storyId}"
    console.log "Current open stories:   #{Object.keys(state.openStories).map((o) -> o.slice 0, 7).join()}"
    console.log "Current closed stories: #{Object.keys(state.closedStories).map((o) -> o.slice 0, 7).join()}"
    if record.fStory 
      state = _rxStory state, record, fPastRecords
    else 
      state = _rxLog state, record
    console.groupEnd()
  state

_rxStory = (state, record, fPastRecords) ->
  {storyId} = record

  # We ignore root stories, both client- and server-side
  # (we have our own root stories)
  return state if storyId is '*'

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
    state = _addStory state, pathStr, record
  state

_updateStory = (state, pathStr, record) ->
  {fOpen, title, status, action, storyId} = record
  path = "mainStory/#{pathStr}".split '/'
  prevStory = timm.getIn state, path
  newStory = timm.merge prevStory, {fOpen, title, status, action}
  state = timm.setIn state, path, newStory
  if not newStory.fOpen 
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
    fExpanded: true
    fHierarchical: true
  path = "mainStory/#{pathStr}".split '/'
  state = timm.setIn state, path, story
  pathSeg = if story.fOpen then 'openStories' else 'closedStories'
  state = timm.setIn state, [pathSeg, story.storyId], pathStr
  state

_rxLog = (state, record) ->
  {storyId, fServer} = record
  pathStr = state.openStories[storyId] ? _mainStoryPathStr(fServer)
  path = "mainStory/#{pathStr}/records".split '/'
  state = timm.updateIn state, path, (prevRecords) ->
    return timm.addLast prevRecords, record
  state

module.exports = reducer
