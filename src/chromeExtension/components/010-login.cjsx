React = require 'react'
LargeMessage = require './900-largeMessage'

require './app.sass'

Login = React.createClass
  displayName: 'Login'

  #-----------------------------------------------------
  propTypes:
    submitLogin:            React.PropTypes.func.isRequired
    fShow:                  React.PropTypes.bool.isRequired
    fLoggingIn:             React.PropTypes.bool.isRequired
  getInitialState: ->
    login:                  ''
    password:               ''

  #-----------------------------------------------------
  render: -> 
    return if not @props.fShow
    <div>
      The Storyboard server asks for your credentials:
      <input ref="login"
        id="login"
        type="text"
        value={@state.login}
        placeholder="Login"
        onChange={@_handleChangeCredentials}
      />
      <input ref="password"
        id="password"
        type="password"
        value={@state.password}
        placeholder="Password"
        onChange={@_handleChangeCredentials}
      />
      <button onClick={@_handleClickSubmit} disabled={@props.fLoggingIn}>Submit</button>
    </div>

  #-----------------------------------------------------
  _handleClickSubmit: ->

    @props.msgSend {src: 'DT', type, data}

  _rxMsg: (msg) ->
    {src, type, data} = msg
    console.log "[DT] RX #{src}/#{type}", data
    switch type
      when 'INIT_E2E_RSP' then @setState {fEstablishedE2E: true}
      when 'SERVER_REQUIRES_AUTH' then @setState {fLoginRequired: true}
      when 'RECORDS' then @_rxRecords data
    return

  _rxRecords: (records) ->
    {rootStory} = @state
    rootStory = rootStory.concat records
    @setState {rootStory}

#-----------------------------------------------------
_style = {}

module.exports = Login
