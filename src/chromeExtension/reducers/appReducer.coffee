timm              = require 'timm'
cxReducer         = require './cxReducer'
storiesReducer    = require './storyReducer'
settingsReducer   = require './settingsReducer'

reducer = (state = {}, action) ->
  state = _updateSettings state, action
  state = _updateCx       state, action
  state = _updateStories  state, action
  state

_updateSettings = (state, action) ->
  return timm.set state, 'settings', 
    settingsReducer(state.settings, action)

_updateCx = (state, action) ->
  return timm.set state, 'cx', cxReducer(state.cx, action)

_updateStories = (state, action) ->
  return timm.set state, 'stories', 
    storiesReducer(state.stories, action, state.settings)

module.exports = reducer
