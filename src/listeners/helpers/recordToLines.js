import { merge } from 'timm';
import chalk from 'chalk';
import { padStart } from '../../vendor/lodash';
import ansiColors from '../../gral/ansiColors';
import k from '../../gral/constants';
import filters from '../../gral/filters';
import treeLines from '../../gral/treeLines';

const TIME_COL_RELATIVE_LENGTH = 7;
const TIME_COL_RELATIVE_EMPTY = padStart('', TIME_COL_RELATIVE_LENGTH);
const TIME_COL_ABSOLUTE_LENGTH = new Date().toISOString().length;
const TIME_COL_ABSOLUTE_EMPTY = padStart('', TIME_COL_ABSOLUTE_LENGTH);

const recordToLines = (record, options) => {
  const {
    src, storyId, level, fStory, fServer,
    obj, objLevel, objOptions,
  } = record;
  let { objExpanded } = record;
  const {
    moduleNameLength,
    relativeTime,
    colors = true,
  } = options;
  const out = [];

  const tmp = getTimeStr(record, options);
  let { timeStr } = tmp;
  const { fLongDelay } = tmp;
  const levelStr = ansiColors.LEVEL_NUM_TO_COLORED_STR[level];
  let msgStr;
  let actionStr;
  // let parents
  if (fStory) {
    // parents = record.parents;
    timeStr = chalk.bold(timeStr);
    let storyPrefix;
    switch (record.action) {
      case 'CREATED': storyPrefix = '\u250c\u2500\u2500'; break;
      case 'CLOSED': storyPrefix = '\u2514\u2500\u2500'; break;
      default: storyPrefix = '\u251c\u2500\u2500'; break;
    }
    msgStr = chalk.bold(`${storyPrefix} ${record.title}`);
    actionStr = ` [${chalk.bold(record.action)}]`;
  } else {
    // parents = [storyId];
    msgStr = record.msg;
    actionStr = '';
  }
  // const parentsStr = _.padEnd(parents.map(o => o.slice(0,7)).join(', '), 10);
  const srcStr = ansiColors.getSrcChalkColor(src)(padStart(src, options.moduleNameLength));
  let objStr = '';
  if ((obj != null) && !objExpanded) {
    try {
      objStr = chalk.yellow(` -- ${JSON.stringify(obj)}`);
    } catch (err) {
      objStr = chalk.red(' -- [could not stringify object, expanding...]');
      objExpanded = true;
    }
  }
  if (level >= k.LEVEL_STR_TO_NUM.ERROR) {
    msgStr = chalk.red.bold(msgStr);
  } else if (level >= k.LEVEL_STR_TO_NUM.WARN) {
    msgStr = chalk.yellow.bold(msgStr);
  }
  let finalMsg = `${timeStr} ${srcStr} ${levelStr}${msgStr}${actionStr}${objStr}`;
  if (!colors) finalMsg = chalk.stripColor(finalMsg);
  out.push({ text: finalMsg, level: record.level, fLongDelay });
  if (objExpanded && filters.passesFilter(src, objLevel)) {
    const lines = treeLines(obj, merge({ prefix: '  ' }, objOptions));
    const levelStr = ansiColors.LEVEL_NUM_TO_COLORED_STR[objLevel];
    const emptyTimeStr = options.relativeTime ? TIME_COL_RELATIVE_EMPTY : TIME_COL_ABSOLUTE_EMPTY;
    lines.forEach(line => {
      let text = `${emptyTimeStr} ${srcStr} ${levelStr}${line}`;
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
    fLongDelay = (dif > 1);
    if (dif < 0.010) timeStr = TIME_COL_RELATIVE_EMPTY;
  } else {
    timeStr = new Date(record.t).toISOString();
  }
  return { timeStr, fLongDelay };
};

export default recordToLines;
