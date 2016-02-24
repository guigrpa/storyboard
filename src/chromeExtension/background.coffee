# Connections hub. Each key corresponds is a tab ID, and the associated value
# is an object with (eventually) `DT` (devtools) and `CS` (content-script) keys,
# each of them holding the corresponding connection.
_connections = {}

console.log "[BG] Launching..."

_logConnections = ->
  console.log "[BG] Current connections:"
  for tabId, connections of _connections
    console.log "- #{tabId}: " +
      "DT: #{if connections.DT? then 'YES' else 'NO'}, " +
      "CS: #{if connections.CS? then 'YES' else 'NO'}"

chrome.runtime.onConnect.addListener (port) ->
  console.log "[BG] Connected: #{port.sender.url} [tabId: #{port.sender.tab?.id}]"
  listener = (msg) ->
    {src, dst, type, data} = msg
    console.log "[BG] RX #{src}/#{type}", data

    # Connection initialisation
    if type is 'CONNECT_LINK'
      tabId = switch src
        when 'DT' then data.tabId
        when 'CS' then port.sender.tab.id
      if not tabId?
        console.error "[BG] Could not determine the tab ID associated to the connection"
        return
      _connections[tabId] ?= {}
      _connections[tabId][src] = port
      _logConnections()

    # Message relays: `PAGE` <-> `DT`
    else
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
          if (not _connections[tabId].DT?) and (not _connections[tabId].CS?)
            delete _connections[tabId]
          break

    _logConnections()
    return
