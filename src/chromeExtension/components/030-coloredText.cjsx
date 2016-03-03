_                 = require '../../vendor/lodash'
React             = require 'react'
PureRenderMixin   = require 'react-addons-pure-render-mixin'
ansiColors        = require '../../gral/ansiColors'

ColoredText = React.createClass
  displayName: 'ColoredText'
  mixins: [PureRenderMixin]

  #-----------------------------------------------------
  propTypes:
    text:                   React.PropTypes.string.isRequired
    onClick:                React.PropTypes.func
    style:                  React.PropTypes.object

  #-----------------------------------------------------
  render: -> 
    segments = ansiColors.getStyledSegments @props.text
    <span 
      onClick={@props.onClick}
      style={@props.style}
    >
      {_.map segments, @renderMsgSegment}
    </span>

  renderMsgSegment: (segment, idx) ->
    <span key={idx} style={segment.style}>
      {segment.text}
    </span>

module.exports = ColoredText
