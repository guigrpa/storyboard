console.log "[DT] Starting up..."
node = document.getElementById 'app'

# Initialise connection to background page
_tabId = chrome.devtools.inspectedWindow.tabId
_bgConnection = chrome.runtime.connect()
_bgConnection.postMessage {src: 'DT', type: 'INIT', data: {tabId: _tabId}}
_bgConnection.onMessage.addListener (msg) ->
  {src, type, data} = msg
  console.log "[DT] RX #{src}/#{type}", data
  node.innerHTML = data.msg
  return

# Pane application
node.innerHTML = 'Uninitialised'
btn = document.getElementById 'btn'
btn.addEventListener 'click', ->
  console.log "[DT] Clicked"
  _bgConnection.postMessage {src: 'DT', dst: _tabId, type: 'CLICK', data: {t: new Date()}}
