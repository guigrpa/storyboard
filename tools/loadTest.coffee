http = require 'http'
chalk = require 'chalk'
storyboard = require '../src/storyboard'
wsServer = require '../src/listeners/wsServer'
{mainStory} = storyboard
storyboard.config filter: '*:*'

PORT = 3000

# Initialise our server
mainStory.info 'server', 'Initialising server...'
express = require 'express'
app = express()
httpServer = http.createServer app
httpServer.listen PORT
mainStory.info 'httpServer', "Listening on port #{chalk.cyan PORT}..."

storyboard.addListener wsServer,
  httpServer: httpServer
  authenticate: ({login, password}) -> true

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
mainStory.error 'server', "Example error", attach: new Error('EXAMPLE error message')
setInterval -> 
  mainStory.debug 'server', "t: #{chalk.blue new Date().toISOString()}"
, 60000

for n in [0...1e3]
  mainStory.info 'server', "Load test: #{n}"
