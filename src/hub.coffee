_listeners = []

addListener = (listener) -> _listeners.push listener
getListeners = -> _listeners
emit = (record) ->
  for listener in _listeners
    listener.process record

module.exports = {
  addListener, getListeners,
  emit,
}