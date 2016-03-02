_               = require 'lodash'
settingsActions = require './settingsActions'
storyActions    = require './storyActions'
cxActions       = require './cxActions'

init = (deps) ->
  {sendMsg} = deps
  if not(sendMsg?)
    throw new Error "MISSING_DEPS"
  cxActions.init {sendMsg}

module.exports = _.merge {init}, 
  settingsActions.actions,
  storyActions.actions,
  cxActions.actions
