React = require 'react'
ReactDOM = require 'react-dom'
server = require './actions/serverSaga'

## DELETE!
_listeners = []
## DELETE!
_subscribe = (listener) ->
  _listeners.push listener
  return

#-------------------------------------------------
# ## Dependencies
#-------------------------------------------------
_sendMsg = null

#-------------------------------------------------
# ## Internal
#-------------------------------------------------
_store = null

#-------------------------------------------------
# ## Initialisation
#-------------------------------------------------
init = (deps) ->
  {sendMsg: _sendMsg} = deps
  if not(_sendMsg?)
    throw new Error "MISSING_DEPS"
  console.log "[DT] Starting up..."

  server.init {sendMsg: _sendMsg}

  createStore = require './store/createStore'
  _store = createStore()

  # Render the app
  RootComponent = require './components/000-root'
  RootElement = React.createElement RootComponent,
    store: _store
    ## DELETE!
    msgSend: _sendMsg
    msgSubscribe: _subscribe
  ReactDOM.render RootElement, document.getElementById 'devToolsApp'

#-------------------------------------------------
# ## Message processing
#-------------------------------------------------
processMsg = (msg) ->
  ## DELETE!
  for listener in _listeners
    listener msg
  _store?.dispatch {type: 'MSG_RECEIVED', msg}

#-------------------------------------------------
# ## API
#-------------------------------------------------
module.exports = {
  init,
  processMsg,
}