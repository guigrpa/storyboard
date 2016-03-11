# This module simulates database access
_ = require 'lodash'
{mainStory} = require '../storyboard'  # you'd write: `'storyboard'`
Promise = require 'bluebird'
chalk = require 'chalk'

ANIMALS = ['Cow', 'Hummingbird', 'Rhinoceros', 'Capybara', 'Igel', 'Sheep']

init = -> mainStory.info 'db', "Initialising database..."

getItems = (options = {}) -> 
  {story = mainStory} = options
  story.debug 'db', "Retrieving animals..."
  Promise.delay 1500
  .then -> 
    numAnimals = 2 + Math.floor(Math.random()*3)
    story.debug 'db', "Animals found: #{chalk.cyan numAnimals}"
    return ['Unicorn'].concat _.sampleSize(ANIMALS, numAnimals)

module.exports = {
  init,
  getItems,
}
