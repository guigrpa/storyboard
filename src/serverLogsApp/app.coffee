{mainStory, addListener} = require '../storyboard'
wsClient = require '../listeners/wsClient'
addListener wsClient

mainStory.info 'startup', "Server logs app starting..."
