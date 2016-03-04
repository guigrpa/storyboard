toggleTimeType = -> {type: 'TOGGLE_TIME_TYPE'}
toggleShowClosedActions = -> {type: 'TOGGLE_SHOW_CLOSED_ACTIONS'}

module.exports =
  actions: {
    toggleTimeType,
    toggleShowClosedActions,
  }
