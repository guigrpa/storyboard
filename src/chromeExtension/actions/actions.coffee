_               = require 'lodash'
actionGroups = [
  require './settingsActions'
  require './storyActions'
]

actions = {}
for actionGroup in actionGroups
  _.extend actions, (actionGroup.actions ? {})

module.exports = actions
