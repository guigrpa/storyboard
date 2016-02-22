###
| Storyboard
| (c) Guillermo Grau Panea 2016
| License: MIT
###
hub = require './hub'
logger = require './logger'
consoleListener = require './consoleListener'

mainStory = logger.createStory []
hub.addListener consoleListener.create()

module.exports = {
  mainStory,
  addListener: hub.addListener,
  getListeners: hub.getListeners,
}