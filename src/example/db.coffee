# This module simulates database access
{mainStory} = require '../storyboard'  # you'd write: `'storyboard'`
Promise = require 'bluebird'
chalk = require 'chalk'

LOG_MODULE = 'db'

_items = []

init = ->
  mainStory.info LOG_MODULE, "Initialising database..."
  _items = _items.concat ['Unicorn', 'Cow', 'Hummingbird']

getItems = (options = {}) -> 
  {story = mainStory} = options
  story.debug LOG_MODULE, "Retrieving items..."
  Promise.delay 2500
  .then -> 
    story.debug LOG_MODULE, "Items found: #{chalk.cyan _items.length}"
    return _items

module.exports = {
  init,
  getItems,
}
