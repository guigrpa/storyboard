React = require 'react'
ReactDOM = require 'react-dom'

_listeners = []
_subscribe = (listener) ->
  _listeners.push listener
  return

#-------------------------------------------------
# ## Dependencies
#-------------------------------------------------
_sendMsg = null

#-------------------------------------------------
# ## Initialisation
#-------------------------------------------------
init = (deps) ->
  {sendMsg: _sendMsg} = deps
  if not(_sendMsg?)
    throw new Error "MISSING_DEPS"
  console.log "[DT] Starting up..."
  RootComponent = require './components/000-root'
  RootElement = React.createElement RootComponent,
    msgSend: _sendMsg
    msgSubscribe: _subscribe
  ReactDOM.render RootElement, document.getElementById 'devToolsApp'

#-------------------------------------------------
# ## Message processing
#-------------------------------------------------
processMsg = (msg) ->
  for listener in _listeners
    listener msg
  return

#-------------------------------------------------
# ## API
#-------------------------------------------------
module.exports = {
  init,
  processMsg,
}