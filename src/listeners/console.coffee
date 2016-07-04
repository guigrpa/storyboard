_           = require '../vendor/lodash'
timm        = require 'timm'
ansiColors  = require '../gral/ansiColors'
k           = require '../gral/constants'
recordToLines = require('./helpers/recordToLines').default

DEFAULT_CONFIG =
  moduleNameLength: 20
  relativeTime:     k.IS_BROWSER

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
_getBrowserConsoleArgs = (str) -> ansiColors.getBrowserConsoleArgs str

_prevTime = 0

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
_process = (record, config) ->
  # Do not pollute server logs with uploaded client logs
  return if (not k.IS_BROWSER) and record.uploadedBy?

  options = timm.set(config, 'prevTime', _prevTime)
  lines = recordToLines record, options
  _prevTime = new Date(record.t)

  for { text, level, fLongDelay } in lines
    _outputLog text, level, fLongDelay

_outputLog = (text, level, fLongDelay) ->
  if k.IS_BROWSER
    args = _getBrowserConsoleArgs text
  else
    args = [text]
  if fLongDelay then console.log "          ..."
  output = if (level >= 50 and level <= 60) then 'error' else 'log'
  console[output].apply console, args

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (baseConfig) ->
  config = timm.addDefaults baseConfig, DEFAULT_CONFIG
  listener =
    type: 'CONSOLE'
    init: ->
    process: (record) -> _process record, config
    config: (newConfig) -> config = timm.merge config, newConfig
  listener

module.exports = {
  create,
}
