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
    segments = ansiColors.getStructured @props.text
    <span 
      onClick={@props.onClick}
      style={@props.style}
    >
      {@_renderMsgSegments segments}
    </span>

  # Recursive
  _renderMsgSegments: (segments) ->
    return null if not segments
    return null if not segments.length
    return segments.map (segment, idx) =>
      if _.isString segment
        return segment
      <span key={idx} style={segment.style}>
        {@_renderMsgSegments segment.children}
      </span>

module.exports = ColoredText
