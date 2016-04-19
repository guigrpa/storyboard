module.exports = require './noPlugins'
k = require './gral/constants'
hub = require './gral/hub'

# Browser side: in production, nothing. 
# In development, everything, including wsClient
if k.IS_BROWSER
  if process.env.NODE_ENV isnt 'production'
    hub.addListener require './listeners/console'
    hub.addListener require './listeners/browserExtension'
    hub.addListener require './listeners/wsClient'

# Server side: console listener
else
  hub.addListener require './listeners/console'
