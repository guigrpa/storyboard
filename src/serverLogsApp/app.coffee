{mainStory, addListener} = require '../storyboard'
wsClient = require '../listeners/wsClient'

mainStory.info 'startup', "Server logs app starting..."
addListener wsClient
