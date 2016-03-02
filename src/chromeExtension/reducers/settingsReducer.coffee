timm = require 'timm'

INITIAL_STATE =
  timeType: 'LOCAL'

reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    when 'TOGGLE_TIME_TYPE'
      newType = switch state.timeType
        when 'LOCAL' then 'RELATIVE'
        when 'RELATIVE' then 'UTC'
        else 'LOCAL'
      return timm.set state, 'timeType', newType

    else return state

module.exports = reducer
