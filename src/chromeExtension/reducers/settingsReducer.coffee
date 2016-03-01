timm = require 'timm'

INITIAL_STATE =
  fRelativeTime: false

reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    when 'TOGGLE_RELATIVE_TIME'
      return timm.set state, 'fRelativeTime', not state.fRelativeTime

    else return state

module.exports = reducer
