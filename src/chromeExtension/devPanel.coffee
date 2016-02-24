timm = require 'timm'
devToolsApp = require './devToolsApp'

# Initialise connection to background page. All incoming
# messages are relayed to the devtools application
_tabId = chrome.devtools.inspectedWindow.tabId
_bgConnection = chrome.runtime.connect()
_bgConnection.postMessage {src: 'DT', type: 'CONNECT_LINK', data: {tabId: _tabId}}
_bgConnection.onMessage.addListener devToolsApp.processMsg

# Initialise application
devToolsApp.init 
  sendMsg: (msg) -> _bgConnection.postMessage timm.merge(msg, {dst: _tabId})
