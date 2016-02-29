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
    {story, level} = @props
    {title, fOpen, records} = story
    if not fOpen then title += ' - CLOSED'

  _renderRootStory: ->
    {level, story} = @props
    <div style={timm.merge _style.rootStory.main, _style.storyOuter(level, story)}>
      <div style={_style.rootStory.title}>{story.title.toUpperCase()}</div>
      {@_renderRecords()}
    </div>

  _renderNormalStory: ->
    {level, story} = @props
    {title, fOpen} = story
    if not fOpen then lock = <Icon icon="lock"/>
    <div style={_style.storyOuter(level, story)}>
      <div style={_style.indent(level - 1)}>
        <ColoredText text={title}/>
        {' '}
        {lock}
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
    msg += if fServer then ' (server)' else ' (client)'
    <div key={id} style={_style.indent @props.level}>
      <ColoredText text={msg}/>
    </div>

#-----------------------------------------------------
_style = 
  storyOuter: (level, story) ->
    bgColor = 'aliceblue'
    if story.fServer then bgColor = tinycolor(bgColor).darken(5).toHexString()
    backgroundColor: bgColor # if story.fServer then '#f5f5f5' else '#e8e8e8'
  rootStory:
    main:
      marginBottom: 5
    title: 
      fontWeight: 900
      textAlign: 'center'
  indent: (level) ->
    paddingLeft: 20 * (level - 1)

module.exports = Story
