_           = require '../vendor/lodash'
timm        = require 'timm'
chalk       = require 'chalk'
k           = require '../gral/constants'
ansiColors  = require '../gral/ansiColors'
treeLines   = require '../gral/treeLines'
filters     = require '../gral/filters'

DEFAULT_CONFIG =
  moduleNameLength: 20
  relativeTime:     k.IS_BROWSER
  minLevel:         10

_console = console
_setConsole = (o) -> _console = o

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
_getBrowserConsoleArgs = (str) -> ansiColors.getBrowserConsoleArgs str

_prevTime = 0
_getTimeStr = (record, config) ->
  timeStr = ''
  extraTimeStr = undefined
  if config.relativeTime
    newTime = new Date(record.t)
    dif = if _prevTime then (newTime - _prevTime)/1000 else 0
    _prevTime = newTime
    timeStr = if dif < 1 then dif.toFixed(3) else dif.toFixed(1)
    timeStr = _.padStart timeStr, 7
    if dif > 1 then extraTimeStr = '    ...'
    if dif < 0.010 then timeStr = '       '
  else
    timeStr = new Date(record.t).toISOString()
  return [timeStr, extraTimeStr]

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
_process = (record, config) ->
  {src, storyId, level, fStory, obj, objExpanded, objLevel, objOptions} = record
  [timeStr, extraTimeStr] = _getTimeStr record, config
  if fStory
    ## parents = record.parents
    msgStr = record.title
    levelStr = '----- '
    storyIdStr = "#{storyId.slice 0, 8} - "
    actionStr = " [#{record.action}]"
  else
    ## parents = [storyId]
    msgStr = record.msg
    levelStr = ansiColors.LEVEL_NUM_TO_COLORED_STR[level]
    storyIdStr = ''
    actionStr = ''
  ## parentsStr = _.padEnd parents.map((o) -> o.slice 0, 7).join(', '), 10
  srcStr = ansiColors.getSrcChalkColor(src) _.padStart(src, config.moduleNameLength)
  objStr = ''
  if obj? and not objExpanded
    try
      objStr = chalk.yellow " -- #{JSON.stringify obj}"
    catch e
      objStr = chalk.red " -- [could not stringify object, expanding...]"
      objExpanded = true
  if level >= k.LEVEL_STR_TO_NUM.ERROR then msgStr = chalk.red.bold msgStr
  else if level >= k.LEVEL_STR_TO_NUM.WARN then msgStr = chalk.red.yellow msgStr
  ## finalMsg = "#{parentsStr} #{timeStr} #{srcStr} #{levelStr} #{storyIdStr}#{msgStr}#{actionStr}"
  finalMsg = "#{timeStr} #{srcStr} #{levelStr}#{storyIdStr}#{msgStr}#{actionStr}#{objStr}"
  if fStory then finalMsg = chalk.bold finalMsg
  _outputLog finalMsg, record.level, extraTimeStr
  if objExpanded and filters.passesFilter src, objLevel
    treeOptions = timm.merge {prefix: '  '}, objOptions
    lines = treeLines obj, treeOptions
    levelStr = ansiColors.LEVEL_NUM_TO_COLORED_STR[objLevel]
    for line in lines
      text = "#{timeStr} #{srcStr} #{levelStr}#{line}"
      _outputLog text
  return

_outputLog = (text, level, extraTimeStr) ->
  if k.IS_BROWSER
    args = _getBrowserConsoleArgs text
  else
    args = [text]
  if extraTimeStr? then _console.log "      #{extraTimeStr}"
  output = if (level? and level >= 50) then 'error' else 'log'
  _console[output].apply _console, args

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

  # Just for unit testing
  _setConsole,
}
