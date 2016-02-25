_bgConnection = null

# Connect to the actual page via DOM messaging
window.addEventListener 'message', (event) ->

  # We only accept messages from ourselves
  return if event.source isnt window

  # Extract the message contents from the event, and
  # discard messages with wrong `src`
  {data: {src, type, data}} = event
  return if src isnt 'PAGE'
  console.log "[CS] RX #{src}/#{type}", data

  # A `CONNECT_REQUEST` message causes a bidirectional connection to be established 
  # with the background page and is then relayed
  if type is 'CONNECT_REQUEST'
    _bgConnection = chrome.runtime.connect()

    # All messages from the background page are just relayed to the actual page
    _bgConnection.onMessage.addListener (msg) -> window.postMessage msg, '*'

  # All other messages from the page are just relayed to the background page
  _bgConnection?.postMessage event.data
