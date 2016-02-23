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
  ANSI_REGEX = /(?:(?:\u001b\[)|\u009b)(?:(?:[0-9]{1,3})?(?:(?:;[0-9]{0,3})*)?[A-M|f-m])|\u001b[A-M]/g
  MAP_ADD_STYLE = 
    30: 'color: black'
    31: 'color: red'
    32: 'color: green'
    33: 'color: yellow'
    34: 'color: blue'
    35: 'color: magenta'
    36: 'color: cyan'
    37: 'color: lightgrey'
    40: 'color: white;background-color: black'
    41: 'color: white;background-color: red'
    42: 'color: white;background-color: green'
    43: 'color: white;background-color: yellow'
    44: 'color: white;background-color: blue'
    45: 'color: white;background-color: magenta'
    46: 'color: white;background-color: cyan'
    47: 'color: white;background-color: lightgrey'
    1: 'font-weight: bold'
    2: 'opacity: 0.8'
    3: 'font-style: italic'
    4: 'text-decoration: underline'
    8: 'display: none'
    9: 'text-decoration: line-through'
  REMOVE_STYLE_LIST = [0, 21, 22, 23, 24, 27, 28, 29, 39, 49]

  _argsForBrowserConsole = (str) ->
    outStr = str.replace ANSI_REGEX, '%c'
    argArray = [outStr]
    curStyles = []
    regex = /\u001b\[(\d+)*m/gi
    while (res = regex.exec str)
      code = Number res[1]
      if code in REMOVE_STYLE_LIST
        curStyles.pop()
      else
        curStyles.push(MAP_ADD_STYLE[code] ? '')
      argArray.push curStyles.join(';')
    argArray

_prevTime = 0
_getTimeStr = (record, config) ->
  timeStr = ''
  extraTimeStr = undefined
  if not config.relativeTime
    timeStr = record.t.toISOString()
  else
    newTime = record.t
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
  {src, parents, level, msg, fStory, action} = record
  {timeStr, extraTimeStr} = _getTimeStr record, config
  srcStr = _getSrcColor(src) _.padStart(src, config.moduleNameLength)
  levelStr = if fStory then '-----' else LEVEL_NUM_TO_COLORED_STR[level]
  msg = "#{timeStr} #{srcStr} #{levelStr} #{msg}"
  if action then msg += " [#{action}]"
  if k.IS_BROWSER and (process.env.NODE_ENV isnt 'production')
    args = _argsForBrowserConsole msg
  else
    args = [msg]
  if record.level >= 50
    if extraTimeStr? then console.log "      #{extraTimeStr}"
    console.error.apply console, args
  else if (not k.IS_BROWSER) or (process.env.NODE_ENV isnt 'production')
    if extraTimeStr? then console.log "      #{extraTimeStr}"
    console.log.apply console, args

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (story, baseConfig = {}) ->
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
