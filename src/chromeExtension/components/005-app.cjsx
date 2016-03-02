_                 = require '../../vendor/lodash'
React             = require 'react'
ReactRedux        = require 'react-redux'
Login             = require './010-login'
Story             = require './020-story'
LargeMessage      = require './900-largeMessage'
if process.env.NODE_ENV isnt 'production'
  ReduxDevTools   = require '../components/990-reduxDevTools'

require './app.sass'
require 'font-awesome/css/font-awesome.css'

mapStateToProps = (state) -> 
  fRelativeTime:  state.settings.fRelativeTime
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

  ###
  _rxMsg: (msg) ->
    {src, type, result, data} = msg
    console.log "[DT005] RX #{src}/#{type}", data
    return

  _initStories: -> 
    @_rootStory = 
      fWrapper: true
      fOpen: true
      records: []
    @_openStories = {}
    @_closedStories = {}
    @_clientMainStoryPath = @_addMainStory {title: 'Client', fServer: false}
    @_serverMainStoryPath = @_addMainStory {title: 'Server', fServer: true}
    return

  _addMainStory: (story) ->
    story.fStory = true
    story.action = 'CREATED'
    story.t = new Date().getTime()
    story.id = story.storyId = "main_#{_storyId++}"
    story.src = 'main'
    return @_addStory [], story

  _rxRecords: (records, options) ->
    prevRootStory = @_rootStory
    for record in records
      console.groupCollapsed "#{if record.fStory then record.title else record.msg}#{if record.action then ' - '+record.action else ''}"
      console.log "Story ID: #{record.storyId}"
      console.log "Current open stories:   #{Object.keys(@_openStories).map((o) -> o.slice 0, 7).join()}"
      console.log "Current closed stories: #{Object.keys(@_closedStories).map((o) -> o.slice 0, 7).join()}"
      if record.fStory 
        @_rxStory record, options 
      else 
        @_rxLog record, options
      console.groupEnd()
    if @_rootStory isnt prevRootStory then @forceUpdate()
    return

  _rxStory: (record, options = {}) ->
    {storyId} = record
    return if storyId is '*'
    path = @_openStories[storyId]
    if (not path?) and options.fIncludeClosedStories
      path = @_closedStories[storyId]
    if path?
      @_updateStory path, record
    else
      {parents, fServer} = record
      for parent in parents
        if (not path?) or (parent[0] is 'c')
          candidate = @_openStories[parent]
          if (not candidate?) and options.fIncludeClosedStories
            candidate = @_closedStories[parent]
          if candidate? then path = candidate
      path ?= @_getMainStoryPath fServer
      @_addStory path, record
    return

  _rxLog: (record, options) ->
    {storyId, fServer} = record
    if storyId is '*'
      path = @_getMainStoryPath fServer
    else
      path = @_openStories[storyId] ? @_getMainStoryPath fServer
    @_addLog path, record, options
    return

  _getMainStoryPath: (fServer) ->
    return (if fServer then @_serverMainStoryPath else @_clientMainStoryPath)

  # Mutates `record`
  _addStory: (parentStoryPath, record) ->
    story = record
    story.records = []
    story.fOpen ?= true
    story.status ?= undefined
    parentRecordsPath = parentStoryPath.concat 'records'
    nextRecords = null
    @_rootStory = timm.updateIn @_rootStory, parentRecordsPath, (prevRecords) ->
      nextRecords = timm.addLast prevRecords, story
      nextRecords
    newStoryPath = parentRecordsPath.concat String(nextRecords.length - 1)
    @_openStories[story.storyId] = newStoryPath
    newStoryPath

  _updateStory: (path, record) ->
    {fOpen, title, status, action, storyId} = record
    prevStory = timm.getIn @_rootStory, path
    newStory = timm.merge prevStory, {fOpen, title, status, action}
    @_rootStory = timm.setIn @_rootStory, path, newStory
    if not newStory.fOpen 
      delete @_openStories[storyId]
      @_closedStories[storyId] = path
    return

  _addLog: (path, record, options = {}) ->
    recordsPath = path.concat 'records'
    @_rootStory = timm.updateIn @_rootStory, recordsPath, (prevRecords) ->
      if options.fDedupe
        return prevRecords if _.find prevRecords, (o) -> o.id is record.id
      record.t = moment(record.t)
      return timm.addLast prevRecords, record
    return
  ###

#-----------------------------------------------------
_style = 
  outer: 
    backgroundColor: 'white'
    height: '100%'
    padding: 4

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps
module.exports = connect App
