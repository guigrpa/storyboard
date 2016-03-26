Promise = require 'bluebird'

# From: https://www.promisejs.org/generators/
async = (makeGenerator) ->
  ->
    generator = makeGenerator arguments...
    handle = (result) ->
      # result => { done: [Boolean], value: [Object] }
      if result.done then return Promise.resolve result.value
      p = Promise.resolve result.value
      .then ((res) -> handle generator.next res), \
        ((err) -> handle generator.throw err)
      p
    try 
      return handle generator.next()
    catch ex
      return Promise.reject ex

waitUntil = async (timeout, fn) ->
  t0 = new Date().getTime()
  while true
    t1 = new Date().getTime()
    if t1 - t0 > timeout
      console.log 'Timeout!'
      throw new Error "Timeout"
    if fn() then return true
    yield Promise.delay 20

module.exports = {
  waitUntil,
}