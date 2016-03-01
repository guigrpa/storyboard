ReactRedux        = require 'react-redux'
React             = require 'react'
App               = require './005-app'

module.exports = Root = ({store, msgSend, msgSubscribe}) ->
  <ReactRedux.Provider store={store}>
    <App msgSend={msgSend} msgSubscribe={msgSubscribe}/>
  </ReactRedux.Provider>

Root.displayName = 'Root'
