chalk = require 'chalk'
_ = require './vendor/lodash'
hub = require './hub'
k = require './constants'

DEFAULT_SRC = 'main'
DEFAULT_CHILD_TITLE = ''

#-----------------------------------------------
# ### Stories
#-----------------------------------------------
_storyId = 0
_getStoryId = -> if k.IS_BROWSER then "c#{_storyId++}" else "s#{_storyId++}"
_logId = 0
_getLogId = -> if k.IS_BROWSER then "c#{_logId++}" else "s#{_logId++}"

_createStory = (parents, src, title) ->
  story = {
    id: _getStoryId(),
    parents, src, title,
    fRoot: not parents.length,
    fServer: not k.IS_BROWSER,
    t: new Date().toISOString(),
    fOpen: true,
    status: undefined,
  }
  story.logStory = (action) ->
    _emit
      t: story.t
      parents: story.parents
      id: story.id,
      fStory: true
      src: story.src
      msg: story.title
      action: action
  story.logStory 'CREATED'

  story.addParent = (id) -> story.parents.push id
  story.close = -> 
    story.fOpen = false
    story.logStory 'CLOSED'
  story.changeTitle = (title) ->
    story.title = title
    story.logStory 'TITLE_CHANGED'
  story.changeStatus = (status) ->
    story.status = status
    story.logStory 'STATUS_CHANGED'
  story.child = (options = {}) -> 
    {src = DEFAULT_SRC, title = DEFAULT_CHILD_TITLE, extraParents} = options
    parents = [story.id]
    if extraParents?
      parents = parents.concat extraParents
    return _createStory parents, src, title

  _.each k.LEVEL_NUM_TO_STR, (levelStr, levelNum) ->
    return if levelStr is 'STORY'
    story[levelStr.toLowerCase()] = (src, msg, obj) -> 
      _emit { 
        parents: [story.id],
        id: _getLogId(),
        level: levelNum,
        src, msg, obj
      }

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
      _treeLine prefix, key, chalk.magenta(val.toISOString()), options
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
    _tree val, options, "  #{prefix}", stack
  for key in postponedArrayAttrs
    val = node[key]
    _treeLine prefix, key, '', options
    _tree val, options, "  #{prefix}", stack
  stack.pop()

_treeLine = (prefix, key, strVal, options) ->
  options.log "#{prefix}#{key}: #{chalk.bold strVal}"

# Records can be logs or stories:
# * `fStory: boolean`
# * `action: string` (only for stories)
# * `id: string` (a story id or log id, depending on the case)
# * `parents: Array`
# * `t: string` (if not in the record, added here) (for stories, creation time)
# * `level: number`
# * `src: string?`
# * `msg: string`
# * `obj: object?
_emit = (record) ->
  record.t ?= new Date().toISOString()
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

#-----------------------------------------------
# ### API
#-----------------------------------------------
mainStory = _createStory [], 'storyboard', 'ROOT STORY'
module.exports = mainStory
