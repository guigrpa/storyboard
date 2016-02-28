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

  #-----------------------------------------------------
  render: -> 
    segments = ansiColors.getStructured @props.text
    <span style={_style}>{@_renderMsgSegments segments}</span>

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


#-----------------------------------------------------
_style =
  fontFamily: 'monospace'
  whiteSpace: 'pre'

module.exports = ColoredText
