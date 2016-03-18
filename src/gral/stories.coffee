uuid        = require 'node-uuid'
_           = require '../vendor/lodash'
hub         = require './hub'
k           = require './constants'
filters     = require './filters'

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
Story = (parents, src, title, levelNum) ->
  @parents = parents
  @fRoot = not parents.length
  @storyId = if @fRoot then '*' else _getStoryId()
  @src = src
  @title = title
  @level = levelNum
  @fServer = not k.IS_BROWSER
  @t = new Date().getTime()
  @fOpen = true
  @status = undefined
  @pastActionRecords = []
  @emitAction 'CREATED', @t

#-----------------------------------------------
# ### Story lifecycle
#-----------------------------------------------
Story::close = -> 
  @fOpen = false
  @emitAction 'CLOSED'
  return
Story::changeTitle = (title) ->
  @title = title
  @emitAction 'TITLE_CHANGED'
  return
Story::changeStatus = (status) ->
  @status = status
  @emitAction 'STATUS_CHANGED'
  return

Story::child = (options = {}) -> 
  {src, title, extraParents, level: levelStr} = options
  src ?= DEFAULT_SRC
  title ?= DEFAULT_CHILD_TITLE
  levelNum = k.LEVEL_STR_TO_NUM[levelStr?.toUpperCase()] ? k.LEVEL_STR_TO_NUM.INFO
  parents = [@storyId]
  if extraParents? then parents = parents.concat extraParents
  return new Story parents, src, title, levelNum

#-----------------------------------------------
# ### Logs
#-----------------------------------------------
_.each k.LEVEL_NUM_TO_STR, (levelStr, levelNum) ->
  return if levelStr is 'STORY'
  Story::[levelStr.toLowerCase()] = (src, msg, options) ->
    #- `log.info msg`
    if arguments.length <= 1
      msg = arguments[0] ? ''
      src = DEFAULT_SRC
    #- `log.info msg, options`
    else if _.isObject arguments[1]
      options = arguments[1]
      msg = arguments[0] ? ''
      src = DEFAULT_SRC
    options ?= {}
    record =
      storyId: @storyId
      level: levelNum
      src: src
      msg: msg
    if options.hasOwnProperty 'attach'
      record.obj = options.attach
      record.objExpanded = not(options.attachInline ? false)
    else if options.hasOwnProperty 'attachInline'
      record.obj = options.attachInline
      record.objExpanded = false
    if record.hasOwnProperty 'obj'
      objLevel = k.LEVEL_STR_TO_NUM[options.attachLevel?.toUpperCase()] ? levelNum
      record.objLevel = objLevel
      record.objOptions = _.pick options, ['ignoreKeys']
      record.objIsError = _.isError record.obj
    _emit record
    return

#-----------------------------------------------
# ### Story helpers
#-----------------------------------------------
Story::emitAction = (action, t) ->
  record = _emit
    parents: @parents
    fRoot: @fRoot
    storyId: @storyId
    src: @src
    title: @title
    level: @level
    fServer: @fServer
    t: t
    fOpen: @fOpen
    status: @status
    fStory: true
    action: action
  @pastActionRecords.push record
  return

# Records can be logs or stories:
# * `id: string` (a unique record id)
# * `fStory: boolean`
# * `fServer: boolean`
# * `storyId: string`
# * `t: string` (if not in the record, added here) (for stories, creation time)
# * `level: number`
# * `src: string?`
# * `msg: string`
# * `action: string` (only for stories)
# * `parents: Array` (only for stories)
# * `title: string?` (only for stories)
# * `obj: object?`       (only for logs)
# * `objExpanded: bool?` (only for logs)
# * `objLevel: string?`  (only for logs)
# * `objOptions: object?`  (only for logs)
# * `objIsError: bool?` (only for logs)
_emit = (record) ->
  if not record.fStory
    return unless filters.passesFilter record.src, record.level
  record.id = _getRecordId()
  record.t ?= new Date().getTime()
  record.fServer = not k.IS_BROWSER
  hub.emit record
  record

#-----------------------------------------------
# ### API
#-----------------------------------------------
title = (if k.IS_BROWSER then 'BROWSER' else 'SERVER') + ' ROOT STORY'
mainStory = new Story [], 'storyboard', title, k.LEVEL_STR_TO_NUM.FATAL
module.exports = mainStory
