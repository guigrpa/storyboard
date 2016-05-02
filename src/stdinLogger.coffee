split = require 'split'
{mainStory} = require './storyboard'

process.stdin.pipe split()
  .on 'data', (line) -> mainStory.info line
  .on 'end', -> process.exit(0)
