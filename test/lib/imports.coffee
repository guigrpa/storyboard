_         = require 'lodash'
Promise   = require 'bluebird'
chai      = require 'chai'
sinon     = require 'sinon'
sinonChai = require 'sinon-chai'
chai.use sinonChai
expect    = chai.expect
if process.env.TEST_MINIFIED_LIB
  console.log "Running tests on minified library"
  storyboard = require '../../dist/storyboard.min'
else
  storyboard = require '../../src/storyboard'
fProduction = (process.env.NODE_ENV is 'production') or process.env.TEST_MINIFIED_LIB

module.exports = {
  storyboard,
  _, Promise,
  expect, sinon,
  fProduction,
}
