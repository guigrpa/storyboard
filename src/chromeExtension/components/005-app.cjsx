_                 = require '../../vendor/lodash'
React             = require 'react'
ReactRedux        = require 'react-redux'
{
  Floats, Notifications,
  LargeMessage,
  Spinner,
  isDark,
}                 = require 'giu'
tinycolor         = require 'tinycolor2'
Toolbar           = require './015-toolbar'
Story             = require './020-story'
if process.env.NODE_ENV isnt 'production'
  ReduxDevTools   = require '../components/990-reduxDevTools'

require './app.sass'

mapStateToProps = (state) ->
  fRelativeTime:  state.settings.timeType is 'RELATIVE'
  cxState:        state.cx.cxState
  mainStory:      state.stories.mainStory
  colors: _.pick(state.settings, [
    'colorClientBg', 'colorServerBg', 'colorUiBg',
    'colorClientFg', 'colorServerFg', 'colorUiFg',
    'colorClientBgIsDark', 'colorServerBgIsDark', 'colorUiBgIsDark',
  ])

App = React.createClass
  displayName: 'App'

  #-----------------------------------------------------
  propTypes:
    # From Redux.connect
    fRelativeTime:          React.PropTypes.bool.isRequired
    cxState:                React.PropTypes.string.isRequired
    mainStory:              React.PropTypes.object.isRequired
    colors:                 React.PropTypes.object.isRequired
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
    { cxState, colors } = @props
    ## if process.env.NODE_ENV isnt 'production'
    ##   reduxDevTools = <ReduxDevTools/>
    fConnected = cxState is 'CONNECTED'
    <div ref="outer" id="appRoot" style={_style.outer(colors)}>
      <Floats />
      <Notifications />
      {if not fConnected then @renderConnecting()}
      {if fConnected then <Toolbar colors={colors}/>}
      {if fConnected then @renderStories()}
      {reduxDevTools}
    </div>

  renderStories: ->
    <div style={_style.stories}>
      <Story
        story={@props.mainStory}
        level={0}
        seqFullRefresh={@state.seqFullRefresh}
        colors={@props.colors}
      />
    </div>

  renderConnecting: ->
    <LargeMessage style={_style.largeMessage @props.colors}>
      <div><Spinner /> Connecting to Storyboard... </div>
      <div>Navigate to your Storyboard-equipped app (and log in if required)</div>
    </LargeMessage>

#-----------------------------------------------------
_style =
  outer: (colors) ->
    height: '100%'
    backgroundColor: colors.colorUiBg
    color: colors.colorUiFg
  largeMessage: (colors) ->
    color = tinycolor(colors.colorUiFg)
    color = if isDark(colors.colorUiFg) then color.lighten(20) else color.darken(20)
    color: color.toRgbString()
  stories:
    padding: 4

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps
module.exports = connect App
