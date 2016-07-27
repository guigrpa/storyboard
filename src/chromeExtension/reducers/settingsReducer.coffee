timm = require 'timm'

INITIAL_STATE =
  timeType: 'LOCAL'
  fShowClosedActions: false
  fShorthandForDuplicates: true
  fCollapseAllNewStories: false
  fExpandAllNewAttachments: false
  fDiscardRemoteClientLogs: false
  maxRecords: 800
  forgetHysteresis: 0.25
  mainColor: 'f0f8ff' # 'lemonchiffon' is also nice

reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    when 'UPDATE_SETTINGS'
      {settings} = action
      state = timm.merge state, settings
      if not(state.maxRecords > 0)
        state = timm.set state, 'maxRecords', INITIAL_STATE.maxRecords
      return state

    else return state

module.exports = reducer
reducer.DEFAULT_SETTINGS = INITIAL_STATE
