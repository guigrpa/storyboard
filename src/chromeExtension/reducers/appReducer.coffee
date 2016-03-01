Redux = require 'redux'
cx = require './cxReducer'
stories = require './storyReducer'
settings = require './settingsReducer'

module.exports = Redux.combineReducers {cx, stories, settings}
