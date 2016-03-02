_ = require '../vendor/lodash'
timm = require 'timm'
chalk = require 'chalk'
k = require '../gral/constants'
ansiColors = require '../gral/ansiColors'

DEFAULT_CONFIG =
  moduleNameLength: 20
  relativeTime:     k.IS_BROWSER
  minLevel:         10

  # TODO: implement minLevel

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
_argsForBrowserConsole = (str) -> ansiColors.argsForBrowserConsole str

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
  return {timeStr, extraTimeStr}

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
_process = (record, config) ->
  {src, storyId, level, fStory, obj} = record
  {timeStr, extraTimeStr} = _getTimeStr record, config
  if fStory
    ## parents = record.parents
    msgStr = record.title
    levelStr = '-----'
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
  objStr = if obj? then chalk.yellow " -- #{JSON.stringify obj}" else ''
  ## finalMsg = "#{parentsStr} #{timeStr} #{srcStr} #{levelStr} #{storyIdStr}#{msgStr}#{actionStr}"
  finalMsg = "#{timeStr} #{srcStr} #{levelStr} #{storyIdStr}#{msgStr}#{actionStr}#{objStr}"
  if fStory then finalMsg = chalk.bold finalMsg
  if k.IS_BROWSER
    args = _argsForBrowserConsole finalMsg
  else
    args = [finalMsg]
  if record.level >= 50
    if extraTimeStr? then console.log "      #{extraTimeStr}"
    console.error.apply console, args
  else if (not k.IS_BROWSER) or (process.env.NODE_ENV isnt 'production')
    if extraTimeStr? then console.log "      #{extraTimeStr}"
    console.log.apply console, args

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
