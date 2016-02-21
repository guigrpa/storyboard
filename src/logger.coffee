_ = require 'lodash'
chalk = require 'chalk'
hub = require './hub'
k = require './constants'

DEFAULT_SRC = 'main'
CHILD_TITLE = ''

#-----------------------------------------------
# ### Stories
#-----------------------------------------------
_id = 0
_getId = -> if k.IS_BROWSER then "c#{_id++}" else "s#{_id++}"

createStory = (parents) ->
  story = {
    parents,
    _id: _getId(),
    fOpen: true,
  }

  story.addParent = (id) -> story.parents.push id
  story.close = -> story.fOpen = false
  story.child = (src, title = CHILD_TITLE) -> 
    childStory = _createStory [story._id]
    _log {parent: story._id, level: 70, src, msg: title}
    childStory

  _.each k.LEVEL_NUM_TO_STR, (levelStr, levelNum) ->
    return if levelStr is 'STORY'
    story[levelStr.toLowerCase()] = (src, msg, obj) -> _log {parent: story._id, level: levelNum, src, msg, obj}

  story.tree = (src, node, options, prefix) -> 
    #- `tree obj`
    if _.isObject src
      prefix = options
      options = node
      node = src
      src = DEFAULT_SRC
    options ?= {}
    prefix ?= ''
    level = (options.level ? 'INFO').toLowerCase()
    options.log = (msg) -> story[level] src, msg
    return _tree node, options, prefix, []

  story

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

# A log message has:
# * `parent: number`
# * `t: date`
# * `level: number`
# * `src: string?`
# * `msg: string`
# * `obj: object?
_log = (record) ->
  record.t = new Date()
  #- `log.info msg`
  if not record.msg?
    record.msg = record.src
    record.src = DEFAULT_SRC
  #- `log.info msg, obj`
  else if not _.isString record.msg
    record.obj = record.msg
    record.msg = record.src
    record.src = DEFAULT_SRC

  hub.emit record
  return


module.exports = {
  createStory,
}