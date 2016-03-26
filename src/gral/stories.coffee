uuid        = require 'node-uuid'
_           = require '../vendor/lodash'
hub         = require './hub'
k           = require './constants'
filters     = require './filters'

DEFAULT_SRC = 'main'
DEFAULT_CHILD_TITLE = ''

_hiddenStories = {}

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
Story = ({parents, src, title, levelNum, fHiddenByFilter}) ->
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
  @hiddenRecords = []
  @fHiddenByFilter = fHiddenByFilter or (not filters.passesFilter @src, @level)
  if @fHiddenByFilter then _hiddenStories[@storyId] = @
  if not @fRoot
    @emitAction 'CREATED', @t

#-----------------------------------------------
# ### Story lifecycle
#-----------------------------------------------
Story::close = -> 
  @fOpen = false
  @emitAction 'CLOSED'
  if @fHiddenByFilter
    _hiddenStories[@storyId] = null
    @hiddenRecords = []
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
  return new Story {
    parents, src, title, levelNum, 
    fHiddenByFilter: @fHiddenByFilter
  }

#-----------------------------------------------
# ### Logs
#-----------------------------------------------
_.each k.LEVEL_STR_TO_NUM, (levelNum, levelStr) ->
  Story::[levelStr.toLowerCase()] = (src, msg, options) ->

    # Prepare arguments
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

    # Filtering rule #1
    return if not filters.passesFilter src, levelNum

    # Prepare record
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
    record = _completeRecord record

    # Filtering rule #2
    if @fHiddenByFilter
      if levelNum < k.LEVEL_STR_TO_NUM.WARN
        @hiddenRecords.push record
        return
      @reveal()

    _emit record
    return

#-----------------------------------------------
# ### Story helpers
#-----------------------------------------------
Story::emitAction = (action, t) ->
  record = _completeRecord
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
  if @fHiddenByFilter
    @hiddenRecords.push record
    return
  _emit record
  return

# Reveal parents recursively, and then reveal myself
Story::reveal = ->
  for parentStoryId in @parents
    _hiddenStories[parentStoryId]?.reveal()
  @fHiddenByFilter = false
  _hiddenStories[@storyId] = null
  _emit record for record in @hiddenRecords
  @hiddenRecords = []
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
_completeRecord = (record) ->
  record.id = _getRecordId()
  record.t ?= new Date().getTime()
  record.fServer = not k.IS_BROWSER
  record

_emit = (record) -> hub.emit record

#-----------------------------------------------
# ### API
#-----------------------------------------------
title = (if k.IS_BROWSER then 'BROWSER' else 'SERVER') + ' ROOT STORY'
mainStory = new Story 
  parents: []
  src: 'storyboard'
  title: title
  levelNum: k.LEVEL_STR_TO_NUM.FATAL
module.exports = mainStory
