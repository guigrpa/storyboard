###
| Storyboard
| (c) Guillermo Grau Panea 2016
| License: MIT
###
k = require './constants'

# Enable chalk colors in the browser (we'll handle the conversion)
if k.IS_BROWSER
  process.env.COLORTERM = true

hub = require './hub'
stories = require './stories'
consoleListener = require './listeners/console'

mainStory = stories.createStory []
hub.init {mainStory}
hub.addListener consoleListener

# Make sure a record is created
mainStory.changeTitle 'ROOT STORY'

module.exports = {
  mainStory,
  addListener: hub.addListener,
  getListeners: hub.getListeners,
}