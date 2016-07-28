React             = require 'react'
ReactRedux        = require 'react-redux'
{
  notify,
  TextInput, PasswordInput,
  Icon, Spinner,
}                 = require 'giu'
Promise           = require 'bluebird'
actions           = require '../actions/actions'

RETURN_KEY = 13

mapStateToProps = ({cx: {fLoginRequired, loginState, login}}) ->
  return {fLoginRequired, loginState, login}

Login = React.createClass
  displayName: 'Login'

  #-----------------------------------------------------
  propTypes:
    colors:                 React.PropTypes.object.isRequired
    # From Redux.connect
    fLoginRequired:         React.PropTypes.bool
    loginState:             React.PropTypes.string.isRequired
    login:                  React.PropTypes.string
    logIn:                  React.PropTypes.func.isRequired
    logOut:                 React.PropTypes.func.isRequired

  #-----------------------------------------------------
  render: ->
    { fLoginRequired, loginState, colors } = @props
    if not fLoginRequired?
      return (
        <div style={_style.outer(colors)}>
          <Spinner size="lg" fixedWidth />
        </div>
      )
    if not fLoginRequired
      return <div style={_style.outer(colors)}><i>No login required to see server logs</i></div>
    if loginState is 'LOGGED_IN'
      return @renderLogOut()
    else
      return @renderLogIn()

  renderLogOut: ->
    { login, colors } = @props
    msg = if login then "Logged in as #{login}" else "Logged in"
    <div style={_style.outer(colors)}>
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
    { loginState, colors } = @props
    btn = switch loginState
      when 'LOGGED_OUT'
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
    <div style={_style.outer colors, true}>
      <b>Server logs:</b>
      {' '}
      <TextInput ref="login"
        id="login"
        placeholder="Login"
        onKeyUp={@onKeyUpCredentials}
        style={_style.field}
        required errorZ={12}
      />
      <PasswordInput ref="password"
        id="password"
        placeholder="Password"
        onKeyUp={@onKeyUpCredentials}
        style={_style.field}
        required errorZ={12}
      />
      {btn}
    </div>

  #-----------------------------------------------------
  logIn: ->
    credentials = {}
    Promise.map ['login', 'password'], (key) =>
      this.refs[key].validateAndGetValue()
      .then (val) -> credentials[key] = val
    .then => @props.logIn credentials
    return

  logOut: -> @props.logOut()

  onKeyUpCredentials: (ev) -> @logIn() if ev.which is RETURN_KEY

#-----------------------------------------------------
_style =
  outer: (colors, fHighlight) ->
    padding: "4px 10px"
    backgroundColor: if fHighlight then colors.colorServerBg else colors.colorUiBg
    color: if fHighlight then colors.colorServerFg else colors.colorUiFg
  field:
    marginRight: 4
    width: 70
    backgroundColor: 'transparent'

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, actions
module.exports = connect Login
