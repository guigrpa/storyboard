module.exports = {
  mainStory: {
    info: function(){console.log.apply(console, arguments)},
    warn: function(){console.log.apply(console, arguments)},
    debug: function(){console.log.apply(console, arguments)},
    error: function(){console.log.apply(console, arguments)},
    trace: function(){console.log.apply(console, arguments)},
    close: function(){},
    child: function(){return module.exports.mainStory;},
  },
  addListener: function(){}
}