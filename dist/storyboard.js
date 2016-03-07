
/*
| Storyboard
| (c) Guillermo Grau Panea 2016
| License: MIT
 */

(function() {
  var chalk, config, filters, hub, k, mainStory;

  chalk = require('chalk');

  chalk.enabled = true;

  k = require('./gral/constants');

  mainStory = require('./gral/stories');

  filters = require('./gral/filters');

  hub = require('./gral/hub');

  hub.init({
    mainStory: mainStory
  });

  if (k.IS_BROWSER) {
    if (process.env.NODE_ENV !== 'production') {
      hub.addListener(require('./listeners/console'));
    }
    hub.addListener(require('./listeners/wsClient'));
  } else {
    hub.addListener(require('./listeners/console'));
  }

  config = function(options) {
    var key, val;
    if (options == null) {
      options = {};
    }
    for (key in options) {
      val = options[key];
      switch (key) {
        case 'filter':
          filters.config(val);
          break;
        case 'bufSize':
          hub.config({
            bufSize: val
          });
      }
    }
  };

  module.exports = {
    mainStory: mainStory,
    config: config,
    addListener: hub.addListener,
    getListeners: hub.getListeners,
    removeAllListeners: hub.removeAllListeners
  };

}).call(this);
