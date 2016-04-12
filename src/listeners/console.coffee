_           = require '../vendor/lodash'
timm        = require 'timm'
chalk       = require 'chalk'
ansiColors  = require '../gral/ansiColors'
k           = require '../gral/constants'
filters     = require '../gral/filters'
treeLines   = require '../gral/treeLines'

DEFAULT_CONFIG =
  moduleNameLength: 20
  relativeTime:     k.IS_BROWSER
  minLevel:         10

TIME_COL_RELATIVE_LENGTH = 7
TIME_COL_RELATIVE_EMPTY = _.padStart '', TIME_COL_RELATIVE_LENGTH
TIME_COL_ABSOLUTE_LENGTH = new Date().toISOString().length
TIME_COL_ABSOLUTE_EMPTY = _.padStart '', TIME_COL_ABSOLUTE_LENGTH

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
    timeStr = _.padStart timeStr, TIME_COL_RELATIVE_LENGTH
    if dif > 1 then extraTimeStr = '    ...'
    if dif < 0.010 then timeStr = TIME_COL_RELATIVE_EMPTY
  else
    timeStr = new Date(record.t).toISOString()
  return [timeStr, extraTimeStr]

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
_process = (record, config) ->
  {
    src, storyId, level, fStory, fServer,
    obj, objExpanded, objLevel, objOptions,
    uploadedBy,
  } = record

  # Do not pollute server logs with uploaded client logs
  return if (not k.IS_BROWSER) and uploadedBy?

  [timeStr, extraTimeStr] = _getTimeStr record, config
  levelStr = ansiColors.LEVEL_NUM_TO_COLORED_STR[level]
  if fStory
    ## parents = record.parents
    timeStr = chalk.bold timeStr
    storyPrefix = switch record.action
      when 'CREATED' then "\u250c\u2500\u2500"
      when 'CLOSED'  then "\u2514\u2500\u2500"
      else                "\u251c\u2500\u2500"
    msgStr = chalk.bold "#{storyPrefix} #{record.title}"
    actionStr = " [#{chalk.bold record.action}]"
  else
    ## parents = [storyId]
    msgStr = record.msg
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
  else if level >= k.LEVEL_STR_TO_NUM.WARN then msgStr = chalk.yellow.bold msgStr
  ## finalMsg = "#{parentsStr} #{timeStr} #{srcStr} #{levelStr} #{msgStr}#{actionStr}"
  finalMsg = "#{timeStr} #{srcStr} #{levelStr}#{msgStr}#{actionStr}#{objStr}"
  _outputLog finalMsg, record.level, extraTimeStr
  if objExpanded and filters.passesFilter src, objLevel
    treeOptions = timm.merge {prefix: '  '}, objOptions
    lines = treeLines obj, treeOptions
    levelStr = ansiColors.LEVEL_NUM_TO_COLORED_STR[objLevel]
    emptyTimeStr = if config.relativeTime then TIME_COL_RELATIVE_EMPTY else TIME_COL_ABSOLUTE_EMPTY
    for line in lines
      text = "#{emptyTimeStr} #{srcStr} #{levelStr}#{line}"
      _outputLog text
  return

_outputLog = (text, level, extraTimeStr) ->
  if k.IS_BROWSER
    args = _getBrowserConsoleArgs text
  else
    args = [text]
  if extraTimeStr? then console.log "      #{extraTimeStr}"
  output = if (level? and level >= 50 and level <= 60) then 'error' else 'log'
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
