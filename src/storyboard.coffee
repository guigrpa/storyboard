###
| Storyboard
| (c) Guillermo Grau Panea 2016
| License: MIT
###

# Chalk is disabled by default in the browser. Override
# this default (we'll handle ANSI code conversion ourselves
# when needed)
chalk = require 'chalk'
chalk.enabled = true

k = require './gral/constants'

mainStory = require './gral/stories'

hub = require './gral/hub'
hub.init {mainStory}
if k.IS_BROWSER
  if process.env.NODE_ENV isnt 'production'
    hub.addListener require './listeners/console'
  hub.addListener require './listeners/wsClient'
else
  hub.addListener require './listeners/console'

module.exports = {
  mainStory,
  addListener: hub.addListener,
  getListeners: hub.getListeners,
}