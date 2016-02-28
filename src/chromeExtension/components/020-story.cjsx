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
    {fWrapper, title, fServer, fOpen, records} = @props.story
    if fWrapper then return @_renderRecords records
    title += if fServer then ' (server)' else ' (client)'
    if not fOpen then title += ' - CLOSED'
    <li>
      <ColoredText text={title}/>
      {@_renderRecords records}
    </li>

  _renderRecords: (records) ->
    <ul>
      {records.map @_renderRecord}
    </ul>

  _renderRecord: (record, idx) ->
    {id, msg, fServer} = record
    if record.fStory then return <Story key={id} story={record}/>
    msg += if fServer then ' (server)' else ' (client)'
    <li key={id}>
      <ColoredText text={msg}/>
    </li>

#-----------------------------------------------------
_style = {}

module.exports = Story
