(function() {
  var ANSI_ADD, ANSI_ADD_BGCOLOR, ANSI_ADD_COLOR, ANSI_REGEX, ANSI_REMOVE, BASE_COLORS, COLORS, CSS_COLORS, CSS_STYLES, LEVEL_NUM_TO_COLORED_STR, NUM_COLORS, REACT_STYLES, _, _srcCnt, _srcColorCache, _toConsoleArgs, _toSegmentStyle, _updateStyles, chalk, getBrowserConsoleArgs, getSrcChalkColor, getStyledSegments, k;

  _ = require('../vendor/lodash');

  chalk = require('chalk');

  chalk.enabled = true;

  k = require('./constants');

  LEVEL_NUM_TO_COLORED_STR = {};

  _.each(k.LEVEL_NUM_TO_STR, function(str, num) {
    var col;
    num = Number(num);
    col = chalk.grey;
    if (num === 30) {
      col = k.IS_BROWSER ? chalk.bold : chalk.white;
    } else if (num === 40) {
      col = chalk.yellow;
    } else if (num >= 50) {
      col = chalk.red;
    }
    return LEVEL_NUM_TO_COLORED_STR[num] = col(_.padEnd(str, 6));
  });

  COLORS = [];

  BASE_COLORS = ['cyan', 'yellow', 'red', 'green', 'blue', 'magenta'];

  _.each(BASE_COLORS, function(col) {
    return COLORS.push(chalk[col].bold);
  });

  _.each(BASE_COLORS, function(col) {
    return COLORS.push(chalk[col]);
  });

  NUM_COLORS = COLORS.length;

  _srcColorCache = {};

  _srcCnt = 0;

  getSrcChalkColor = function(src) {
    if (_srcColorCache[src] == null) {
      _srcColorCache[src] = COLORS[_srcCnt++ % NUM_COLORS];
    }
    return _srcColorCache[src];
  };

  ANSI_REGEX = /(?:(?:\u001b\[)|\u009b)(?:(?:[0-9]{1,3})?(?:(?:;[0-9]{0,3})*)?[A-M|f-m])|\u001b[A-M]/g;

  ANSI_ADD = {
    1: 'BOLD',
    2: 'DIM',
    3: 'ITALIC',
    4: 'UNDERLINE',
    7: 'INVERSE',
    8: 'HIDDEN',
    9: 'STRIKETHROUGH'
  };

  ANSI_ADD_COLOR = {
    30: 'BLACK',
    31: 'RED',
    32: 'GREEN',
    33: 'YELLOW',
    34: 'BLUE',
    94: 'BLUE',
    35: 'MAGENTA',
    36: 'CYAN',
    37: 'WHITE',
    90: 'GREY'
  };

  ANSI_ADD_BGCOLOR = {
    40: 'BLACK',
    41: 'RED',
    42: 'GREEN',
    43: 'YELLOW',
    44: 'BLUE',
    45: 'MAGENTA',
    46: 'CYAN',
    47: 'WHITE'
  };

  ANSI_REMOVE = {
    21: ['BOLD'],
    22: ['BOLD', 'DIM'],
    23: ['ITALIC'],
    24: ['UNDERLINE'],
    27: ['INVERSE'],
    28: ['HIDDEN'],
    29: ['STRIKETHROUGH']
  };

  CSS_COLORS = {
    BLACK: 'black',
    RED: 'red',
    GREEN: 'green',
    YELLOW: 'orange',
    BLUE: 'blue',
    MAGENTA: 'magenta',
    CYAN: 'darkturquoise',
    WHITE: 'lightgrey',
    GREY: 'grey'
  };

  CSS_STYLES = {
    BOLD: 'font-weight: bold',
    DIM: 'opacity: 0.8',
    ITALIC: 'font-style: italic',
    UNDERLINE: 'text-decoration: underline',
    INVERSE: '',
    HIDDEN: 'display: none',
    STRIKETHROUGH: 'text-decoration: line-through'
  };

  REACT_STYLES = {
    BOLD: {
      fontWeight: 'bold'
    },
    DIM: {
      opacity: 0.8
    },
    ITALIC: {
      fontStyle: 'italic'
    },
    UNDERLINE: {
      textDecoration: 'underline'
    },
    INVERSE: {},
    HIDDEN: {
      display: 'none'
    },
    STRIKETHROUGH: {
      textDecoration: 'line-through'
    }
  };

  getBrowserConsoleArgs = function(str) {
    var argArray, curStyles, outStr, regex, res;
    outStr = str.replace(ANSI_REGEX, '%c');
    argArray = [outStr];
    curStyles = {};
    regex = /\u001b\[(\d+)*m/gi;
    while ((res = regex.exec(str))) {
      curStyles = _updateStyles(curStyles, Number(res[1]));
      argArray.push(_toConsoleArgs(curStyles));
    }
    return argArray;
  };

  getStyledSegments = function(str) {
    var curStyles, i, idx, out, ref, text, tokens;
    out = [];
    if (!_.isString(str)) {
      return out;
    }
    tokens = str.split(/\u001b\[(\d+)*m/gi);
    curStyles = {};
    text = tokens[0];
    if (text.length) {
      out.push({
        text: text,
        style: {}
      });
    }
    for (idx = i = 1, ref = tokens.length; i < ref; idx = i += 2) {
      curStyles = _updateStyles(curStyles, Number(tokens[idx]));
      text = tokens[idx + 1];
      if (!text.length) {
        continue;
      }
      out.push({
        text: text,
        style: _toSegmentStyle(curStyles)
      });
    }
    return out;
  };

  _updateStyles = function(curStyles, code) {
    var bgColor, color, i, len, removeStyles, style;
    if ((style = ANSI_ADD[code])) {
      curStyles[style] = true;
    } else if ((color = ANSI_ADD_COLOR[code])) {
      curStyles.color = color;
    } else if ((bgColor = ANSI_ADD_BGCOLOR[code])) {
      curStyles.bgColor = bgColor;
    } else if (code === 39) {
      curStyles.color = void 0;
    } else if (code === 49) {
      curStyles.bgColor = void 0;
    } else if ((removeStyles = ANSI_REMOVE[code])) {
      for (i = 0, len = removeStyles.length; i < len; i++) {
        style = removeStyles[i];
        curStyles[style] = void 0;
      }
    } else {

      /* istanbul ignore else */
      if (code === 0) {
        curStyles = {};
      }
    }
    return curStyles;
  };

  _toConsoleArgs = function(styles) {
    var key, out, val;
    out = [];
    for (key in styles) {
      val = styles[key];
      if (val == null) {
        continue;
      }
      switch (key) {
        case 'color':
          out.push("color: " + CSS_COLORS[val]);
          break;
        case 'bgColor':
          out.push("color: white; background-color: " + CSS_COLORS[val]);
          break;
        default:
          out.push(CSS_STYLES[key]);
      }
    }
    return out.join(';');
  };

  _toSegmentStyle = function(styles) {
    var key, out, val;
    out = {};
    for (key in styles) {
      val = styles[key];
      if (val == null) {
        continue;
      }
      switch (key) {
        case 'color':
          out.color = CSS_COLORS[val];
          break;
        case 'bgColor':
          out.color = 'white';
          out.backgroundColor = CSS_COLORS[val];
          break;
        default:
          _.extend(out, REACT_STYLES[key]);
      }
    }
    return out;
  };

  module.exports = {
    LEVEL_NUM_TO_COLORED_STR: LEVEL_NUM_TO_COLORED_STR,
    getSrcChalkColor: getSrcChalkColor,
    getBrowserConsoleArgs: getBrowserConsoleArgs,
    getStyledSegments: getStyledSegments
  };

}).call(this);
