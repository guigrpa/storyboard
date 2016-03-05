setTimeType = (timeType) -> {type: 'SET_TIME_TYPE', timeType}
setShowClosedActions = (fEnabled) -> {type: 'SET_SHOW_CLOSED_ACTIONS', fEnabled}

module.exports =
  actions: {
    setTimeType,
    setShowClosedActions,
  }
