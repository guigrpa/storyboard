timm        = require 'timm'
cx          = require './cxReducer'
stories     = require './storyReducer'
settings    = require './settingsReducer'

reducer = (state = {}, action) ->
  nextState = timm.merge state,
    cx:       cx        state.cx,       action
    stories:  stories   state.stories,  action
    settings: settings  state.settings, action
  nextState

module.exports = reducer
