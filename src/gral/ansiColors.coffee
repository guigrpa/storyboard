_ = require '../vendor/lodash'
chalk = require 'chalk'
k = require './constants'

#-------------------------------------------------
# ## Map severity level to a colored string
#-------------------------------------------------
LEVEL_NUM_TO_COLORED_STR = {}
_.each k.LEVEL_NUM_TO_STR, (str, num) ->
  num = Number num
  col = chalk.grey
  if num is 30
    col = if k.IS_BROWSER then chalk.bold else chalk.white
  else if num is 40 then col = chalk.yellow
  else if num >= 50 then col = chalk.red
  LEVEL_NUM_TO_COLORED_STR[num] = col _.padEnd(str, 5)

#-------------------------------------------------
# ## Get a color for a given src (cached)
#-------------------------------------------------
COLORS = []
BASE_COLORS = ['cyan', 'yellow', 'red', 'green', 'blue', 'magenta']
_.each BASE_COLORS, (col) -> COLORS.push chalk[col].bold
_.each BASE_COLORS, (col) -> COLORS.push chalk[col]
NUM_COLORS = COLORS.length

_srcColorCache = {}
_srcCnt = 0
getSrcChalkColor = (src) ->
  _srcColorCache[src] ?= COLORS[_srcCnt++ % NUM_COLORS]
  _srcColorCache[src]

#-------------------------------------------------
# ## Convert ANSI codes to console args and styled segments
#-------------------------------------------------
ANSI_REGEX = /(?:(?:\u001b\[)|\u009b)(?:(?:[0-9]{1,3})?(?:(?:;[0-9]{0,3})*)?[A-M|f-m])|\u001b[A-M]/g
ANSI_ADD =
  1: 'BOLD'
  2: 'DIM'
  3: 'ITALIC'
  4: 'UNDERLINE'
  7: 'INVERSE'
  8: 'HIDDEN'
  9: 'STRIKETHROUGH'
ANSI_ADD_COLOR =
  30: 'BLACK'
  31: 'RED'
  32: 'GREEN'
  33: 'YELLOW'
  34: 'BLUE'
  94: 'BLUE'
  35: 'MAGENTA'
  36: 'CYAN'
  37: 'WHITE'
  90: 'GREY'
ANSI_ADD_BGCOLOR =
  40: 'BLACK'
  41: 'RED'
  42: 'GREEN'
  43: 'YELLOW'
  44: 'BLUE'
  45: 'MAGENTA'
  46: 'CYAN'
  47: 'WHITE'
ANSI_REMOVE =
  # 0, 39, 49: handled manually
  21: ['BOLD']
  22: ['BOLD', 'DIM']
  23: ['ITALIC']
  24: ['UNDERLINE']
  27: ['INVERSE']
  28: ['HIDDEN']
  29: ['STRIKETHROUGH']
CSS_COLORS =
  BLACK: 'black'
  RED: 'red'
  GREEN: 'green'
  YELLOW: 'orange'
  BLUE: 'blue'
  MAGENTA: 'magenta'
  CYAN: 'darkturquoise'
  WHITE: 'lightgrey'
  GREY: 'grey'
CSS_STYLES =
  BOLD: 'font-weight: bold'
  DIM: 'opacity: 0.8'
  ITALIC: 'font-style: italic'
  UNDERLINE: 'text-decoration: underline'
  INVERSE: ''
  HIDDEN: 'display: none'
  STRIKETHROUGH: 'text-decoration: line-through'
REACT_STYLES =
  BOLD: fontWeight: 'bold'
  DIM: opacity: 0.8
  ITALIC: fontStyle: 'italic'
  UNDERLINE: textDecoration: 'underline'
  INVERSE: {}
  HIDDEN: {display: 'none'}
  STRIKETHROUGH: {textDecoration: 'line-through'}

getBrowserConsoleArgs = (str) ->
  outStr = str.replace ANSI_REGEX, '%c'
  argArray = [outStr]
  curStyles = {}
  regex = /\u001b\[(\d+)*m/gi
  while (res = regex.exec str)
    curStyles = _updateStyles curStyles, Number res[1]
    argArray.push _toConsoleArgs curStyles
  argArray

getStyledSegments = (str) ->
  out = []
  return out if not _.isString str
  tokens = str.split /\u001b\[(\d+)*m/gi
  curStyles = {}
  text = tokens[0]
  if text.length then out.push {text}
  for idx in [1...tokens.length] by 2
    curStyles = _updateStyles curStyles, Number tokens[idx]
    text = tokens[idx+1]
    continue if not text.length
    out.push {text, style: _toSegmentStyle curStyles}
  out

_updateStyles = (curStyles, code) ->
  if (style = ANSI_ADD[code])
    curStyles[style] = true
  else if (color = ANSI_ADD_COLOR[code])
    curStyles.color = color
  else if (bgColor = ANSI_ADD_BGCOLOR[code])
    curStyles.bgColor = color
  else if code is 39
    curStyles.color = undefined
  else if code is 49
    curStyles.bgColor = undefined
  else if (removeStyles = ANSI_REMOVE[code])
    curStyles[style] = undefined for style in removeStyles
  else if code is 0
    curStyles = {}
  curStyles

_toConsoleArgs = (styles) ->
  out = []
  for key, val of styles
    continue if not val?
    switch key
      when 'color' 
        out.push "color: #{CSS_COLORS[val]}"
      when 'bgColor' 
        out.push "color: white; background-color: #{CSS_COLORS[val]}"
      else
        out.push CSS_STYLES[key]
  return out.join ';'

_toSegmentStyle = (styles) ->
  out = {}
  for key, val of styles
    continue if not val?
    switch key
      when 'color'
        out.color = CSS_COLORS[val]
      when 'bgColor'
        out.color = 'white'
        out.backgroundColor = CSS_COLORS[val]
      else
        _.extend out, REACT_STYLES[key]
  out

#-------------------------------------------------
# ## Public API
#-------------------------------------------------
module.exports = {
  LEVEL_NUM_TO_COLORED_STR,
  getSrcChalkColor,
  getBrowserConsoleArgs,
  getStyledSegments,
}
