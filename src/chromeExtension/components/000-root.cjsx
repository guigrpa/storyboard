ReactRedux        = require 'react-redux'
React             = require 'react'
App               = require './005-app'

module.exports = Root = ({store}) ->
  <ReactRedux.Provider store={store}>
    <App/>
  </ReactRedux.Provider>

Root.displayName = 'Root'
