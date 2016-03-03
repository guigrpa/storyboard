_                     = require '../../vendor/lodash'
React                 = require 'react'
PureRenderMixin       = require 'react-addons-pure-render-mixin'

Icon = React.createClass
  displayName: 'Icon'
  mixins: [PureRenderMixin]

  #-----------------------------------------------------
  propTypes:
    icon:             React.PropTypes.string.isRequired
    size:             React.PropTypes.string   # lg, 2x, 3x, 4x, 5x
    fFixedWidth:      React.PropTypes.bool
    # all other props are passed through
  getDefaultProps: ->
    fFixedWidth:      false

  #-----------------------------------------------------
  render: -> 
    {icon, size, fFixedWidth} = @props
    otherProps = _.omit @props, ['icon', 'size']
    className = "fa fa-#{icon}"
    if size? then className += " fa-#{size}"
    if fFixedWidth then className += ' fa-fw'
    if icon is 'circle-o-notch' then className += " fa-spin"
    <i className={className} {...otherProps}/>

module.exports = Icon
