Promise = require 'bluebird'

{mainStory, addListener, getListeners} = require '../src/storyboard'
wsServer = require '../src/listeners/wsServer'
addListener wsServer #, {authenticate: ({login, password}) -> true}

_story = null
_consoleListener = null
Promise.delay 3000
.then ->
  mainStory.trace 'Some traces:'
  mainStory.tree 
    date: new Date()
    nested: b: {b1: 1, b2: 2}
    array: ['a', 'b', 'c']
    longArray: [{a: 1}, {a: 2}, {a: 3}]
    string: 'foo'
    "undefined": undefined
    "null": null
    bool1: true
    bool2: false
  , {level: 'TRACE'}, '  '
  mainStory.debug 'Debug line'
  mainStory.info 'Hello!'
  mainStory.warn 'A warning'
  mainStory.error 'An error'
  mainStory.info 'anotherSrc', 'Initialised'
  mainStory.info 'yetAnother', 'Initialised'

  _story = mainStory.child 'Request from 192.168.1.3'
  _story.info 'Authenticating...'
  _story.debug 'Authenticated'
  _story.changeStatus 'ONGOING'
  _story.close()

.then ->
  listeners = getListeners()
  _consoleListener = listeners[0]
  if _consoleListener.type isnt 'CONSOLE'
    throw new Error 'First listener was expected to be a consoleListener'
  _consoleListener.config relativeTime: true
  _story.info 'Checking relative time...'

.delay 50
.then -> _story.info 'Checking relative time...'
.delay 1100
.then ->
  _story.info 'Checking relative time...'
  _consoleListener.config relativeTime: false
.delay 100
.then ->
  setInterval ->
    _story.info new Date().toISOString()
  , 10000
