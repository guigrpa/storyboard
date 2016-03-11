# Connections hub. Each key corresponds is a tab ID, and the associated value
# is an object with (eventually) `DT` (devtools) and `CS` (content-script) keys,
# each of them holding the corresponding connection.
_connections = {}

console.log "[BG] Launched"

_logConnections = ->
  title = "[BG] Current connections:"
  title += ' none' if not Object.keys(_connections).length
  console.log title
  for tabId, connections of _connections
    console.log "- #{tabId}: " +
      "DevTools (DT): #{if connections.DT? then 'YES' else 'NO'}, " +
      "content script (YES): #{if connections.CS? then 'YES' else 'NO'}"
  return

chrome.runtime.onConnect.addListener (port) ->
  console.log "[BG] Connected: #{port.sender.url} [tabId: #{port.sender.tab?.id}]"
  listener = (msg) ->
    {src, dst, type, data} = msg
    if process.env.NODE_ENV isnt 'production'
      console.log "[BG] RX #{src}/#{type}", data

    # Connection initialisation
    if type is 'CONNECT_REQUEST'
      tabId = switch src
        when 'DT' then dst
        when 'PAGE' then port.sender.tab.id
      if not tabId?
        console.error "[BG] Could not determine the tab ID associated to the connection"
        return
      _connections[tabId] ?= {}
      cxType = if src is 'PAGE' then 'CS' else 'DT'
      _connections[tabId][cxType] = port
      _logConnections()

    # Message relays: `PAGE` <-> `DT`
    switch src
      when 'PAGE' then _connections[port.sender.tab.id]?.DT?.postMessage msg
      when 'DT'   then _connections[dst]?.CS?.postMessage msg

  port.onMessage.addListener listener

  # Clean up when connections are closed
  port.onDisconnect.addListener ->
    port.onMessage.removeListener listener
    for tabId, connections of _connections
      for cxType, connection of connections
        if connection is port
          delete _connections[tabId][cxType]

          # Tell the DT for a given page that the user went away
          if _connections[tabId].DT?
            _connections[tabId].DT.postMessage
              src: 'PAGE'
              type: 'CX_DISCONNECTED'

          # Purge entry in `_connections`, if needed
          if (not _connections[tabId].DT?) and (not _connections[tabId].CS?)
            delete _connections[tabId]
          break

    _logConnections()
    return

_logConnections()
