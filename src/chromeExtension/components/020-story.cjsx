React             = require 'react'
PureRenderMixin   = require 'react-addons-pure-render-mixin'
ColoredText       = require './030-coloredText'

Story = React.createClass
  displayName: 'Story'
  mixins: [PureRenderMixin]

  #-----------------------------------------------------
  propTypes:
    story:                  React.PropTypes.object.isRequired
  getInitialState: ->
    fHierarchical:          true

  #-----------------------------------------------------
  render: -> 
    {fWrapper, title, records} = @props.story
    if fWrapper then return @_renderRecords records
    <li>
      <ColoredText text={title}/>
      {@_renderRecords records}
    </li>

  _renderRecords: (records) ->
    <ul>
      {records.map @_renderRecord}
    </ul>

  _renderRecord: (record, idx) ->
    {id, msg} = record
    if record.fStory then return <Story key={id} story={record}/>
    <li key={id}>
      <ColoredText text={msg}/>
    </li>

#-----------------------------------------------------
_style = {}

module.exports = Story
