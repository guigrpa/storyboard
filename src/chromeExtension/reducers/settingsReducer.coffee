timm = require 'timm'

INITIAL_STATE =
  timeType: 'LOCAL'
  fShowClosedActions: false

reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    when 'SET_TIME_TYPE'
      {timeType} = action
      return timm.set state, 'timeType', timeType

    when 'SET_SHOW_CLOSED_ACTIONS'
      {fShowClosedActions} = action
      return timm.set state, 'fShowClosedActions', fShowClosedActions

    else return state

module.exports = reducer
