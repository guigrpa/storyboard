import { merge } from 'timm';
import chalk from 'chalk';
import { padStart } from '../vendor/lodash';
import * as ansiColors from './ansiColors';
import { LEVEL_STR_TO_NUM } from './constants';
import * as filters from './filters';
import { deserialize } from './serialize';
import treeLines from './treeLines';

const TIME_COL_RELATIVE_LENGTH = 7;
const TIME_COL_RELATIVE_EMPTY = padStart('', TIME_COL_RELATIVE_LENGTH);
const TIME_COL_ABSOLUTE_LENGTH = new Date().toISOString().length;
const TIME_COL_ABSOLUTE_EMPTY = padStart('', TIME_COL_ABSOLUTE_LENGTH);

const recordToLines = (record, options) => {
  const {
    // storyId,
    src,
    level,
    fRoot,
    fStory,
    shortId = ' ',
    obj,
    objLevel,
    objOptions,
    objExpanded,
  } = record;
  const { moduleNameLength, relativeTime, colors = true } = options;
  const out = [];

  const tmp = getTimeStr(record, options);
  let { timeStr } = tmp;
  const { fLongDelay } = tmp;
  const levelStr = ansiColors.LEVEL_NUM_TO_COLORED_STR[level];
  let prefix;
  let msgStr;
  let actionStr;
  // let parents
  if (fStory) {
    // parents = record.parents;
    timeStr = chalk.bold(timeStr);
    switch (record.action) {
      case 'CREATED':
        prefix = fRoot
          ? '\u250c\u2500\u2500\u2500 '
          : '\u250c\u2500\u252c\u2500 ';
        break;
      case 'CLOSED':
        prefix = fRoot
          ? '\u2514\u2500\u2500\u2500 '
          : '\u2514\u2500\u2534\u2500 ';
        break;
      default:
        prefix = fRoot
          ? '\u251c\u2500\u2500\u2500 '
          : `\u2502${shortId}\u251c\u2500 `;
        break;
    }
    msgStr = chalk.bold(record.title);
    actionStr = ` [${chalk.dim(shortId)}·${chalk.bold(record.action)}]`;
  } else {
    // parents = [storyId];
    prefix = fRoot || record.signalType ? '' : `\u2502${shortId}\u2502  `;
    msgStr = record.msg;
    actionStr = '';
  }
  prefix = chalk.dim(prefix);
  // const parentsStr = _.padEnd(parents.map(o => o.slice(0,7)).join(', '), 10);
  const srcStr = ansiColors.getSrcChalkColor(src)(
    padStart(src, moduleNameLength)
  );
  let objStr = '';
  const fHasObj = obj != null;
  const deserializedObj = fHasObj ? deserialize(obj) : undefined;
  if (fHasObj && !objExpanded) {
    try {
      objStr = chalk.yellow(` -- ${JSON.stringify(deserializedObj)}`);
    } catch (err) {
      /* ignore */
    }
  }
  if (level >= LEVEL_STR_TO_NUM.ERROR) {
    msgStr = chalk.red.bold(msgStr);
  } else if (level >= LEVEL_STR_TO_NUM.WARN) {
    msgStr = chalk.yellow.bold(msgStr);
  }
  let finalMsg = `${timeStr} ${srcStr} ${levelStr}${prefix}${msgStr}${actionStr}${objStr}`;
  if (!colors) finalMsg = chalk.stripColor(finalMsg);
  out.push({ text: finalMsg, level: record.level, fLongDelay });
  if (fHasObj && objExpanded && filters.passesFilter(src, objLevel)) {
    const lines = treeLines(
      deserializedObj,
      merge({ prefix: '  ' }, objOptions)
    );
    const levelStr2 = ansiColors.LEVEL_NUM_TO_COLORED_STR[objLevel];
    const emptyTimeStr = relativeTime
      ? TIME_COL_RELATIVE_EMPTY
      : TIME_COL_ABSOLUTE_EMPTY;
    lines.forEach((line) => {
      let text = `${emptyTimeStr} ${srcStr} ${levelStr2}${prefix}${line}`;
      if (!colors) text = chalk.stripColor(text);
      out.push({ text, level: objLevel });
    });
  }
  return out;
};

const getTimeStr = (record, options) => {
  const { relativeTime, prevTime } = options;
  let timeStr = '';
  let fLongDelay;
  if (relativeTime) {
    const newTime = new Date(record.t);
    const dif = prevTime ? (newTime - prevTime) / 1000 : 0;
    timeStr = dif < 1 ? dif.toFixed(3) : dif.toFixed(1);
    timeStr = padStart(timeStr, TIME_COL_RELATIVE_LENGTH);
    fLongDelay = dif > 1;
    if (dif < 0.01) timeStr = TIME_COL_RELATIVE_EMPTY;
  } else {
    timeStr = new Date(record.t).toISOString();
  }
  return { timeStr, fLongDelay };
};

export default recordToLines;
