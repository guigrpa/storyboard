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
  70: 'STORY'
# TODO: create inverse map automatically
MAP_LEVELS =
  TRACE: 10
  DEBUG: 20
  INFO: 30
  WARN: 40
  ERROR: 50
  FATAL: 60
  STORY: 70
MAIN_SRC = 'main'
CHILD_TITLE = ''

#-----------------------------------------------
#- ### Helpers
#-----------------------------------------------
# A log message has:
# * `parent: number`
# * `t: date`
# * `level: number`
# * `src: string?`
# * `msg: string`
# * `obj: object?
_log = (data) ->
  data.t = new Date()
  #- `log.info msg`
  if not data.msg?
    data.msg = data.src
    data.src = MAIN_SRC
  #- `log.info msg, obj`
  else if not _.isString data.msg
    data.obj = data.msg
    data.msg = data.src
    data.src = MAIN_SRC

  # TODO: emit msg, instead of logging it...
  console.log "#{data.parent} #{LEVELS[data.level]} #{data.t.toISOString()} #{data.src} #{data.msg}"
  return

#-----------------------------------------------
# ### Storyboard
#-----------------------------------------------
_id = 0
_createStory = (parent) ->
  story = {_id: _id++}
  _.each LEVELS, (levelStr, levelNum) ->
    story[levelStr.toLowerCase()] = (src, msg, obj) -> _log {parent, level: levelNum, src, msg, obj}
  story.tree = (src, node, options, prefix) -> 
    #- `tree obj`
    if _.isObject src
      prefix = options
      options = node
      node = src
      src = MAIN_SRC
    options ?= {}
    prefix ?= ''
    level = (options.level ? 'INFO').toLowerCase()
    options.log = (msg) -> story[level] src, msg
    return _tree node, options, prefix, []
  story.child = (src, title = CHILD_TITLE) -> 
    childStory = _createStory story._id
    _log {parent, level: 70, src, msg: title}
    childStory
  story

# #### tree()
_tree = (node, options, prefix, stack) ->
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
  options.log "#{prefix}#{key}: #{chalk.bold strVal}"


#-----------------------------------------------
#- ### Public API
#-----------------------------------------------
module.exports = {
  mainStory: _createStory(),
}
