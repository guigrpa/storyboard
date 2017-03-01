import { merge } from 'timm';
import chalk from 'chalk';
import * as _ from '../vendor/lodash';
import * as k from './constants';

// We must ensure that `chalk` is enabled already; otherwise,
// all of the following constant definitions will be monochrome
chalk.enabled = true;

// -------------------------------------------------
// Map severity level to a colored string
// -------------------------------------------------
const LEVEL_NUM_TO_COLORED_STR = {};

Object.keys(k.LEVEL_NUM_TO_STR).forEach((key) => {
  const num = Number(key);
  const str = k.LEVEL_NUM_TO_STR[key];
  let col = chalk.grey;
  if (num === 30) {
    col = k.IS_BROWSER ? chalk.bold : chalk.white;
  } else if (num === 40) {
    col = chalk.yellow;
  } else if (num >= 50) {
    col = chalk.red;
  }
  LEVEL_NUM_TO_COLORED_STR[num] = col(_.padEnd(str, 6));
});

// -------------------------------------------------
// Get a color for a given src (cached)
// -------------------------------------------------
const COLORS = [];
const BASE_COLORS = ['cyan', 'yellow', 'red', 'green', 'blue', 'magenta'];
BASE_COLORS.forEach((col) => { COLORS.push(chalk[col].bold); });
BASE_COLORS.forEach((col) => { COLORS.push(chalk[col]); });
const NUM_COLORS = COLORS.length;

const srcColorCache = {};
let _srcCnt = 0;

/* eslint-disable no-plusplus */
const getSrcChalkColor = (src) => {
  if (srcColorCache[src] == null) {
    srcColorCache[src] = COLORS[_srcCnt++ % NUM_COLORS];
  }
  return srcColorCache[src];
};
/* eslint-enable no-plusplus */

// -------------------------------------------------
// Convert ANSI codes to console args and styled segments
// -------------------------------------------------
/* eslint-disable max-len */
const ANSI_REGEX = /(?:(?:\u001b\[)|\u009b)(?:(?:[0-9]{1,3})?(?:(?:;[0-9]{0,3})*)?[A-M|f-m])|\u001b[A-M]/g;
/* eslint-enable max-len */
const ANSI_ADD = {
  1: 'BOLD',
  2: 'DIM',
  3: 'ITALIC',
  4: 'UNDERLINE',
  7: 'INVERSE',
  8: 'HIDDEN',
  9: 'STRIKETHROUGH',
};
const ANSI_ADD_COLOR = {
  30: 'BLACK',
  31: 'RED',
  32: 'GREEN',
  33: 'YELLOW',
  34: 'BLUE',
  94: 'BLUE',
  35: 'MAGENTA',
  36: 'CYAN',
  37: 'WHITE',
  90: 'GREY',
};
const ANSI_ADD_BGCOLOR = {
  40: 'BLACK',
  41: 'RED',
  42: 'GREEN',
  43: 'YELLOW',
  44: 'BLUE',
  45: 'MAGENTA',
  46: 'CYAN',
  47: 'WHITE',
};
const ANSI_REMOVE = {
  // 0, 39, 49: handled manually
  21: ['BOLD'],
  22: ['BOLD', 'DIM'],
  23: ['ITALIC'],
  24: ['UNDERLINE'],
  27: ['INVERSE'],
  28: ['HIDDEN'],
  29: ['STRIKETHROUGH'],
};
const CSS_COLORS = {
  BLACK: 'black',
  RED: '#cc0000',
  GREEN: 'green',
  YELLOW: '#ff6600',
  BLUE: 'blue',
  MAGENTA: 'magenta',
  CYAN: 'darkturquoise',
  WHITE: 'lightgrey',
  GREY: 'grey',
};
const CSS_STYLES = {
  BOLD: 'font-weight: bold',
  DIM: 'opacity: 0.8',
  ITALIC: 'font-style: italic',
  UNDERLINE: 'text-decoration: underline',
  INVERSE: '',
  HIDDEN: 'display: none',
  STRIKETHROUGH: 'text-decoration: line-through',
};
const REACT_STYLES = {
  BOLD: { fontWeight: 'bold' },
  DIM: { opacity: 0.8 },
  ITALIC: { fontStyle: 'italic' },
  UNDERLINE: { textDecoration: 'underline' },
  INVERSE: {},
  HIDDEN: { display: 'none' },
  STRIKETHROUGH: { textDecoration: 'line-through' },
};

const getBrowserConsoleArgs = (str) => {
  const outStr = str.replace(ANSI_REGEX, '%c');
  const argArray = [outStr];
  let curStyles = {};
  const regex = /\u001b\[(\d+)*m/gi;
  let res;
  while ((res = regex.exec(str))) {
    curStyles = updateStyles(curStyles, Number(res[1]));
    argArray.push(toConsoleArgs(curStyles));
  }
  return argArray;
};

const getStyledSegments = (str) => {
  const out = [];
  if (!_.isString(str)) return out;
  const tokens = str.split(/\u001b\[(\d+)*m/gi);
  let curStyles = {};
  let text = tokens[0];
  if (text.length) out.push({ text, style: {} });
  for (let idx = 1; idx < tokens.length; idx += 2) {
    curStyles = updateStyles(curStyles, Number(tokens[idx]));
    text = tokens[idx + 1];
    if (!text.length) continue;
    out.push({ text, style: toSegmentStyle(curStyles) });
  }
  return out;
};

/* eslint-disable no-param-reassign */
const updateStyles = (curStyles, code) => {
  let style;
  let color;
  let bgColor;
  let removeStyles;
  if ((style = ANSI_ADD[code])) {
    curStyles[style] = true;
  } else if ((color = ANSI_ADD_COLOR[code])) {
    curStyles.color = color;
  } else if ((bgColor = ANSI_ADD_BGCOLOR[code])) {
    curStyles.bgColor = bgColor;
  } else if (code === 39) {
    curStyles.color = undefined;
  } else if (code === 49) {
    curStyles.bgColor = undefined;
  } else if ((removeStyles = ANSI_REMOVE[code])) {
    for (let i = 0; i < removeStyles.length; i++) {
      style = removeStyles[i];
      curStyles[style] = undefined;
    }
  } else if (code === 0) {
    curStyles = {};
  }
  return curStyles;
};
/* eslint-enable no-param-reassign */

const toConsoleArgs = (styles) => {
  const out = [];
  Object.keys(styles).forEach((key) => {
    const val = styles[key];
    if (val == null) return;
    switch (key) {
      case 'color':
        out.push(`color: ${CSS_COLORS[val]}`);
        break;
      case 'bgColor':
        out.push(`color: white; background-color: ${CSS_COLORS[val]}`);
        break;
      default:
        out.push(CSS_STYLES[key]);
    }
  });
  return out.join(';');
};

const toSegmentStyle = (styles) => {
  let out = {};
  Object.keys(styles).forEach((key) => {
    const val = styles[key];
    if (val == null) return;
    switch (key) {
      case 'color':
        out.color = CSS_COLORS[val];
        break;
      case 'bgColor':
        out.color = 'white';
        out.backgroundColor = CSS_COLORS[val];
        break;
      default:
        out = merge(out, REACT_STYLES[key]);
    }
  });
  return out;
};

// -------------------------------------------------
// Public API
// -------------------------------------------------
export {
  LEVEL_NUM_TO_COLORED_STR,
  getSrcChalkColor,
  getBrowserConsoleArgs,
  getStyledSegments,
};
