http = require 'http'
path = require 'path'
chalk = require 'chalk'
storyboard = require '../src/storyboard'        # you'd write: `'storyboard'`
{mainStory} = storyboard

PORT = 3000

# Initialise our server
mainStory.info 'server', 'Initialising server...'
express = require 'express'
app = express()
app.use express.static path.join(__dirname, 'public')
httpServer = http.createServer app
httpServer.listen PORT
mainStory.info 'server', "Listening on port #{chalk.cyan PORT}..."

# Configure storyboard. the console listener comes pre-installed;
# we add remote access to server logs via WebSockets (but ask for credentials)
wsServer = require '../src/listeners/wsServer'  # you'd write: `'storyboard/listeners/wsServer'`
storyboard.addListener wsServer,
  httpServer: httpServer
  authenticate: ({login, password}) -> true

# Some example logs
mainStory.debug 'server', "Server info (example):"
someInfo = 
  appName: 'Storyboard example'
  upSince: new Date()
  loginRequiredForLogs: true
  nested: configOptions: 
    foo: undefined
    bar: null
    values: [1, 2]
someInfo.nested.configOptions.mainInfo = someInfo
mainStory.tree 'server', someInfo, {level: 'TRACE'}, '  '

# Initialise our database
db = require './db'
db.init()

setInterval -> 
  mainStory.debug 'server', "t: #{chalk.blue new Date().toISOString()}"
, 10000
