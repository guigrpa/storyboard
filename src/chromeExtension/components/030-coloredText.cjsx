_                 = require '../../vendor/lodash'
timm              = require 'timm'
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
    if segments.length is 1
      segment = segments[0]
      extraProps = 
        onClick: @props.onClick
        style: timm.merge segment.style, @props.style
      return @renderMsgSegment segment, 0, extraProps
    <span 
      onClick={@props.onClick}
      style={@props.style}
    >
      {_.map segments, @renderMsgSegment}
    </span>

  renderMsgSegment: (segment, idx, extraProps = {}) ->
    <span key={idx} style={segment.style} {...extraProps}>
      {segment.text}
    </span>

module.exports = ColoredText
