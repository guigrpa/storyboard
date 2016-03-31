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

mainStory = require 'storyboard-core/lib/stories'
filters = require 'storyboard-core/lib/filters'

hub = require 'storyboard-core/lib/hub'
hub.init {mainStory}

if k.IS_BROWSER
  if process.env.NODE_ENV isnt 'production'
    hub.addListener require './listeners/console'
  if not process.env.TEST_BROWSER
    hub.addListener require './listeners/wsClient'
else
  hub.addListener require './listeners/console'

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