uuid          = require 'node-uuid'
platform      = require 'platform'
chalk         = require 'chalk'
_             = require '../vendor/lodash'
k             = require './constants'
filters       = require './filters'
hub           = require './hub'
{ serialize } = require './serialize'

DEFAULT_SRC = 'main'
DEFAULT_CHILD_TITLE = ''

# Record formats:
# * 1 (or undefined): initial version
# * 2: embeds objects directly, not their visual representation
#   (does not call treeLines before attaching). Circular refs are removed
RECORD_FORMAT_VERSION = 2

_hiddenStories = {}
_hubId = hub.getHubId()

#-----------------------------------------------
# ### Helpers
#-----------------------------------------------
_getStoryId = -> (if k.IS_BROWSER then "cs/" else "ss/") + uuid.v4()
_getRecordId = -> (if k.IS_BROWSER then 'c-' else 's-') + uuid.v4()

#-----------------------------------------------
# ## Story
#-----------------------------------------------
Story = ({parents, src, title, levelNum, fHiddenByFilter}) ->
  @parents = parents
  @fRoot = not parents.length
  @storyId = (if @fRoot then '*/' else '') + _getStoryId()
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
    _processAttachments record, options
    _completeRecord record

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
  record =
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
  _completeRecord record
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
# * Common to stories and logs:
#   - `id: string` (a unique record id)
#   - `hubId: string`
#   - `version: integer`
#   - `fStory: boolean`
#   - `fServer: boolean`
#   - `storyId: string`
#   - `t: string` (for stories, creation time)
#   - `src: string?`
#   - `level: number`
# * Only for stories:
#   - `fRoot: boolean`
#   - `title: string?`
#   - `action: string`
#   - `parents: Array`
# * Only for logs:
#   - `msg: string`
#   - `obj: object?`
#   - `objExpanded: bool?`
#   - `objLevel: integer?`
#   - `objOptions: object?`
#   - `objIsError: bool?`
_completeRecord = (record) ->
  record.id = _getRecordId()
  record.hubId = _hubId
  record.version = RECORD_FORMAT_VERSION
  record.t ?= new Date().getTime()
  record.fServer = not k.IS_BROWSER
  record.fStory ?= false
  record.fRoot ?= false
  return

_processAttachments = (record, options) ->
  if options.hasOwnProperty 'attach'
    record.obj = options.attach
    record.objExpanded = not(options.attachInline ? false)
  else if options.hasOwnProperty 'attachInline'
    record.obj = options.attachInline
    record.objExpanded = false
  if record.hasOwnProperty 'obj'
    objLevel = k.LEVEL_STR_TO_NUM[options.attachLevel?.toUpperCase()] ? record.level
    record.objLevel = objLevel
    record.objOptions = _.pick options, ['ignoreKeys']
    record.objIsError = _.isError record.obj
    record.obj = serialize record.obj
  return

_emit = (record) -> hub.emitMsgWithFields 'STORIES', 'RECORDS', [record]

#-----------------------------------------------
# ### Create the main story
#-----------------------------------------------
title = "ROOT STORY: #{chalk.italic.blue.bold platform.description}"
mainStory = new Story 
  parents: []
  src: 'storyboard'
  title: title
  levelNum: k.LEVEL_STR_TO_NUM.INFO

#-----------------------------------------------
# ### API
#-----------------------------------------------
module.exports = mainStory
