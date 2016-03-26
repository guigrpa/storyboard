_         = require 'lodash'
Promise   = require 'bluebird'
chai      = require 'chai'
sinon     = require 'sinon'
sinonChai = require 'sinon-chai'
chai.use sinonChai
expect    = chai.expect
h           = require '../helpers'
fProduction = process.env.NODE_ENV is 'production'

module.exports = {
  _, Promise,
  expect, sinon,
  h,
  fProduction,
}
