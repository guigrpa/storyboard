_                 = require '../../vendor/lodash'
React             = require 'react'
ReactRedux        = require 'react-redux'
PureRenderMixin   = require 'react-addons-pure-render-mixin'
timm              = require 'timm'
tinycolor         = require 'tinycolor2'
moment            = require 'moment'
chalk             = require 'chalk'
ColoredText       = require './030-coloredText'
Icon              = require './910-icon'
actions           = require '../actions/actions'
k                 = require '../../gral/constants'
ansiColors        = require '../../gral/ansiColors'

_quickFind = (msg, quickFind) ->
  return msg if not quickFind.length
  msg = msg.replace quickFind, chalk.bgYellow(quickFind)
  msg

#-====================================================
# ## Story
#-====================================================
mapStateToProps = (state) -> 
  timeType:           state.settings.timeType
  fShowClosedActions: state.settings.fShowClosedActions
  quickFind:          state.stories.quickFind
mapDispatchToProps = (dispatch) ->
  setTimeType: (timeType) -> dispatch actions.setTimeType timeType
  onToggleExpanded: (pathStr) -> dispatch actions.toggleExpanded pathStr
  onToggleHierarchical: (pathStr) -> dispatch actions.toggleHierarchical pathStr
  onToggleAttachment: (pathStr, recordId) -> 
    dispatch actions.toggleAttachment pathStr, recordId

_Story = React.createClass
  displayName: 'Story'

  #-----------------------------------------------------
  propTypes:
    story:                  React.PropTypes.object.isRequired
    level:                  React.PropTypes.number.isRequired
    seqFullRefresh:         React.PropTypes.number.isRequired
    # From Redux.connect
    timeType:               React.PropTypes.string.isRequired
    fShowClosedActions:     React.PropTypes.bool.isRequired
    quickFind:              React.PropTypes.string.isRequired
    setTimeType:            React.PropTypes.func.isRequired
    onToggleExpanded:       React.PropTypes.func.isRequired
    onToggleHierarchical:   React.PropTypes.func.isRequired
    onToggleAttachment:     React.PropTypes.func.isRequired

  #-----------------------------------------------------
  render: -> 
    if @props.story.fWrapper 
      return <div>{@renderRecords()}</div>
    if @props.level is 1 then return @renderRootStory()
    return @renderNormalStory()

  renderRootStory: ->
    {level, story} = @props
    <div className="rootStory" style={_style.outer level, story}>
      <MainStoryTitle
        title={story.title}
        fHierarchical={story.fHierarchical}
        fExpanded={story.fExpanded}
        onToggleExpanded={@toggleExpanded}
        onToggleHierarchical={@toggleHierarchical}
      />
      {@renderRecords()}
    </div>

  renderNormalStory: ->
    {level, story} = @props
    {title, fOpen} = story
    if fOpen then spinner = <Icon icon="circle-o-notch" style={_style.spinner}/>
    <div className="story" style={_style.outer(level, story)}>
      <Line
        record={story}
        level={@props.level}
        fDirectChild={false}
        timeType={@props.timeType}
        setTimeType={@props.setTimeType}
        quickFind={@props.quickFind}
        onToggleExpanded={@toggleExpanded}
        onToggleHierarchical={@toggleHierarchical}
        seqFullRefresh={@props.seqFullRefresh}
      />
      {@renderRecords()}
    </div>

  renderRecords: ->
    return if not @props.story.fExpanded
    records = @prepareRecords @props.story.records
    out = []
    for record in records
      el = @renderRecord record
      continue if not el?
      out.push el
      if record.objExpanded and record.obj?
        out = out.concat @renderAttachment record
    out

  renderRecord: (record) ->
    {id, fStoryObject, storyId, obj, objExpanded, action} = record
    fDirectChild = storyId is @props.story.storyId
    if fStoryObject
      return <Story key={storyId}
        story={record}
        level={@props.level + 1}
        seqFullRefresh={@props.seqFullRefresh}
      />
    else
      if fDirectChild
        return if action is 'CREATED'
        return if (not @props.fShowClosedActions) and (action is 'CLOSED')
      return <Line key={id}
        record={record}
        level={@props.level}
        fDirectChild={fDirectChild}
        timeType={@props.timeType}
        setTimeType={@props.setTimeType}
        quickFind={@props.quickFind}
        onToggleAttachment={@toggleAttachment}
        seqFullRefresh={@props.seqFullRefresh}
      />
    out

  renderAttachment: (record) -> 
    props = _.pick @props, ['level', 'timeType', 'setTimeType', 'quickFind', 'seqFullRefresh']
    return record.obj.map (line, idx) ->
      <AttachmentLine key={"#{record.id}_#{idx}"}
        record={record}
        {...props}
        msg={line}
      />

  #-----------------------------------------------------
  toggleExpanded: -> @props.onToggleExpanded @props.story.pathStr
  toggleHierarchical: -> @props.onToggleHierarchical @props.story.pathStr
  toggleAttachment: (recordId) -> 
    @props.onToggleAttachment @props.story.pathStr, recordId

  #-----------------------------------------------------
  prepareRecords: (records) ->
    if @props.story.fHierarchical
      out = _.sortBy records, 't'
    else
      out = @flatten records
    out

  flatten: (records, level = 0) ->
    out = []
    for record in records
      if record.fStoryObject
        out = out.concat @flatten(record.records, level + 1)
      else
        out.push record
    if level is 0
      out = _.sortBy out, 't'
    out

#-----------------------------------------------------
_style = 
  outer: (level, story) ->
    bgColor = 'aliceblue'
    if story.fServer then bgColor = tinycolor(bgColor).darken(5).toHexString()
    backgroundColor: bgColor # if story.fServer then '#f5f5f5' else '#e8e8e8'
    marginBottom: if level <= 1 then 10
    padding: if level <= 1 then 2

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, mapDispatchToProps
Story = connect _Story


#-====================================================
# ## MainStoryTitle
#-====================================================
MainStoryTitle = React.createClass
  displayName: 'MainStoryTitle'
  mixins: [PureRenderMixin]

  #-----------------------------------------------------
  propTypes:
    title:                  React.PropTypes.string.isRequired
    fHierarchical:          React.PropTypes.bool.isRequired
    fExpanded:              React.PropTypes.bool.isRequired
    onToggleExpanded:       React.PropTypes.func.isRequired
    onToggleHierarchical:   React.PropTypes.func.isRequired
  getInitialState: ->
    fHovered:               false

  #-----------------------------------------------------
  render: ->
    <div 
      className="rootStoryTitle" 
      style={_styleMainTitle.outer}
      onMouseEnter={@onMouseEnter}
      onMouseLeave={@onMouseLeave}
    >
      {@renderCaret()}
      <span 
        style={_styleMainTitle.title}
        onClick={@props.onToggleExpanded}
      >
        {@props.title.toUpperCase()}
      </span>
      {@renderToggleHierarchical()}
    </div>

  renderCaret: ->
    return if not @state.fHovered
    icon = if @props.fExpanded then 'caret-down' else 'caret-right'
    <span 
      onClick={@props.onToggleExpanded}
      style={_styleMainTitle.caret.outer}
    >
      <Icon icon={icon} style={_styleMainTitle.caret.icon}/>
    </span>

  renderToggleHierarchical: ->
    return if not @state.fHovered
    <HierarchicalToggle
      fHierarchical={@props.fHierarchical}
      onToggleHierarchical={@props.onToggleHierarchical}
      fFloat
    />

  #-----------------------------------------------------
  onMouseEnter: -> @setState {fHovered: true}
  onMouseLeave: -> @setState {fHovered: false}

#-----------------------------------------------------
_styleMainTitle =
  outer:
    textAlign: 'center'
    marginBottom: 5
    cursor: 'pointer'
  title:
    fontWeight: 900
    letterSpacing: 3
  caret:
    outer:
      display: 'inline-block'
      position: 'absolute'
    icon:
      display: 'inline-block'
      position: 'absolute'
      right: 6
      top: 2

#-====================================================
# ## AttachmentLine
#-====================================================
AttachmentLine = React.createClass
  displayName: 'AttachmentLine'
  mixins: [PureRenderMixin]

  #-----------------------------------------------------
  propTypes:
    record:                 React.PropTypes.object.isRequired
    level:                  React.PropTypes.number.isRequired
    timeType:               React.PropTypes.string.isRequired
    setTimeType:            React.PropTypes.func.isRequired
    seqFullRefresh:         React.PropTypes.number.isRequired
    msg:                    React.PropTypes.string.isRequired
    quickFind:              React.PropTypes.string.isRequired

  #-----------------------------------------------------
  render: ->
    {record, msg} = @props
    style = _styleLine.log record
    msg = _quickFind msg, @props.quickFind
    <div 
      className="attachmentLine allowUserSelect"
      style={style}
    >
      <Time
        fShowFull={false}
        timeType={@props.timeType}
        setTimeType={@props.setTimeType}
        seqFullRefresh={@props.seqFullRefresh}
      />
      <Severity level={String record.objLevel}/>
      <Src src={record.src}/>
      <Indent level={@props.level}/>
      <CaretOrSpace/>
      <ColoredText text={'  ' + msg}/>
    </div>


#-====================================================
# ## Line
#-====================================================
Line = React.createClass
  displayName: 'Line'
  mixins: [PureRenderMixin]

  #-----------------------------------------------------
  propTypes:
    record:                 React.PropTypes.object.isRequired
    level:                  React.PropTypes.number.isRequired
    fDirectChild:           React.PropTypes.bool.isRequired
    timeType:               React.PropTypes.string.isRequired
    setTimeType:            React.PropTypes.func.isRequired
    quickFind:              React.PropTypes.string.isRequired
    onToggleExpanded:       React.PropTypes.func
    onToggleHierarchical:   React.PropTypes.func
    onToggleAttachment:     React.PropTypes.func
    seqFullRefresh:         React.PropTypes.number.isRequired
  getInitialState: ->
    fHovered:               false

  #-----------------------------------------------------
  render: ->
    {record, fDirectChild, level} = @props
    {id, msg, fStory, fStoryObject, fOpen, title, action} = record
    if fStoryObject then msg = title
    if fStory 
      msg = if not fDirectChild then "#{title} " else ''
      if action then msg += chalk.gray "[#{action}]"
    if fStoryObject
      className = 'storyTitle'
      style = _styleLine.titleRow level
      indentLevel = level - 1
      if fOpen then spinner = <Icon icon="circle-o-notch" style={_styleLine.spinner}/>
    else
      className = 'log'
      style = _styleLine.log record
      indentLevel = level
    <div 
      className={"#{className} allowUserSelect fadeIn"}
      onMouseEnter={@onMouseEnter}
      onMouseLeave={@onMouseLeave}
      style={style}
    >
      {@renderTime record}
      <Severity level={if fStory then null else record.level}/>
      <Src src={record.src}/>
      <Indent level={indentLevel}/>
      {@renderCaretOrSpace record}
      {@renderMsg fStoryObject, msg, record.level}
      {if fStoryObject then @renderToggleHierarchical record}
      {spinner}
      {@renderAttachmentIcon record}
    </div>

  renderMsg: (fStoryObject, msg, level) ->
    msg = _quickFind msg, @props.quickFind
    if level >= k.LEVEL_STR_TO_NUM.ERROR then msg = chalk.red.bold msg
    else if level >= k.LEVEL_STR_TO_NUM.WARN then msg = chalk.red.yellow msg
    if fStoryObject
      <ColoredText 
        text={msg} 
        onClick={@props.onToggleExpanded}
        style={_styleLine.title}
      />
    else
      <ColoredText text={msg}/>

  renderTime: (record) ->
    {fStoryObject, t} = record
    {level, timeType, setTimeType, seqFullRefresh} = @props
    fShowFull = (fStoryObject and level <= 2) or (level <= 1)
    <Time
      t={t}
      fShowFull={fShowFull}
      timeType={timeType}
      setTimeType={setTimeType}
      seqFullRefresh={seqFullRefresh}
    />

  renderCaretOrSpace: (record) ->
    if @props.onToggleExpanded and record.fStoryObject
      fExpanded = record.fExpanded
    <CaretOrSpace fExpanded={fExpanded} onToggleExpanded={@props.onToggleExpanded}/>

  renderToggleHierarchical: (story) ->
    return if not @props.onToggleHierarchical
    return if not @state.fHovered
    <HierarchicalToggle
      fHierarchical={story.fHierarchical}
      onToggleHierarchical={@props.onToggleHierarchical}
    />

  renderAttachmentIcon: (record) ->
    return if not record.obj?
    if record.objIsError
      icon = if record.objExpanded then 'folder-open' else 'folder'
      style = timm.set _styleLine.attachmentIcon, 'color', '#cc0000'
    else
      icon = if record.objExpanded then 'folder-open-o' else 'folder-o'
      style = _styleLine.attachmentIcon
    <Icon 
      icon={icon} 
      onClick={@onClickAttachment}
      style={style}
    />

  #-----------------------------------------------------
  onMouseEnter: -> @setState {fHovered: true}
  onMouseLeave: -> @setState {fHovered: false}
  onClickAttachment: -> @props.onToggleAttachment @props.record.id

#-----------------------------------------------------
_styleLine =
  titleRow: (level) ->
    fontWeight: 900
    fontFamily: 'Menlo, Consolas, monospace'
    whiteSpace: 'pre'
  title:
    cursor: 'pointer'
  log: (record) ->
    bgColor = 'aliceblue'
    if record.fServer then bgColor = tinycolor(bgColor).darken(5).toHexString()
    backgroundColor: bgColor # if story.fServer then '#f5f5f5' else '#e8e8e8'
    fontFamily: 'Menlo, Consolas, monospace'
    whiteSpace: 'pre'
    fontWeight: if record.fStory and (record.action is 'CREATED') then 900
  spinner:
    marginLeft: 8
  attachmentIcon:
    marginLeft: 8
    cursor: 'pointer'

#-====================================================
# ## Time
#-====================================================
TIME_LENGTH = 25

Time = React.createClass
  displayName: 'Time'
  mixins: [PureRenderMixin]
  propTypes:
    t:                      React.PropTypes.number
    fShowFull:              React.PropTypes.bool
    timeType:               React.PropTypes.string.isRequired
    setTimeType:            React.PropTypes.func.isRequired
    seqFullRefresh:         React.PropTypes.number.isRequired

  render: ->
    {t, fShowFull, timeType} = @props
    if not t? then return <span>{_.padEnd '', TIME_LENGTH}</span>
    fRelativeTime = false
    m = moment t
    localTime = m.format('YYYY-MM-DD HH:mm:ss.SSS')
    if timeType is 'RELATIVE'
      shownTime = m.fromNow()
      fRelativeTime = true
    else
      if timeType is 'UTC' then m.utc()
      if fShowFull
        shownTime = m.format('YYYY-MM-DD HH:mm:ss.SSS')
      else
        shownTime = '           ' + m.format('HH:mm:ss.SSS')
      if timeType is 'UTC' then shownTime += 'Z'
    shownTime = _.padEnd shownTime, TIME_LENGTH
    <span 
      onClick={@onClick}
      style={_styleTime fRelativeTime}
      title={if timeType isnt 'LOCAL' then localTime}
    >
      {shownTime}
    </span>

  onClick: ->
    newTimeType = switch @props.timeType
      when 'LOCAL' then 'RELATIVE'
      when 'RELATIVE' then 'UTC'
      else 'LOCAL'
    @props.setTimeType newTimeType

_styleTime = (fRelativeTime) ->
  display: 'inline-block'
  cursor: 'pointer'
  fontStyle: if fRelativeTime then 'italic'

#-====================================================
# ## Severity
#-====================================================
Severity = React.createClass
  displayName: 'Severity'
  mixins: [PureRenderMixin]
  propTypes:
    level:                  React.PropTypes.string
  render: ->
    {level} = @props
    if level?
      levelStr = ansiColors.LEVEL_NUM_TO_COLORED_STR[level]
      <ColoredText text={levelStr}/>
    else
      <span style={_styleStorySeverity}>----- </span>

_styleStorySeverity = 
  color: 'gray'

#-====================================================
# ## Src
#-====================================================
Src = React.createClass
  displayName: 'Src'
  mixins: [PureRenderMixin]
  propTypes:
    src:                    React.PropTypes.string
  render: ->
    {src} = @props
    srcStr = ansiColors.getSrcChalkColor(src) _.padEnd(src, 15)
    console.log srcStr
    <ColoredText text={srcStr}/>

#-====================================================
# ## Indent
#-====================================================
Indent = ({level}) -> 
  style = 
    display: 'inline-block'
    width: 20 * (level - 1)
  <div style={style}/>

#-====================================================
# ## CaretOrSpace
#-====================================================
CaretOrSpace = React.createClass
  displayName: 'CaretOrSpace'
  mixins: [PureRenderMixin]
  propTypes:
    fExpanded:              React.PropTypes.bool
    onToggleExpanded:       React.PropTypes.func
  render: ->
    if @props.fExpanded?
      iconType = if @props.fExpanded then 'caret-down' else 'caret-right'
      icon = <Icon icon={iconType} onClick={@props.onToggleExpanded}/>
    <span style={_styleCaretOrSpace}>{icon}</span>

_styleCaretOrSpace =
  display: 'inline-block'
  width: 30
  paddingLeft: 10
  cursor: 'pointer'


#-====================================================
# ## HierarchicalToggle
#-====================================================
HierarchicalToggle = React.createClass
  displayName: 'HierarchicalToggle'
  mixins: [PureRenderMixin]
  propTypes:
    fHierarchical:          React.PropTypes.bool.isRequired
    onToggleHierarchical:   React.PropTypes.func.isRequired
    fFloat:                 React.PropTypes.bool
  render: ->
    if @props.fHierarchical
      text = 'Show flat' 
      icon = 'bars'
    else 
      text = 'Show tree'
      icon = 'sitemap'
    <span
      onClick={@props.onToggleHierarchical}
      style={_styleHierarchical.outer @props.fFloat}
    >
      <Icon icon={icon} style={_styleHierarchical.icon}/>
      {text}
    </span>

_styleHierarchical =
  outer: (fFloat) ->
    display: 'inline-block'
    position: if fFloat then 'absolute'
    marginLeft: 10
    color: 'darkgrey'
    textDecoration: 'underline'
    cursor: 'pointer'
    fontWeight: 'normal'
    fontFamily: 'Menlo, Consolas, monospace'
  icon:
    marginRight: 4

#-----------------------------------------------------
module.exports = Story
