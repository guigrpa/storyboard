React             = require 'react'
ReactRedux        = require 'react-redux'
actions           = require '../actions/actions'

mapStateToProps = ({cx: {fLoginRequired, loginState, login}}) -> 
  return {fLoginRequired, loginState, login}
mapDispatchToProps = (dispatch) ->
  onSubmit: (credentials) -> dispatch actions.logIn credentials

Login = React.createClass
  displayName: 'Login'

  #-----------------------------------------------------
  propTypes:
    # From Redux.connect
    fLoginRequired:         React.PropTypes.bool.isRequired
    loginState:             React.PropTypes.string.isRequired
    login:                  React.PropTypes.string
    onSubmit:               React.PropTypes.func.isRequired
  getInitialState: ->
    login:                  ''
    password:               ''

  #-----------------------------------------------------
  render: -> 
    {fLoginRequired, loginState} = @props
    if (not fLoginRequired) or (loginState is 'LOGGED_IN')
      return <div/>
    btnMessage = switch @props.loginState
      when 'LOGGED_OUT' then 'Submit'
      when 'LOGGING_IN' then 'Logging in...'
      else 'Logged in'
    <div style={_style.outer}>
      The Storyboard server asks for your credentials:
      {' '}
      <div>
        <input ref="login"
          id="login"
          type="text"
          value={@state.login}
          placeholder="Login"
          onChange={@onChangeCredentials}
          style={_style.field}
        />
        <input ref="password"
          id="password"
          type="password"
          value={@state.password}
          placeholder="Password"
          onChange={@onChangeCredentials}
          style={_style.field}
        />
        <button 
          onClick={@onClickSubmit} 
          disabled={loginState isnt 'LOGGED_OUT'}
        >
          {btnMessage}
        </button>
      </div>
    </div>

  #-----------------------------------------------------
  onClickSubmit: ->
    @props.onSubmit 
      login: @refs.login.value
      password: @refs.password.value

  onChangeCredentials: (ev) -> 
    @setState {"#{ev.target.id}": ev.target.value}

#-----------------------------------------------------
_style = 
  outer:
    padding: 10
    marginBottom: 10
    backgroundColor: 'lavender'
    borderRadius: 5
  field:
    marginRight: 4

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, mapDispatchToProps
module.exports = connect Login
