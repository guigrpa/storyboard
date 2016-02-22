console.log 'Content script running...'

#port = chrome.runtime.connect()

window.addEventListener 'message', (event) ->
  # We only accept messages from ourselves
  return if event.source isnt window
  {data: {type, subtype, data}} = event
  return if type isnt 'FROM_PAGE'
  console.log "#{type}/#{subtype} #{data.msg}"
  window.postMessage {type: 'FROM_CONTENT_SCRIPT', subtype: 'ACK'}, '*'
  #port.postMessage data.text
, false
