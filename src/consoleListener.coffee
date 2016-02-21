_ = require 'lodash'
timm = require 'timm'
chalk = require 'chalk'
ansiHtml = require 'ansi-html'
k = require './constants'

DEFAULTS =
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
  LEVEL_NUM_TO_COLORED_STR[num] = col _.padEnd(str, 8)

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
_srcColorCache = {}
_srcCnt = 0
_getSrcColor = (src) ->
  _srcColorCache[src] ?= COLORS[_srcCnt++ % NUM_COLORS]
  _srcColorCache[src]

if process.env.NODE_ENV isnt 'production'
  _argsForBrowserConsole = (str) ->
    str = ansiHtml str
    startTagRe = /<span\s+style=(['"])([^'"]*)\1\s*>/gi
    endTagRe = /<\/span>/gi
    argArray = [str.replace(startTagRe, '%c').replace(endTagRe, '%c')]
    while (reResultArray = startTagRe.exec str)
      argArray.push reResultArray[2]
      argArray.push ''
    argArray

_prevTime = 0
_getTimeStr = (record, options) ->
  timeStr = ''
  extraTimeStr = undefined
  if not options.relativeTime
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
_process = (record, options) ->
  {src} = record
  {timeStr, extraTimeStr} = _getTimeStr record, options
  srcStr = _getSrcColor(src) _.padStart(src, options.moduleNameLength)
  levelStr = _.padEnd LEVEL_NUM_TO_COLORED_STR[record.level], 3
  msg = "#{_.padEnd record.parent, 5} #{timeStr} #{srcStr} #{levelStr} #{record.msg}"
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
create = (options = {}) ->
  _options = timm.addDefaults options, DEFAULTS
  listener =
    process: (record) -> _process record, _options
  listener

module.exports = {
  create,
}
