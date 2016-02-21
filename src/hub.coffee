_listeners = []

addListener = (listener) -> _listeners.push listener
emit = (record) ->
  for listener in _listeners
    listener.process record

module.exports = {
  addListener,
  emit,
}