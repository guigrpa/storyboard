_                     = require '../../vendor/lodash'
React                 = require 'react'

COMPONENT_CONFIG =
  displayName: 'Icon'
  propTypes:
    icon:             React.PropTypes.string.isRequired
    size:             React.PropTypes.string   # lg, 2x, 3x, 4x, 5x
    # all other props are passed trhough

Icon = (props) ->
  {icon, size} = props
  otherProps = _.omit props, ['icon', 'size']
  className = "fa fa-#{icon} fa-fw"
  if size? then className += " fa-#{size}"
  if icon is 'circle-o-notch' then className += " fa-spin"
  <i className={className} {...otherProps}/>

_.extend Icon, COMPONENT_CONFIG
module.exports = Icon
