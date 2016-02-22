{mainStory, addListener, getListeners} = require '../src/storyboard'
wsServer = require '../src/listeners/wsServer'
addListener wsServer #, {authenticate: (o) -> true}

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

story = mainStory.child 'Request from 192.168.1.3'
story.info 'Authenticating...'
story.debug 'Authenticated'
story.changeStatus 'ONGOING'
story.close()

listeners = getListeners()
consoleListener = listeners[0]
if consoleListener.type isnt 'CONSOLE'
  throw new Error 'First listener was expected to be a consoleListener'
consoleListener.config relativeTime: true
story.info 'Checking relative time...'
setTimeout ->
  story.info 'Checking relative time...'
, 50
setTimeout ->
  story.info 'Checking relative time...'
  consoleListener.config relativeTime: false
, 1200
setInterval ->
  story.info new Date().toISOString()
, 2500