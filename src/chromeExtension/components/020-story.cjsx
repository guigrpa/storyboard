_                 = require '../../vendor/lodash'
React             = require 'react'
ReactRedux        = require 'react-redux'
timm              = require 'timm'
tinycolor         = require 'tinycolor2'
moment            = require 'moment'
ColoredText       = require './030-coloredText'
Icon              = require './910-icon'
actions           = require '../actions/actions'
k                 = require '../../gral/constants'
ansiColors        = require '../../gral/ansiColors'

mapStateToProps = (state) -> 
  timeType:             state.settings.timeType
mapDispatchToProps = (dispatch) ->
  onToggleTimeType:     -> dispatch actions.toggleTimeType()
  onToggleExpanded:     (pathStr) -> dispatch actions.toggleExpanded pathStr
  onToggleHierarchical: (pathStr) -> dispatch actions.toggleHierarchical pathStr

_Story = React.createClass
  displayName: 'Story'

  #-----------------------------------------------------
  propTypes:
    story:                  React.PropTypes.object.isRequired
    level:                  React.PropTypes.number.isRequired
    seqFullRefresh:         React.PropTypes.number.isRequired
    fFlatAscendant:         React.PropTypes.bool.isRequired
    # From Redux.connect
    timeType:               React.PropTypes.string.isRequired
    onToggleTimeType:       React.PropTypes.func.isRequired
    onToggleExpanded:       React.PropTypes.func.isRequired
    onToggleHierarchical:   React.PropTypes.func.isRequired
  getInitialState: ->
    fHoveredTitle:          false

  #-----------------------------------------------------
  render: -> 
    if @props.story.fWrapper then return @renderRecords()
    if @props.level is 1 then return @renderRootStory()
    return @renderNormalStory()

  renderRootStory: ->
    {level, story} = @props
    <div className="rootStory" style={_style.outer level, story}>
      <div 
        className="rootStoryTitle" 
        style={_style.rootStoryTitle}
        onClick={@toggleHierarchical}
      >
        {story.title.toUpperCase()}
      </div>
      {@renderRecords()}
    </div>

  renderNormalStory: ->
    {level, story} = @props
    {title, fOpen} = story
    if fOpen then spinner = <Icon icon="circle-o-notch"/>
    <div className="story" style={_style.outer(level, story)}>
      <div 
        className="storyTitle fadeIn" 
        style={_style.titleRow level}
        onMouseEnter={@onMouseEnterTitle}
        onMouseLeave={@onMouseLeaveTitle}
      >
        {@renderTime story}
        {@renderLevel story}
        {@renderSrc story}
        {@renderIndent level-1}
        {@renderCaretOrSpace story}
        <ColoredText 
          text={title} 
          onClick={@toggleExpanded}
          style={_style.title}
        />
        {@renderToggleHierarchical story}
        {spinner}
      </div>
      {@renderRecords()}
    </div>

  renderRecords: ->
    return if not @props.story.fExpanded
    records = @props.story.records
    if not @props.story.fHierarchical
      records = @flatten records
    <div>{records.map @renderRecord}</div>

  renderRecord: (record, idx) ->
    {id, storyId, msg, fServer} = record
    if record.fStory 
      return <Story key={id} 
        story={record} 
        level={@props.level + 1}
        seqFullRefresh={@props.seqFullRefresh}
        fFlatAscendant={@props.fFlatAscendant or not @props.story.fHierarchical}
      />
    level = @props.level
    <div key={id} 
      className="log fadeIn"
      style={_style.log record}
    >
      {@renderTime record}
      {@renderLevel record}
      {@renderSrc record}
      {@renderIndent level}
      {@renderCaretOrSpace record}
      <ColoredText text={msg}/>
    </div>

  renderTime: (record) ->
    {fStory, t} = record
    {level, timeType} = @props
    fRelativeTime = false
    m = moment t
    localTime = m.format('YYYY-MM-DD HH:mm:ss.SSS')
    if timeType is 'RELATIVE'
      shownTime = m.fromNow()
      fRelativeTime = true
    else
      if timeType is 'UTC' then m.utc()
      if (fStory and level <= 2) or (level <= 1)
        shownTime = m.format('YYYY-MM-DD HH:mm:ss.SSS')
      else
        shownTime = '           ' + m.format('HH:mm:ss.SSS')
      if timeType is 'UTC' then shownTime += 'Z'
    shownTime = _.padEnd shownTime, 24
    <span 
      onClick={@props.onToggleTimeType}
      style={_style.time fRelativeTime}
      title={if timeType isnt 'LOCAL' then localTime}
    >
      {shownTime}
    </span>

  renderLevel: (record) ->
    {fStory, level} = record
    if fStory
      return <span style={_style.storyLevel}> -----</span>
    levelStr = ' ' + ansiColors.LEVEL_NUM_TO_COLORED_STR[level]
    <ColoredText text={levelStr}/>

  renderSrc: (record) ->
    {src} = record
    srcStr = ' ' + ansiColors.getSrcChalkColor(src) _.padEnd(src, 15)
    <ColoredText text={srcStr}/>

  renderIndent: (level) -> <div style={_style.indent level}/>
  renderCaretOrSpace: (record) ->
    {fStory} = record
    if fStory and record.records.length
      iconType = if @props.story.fExpanded then 'caret-down' else 'caret-right'
      icon = <Icon icon={iconType} onClick={@toggleExpanded}/>
    <span style={_style.caretOrSpace}>{icon}</span>

  renderToggleHierarchical: (story) ->
    return if not @state.fHoveredTitle
    {fHierarchical} = story
    text = if fHierarchical then 'flat' else 'hierarchical'
    <span 
      onClick={@toggleHierarchical}
      style={_style.toggleHierarchical}
    >
      {text}
    </span>

  #-----------------------------------------------------
  toggleExpanded: -> @props.onToggleExpanded @props.story.pathStr
  toggleHierarchical: -> @props.onToggleHierarchical @props.story.pathStr
  onMouseEnterTitle: -> if not @props.fFlatAscendant then @setState {fHoveredTitle: true}
  onMouseLeaveTitle: -> if not @props.fFlatAscendant then @setState {fHoveredTitle: false}

  #-----------------------------------------------------
  flatten: (records, level = 0) ->
    out = []
    for record in records
      if record.fStory
        titleRecord = _.omit(record, ['records'])
        titleRecord.records = []
        out.push titleRecord
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
  rootStoryTitle:
    fontWeight: 900
    textAlign: 'center'
    letterSpacing: 3
    marginBottom: 5
    cursor: 'pointer'
  titleRow: (level) ->
    fontWeight: 900
    fontFamily: 'monospace'
    whiteSpace: 'pre'
  title:
    cursor: 'pointer'
  log: (record) ->
    bgColor = 'aliceblue'
    if record.fServer then bgColor = tinycolor(bgColor).darken(5).toHexString()
    backgroundColor: bgColor # if story.fServer then '#f5f5f5' else '#e8e8e8'
    fontFamily: 'monospace'
    whiteSpace: 'pre'
  time: (fRelativeTime) ->
    display: 'inline-block'
    cursor: 'pointer'
    fontStyle: if fRelativeTime then 'italic'
  indent: (level) ->
    display: 'inline-block'
    width: 20 * (level - 1)
  storyLevel: 
    color: 'gray'
  caretOrSpace:
    display: 'inline-block'
    width: 30
    paddingLeft: 10
    cursor: 'pointer'
  toggleHierarchical:
    display: 'inline-block'
    marginLeft: 10
    color: 'darkgrey'
    textDecoration: 'underline'
    cursor: 'pointer'

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, mapDispatchToProps
Story = connect _Story
module.exports = Story
