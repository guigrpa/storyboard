timm = require 'timm'

INITIAL_STATE =
  loginState: 'LOGGED_OUT'

reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    when 'LOGIN_STARTED'
      return timm.set state, 'loginState', 'LOGGING_IN'

    when 'LOGIN_SUCCEEDED'
      return timm.set state, 'loginState', 'LOGGED_IN'

    when 'LOGIN_FAILED'
      return timm.set state, 'loginState', 'LOGGED_OUT'

    when 'LOGGED_OUT'
      return timm.set state, 'loginState', 'LOGGED_OUT'

    else return state

module.exports = reducer
