_                 = require '../../vendor/lodash'
React             = require 'react'
ReactRedux        = require 'react-redux'
{
  Floats,
  LargeMessage,
  Spinner,
}                 = require 'giu'
Toolbar           = require './015-toolbar'
Story             = require './020-story'
if process.env.NODE_ENV isnt 'production'
  ReduxDevTools   = require '../components/990-reduxDevTools'

require './app.sass'
require 'font-awesome/css/font-awesome.css'

mapStateToProps = (state) -> 
  fRelativeTime:  state.settings.timeType is 'RELATIVE'
  cxState:        state.cx.cxState
  mainStory:      state.stories.mainStory

App = React.createClass
  displayName: 'App'

  #-----------------------------------------------------
  propTypes:
    # From Redux.connect
    fRelativeTime:          React.PropTypes.bool.isRequired
    cxState:                React.PropTypes.string.isRequired
    mainStory:              React.PropTypes.object.isRequired
  getInitialState: ->
    seqFullRefresh:         0

  #-----------------------------------------------------
  componentDidMount: -> 
    @timerFullRefresh = setInterval @fullRefresh, 30e3
    window.addEventListener 'scroll', @onScroll

  componentWillUnmount: ->
    clearInterval @timerFullRefresh
    @timerFullRefresh = null
    window.removeEventListener 'scroll', @onScroll

  componentDidUpdate: ->
    if @fAnchoredToBottom
      window.scrollTo 0, document.body.scrollHeight

  fullRefresh: -> 
    return if not @props.fRelativeTime
    @setState {seqFullRefresh: @state.seqFullRefresh + 1}

  onScroll: ->
    bcr = @refs.outer.getBoundingClientRect()
    @fAnchoredToBottom = (bcr.bottom - window.innerHeight) < 30

  #-----------------------------------------------------
  render: -> 
    reduxDevTools = undefined
    ## if process.env.NODE_ENV isnt 'production'
    ##   reduxDevTools = <ReduxDevTools/>
    fConnected = @props.cxState is 'CONNECTED'
    <div ref="outer" id="appRoot" style={_style.outer}>
      <Floats />
      {if not fConnected then @renderConnecting()}
      {if fConnected then <Toolbar/>}
      {if fConnected then @renderStories()}
      {reduxDevTools}
    </div>

  renderStories: ->
    <div style={_style.stories}>
      <Story 
        story={@props.mainStory} 
        level={0} 
        seqFullRefresh={@state.seqFullRefresh}
      />
    </div>

  renderConnecting: ->
    <LargeMessage>
      <div><Spinner /> Connecting to Storyboard... </div>
      <div>Navigate to your Storyboard-equipped app (and log in if required)</div>
    </LargeMessage>

#-----------------------------------------------------
_style = 
  outer: 
    backgroundColor: 'white'
    backgroundOpacity: 0.5
  stories:
    padding: 4

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps
module.exports = connect App
