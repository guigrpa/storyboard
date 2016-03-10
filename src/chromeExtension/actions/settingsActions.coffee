#-------------------------------------------------
# ## Actions
#-------------------------------------------------
setTimeType = (timeType) -> 
  _set 'timeType', timeType
  {type: 'SET_TIME_TYPE', timeType}

setShowClosedActions = (fShowClosedActions) -> 
  _set 'fShowClosedActions', fShowClosedActions
  {type: 'SET_SHOW_CLOSED_ACTIONS', fShowClosedActions}

#-------------------------------------------------
# ## LocalStorage
#-------------------------------------------------
LOCALSTORAGE_PREFIX = 'storyboard'

_get = (key) ->
  try
    json = localStorage["#{LOCALSTORAGE_PREFIX}_#{key}"]
    return JSON.parse json
  return

_set = (key, val) ->
  try
    localStorage["#{LOCALSTORAGE_PREFIX}_#{key}"] = JSON.stringify val
  return

loadSettings = -> (dispatch) ->
  timeType = _get 'timeType'
  if timeType? then dispatch setTimeType timeType
  fShowClosedActions = _get 'fShowClosedActions'
  if fShowClosedActions? then dispatch setShowClosedActions fShowClosedActions
  
module.exports =
  actions: {
    loadSettings,
    setTimeType,
    setShowClosedActions,
  }
