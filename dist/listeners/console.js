(function() {
  var DEFAULT_CONFIG, _, _console, _getBrowserConsoleArgs, _getTimeStr, _outputLog, _prevTime, _process, _setConsole, ansiColors, chalk, create, filters, k, timm, treeLines;

  _ = require('../vendor/lodash');

  timm = require('timm');

  chalk = require('chalk');

  k = require('../gral/constants');

  ansiColors = require('../gral/ansiColors');

  treeLines = require('../gral/treeLines');

  filters = require('../gral/filters');

  DEFAULT_CONFIG = {
    moduleNameLength: 20,
    relativeTime: k.IS_BROWSER,
    minLevel: 10
  };

  _console = console;

  _setConsole = function(o) {
    return _console = o;
  };

  _getBrowserConsoleArgs = function(str) {
    return ansiColors.getBrowserConsoleArgs(str);
  };

  _prevTime = 0;

  _getTimeStr = function(record, config) {
    var dif, extraTimeStr, newTime, timeStr;
    timeStr = '';
    extraTimeStr = void 0;
    if (config.relativeTime) {
      newTime = new Date(record.t);
      dif = _prevTime ? (newTime - _prevTime) / 1000 : 0;
      _prevTime = newTime;
      timeStr = dif < 1 ? dif.toFixed(3) : dif.toFixed(1);
      timeStr = _.padStart(timeStr, 7);
      if (dif > 1) {
        extraTimeStr = '    ...';
      }
      if (dif < 0.010) {
        timeStr = '       ';
      }
    } else {
      timeStr = new Date(record.t).toISOString();
    }
    return [timeStr, extraTimeStr];
  };

  _process = function(record, config) {
    var actionStr, e, error, extraTimeStr, fStory, finalMsg, i, len, level, levelStr, line, lines, msgStr, obj, objExpanded, objLevel, objOptions, objStr, ref, src, srcStr, storyId, storyIdStr, text, timeStr, treeOptions;
    src = record.src, storyId = record.storyId, level = record.level, fStory = record.fStory, obj = record.obj, objExpanded = record.objExpanded, objLevel = record.objLevel, objOptions = record.objOptions;
    ref = _getTimeStr(record, config), timeStr = ref[0], extraTimeStr = ref[1];
    if (fStory) {
      msgStr = record.title;
      levelStr = '----- ';
      storyIdStr = (storyId.slice(0, 8)) + " - ";
      actionStr = " [" + record.action + "]";
    } else {
      msgStr = record.msg;
      levelStr = ansiColors.LEVEL_NUM_TO_COLORED_STR[level];
      storyIdStr = '';
      actionStr = '';
    }
    srcStr = ansiColors.getSrcChalkColor(src)(_.padStart(src, config.moduleNameLength));
    objStr = '';
    if ((obj != null) && !objExpanded) {
      try {
        objStr = chalk.yellow(" -- " + (JSON.stringify(obj)));
      } catch (error) {
        e = error;
        objStr = chalk.red(" -- [could not stringify object, expanding...]");
        objExpanded = true;
      }
    }
    if (level >= k.LEVEL_STR_TO_NUM.ERROR) {
      msgStr = chalk.red.bold(msgStr);
    } else if (level >= k.LEVEL_STR_TO_NUM.WARN) {
      msgStr = chalk.red.yellow(msgStr);
    }
    finalMsg = timeStr + " " + srcStr + " " + levelStr + storyIdStr + msgStr + actionStr + objStr;
    if (fStory) {
      finalMsg = chalk.bold(finalMsg);
    }
    _outputLog(finalMsg, record.level, extraTimeStr);
    if (objExpanded && filters.passesFilter(src, objLevel)) {
      treeOptions = timm.merge({
        prefix: '  '
      }, objOptions);
      lines = treeLines(obj, treeOptions);
      levelStr = ansiColors.LEVEL_NUM_TO_COLORED_STR[objLevel];
      for (i = 0, len = lines.length; i < len; i++) {
        line = lines[i];
        text = timeStr + " " + srcStr + " " + levelStr + line;
        _outputLog(text);
      }
    }
  };

  _outputLog = function(text, level, extraTimeStr) {
    var args, output;
    if (k.IS_BROWSER) {
      args = _getBrowserConsoleArgs(text);
    } else {
      args = [text];
    }
    if (extraTimeStr != null) {
      _console.log("      " + extraTimeStr);
    }
    output = (level != null) && level >= 50 ? 'error' : 'log';
    return _console[output].apply(_console, args);
  };

  create = function(baseConfig) {
    var config, listener;
    config = timm.addDefaults(baseConfig, DEFAULT_CONFIG);
    listener = {
      type: 'CONSOLE',
      init: function() {},
      process: function(record) {
        return _process(record, config);
      },
      config: function(newConfig) {
        return config = timm.merge(config, newConfig);
      }
    };
    return listener;
  };

  module.exports = {
    create: create,
    _setConsole: _setConsole
  };

}).call(this);
