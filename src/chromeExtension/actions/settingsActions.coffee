timm = require 'timm'

#-------------------------------------------------
# ## Actions
#-------------------------------------------------
updateSettings = (settings) ->
  prevSettings = _getSettings() ? {}
  nextSettings = timm.merge prevSettings, settings
  _setSettings nextSettings
  return {type: 'UPDATE_SETTINGS', settings}

# Convenience action creator
setTimeType = (timeType) -> updateSettings {timeType}

#-------------------------------------------------
# ## LocalStorage
#-------------------------------------------------
LOCALSTORAGE_PREFIX = 'storyboard'

_getSettings = ->
  try
    json = localStorage["#{LOCALSTORAGE_PREFIX}_settings"]
    return JSON.parse json
  return

_setSettings = (settings) ->
  try
    localStorage["#{LOCALSTORAGE_PREFIX}_settings"] = JSON.stringify settings
  return

loadSettings = -> (dispatch) ->
  settings = _getSettings()
  if settings? then dispatch updateSettings settings
  return
  
module.exports =
  actions: {
    loadSettings,
    updateSettings,
    setTimeType,
  }
