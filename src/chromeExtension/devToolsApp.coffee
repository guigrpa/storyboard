React = require 'react'
ReactDOM = require 'react-dom'
actions = require './actions/actions'

if process.env.NODE_ENV isnt 'production'
  window.ReactPerf = require 'react-addons-perf'
  window.chalk = require 'chalk'

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
  _store.dispatch actions.loadSettings()

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