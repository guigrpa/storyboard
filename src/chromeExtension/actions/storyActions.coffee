_       = require '../../vendor/lodash'
Promise = require 'bluebird'
Saga    = require 'redux-saga/effects'
require 'babel-polyfill'

CHECK_FORGET_PERIOD = 3000
QUICK_FIND_DEBOUNCE = 250

#-------------------------------------------------
# ## Miscellaneous actions
#-------------------------------------------------
toggleExpanded = (pathStr) ->
  {type: 'TOGGLE_EXPANDED', pathStr}
toggleHierarchical = (pathStr) ->
  {type: 'TOGGLE_HIERARCHICAL', pathStr}
toggleAttachment = (pathStr, recordId) ->
  {type: 'TOGGLE_ATTACHMENT', pathStr, recordId}
expandAllStories = -> {type: 'EXPAND_ALL_STORIES'}
collapseAllStories = -> {type: 'COLLAPSE_ALL_STORIES'}
clearLogs = -> {type: 'CLEAR_LOGS'}
quickFind = (txt) -> (dispatch) -> _quickFind dispatch, txt
_quickFind = _.debounce (dispatch, txt) ->
  dispatch {type: 'QUICK_FIND', txt}
, QUICK_FIND_DEBOUNCE

#-------------------------------------------------
# ## forgetRecords saga
#-------------------------------------------------
forgetRecords = ->
  while true
    for idx in [0, 1]
      {story, maxRecords} = yield Saga.select (state) ->
        story:      state.stories.mainStory.records[idx]
        maxRecords: state.settings.maxRecords
      if story.numRecords > maxRecords
        yield Saga.put {type: 'FORGET', pathStr: story.pathStr}
    yield Promise.delay CHECK_FORGET_PERIOD
  return

#-------------------------------------------------
# ## API
#-------------------------------------------------
module.exports = {
  actions: {
    toggleExpanded,
    toggleHierarchical,
    toggleAttachment,
    expandAllStories,
    collapseAllStories,
    clearLogs,
    quickFind,
  }
  sagas: [
    forgetRecords
  ]
}
