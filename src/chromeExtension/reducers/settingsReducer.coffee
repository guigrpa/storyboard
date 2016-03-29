timm = require 'timm'

INITIAL_STATE =
  timeType: 'LOCAL'
  fShowClosedActions: false
  fShorthandForDuplicates: true
  fCollapseAllNewStories: false
  fExpandAllNewAttachments: false
  maxRecords: 800
  forgetHysteresis: 0.25

reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    when 'UPDATE_SETTINGS'
      {settings} = action
      return timm.merge state, settings

    else return state

module.exports = reducer
