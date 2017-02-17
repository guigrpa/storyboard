chai      = require 'chai'
sinon     = require 'sinon'
sinonChai = require 'sinon-chai'
chai.use sinonChai
expect    = chai.expect

module.exports = {
  expect, sinon,
}
