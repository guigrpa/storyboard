timm = require 'timm'

INITIAL_STATE =
  cxState: 'DISCONNECTED'
  fTakingLong: false
  fLoginRequired: false
  loginState: 'LOGGED_OUT'
  login: null

reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    #-------------------------------------------------
    # ## Connection-related actions
    #-------------------------------------------------
    when 'CX_SUCCEEDED'
      return timm.set state, 'cxState', 'CONNECTED'

    when 'CX_TAKING_LONG'
      return timm.set state, 'fTakingLong', true

    #-------------------------------------------------
    # ## Login-related actions
    #-------------------------------------------------
    when 'LOGIN_REQUIRED'
      return timm.set state, 'fLoginRequired', true

    when 'LOGIN_STARTED'
      return timm.set state, 'loginState', 'LOGGING_IN'

    when 'LOGIN_SUCCEEDED'
      {login} = action
      return timm.merge state, {login, loginState: 'LOGGED_IN'}

    when 'LOGIN_FAILED'
      return timm.merge state, {login: null, loginState: 'LOGGED_OUT'}

    when 'LOGGED_OUT'
      return timm.merge state, {login: null, loginState: 'LOGGED_OUT'}

    else return state

module.exports = reducer
