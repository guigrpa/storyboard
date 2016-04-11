###!
* Storyboard
* (c) Guillermo Grau Panea 2016
* License: MIT
###

# Chalk is disabled by default in the browser. Override
# this default (we'll handle ANSI code conversion ourselves
# when needed)
chalk = require 'chalk'
chalk.enabled = true

k = require './gral/constants'

mainStory = require './gral/stories'
filters = require './gral/filters'

hub = require './gral/hub'
hub.init {mainStory}

config = (options = {}) ->
  for key, val of options
    switch key
      when 'filter' then filters.config val
      when 'bufSize' then hub.config {bufSize: val}
  return

module.exports = {
  mainStory,
  config,
  chalk,
  addListener: hub.addListener,
  removeListener: hub.removeListener,
  getListeners: hub.getListeners,
  removeAllListeners: hub.removeAllListeners,
}