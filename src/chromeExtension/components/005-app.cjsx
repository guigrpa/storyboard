_                 = require '../../vendor/lodash'
React             = require 'react'
ReactRedux        = require 'react-redux'
Login             = require './010-login'
Toolbar           = require './015-toolbar'
Story             = require './020-story'
LargeMessage      = require './900-largeMessage'
if process.env.NODE_ENV isnt 'production'
  ReduxDevTools   = require '../components/990-reduxDevTools'

require './app.sass'
require 'font-awesome/css/font-awesome.css'

mapStateToProps = (state) -> 
  fRelativeTime:  state.settings.timeType is 'RELATIVE'
  cxState:        state.cx.cxState
  fTakingLong:    state.cx.fTakingLong
  mainStory:      state.stories.mainStory

App = React.createClass
  displayName: 'App'

  #-----------------------------------------------------
  propTypes:
    # From Redux.connect
    fRelativeTime:          React.PropTypes.bool.isRequired
    cxState:                React.PropTypes.string.isRequired
    fTakingLong:            React.PropTypes.bool.isRequired
    mainStory:              React.PropTypes.object.isRequired
  getInitialState: ->
    seqFullRefresh:         0

  #-----------------------------------------------------
  componentDidMount: -> 
    @_timerFullRefresh = setInterval @_fullRefresh, 30e3

  componentWillUnmount: ->
    clearInterval @_timerFullRefresh
    @_timerFullRefresh = null

  _fullRefresh: -> 
    return if not @props.fRelativeTime
    @setState {seqFullRefresh: @state.seqFullRefresh + 1}

  #-----------------------------------------------------
  render: -> 
    reduxDevTools = undefined
    if process.env.NODE_ENV isnt 'production'
      reduxDevTools = <ReduxDevTools/>
    <div style={_style.outer}>
      {@_renderContents()}
      {reduxDevTools}
    </div>

  _renderContents: ->
    {cxState, fTakingLong, mainStory} = @props
    if cxState isnt 'CONNECTED' then return @_renderConnecting fTakingLong
    <div>
      <Login/>
      <Toolbar/>
      <Story 
        story={mainStory} 
        level={0} 
        seqFullRefresh={@state.seqFullRefresh}
      />
    </div>

  _renderConnecting: (fTakingLong) ->
    extra = if fTakingLong then \
      <div>If this seems to be taking a long time, please verify your URL</div>
    <LargeMessage>
      Connecting to Storyboard...
      {extra}
    </LargeMessage>

#-----------------------------------------------------
_style = 
  outer: 
    backgroundColor: 'white'
    height: '100%'
    padding: 4

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps
module.exports = connect App
