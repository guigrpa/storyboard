React             = require 'react'
PureRenderMixin   = require 'react-addons-pure-render-mixin'
timm              = require 'timm'
tinycolor         = require 'tinycolor2'
ColoredText       = require './030-coloredText'
Icon              = require './910-icon'

Story = React.createClass
  displayName: 'Story'
  mixins: [PureRenderMixin]

  #-----------------------------------------------------
  propTypes:
    story:                  React.PropTypes.object.isRequired
    level:                  React.PropTypes.number.isRequired
  getInitialState: ->
    fHierarchical:          true
    fExpanded:              @props.story.fOpen

  #-----------------------------------------------------
  render: -> 
    if @props.story.fWrapper then return @_renderRecords()
    if @props.level is 1 then return @_renderRootStory()
    return @_renderNormalStory()

  _renderRootStory: ->
    {level, story} = @props
    <div style={_style.outer level, story}>
      <div style={_style.rootStoryTitle}>{story.title.toUpperCase()}</div>
      {@_renderRecords()}
    </div>

  _renderNormalStory: ->
    {level, story} = @props
    {title, fOpen} = story
    if fOpen then icon = <Icon icon="circle-o-notch"/>
    <div style={_style.outer(level, story)}>
      <div style={_style.title level}>
        {@_getTimeStr story}
        {' '}
        <ColoredText text={title}/>
        {' '}
        {icon}
      </div>
      {@_renderRecords()}
    </div>

  _renderRecords: ->
    records = @props.story.records
    <div>
      {records.map @_renderRecord}
    </div>

  _renderRecord: (record, idx) ->
    {id, storyId, msg, fServer} = record
    if record.fStory then return <Story key={id} story={record} level={@props.level + 1}/>
    <div key={id} style={_style.log @props.level}>
      {@_getTimeStr record}
      {' '}
      <ColoredText text={msg}/>
    </div>

  _getTimeStr: (record) ->
    {fStory, t} = record
    fRoot = (fStory and @props.level <= 2) or (@props.level <= 1)
    if fRoot 
      tStr = t.format('YYYY-MM-DD HH:mm:ss.SSS')
    else
      tStr = '           ' + t.format('HH:mm:ss.SSS')
    tStr

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
    letterSpacing: "3px"
  title: (level) ->
    fontWeight: 900
    paddingLeft: 20 * (level - 2)
    fontFamily: 'monospace'
    whiteSpace: 'pre'
  log: (level) ->
    paddingLeft: 20 * (level - 1)
    fontFamily: 'monospace'
    whiteSpace: 'pre'

module.exports = Story
