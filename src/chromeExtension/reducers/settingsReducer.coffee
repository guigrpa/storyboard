timm = require 'timm'

INITIAL_STATE =
  timeType: 'LOCAL'
  fShowClosedActions: false

reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    when 'TOGGLE_TIME_TYPE'
      newType = switch state.timeType
        when 'LOCAL' then 'RELATIVE'
        when 'RELATIVE' then 'UTC'
        else 'LOCAL'
      return timm.set state, 'timeType', newType

    when 'TOGGLE_SHOW_CLOSED_ACTIONS'
      return timm.set state, 'fShowClosedActions', \
        not state.fShowClosedActions

    else return state

module.exports = reducer
