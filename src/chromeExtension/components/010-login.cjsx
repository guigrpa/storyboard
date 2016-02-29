React             = require 'react'

Login = React.createClass
  displayName: 'Login'

  #-----------------------------------------------------
  propTypes:
    fLoginRequired:         React.PropTypes.bool.isRequired
    loginStatus:            React.PropTypes.string.isRequired
    submit:                 React.PropTypes.func.isRequired
  getInitialState: ->
    login:                  ''
    password:               ''

  #-----------------------------------------------------
  render: -> 
    if (not @props.fLoginRequired) or (@props.loginStatus is 'LOGGED_IN')
      return <div/>
    btnMessage = switch @props.loginStatus
      when 'LOGGED_OUT' then 'Submit'
      when 'LOGGING_IN' then 'Logging in...'
      else 'Logged in'
    <div style={_style.outer}>
      The Storyboard server asks for your credentials:
      {' '}
      <input ref="login"
        id="login"
        type="text"
        value={@state.login}
        placeholder="Login"
        onChange={@_handleChangeCredentials}
        style={_style.field}
      />
      <input ref="password"
        id="password"
        type="password"
        value={@state.password}
        placeholder="Password"
        onChange={@_handleChangeCredentials}
        style={_style.field}
      />
      <button 
        onClick={@_handleClickSubmit} 
        disabled={@props.loginStatus isnt 'LOGGED_OUT'}
      >
        {btnMessage}
      </button>
    </div>

  #-----------------------------------------------------
  _handleClickSubmit: ->
    @props.submit 
      login: @refs.login.value
      password: @refs.password.value

  _handleChangeCredentials: (ev) -> @setState {"#{ev.target.id}": ev.target.value}

#-----------------------------------------------------
_style = 
  outer:
    padding: 10
    marginBottom: 10
    backgroundColor: 'lavender'
    borderRadius: 5
  field:
    marginRight: 4

module.exports = Login
