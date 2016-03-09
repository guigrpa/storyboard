_ = require '../../vendor/lodash'

QUICK_FIND_DEBOUNCE = 250

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

module.exports =
  actions: {
    toggleExpanded,
    toggleHierarchical,
    toggleAttachment,
    expandAllStories,
    collapseAllStories,
    clearLogs,
    quickFind,
  }
