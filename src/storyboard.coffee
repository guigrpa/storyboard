###
| Storyboard
| (c) Guillermo Grau Panea 2016
| License: MIT
###
k = require './constants'

# Chalk is disabled by default in the browser. Override
# this default (we'll handle ANSI code conversion ourselves
# when needed)
chalk = require 'chalk'
chalk.enabled = true

mainStory = require './stories'
hub = require './hub'
hub.init {mainStory}

hub.addListener require './listeners/console'
if k.IS_BROWSER
  hub.addListener require './listeners/wsClient'

# Make sure a record is created for the root story
mainStory.logStory 'CREATED'

module.exports = {
  mainStory,
  addListener: hub.addListener,
  getListeners: hub.getListeners,
}