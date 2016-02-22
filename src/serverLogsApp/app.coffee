{mainStory, addListener} = require '../storyboard'
wsClient = require '../listeners/wsClient'

mainStory.info 'startup', "Server logs app starting..."
mainStory.tree 'startup', {a: true, b: 4, c: new Date(), d: null, e: undefined}
addListener wsClient
