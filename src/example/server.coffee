http = require 'http'
path = require 'path'
chalk = require 'chalk'
bodyParser = require 'body-parser'
storyboard = require '../storyboard'        # you'd write: `'storyboard'`
wsServer = require '../listeners/wsServer'  # you'd write: `'storyboard/listeners/wsServer'`
{mainStory} = storyboard
storyboard.config filter: '*:*'

PORT = 3000

# Initialise our server
mainStory.info 'server', 'Initialising server...'
express = require 'express'
app = express()
app.use bodyParser.json()
app.use bodyParser.urlencoded {extended: true}
app.use express.static path.join(process.cwd(), 'example')
app.post '/items', (req, res, next) ->
  {storyId} = req.body
  if storyId? then extraParents = [storyId]
  story = mainStory.child {src: 'server', title: "HTTP request #{chalk.green req.url}", extraParents}
  db.getItems {story}
  .then (result) -> 
    story.debug 'server', "HTTP response: #{result.length} items", attachInline: result
    res.json result
    story.close()
httpServer = http.createServer app
httpServer.listen PORT
mainStory.info 'server', "Listening on port #{chalk.cyan PORT}..."

# Apart from the pre-installed console listener, 
# add remote access to server logs via WebSockets 
# (but ask for credentials)
storyboard.addListener wsServer,
  httpServer: httpServer
  authenticate: ({login, password}) -> true

# Initialise our fake database
db = require './db'
db.init()

# Some example logs (including a circular reference)
someInfo = 
  appName: 'Storyboard example'
  upSince: new Date()
  dontShow: 'hidden'
  loginRequiredForLogs: true
  nested: configOptions: 
    foo: undefined
    bar: null
    values: [1, 2]
someInfo.nested.configOptions.mainInfo = someInfo
mainStory.debug 'server', "Example info (expanded):", 
  attach: someInfo
  attachLevel: 'TRACE'
  ignoreKeys: ['dontShow']
mainStory.warn 'server', "Example warning"
mainStory.error 'server', "Example error", attach: new Error('Error message')
setInterval -> 
  mainStory.debug 'server', "t: #{chalk.blue new Date().toISOString()}"
, 60000
