toggleExpanded = (pathStr) -> 
  {type: 'TOGGLE_EXPANDED', pathStr}
toggleHierarchical = (pathStr) -> 
  {type: 'TOGGLE_HIERARCHICAL', pathStr}

module.exports =
  actions: {
    toggleExpanded,
    toggleHierarchical,
  }
