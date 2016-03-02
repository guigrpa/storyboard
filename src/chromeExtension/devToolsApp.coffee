React = require 'react'
ReactDOM = require 'react-dom'
actions = require './actions/actions'

#-------------------------------------------------
# ## Internal
#-------------------------------------------------
_store = null

#-------------------------------------------------
# ## Initialisation
#-------------------------------------------------
init = (deps) ->
  {sendMsg} = deps
  if not(sendMsg?)
    throw new Error "MISSING_DEPS"
  console.log "[DT] Starting up..."

  actions.init {sendMsg}

  createStore = require './store/createStore'
  _store = createStore()

  # Render the app
  RootComponent = require './components/000-root'
  RootElement = React.createElement RootComponent,
    store: _store
  ReactDOM.render RootElement, document.getElementById 'devToolsApp'

#-------------------------------------------------
# ## Message processing
#-------------------------------------------------
processMsg = (msg) ->
  _store?.dispatch {type: 'MSG_RECEIVED', msg}

#-------------------------------------------------
# ## API
#-------------------------------------------------
module.exports = {
  init,
  processMsg,
}