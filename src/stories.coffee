chalk = require 'chalk'
_ = require './vendor/lodash'
hub = require './hub'
k = require './constants'
uuid = require 'node-uuid'

DEFAULT_SRC = 'main'
DEFAULT_CHILD_TITLE = ''

#-----------------------------------------------
# ### Helpers
#-----------------------------------------------
_storyId = 0
_getStoryId = -> (if k.IS_BROWSER then "cs/" else "ss/") + uuid.v4()
_recordId = 0
_getRecordId = -> if k.IS_BROWSER then "c#{_recordId++}" else "s#{_recordId++}"

#-----------------------------------------------
# ## Story
#-----------------------------------------------
Story = (parents, src, title) ->
  @fRoot = not parents.length
  @id = if @fRoot then '*' else _getStoryId()
  @parents = parents
  @src = src
  @title = title
  @fServer = not k.IS_BROWSER
  @t = new Date().toISOString()
  @fOpen = true
  @status = undefined
  @logStory 'CREATED'

#-----------------------------------------------
# ### Story lifecycle
#-----------------------------------------------
Story::close = -> 
  @fOpen = false
  @logStory 'CLOSED'
Story::changeTitle = (title) ->
  @title = title
  @logStory 'TITLE_CHANGED'
Story::changeStatus = (status) ->
  @status = status
  @logStory 'STATUS_CHANGED'

Story::addParent = (id) -> @parents.push id
Story::child = (options = {}) -> 
  {src = DEFAULT_SRC, title = DEFAULT_CHILD_TITLE, extraParents} = options
  parents = [@id]
  if extraParents?
    parents = parents.concat extraParents
  return new Story parents, src, title

#-----------------------------------------------
# ### Logs
#-----------------------------------------------
_.each k.LEVEL_NUM_TO_STR, (levelStr, levelNum) ->
  return if levelStr is 'STORY'
  Story::[levelStr.toLowerCase()] = (src, msg, obj) ->
    _emit {
      storyId: @id,
      level: levelNum,
      src, msg, obj
    }

Story::tree = (src, node, options, prefix) -> 
  #- `tree obj`
  if _.isObject src
    prefix = options
    options = node
    node = src
    src = DEFAULT_SRC
  options ?= {}
  prefix ?= ''
  level = (options.level ? 'INFO').toLowerCase()
  story = @
  options.log = (msg) -> story[level] src, msg
  return _tree node, options, prefix, []

#-----------------------------------------------
# ### Story helpers
#-----------------------------------------------
Story::logStory = (action) ->
  _emit
    t: @t
    storyId: @id
    parents: @parents
    fStory: true
    src: @src
    msg: @title
    action: action

_tree = (node, options, prefix, stack) ->
  options.ignoreKeys ?= []
  stack.push node
  postponedArrayAttrs = []
  postponedObjectAttrs = []
  for key, val of node
    continue if key in options.ignoreKeys
    if _.isObject(val) and _.includes(stack, val)  # Avoid circular dependencies
      _treeLine prefix, key, chalk.green('[CIRCULAR]'), options
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
# * `fServer: boolean`
# * `storyId: string`
# * `action: string` (only for stories)
# * `parents: Array` (only for stories)
# * `id: string` (a unique record id)
# * `t: string` (if not in the record, added here) (for stories, creation time)
# * `level: number` (only for logs)
# * `src: string?`
# * `msg: string`
# * `obj: object?
_emit = (record) ->
  record.id = _getRecordId()
  record.t ?= new Date().toISOString()
  record.fServer = not k.IS_BROWSER
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
title = (if k.IS_BROWSER then 'BROWSER' else 'SERVER') + ' ROOT STORY'
mainStory = new Story [], 'storyboard', title
module.exports = mainStory
