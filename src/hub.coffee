timm = require 'timm'

DEFAULT_CONFIG =
  bufSize = 1000

_listeners = []
_buf = []
_config = DEFAULT_CONFIG
mainStory = null

init = (deps, options) ->
  {mainStory} = deps
  if not(mainStory?)
    throw new Error 'MISSING_DEPENDENCIES'
  if options? then config options

config = (options) -> 
  _config = timm.merge _config, options

addListener = (listenerFactory, config) ->
  listenerConfig = timm.merge {mainStory, hub}, config
  listener = listenerFactory.create listenerConfig
  _listeners.push listener
  listener.init?()

getListeners = -> _listeners

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
  addListener, getListeners,
  emit,
  getBufferedRecords,
}
