_                 = require '../../vendor/lodash'
React             = require 'react'
PureRenderMixin   = require 'react-addons-pure-render-mixin'
ansiColors        = require '../../gral/ansiColors'

Story = React.createClass
  displayName: 'Story'
  mixins: [PureRenderMixin]

  #-----------------------------------------------------
  propTypes:
    records:                React.PropTypes.array.isRequired
  getInitialState: ->
    fHierarchical:          true

  #-----------------------------------------------------
  render: -> 
    <ul>
      {@props.records.map @_renderRecord}
    </ul>

  _renderRecord: (record, idx) ->
    {msg, fStory, action} = record
    if fStory and action?
      msg += " [#{action}]"
    segments = ansiColors.getStructured msg
    <li key={idx} style={_style.record}>
      {@_renderMsgSegments segments}
    </li>

  _renderMsgSegments: (segments) ->
    return null if not segments
    return null if not segments.length
    return segments.map (segment) =>
      if _.isString segment
        return segment
      <span style={segment.style}>
        {@_renderMsgSegments segment.children}
      </span>


#-----------------------------------------------------
_style =
  record:
    fontFamily: 'monospace'
    whiteSpace: 'pre'

module.exports = Story
