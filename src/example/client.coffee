require 'babel-polyfill'    # for IE
require 'isomorphic-fetch'  # for IE
{mainStory, chalk, addListener} = require '../storyboard'  # you'd write: `'storyboard'`
addListener require('../listeners/console').default
addListener require('../listeners/browserExtension').default
addListener require('../listeners/wsClient')

mainStory.info 'client', 'Running client...'

nodeButton = document.getElementById 'refresh'
nodeItems  = document.getElementById 'items'
nodeButton.addEventListener 'click', -> _refresh 'Click on Refresh'

_refresh = (storyTitle) ->
  seq = Math.floor(Math.random() * 100)
  story = mainStory.child 
    src: 'client'
    title: storyTitle + " (seq=#{seq})"
  story.info 'serverInterface', "Fetching animals from server..."
  nodeItems.innerHTML = "Fetching..."
  fetch "/animals?seq=#{seq}",
    method: 'post'
    headers:
      'Accept': 'application/json'
      'Content-Type': 'application/json'
    body: JSON.stringify {storyId: story.storyId}
  .then (response) -> response.json()
  .then (items) ->
    if Array.isArray items
      story.info 'serverInterface', "Fetched animals from server: #{chalk.cyan.bold items.length}", attach: items
      nodeItems.innerHTML = items.map((o) -> "<li>#{o}</li>").join('')
    story.close()

_refresh 'Initial fetch'

setInterval (-> mainStory.debug "Repeated message"), 5000

# Enable the following block to mount the developer tools 
# in the main page (for faster development)
if false
  devToolsApp = require '../chromeExtension/devToolsApp'

  # Emulate the content script for page -> devtools messages
  window.addEventListener 'message', (event) ->
    return if event.source isnt window
    msg = event.data
    return if msg.src isnt 'PAGE'
    devToolsApp.processMsg msg

  # Emulate the content script for devtools -> page messages
  devToolsApp.init
    sendMsg: (msg) -> window.postMessage msg, '*'
