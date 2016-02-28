_                 = require '../../vendor/lodash'
timm              = require 'timm'
React             = require 'react'
moment            = require 'moment'
Login             = require './010-login'
Story             = require './020-story'
LargeMessage      = require './900-largeMessage'
ansiColors        = require '../../gral/ansiColors'

require './app.sass'

_storyId = 0

Root = React.createClass
  displayName: 'Root'

  #-----------------------------------------------------
  propTypes:
    msgSubscribe:           React.PropTypes.func.isRequired
    msgSend:                React.PropTypes.func.isRequired
  getInitialState: ->
    fEstablishedE2E:        false
    fWarnEstablishmentE2E:  false
    loginStatus:            'LOGGED_OUT'
    fLoginRequired:         false

  #-----------------------------------------------------
  componentWillMount: -> @_initStories()

  componentDidMount: -> 
    @props.msgSubscribe @_rxMsg
    @_txMsg 'CONNECT_REQUEST'
    setTimeout =>
      if not @state.fEstablishedE2E
        @setState {fWarnEstablishmentE2E: true}
    , 2000

  #-----------------------------------------------------
  render: -> <div style={_style.outer}>{@_renderContents()}</div>

  _renderContents: ->
    if not @state.fEstablishedE2E then return @_renderConnecting()
    <div>
      <Login 
        fLoginRequired={@state.fLoginRequired}
        loginStatus={@state.loginStatus}
        submit={@_handleSubmitLogin}
      />
      {@_renderDownloadBuffered()}
      <div>Records:</div>
      <ul>
        <Story story={@_rootStory}/>
      </ul>
    </div>

  _renderConnecting: ->
    <LargeMessage>
      Connecting to Storyboard...
      {@_renderConnecting2()}
    </LargeMessage>

  _renderConnecting2: ->
    return if not @state.fWarnEstablishmentE2E 
    <div>If this seems to be taking a long time, please verify your URL</div>

  _renderDownloadBuffered: ->
    return if @state.fLoginRequired and @state.loginStatus isnt 'LOGGED_IN'
    <button onClick={@_handleDownloadBuffered}>
      Download buffered logs
    </button>

  #-----------------------------------------------------
  _txMsg: (type, data) ->
    @props.msgSend {src: 'DT', type, data}

  _rxMsg: (msg) ->
    {src, type, result, data} = msg
    console.log "[DT] RX #{src}/#{type}", data
    switch type
      when 'CONNECT_REQUEST', 'CONNECT_RESPONSE'
        @setState {fEstablishedE2E: true}
        @_initStories()
        if type is 'CONNECT_REQUEST' then @_txMsg 'CONNECT_RESPONSE'
      when 'LOGIN_REQUIRED'
        if @_lastCredentials
          @_handleSubmitLogin @_lastCredentials
        else
          @setState {fLoginRequired: true, loginStatus: 'LOGGED_OUT'}
      when 'LOGIN_RESPONSE' 
        if result is 'SUCCESS' then @setState {loginStatus: 'LOGGED_IN'}
      when 'BUFFERED_RECORDS_RESPONSE' 
        if result is 'SUCCESS' then @_rxRecords data, {fDedupe: true}
      when 'RECORDS' then @_rxRecords data
    return

  #-----------------------------------------------------
  _handleSubmitLogin: (credentials) ->
    @_lastCredentials = credentials
    @_txMsg 'LOGIN_REQUEST', credentials
    @setState {loginStatus: 'LOGGING_IN'}

  _handleDownloadBuffered: -> @_txMsg 'BUFFERED_RECORDS_REQUEST'

  #-----------------------------------------------------
  # ### Record management
  #-----------------------------------------------------
  _initStories: -> 
    @_rootStory = 
      fWrapper: true
      records: []
    @_openStories = {}
    @_clientMainStoryPath = @_addMainStory {msg: 'Client main story', fServer: false}
    @_serverMainStoryPath = @_addMainStory {msg: 'Server main story', fServer: true}
    return

  _addMainStory: (story) ->
    story.fStory = true
    story.action = 'CREATED'
    story.id = story.storyId = "main_#{_storyId++}"
    story.src = 'main'
    return @_addStory [], story

  _rxRecords: (records, options) ->
    prevRootStory = @_rootStory
    for record in records
      if record.fStory 
        @_rxStory record, options 
      else 
        @_rxLog record, options
    if @_rootStory isnt prevRootStory
      @forceUpdate()
    return

  ## TODO: dedupe stories
  _rxStory: (record) ->
    {storyId} = record
    return if storyId is '*'
    path = @_openStories[storyId]
    if path?
      @_updateStory path, record
    else
      {parents, fServer} = record
      for parent in parents
        if (not path?) or (parent[0] is 'c')
          candidate = @_openStories[parent]
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
    story.t = if story.t? then moment(story.t) else moment()
    story.records = []
    story.fOpen ?= true
    story.status ?= undefined
    story.title = story.msg
    parentRecordsPath = parentStoryPath.concat 'records'
    nextRecords = null
    @_rootStory = timm.updateIn @_rootStory, parentRecordsPath, (prevRecords) ->
      nextRecords = timm.addLast prevRecords, story
      nextRecords
    newStoryPath = parentRecordsPath.concat String(nextRecords.length - 1)
    @_openStories[story.storyId] = newStoryPath
    newStoryPath

  _updateStory: (path, record) ->
    {fOpen, msg: title, status, action} = record
    prevStory = timm.getIn @_rootStory, path
    newStory = timm.merge prevStory, {fOpen, title, status, action}
    @_rootStory = timm.setIn @_rootStory, path, newStory
    if not newStory.fOpen then delete @_openStories[path]
    return

  _addLog: (path, record, options = {}) ->
    recordsPath = path.concat 'records'
    @_rootStory = timm.updateIn @_rootStory, recordsPath, (prevRecords) ->
      if options.fDedupe
        return prevRecords if _.find prevRecords, (o) -> o.id is record.id
      return timm.addLast prevRecords, record
    return

#-----------------------------------------------------
_style = 
  outer: 
    backgroundColor: 'white'
    height: '100%'
    padding: 4

module.exports = Root
