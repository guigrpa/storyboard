# This module simulates database access
{mainStory} = require '../storyboard'  # you'd write: `'storyboard'`
Promise = require 'bluebird'
chalk = require 'chalk'

_items = []

init = ->
  mainStory.info 'db', "Initialising database..."
  _items = _items.concat ['Unicorn', 'Cow', 'Hummingbird']

getItems = (options = {}) -> 
  {story = mainStory} = options
  story.debug 'db', "Retrieving items..."
  Promise.delay 2500
  .then -> 
    story.debug 'db', "Items found: #{chalk.cyan _items.length}"
    return _items

module.exports = {
  init,
  getItems,
}
