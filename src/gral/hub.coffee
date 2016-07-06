timm = require 'timm'
_ = require '../vendor/lodash'

DEFAULT_CONFIG =
  bufSize: 1000

_listeners = []
_buf = []
_config = DEFAULT_CONFIG
mainStory = null

init = (deps, options) ->
  {mainStory} = deps
  ### istanbul ignore if ###
  if not(mainStory?)
    throw new Error 'MISSING_DEPENDENCIES'
  ### istanbul ignore if ###
  if options? then config options
  return

config = (options) -> 
  _config = timm.merge _config, options

addListener = (listenerFactory, config) ->
  listenerConfig = timm.merge {mainStory, hub}, config
  listener = listenerFactory listenerConfig
  _listeners.push listener
  listener.init?()
  for record in _buf
    listener.process record
  listener

removeListener = (listener) ->
  listener.tearDown?()
  _listeners = _.filter _listeners, (o) -> o isnt listener

getListeners = -> _listeners

removeAllListeners = -> _listeners = []

emit = (record) ->
  _buf.push record
  bufLen = _config.bufSize
  if _buf.length > bufLen
    _buf.splice 0, (_buf.length - bufLen)
  for listener in _listeners
    listener.process record

getBufferedRecords = -> [].concat _buf

#-------------------------------------------------
# ## API
#-------------------------------------------------
module.exports = hub = {
  init, config,
  addListener, removeListener, getListeners, removeAllListeners,
  emit,
  getBufferedRecords,
}
