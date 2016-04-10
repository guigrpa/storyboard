_window = undefined
if not process.env.TEST_BROWSER
  try
    _window = window
_listeners = []
_fExtensionReady = false

#-------------------------------------------------
# ## Main
#-------------------------------------------------
tx = (msg) -> _txMsg msg
rx = (listener) -> _listeners.push listener

#-------------------------------------------------
# ## Internal
#-------------------------------------------------
_init = ->
  return if not _window?
  _window.addEventListener 'message', (event) ->
    {source, data: msg} = event
    return if source isnt _window
    _rxMsg msg
  _txMsg {type: 'CONNECT_REQUEST'}

_rxMsg = (msg) ->
  {src, type, data} = msg
  return if src isnt 'DT'
  ## console.log "[PG] RX #{src}/#{type}", data

  if (type is 'CONNECT_REQUEST') or 
     (type is 'CONNECT_RESPONSE')
    _fExtensionReady = true
    if type is 'CONNECT_REQUEST' 
      _txMsg {type: 'CONNECT_RESPONSE'}
    _txPendingMsgs()

  for listener in _listeners
    listener {type, data}
  return

_msgQueue = []
_txMsg = (msg) ->
  msg.src = 'PAGE'
  if _fExtensionReady or (msg.type is 'CONNECT_REQUEST')
    _doTxMsg msg
  else
    _msgQueue.push msg
_txPendingMsgs = ->
  return if not _fExtensionReady
  _doTxMsg msg for msg in _msgQueue
  _msgQueue.length = 0
_doTxMsg = (msg) -> _window?.postMessage msg, '*'


#-------------------------------------------------
# ## Public API
#-------------------------------------------------
# May do nothing (browser tests). In this case, `setWindow`
# will really do the initialisation
_init()

module.exports = {
  tx,
  rx,

  # Just for unit testing
  _setWindow: (w) -> _window = w; _init()
}
