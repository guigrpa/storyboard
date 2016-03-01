_                 = require '../../vendor/lodash'
timm              = require 'timm'
React             = require 'react'
ReactRedux        = require 'react-redux'
moment            = require 'moment'
Login             = require './010-login'
Story             = require './020-story'
LargeMessage      = require './900-largeMessage'
ansiColors        = require '../../gral/ansiColors'
if process.env.NODE_ENV isnt 'production'
  ReduxDevTools   = require '../components/990-reduxDevTools'

require './app.sass'
require 'font-awesome/css/font-awesome.css'

_storyId = 0

mapStateToProps = ({settings, cx, stories: {mainStory}}) -> {settings, cx, mainStory}

App = React.createClass
  displayName: 'App'

  #-----------------------------------------------------
  propTypes:
    msgSubscribe:           React.PropTypes.func.isRequired
    msgSend:                React.PropTypes.func.isRequired
    # From Redux.connect
    settings:               React.PropTypes.object.isRequired
    mainStory:              React.PropTypes.object.isRequired
  getInitialState: ->
    fEstablishedE2E:        false
    fWarnEstablishmentE2E:  false
    loginStatus:            'LOGGED_OUT'
    fLoginRequired:         false
    seqFullRefresh:         0

  #-----------------------------------------------------
  componentDidMount: -> 
    @_initStories()
    @_timerFullRefresh = setInterval @_fullRefresh, 30e3
    @props.msgSubscribe @_rxMsg

    # Allow a few ms for the other party to establish connection;
    # if not, try ourselves
    setTimeout => 
      return if @state.fEstablishedE2E
      @_txMsg 'CONNECT_REQUEST'
    , 30

    # Provide user feedback
    setTimeout =>
      if not @state.fEstablishedE2E
        @setState {fWarnEstablishmentE2E: true}
    , 2000

  componentWillUnmount: ->
    clearInterval @_timerFullRefresh
    @_timerFullRefresh = null

  _fullRefresh: -> 
    return if not @props.settings.fRelativeTime
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
    if not @state.fEstablishedE2E then return @_renderConnecting()
    <div>
      <Login 
        fLoginRequired={@state.fLoginRequired}
        loginStatus={@state.loginStatus}
        submit={@_handleSubmitLogin}
      />
      <Story 
        story={@_rootStory} 
        level={0} 
        seqFullRefresh={@state.seqFullRefresh}
      />
    </div>

  _renderConnecting: ->
    <LargeMessage>
      Connecting to Storyboard...
      {@_renderConnecting2()}
    </LargeMessage>

  _renderConnecting2: ->
    return if not @state.fWarnEstablishmentE2E 
    <div>If this seems to be taking a long time, please verify your URL</div>

  ## _renderDownloadBuffered: ->
  ##   return if @state.fLoginRequired and @state.loginStatus isnt 'LOGGED_IN'
  ##   <button onClick={@_handleDownloadBuffered}>
  ##     Download buffered logs
  ##   </button>

  #-----------------------------------------------------
  _txMsg: (type, data) ->
    @props.msgSend {src: 'DT', type, data}

  _rxMsg: (msg) ->
    {src, type, result, data} = msg
    console.log "[DT] RX #{src}/#{type}", data
    switch type
      when 'CONNECT_REQUEST', 'CONNECT_RESPONSE'
        if type is 'CONNECT_REQUEST' then @_txMsg 'CONNECT_RESPONSE'
        @setState {fEstablishedE2E: true}
        @_initStories()
      when 'LOGIN_REQUIRED'
        if @_lastCredentials
          @_handleSubmitLogin @_lastCredentials
        else
          @setState {fLoginRequired: true, loginStatus: 'LOGGED_OUT'}
      when 'LOGIN_RESPONSE' 
        if result is 'SUCCESS' 
          @setState {loginStatus: 'LOGGED_IN'}
          if data? then @_rxRecords data, {fIncludeClosedStories: true}
      ## when 'BUFFERED_RECORDS_RESPONSE' 
      ##   if result is 'SUCCESS' then @_rxRecords data, {fDedupe: true}
      when 'RECORDS' then @_rxRecords data
    return

  #-----------------------------------------------------
  _handleSubmitLogin: (credentials) ->
    @_lastCredentials = credentials
    @_txMsg 'LOGIN_REQUEST', credentials
    @setState {loginStatus: 'LOGGING_IN'}

  ## _handleDownloadBuffered: -> @_txMsg 'BUFFERED_RECORDS_REQUEST'

  #-----------------------------------------------------
  # ### Record management
  #-----------------------------------------------------
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
    fAnyServerLog = false
    for record in records
      fAnyServerLog or= record.fServer
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

#-----------------------------------------------------
_style = 
  outer: 
    backgroundColor: 'white'
    height: '100%'
    padding: 4

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps
module.exports = connect App
