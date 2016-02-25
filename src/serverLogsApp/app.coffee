chalk = require 'chalk'
{mainStory} = require '../storyboard'

mainStory.info 'startup', "Server logs app #{chalk.green.bold 'starting up'}..."

# Enable the following block to mount the developer tools 
# in the main page (for faster development)
if true
  devToolsApp = require '../chromeExtension/devToolsApp'

  # Emulate the content script for page -> devtools messages
  window.addEventListener 'message', (event) ->
    return if event.source isnt window
    {data: {src, type, data}} = event
    return if src isnt 'PAGE'
    devToolsApp.processMsg event.data

  # Emulate the content script for devtools -> page messages
  devToolsApp.init
    sendMsg: (msg) -> window.postMessage msg, '*'
