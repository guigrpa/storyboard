_                     = require '../../vendor/lodash'
React                 = require 'react'

COMPONENT_CONFIG =
  displayName: 'Icon'
  propTypes:
    icon:             React.PropTypes.string.isRequired
    size:             React.PropTypes.string   # lg, 2x, 3x, 4x, 5x

Icon = ({icon, size}) ->
  classNames = ['fa', "fa-#{icon}"]
  if size? then classNames.push "fa-#{size}"
  <i className={classNames.join ' '}/>

_.extend Icon, COMPONENT_CONFIG
module.exports = Icon
