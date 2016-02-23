console.log 'Content script running...'

#port = chrome.runtime.connect()

window.addEventListener 'message', (event) ->
  # We only accept messages from ourselves
  return if event.source isnt window
  {data: {src, type, data}} = event
  return if src is 'CS'
  console.log "[CS] #{src}/#{type}", data
  ## window.postMessage {src: 'CS', type: 'ACK'}, '*'
  #port.postMessage data.text
, false
