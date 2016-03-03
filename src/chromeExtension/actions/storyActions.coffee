toggleExpanded = (pathStr) -> 
  {type: 'TOGGLE_EXPANDED', pathStr}
toggleHierarchical = (pathStr) -> 
  {type: 'TOGGLE_HIERARCHICAL', pathStr}
toggleAttachment = (pathStr, recordId) ->
  {type: 'TOGGLE_ATTACHMENT', pathStr, recordId}
expandAllStories = -> {type: 'EXPAND_ALL_STORIES'}
collapseAllStories = -> {type: 'COLLAPSE_ALL_STORIES'}

module.exports =
  actions: {
    toggleExpanded,
    toggleHierarchical,
    toggleAttachment,
    expandAllStories,
    collapseAllStories,
  }
