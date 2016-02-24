{mainStory, addListener} = require '../storyboard'
wsClient = require '../listeners/wsClient'
addListener wsClient

mainStory.info 'startup', "Server logs app starting..."

# Enable the following block to mount the developer tools 
# in the main page (for faster development)
if true
  devToolsApp = require '../chromeExtension/devToolsApp'

  # Emulate the content script for page -> devtools messages
  window.addEventListener 'message', (event) ->
    return if event.source isnt window
    {data: {src, type, data}} = event
    return if src isnt 'PAGE'
    return if type is 'CONNECT_LINK'
    devToolsApp.processMsg event.data

  # Emulate the content script for devtools -> page messages
  devToolsApp.init
    sendMsg: (msg) -> window.postMessage msg, '*'
