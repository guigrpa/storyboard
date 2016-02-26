_ = require '../vendor/lodash'
timm = require 'timm'
chalk = require 'chalk'
k = require '../constants'

DEFAULT_CONFIG =
  moduleNameLength: 20
  relativeTime:     k.IS_BROWSER
  minLevel:         10

  # TODO: implement minLevel

COLORS = []
BASE_COLORS = ['cyan', 'yellow', 'red', 'green', 'blue', 'magenta']
_.each BASE_COLORS, (col) -> COLORS.push chalk[col].bold
_.each BASE_COLORS, (col) -> COLORS.push chalk[col]
NUM_COLORS = COLORS.length
LEVEL_NUM_TO_COLORED_STR = {}
_.each k.LEVEL_NUM_TO_STR, (str, num) ->
  num = Number num
  col = chalk.grey
  if num is 30
    col = if k.IS_BROWSER then chalk.reset.bold else chalk.white
  else if num is 40 then col = chalk.yellow
  else if num >= 50 then col = chalk.red
  LEVEL_NUM_TO_COLORED_STR[num] = col _.padEnd(str, 5)

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
_srcColorCache = {}
_srcCnt = 0
_getSrcColor = (src) ->
  _srcColorCache[src] ?= COLORS[_srcCnt++ % NUM_COLORS]
  _srcColorCache[src]

if process.env.NODE_ENV isnt 'production'
  ansiColors = require '../gral/ansiColors'
  _argsForBrowserConsole = (str) -> ansiColors.argsForBrowserConsole str

_prevTime = 0
_getTimeStr = (record, config) ->
  timeStr = ''
  extraTimeStr = undefined
  if not config.relativeTime
    timeStr = record.t
  else
    newTime = new Date(record.t)
    dif = if _prevTime then (newTime - _prevTime)/1000 else 0
    _prevTime = newTime
    timeStr = if dif < 1 then dif.toFixed(3) else dif.toFixed(1)
    timeStr = _.padStart timeStr, 7
    if dif > 1 then extraTimeStr = '    ...'
    if dif < 0.010 then timeStr = '       '
  return {timeStr, extraTimeStr}

#-------------------------------------------------
# ## Main processing function
#-------------------------------------------------
_process = (record, config) ->
  {src, parents, level, msg, fStory, action, id} = record
  {timeStr, extraTimeStr} = _getTimeStr record, config
  parentsStr = _.padEnd parents.join(', '), 8
  srcStr = _getSrcColor(src) _.padStart(src, config.moduleNameLength)
  levelStr = if fStory then '-----' else LEVEL_NUM_TO_COLORED_STR[level]
  storyId = if fStory then "#{id} - " else ''
  actionStr = if action then " [#{action}]" else ''
  finalMsg = "#{parentsStr} #{timeStr} #{srcStr} #{levelStr} #{storyId}#{msg}#{actionStr}"
  if fStory then finalMsg = chalk.bold finalMsg
  if k.IS_BROWSER and (process.env.NODE_ENV isnt 'production')
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
