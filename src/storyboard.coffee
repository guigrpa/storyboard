###
| Storyboard
| (c) Guillermo Grau Panea 2016
| License: MIT
###
_ = require 'lodash'
chalk = require 'chalk'

fNodeJs = typeof window is 'undefined'
DEFAULTS =
  moduleNameLength: 20
  longTime:         fNodeJs
  logTime:          true
  minLevel:         'DEBUG'
LEVELS = 
  10: 'TRACE'
  20: 'DEBUG'
  30: 'INFO'
  40: 'WARN'
  50: 'ERROR'
  60: 'FATAL'

#-----------------------------------------------
#- ### Helpers
#-----------------------------------------------
# A log message has:
# * `t: date`
# * `level: number`
# * `src: string?`
# * `msg: string`
# * `obj: object?
_log = (data) ->
  data.t = new Date()
  if not data.msg?
    data.msg = data.src
    data.src = undefined
  else if not _.isString data.msg
    data.obj = data.msg
    data.msg = data.src
    data.src = undefined

  ## TODO
  ## if process.env.NODE_ENV isnt 'production'
  ## convert ansi colors to console.log styles
  console.log arguments
  return

#-----------------------------------------------
# ### Storyboard
#-----------------------------------------------
logger = ->
  api = {tree}
  _.each LEVELS, (levelStr, levelNum) ->
    api[levelStr.toLowerCase()] = (src, msg, obj) -> _log {level: levelNum, src, msg, obj}
  api

# #### tree()
tree = (node, options = {}, prefix = '', stack = []) ->
  options.log ?= _log
  options.ignoreKeys ?= []
  stack.push node
  postponedArrayAttrs = []
  postponedObjectAttrs = []
  for key, val of node
    continue if key in options.ignoreKeys
    if _.isObject(val) and _.includes(stack, val)  # Avoid circular dependencies
      _treeLine prefix, key, chalk.gray('[CIRCULAR]'), options
    else if _.isArray(val) and val.length is 0
      _treeLine prefix, key, '[]', options
    else if _.isArray(val) and val.length and _.isString(val[0])
      strVal = _.map(val, (o) -> "'#{o}'").join(', ')
      strVal = chalk.yellow "[#{strVal}]"
      _treeLine prefix, key, strVal, options
    else if _.isDate(val)
      _treeLine prefix, key, chalk.magenta(val), options
    else if _.isObject(val) and Object.keys(val).length is 0
      _treeLine prefix, key, '{}', options
    else if _.isArray val
      postponedArrayAttrs.push key
    else if _.isObject val
      postponedObjectAttrs.push key
    else if _.isString val
      _treeLine prefix, key, chalk.yellow("'#{val}'"), options
    else if _.isNull val
      _treeLine prefix, key, chalk.red("null"), options
    else if _.isUndefined val
      _treeLine prefix, key, chalk.bgRed("undefined"), options
    else if _.isBoolean val
      _treeLine prefix, key, chalk.cyan(val), options
    else if _.isNumber val
      _treeLine prefix, key, chalk.blue(val), options
    else
      _treeLine prefix, key, val, options
  for key in postponedObjectAttrs
    val = node[key]
    _treeLine prefix, key, '', options
    logTree val, options, "  #{prefix}", stack
  for key in postponedArrayAttrs
    val = node[key]
    _treeLine prefix, key, '', options
    logTree val, options, "  #{prefix}", stack
  stack.pop()

_treeLine = (prefix, key, strVal, options) ->
  fnLog = options.log
  fnLog "#{prefix}#{key}: #{chalk.bold strVal}"



#-----------------------------------------------
#- ### Public API
#-----------------------------------------------
module.exports = {
}
