React             = require 'react'
ReactRedux        = require 'react-redux'
{ Icon, Spinner } = require 'giu'
actions           = require '../actions/actions'

RETURN_KEY = 13

mapStateToProps = ({cx: {fLoginRequired, loginState, login}}) -> 
  return {fLoginRequired, loginState, login}
mapDispatchToProps = (dispatch) ->
  onLogIn: (credentials) -> dispatch actions.logIn credentials
  onLogOut: -> dispatch actions.logOut()

Login = React.createClass
  displayName: 'Login'

  #-----------------------------------------------------
  propTypes:
    # From Redux.connect
    fLoginRequired:         React.PropTypes.bool
    loginState:             React.PropTypes.string.isRequired
    login:                  React.PropTypes.string
    onLogIn:                React.PropTypes.func.isRequired
    onLogOut:               React.PropTypes.func.isRequired
  getInitialState: ->
    login:                  ''
    password:               ''

  #-----------------------------------------------------
  render: -> 
    {fLoginRequired, loginState} = @props
    if not fLoginRequired?
      return (
        <div style={_style.outer()}>
          <Spinner size="lg" fixedWidth />
        </div>
      )
    if not fLoginRequired
      return <div style={_style.outer()}><i>No login required to see server logs</i></div>
    if loginState is 'LOGGED_IN'
      return @renderLogOut()
    else
      return @renderLogIn()

  renderLogOut: ->
    {login} = @props
    msg = if login then "Logged in as #{login}" else "Logged in"
    <div style={_style.outer()}>
      {msg}
      {' '}
      <Icon 
        icon="sign-out" 
        title="Log out"
        size="lg" 
        fixedWidth
        onClick={@logOut}
      />
    </div>

  renderLogIn: ->
    {loginState} = @props
    btn = switch loginState
      when 'LOGGED_OUT', 'LOGGED_OUT_WITH_ERROR'
        <Icon 
          icon="sign-in" 
          title="Log in"
          size="lg" 
          fixedWidth
          onClick={@logIn}
        />
      when 'LOGGING_IN' 
        <Spinner 
          title="Logging in"
          size="lg" 
          fixedWidth
        />
      else ''
    fError = loginState is 'LOGGED_OUT_WITH_ERROR'
    <div style={_style.outer true}>
      <b>Server logs:</b>
      {' '}
      <span>
        <input ref="login"
          id="login"
          type="text"
          value={@state.login}
          placeholder="Login"
          onChange={@onChangeCredentials}
          onKeyUp={@onKeyUpCredentials}
          style={_style.field fError}
        />
        <input ref="password"
          id="password"
          type="password"
          value={@state.password}
          placeholder="Password"
          onChange={@onChangeCredentials}
          onKeyUp={@onKeyUpCredentials}
          style={_style.field fError}
        />
        {btn}
      </span>
    </div>

  #-----------------------------------------------------
  logIn: -> @props.onLogIn @state 
  logOut: ->
    @setState {login: '', password: ''}
    @props.onLogOut()

  onKeyUpCredentials: (ev) -> @logIn() if ev.which is RETURN_KEY

  onChangeCredentials: (ev) -> 
    @setState {"#{ev.target.id}": ev.target.value}

#-----------------------------------------------------
_style = 
  outer: (fHighlight) ->
    padding: "4px 10px"
    backgroundColor: if fHighlight then '#d6ecff'
  field: (fError) ->
    marginRight: 4
    width: 70
    backgroundColor: if fError then 'blanchedalmond'

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, mapDispatchToProps
module.exports = connect Login
