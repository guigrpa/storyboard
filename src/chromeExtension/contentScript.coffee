_bgConnection = null

# Connect to the actual page via DOM messaging
window.addEventListener 'message', (event) ->

  # We only accept messages from ourselves
  return if event.source isnt window

  # Extract the message contents from the event, and
  # discard messages with wrong `src`
  {data: {src, type, data}} = event
  ## console.log "[CS] RX #{src}/#{type}", data
  return if src isnt 'PAGE'

  # An `INIT` message causes a connection to be established with the background page
  if type is 'CONNECT_LINK'
    _bgConnection = chrome.runtime.connect()
    _bgConnection.postMessage {src: 'CS', type: 'CONNECT_LINK'}

    # All messages from the background page are just relayed to the actual page
    _bgConnection.onMessage.addListener (msg) -> window.postMessage msg, '*'

  # All other messages from the page are just relayed to the background page
  else
    _bgConnection?.postMessage event.data
