React = require 'react'

LargeMessage = ({children}) ->
  <div style={_style}>{children}</div>

_style = 
  color: '#aaaaaa'
  fontSize: 18
  fontWeight: 'bold'
  lineHeight: 1.3
  padding: 20
  textAlign: 'center'

module.exports = LargeMessage
