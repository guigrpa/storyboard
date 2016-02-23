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
    if type is 'INIT'
      tabId = switch src
        when 'DT' then data.tabId
        when 'CS' then port.sender.tab.id
      if not tabId?
        console.error "[BG] Could not determine the tab ID associated to the connection"
        return
      _connections[tabId] ?= {}
      _connections[tabId][src] = port
      _logConnections()
    else
      switch src
        when 'PAGE' then _connections[port.sender.tab.id]?.DT?.postMessage msg
        when 'DT'   then _connections[dst]?.CS?.postMessage msg

  port.onMessage.addListener listener
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

# Messages from content script
chrome.runtime.onMessage.addListener (msg, sender, sendResponse) ->
  {src, dst, type, data} = msg
  console.log "[BG] OTHER LISTENER RX #{src}/#{type}", data
  ###
  return if src isnt 'PAGE'
  tab = sender.tab
  if not tab?
    console.error "[BG] Sender tab not defined"
    return
  connection = _connections[tab.id]
  if not connection
    console.error "[BG] Sender tab ID not defined"
    return
  _connections[sender.tab.id]?.postMessage msg
  ###
