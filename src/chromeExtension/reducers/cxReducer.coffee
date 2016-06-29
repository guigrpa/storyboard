timm = require 'timm'

INITIAL_STATE =
  cxState: 'DISCONNECTED'   # connection with the WsClient listener ("the" page)
  fLoginRequired: null
  serverFilter: null
  localClientFilter: null
  loginState: 'LOGGED_OUT'
  wsState: 'DISCONNECTED'   # connection btw WsClient listener and WsServer listener
  login: null

reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    #-------------------------------------------------
    # ## Connection-related actions (page-extension connection)
    #-------------------------------------------------
    when 'CX_CONNECTED'
      return timm.set state, 'cxState', 'CONNECTED'

    when 'CX_DISCONNECTED'
      return timm.set state, 'cxState', 'DISCONNECTED'

    #-------------------------------------------------
    # ## WebSocket-related actions
    #-------------------------------------------------
    when 'WS_CONNECTED'
      return timm.set state, 'wsState', 'CONNECTED'

    when 'WS_DISCONNECTED'
      return timm.set state, 'wsState', 'DISCONNECTED'

    #-------------------------------------------------
    # ## Login-related actions
    #-------------------------------------------------
    when 'LOGIN_REQUIRED'
      {fLoginRequired} = action
      return timm.set state, 'fLoginRequired', fLoginRequired

    when 'LOGIN_STARTED'
      return timm.set state, 'loginState', 'LOGGING_IN'

    when 'LOGIN_SUCCEEDED'
      {login} = action
      return timm.merge state, {login, loginState: 'LOGGED_IN'}

    when 'LOGGED_OUT'
      return timm.merge state, {login: null, loginState: 'LOGGED_OUT'}

    #-------------------------------------------------
    # ## Filters
    #-------------------------------------------------
    when 'SERVER_FILTER'
      {filter} = action
      return timm.set state, 'serverFilter', filter

    when 'LOCAL_CLIENT_FILTER'
      {filter} = action
      return timm.set state, 'localClientFilter', filter

    else return state

module.exports = reducer
