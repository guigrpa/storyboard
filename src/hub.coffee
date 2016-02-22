_listeners = []
mainStory = null

init = (deps) ->
  {mainStory} = deps
  if not(mainStory?)
    throw new Error 'MISSING_DEPENDENCIES'

addListener = (listenerFactory, options) -> 
  listener = listenerFactory.create mainStory, options
  _listeners.push listener
  listener.init?()
getListeners = -> _listeners
emit = (record) ->
  for listener in _listeners
    listener.process record

module.exports = {
  init,
  addListener, getListeners,
  emit,
}