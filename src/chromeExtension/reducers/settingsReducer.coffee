timm = require 'timm'
tinycolor = require 'tinycolor2'
{ isDark } = require 'giu'

calcFgColorForBgColor = (bg) ->
  fg = if isDark(bg) then 'white' else 'black'
  fg

calcFgColorForUiBgColor = (bg) ->
  if isDark(bg)
    fg = tinycolor('white').darken(25).toRgbString()
  else
    fg = tinycolor('black').lighten(25).toRgbString()
  fg

# in-place
addFgColors = (state) ->
  state.colorClientFg = calcFgColorForBgColor state.colorClientBg
  state.colorServerFg = calcFgColorForBgColor state.colorServerBg
  state.colorUiFg = calcFgColorForUiBgColor state.colorUiBg
  state

INITIAL_STATE =
  timeType: 'LOCAL'
  fShowClosedActions: false
  fShorthandForDuplicates: true
  fCollapseAllNewStories: false
  fExpandAllNewAttachments: false
  fDiscardRemoteClientLogs: false
  maxRecords: 800
  forgetHysteresis: 0.25
  colorClientBg: 'aliceblue' # lemonchiffon is also nice
  colorServerBg: tinycolor('aliceblue').darken(5).toRgbString()
  colorUiBg: 'white'
addFgColors INITIAL_STATE

reducer = (state = INITIAL_STATE, action) ->
  switch action.type

    when 'UPDATE_SETTINGS'
      {settings} = action
      nextState = timm.merge state, settings
      if nextState isnt state
        addFgColors nextState
      if not(nextState.maxRecords > 0)
        nextState = timm.set nextState, 'maxRecords', INITIAL_STATE.maxRecords
      return nextState

    else return state

module.exports = reducer
reducer.DEFAULT_SETTINGS = INITIAL_STATE
