timm = require 'timm'

_mainStory = (fServer) ->
  pathStr: "records/#{idx}"
  idx = if fServer then 1 else 0
  id = "main_#{idx}"
  id: id
  storyId: id
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

INITIAL_STATE =
  mainStory:
    fWrapper: true
    fOpen: true
    records: [
      _mainStory false
      _mainStory true
    ]
  openStories: {}
  closedStories: {}

reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    when 'TOGGLE_EXPANDED'
      {pathStr} = action
      path = "mainStory/#{pathStr}/fExpanded".split '/'
      return timm.updateIn state, path, (fExpanded) -> not fExpanded

    when 'TOGGLE_HIERARCHICAL'
      {pathStr} = action
      path = "mainStory/#{pathStr}/fHierarchical".split '/'
      return timm.updateIn state, path, (fHierarchical) -> not fHierarchical

    else return state

module.exports = reducer
