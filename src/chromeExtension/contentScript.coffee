console.log 'Content script running...'

_bgConnection = null
window.addEventListener 'message', (event) ->
  # We only accept messages from ourselves
  return if event.source isnt window
  {data: {src, type, data}} = event
  console.log "[CS] RX #{src}/#{type}", data
  if src is 'PAGE' 
    # An `INIT` message is used to establish a connection with the background page
    if type is 'INIT'
      _bgConnection = chrome.runtime.connect()
      _bgConnection.postMessage {src: 'CS', type: 'INIT'}
      _bgConnection.onMessage.addListener (msg) -> window.postMessage msg, '*'
    else
      _bgConnection?.postMessage event.data
, false
