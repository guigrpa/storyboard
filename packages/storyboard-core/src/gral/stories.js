import uuid from 'uuid';
import platform from 'platform';
import chalk from 'chalk';
import * as _ from '../vendor/lodash';
import { IS_BROWSER, LEVEL_STR_TO_NUM } from './constants';
import { passesFilter } from './filters';
import { getHubId, emitMsgWithFields } from './hub';
import { serialize } from './serialize';

const version = require('../../package.json').version;

const DEFAULT_SRC = 'main';
const DEFAULT_CHILD_TITLE = '';

/* eslint-disable max-len */
const REVEAL_SEPARATOR_BEGIN =
  '\u2500\u2500\u2500\u2500 REVEALED PAST LOGS BEGIN HERE (due to warning/error)';
/* eslint-enable max-len */
const REVEAL_SEPARATOR_END =
  '\u2500\u2500\u2500\u2500 REVEALED PAST LOGS END HERE';
const SHORT_IDS =
  ' ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!?,.+-*;:_·$%&()';

// Record formats:
// * 1 (or undefined): initial version
// * 2: embeds objects directly, not their visual representation
//   (does not call treeLines before attaching). Circular refs are removed
// * 3: include type signalType
const RECORD_FORMAT_VERSION = 3;

const hiddenStories = {};
const activeShortIds = {};
const hubId = getHubId();

// -----------------------------------------------
// Helpers
// -----------------------------------------------
const getStoryId = () => (IS_BROWSER ? 'cs/' : 'ss/') + uuid.v4();
const getRecordId = () => (IS_BROWSER ? 'c-' : 's-') + uuid.v4();
const getShortId = () => {
  for (let i = 0; i < SHORT_IDS.length; i++) {
    const shortId = SHORT_IDS[i];
    if (!activeShortIds[shortId]) return shortId;
  }
  return ' ';
};

// -----------------------------------------------
// Story
// -----------------------------------------------
function Story({ parents, src, title, levelNum, fHiddenByFilter }) {
  this.parents = parents;
  this.fRoot = !parents.length;
  this.storyId = (this.fRoot ? '*/' : '') + getStoryId();
  this.shortId = getShortId();
  activeShortIds[this.shortId] = true;
  this.src = src;
  this.title = title;
  this.level = levelNum;
  this.fServer = !IS_BROWSER;
  this.t = new Date().getTime();
  this.fOpen = true;
  this.status = undefined;
  this.hiddenRecords = [];
  this.fHiddenByFilter = fHiddenByFilter || !passesFilter(this.src, this.level);
  if (this.fHiddenByFilter) {
    hiddenStories[this.storyId] = this;
  }
  this.chalk = chalk;
  this.emitAction('CREATED', this.t);
}

// -----------------------------------------------
// Story lifecycle
// -----------------------------------------------
Story.prototype.close = function close() {
  this.fOpen = false;
  activeShortIds[this.shortId] = null;
  this.emitAction('CLOSED');
  if (this.fHiddenByFilter) {
    hiddenStories[this.storyId] = null;
    this.hiddenRecords = [];
  }
};

Story.prototype.changeTitle = function changeTitle(title) {
  this.title = title;
  this.emitAction('TITLE_CHANGED');
};

Story.prototype.changeStatus = function changeStatus(status) {
  this.status = status;
  this.emitAction('STATUS_CHANGED');
};

Story.prototype.child = function child(options = {}) {
  let { src, title } = options;
  if (src == null) src = DEFAULT_SRC;
  if (title == null) title = DEFAULT_CHILD_TITLE;
  const { extraParents, level: levelStr } = options;
  let levelNum;
  if (levelStr != null) levelNum = LEVEL_STR_TO_NUM[levelStr.toUpperCase()];
  if (levelNum == null) levelNum = LEVEL_STR_TO_NUM.INFO;
  let parents = [this.storyId];
  if (extraParents != null) parents = parents.concat(extraParents);
  return new Story({
    parents,
    src,
    title,
    levelNum,
    fHiddenByFilter: this.fHiddenByFilter,
  });
};

// -----------------------------------------------
// Logs
// -----------------------------------------------
Object.keys(LEVEL_STR_TO_NUM).forEach((levelStr) => {
  const levelNum = LEVEL_STR_TO_NUM[levelStr];
  Story.prototype[levelStr.toLowerCase()] = function log(...args) {
    // Prepare arguments
    let src;
    let msg;
    let options;
    // `log.info msg`
    if (args.length <= 1) {
      src = DEFAULT_SRC;
      msg = args[0] != null ? args[0] : '';
      // `log.info msg, options`
    } else if (_.isObject(args[1])) {
      src = DEFAULT_SRC;
      msg = args[0] != null ? args[0] : '';
      options = args[1];
    } else {
      src = args[0];
      msg = args[1];
      options = args[2];
    }
    if (options == null) options = {};

    // Filtering rule #1
    if (!passesFilter(src, levelNum)) return;

    // Prepare record
    const record = {
      storyId: this.storyId,
      shortId: this.shortId,
      fRoot: this.fRoot,
      level: levelNum,
      src,
      msg,
    };
    processAttachments(record, options);
    completeRecord(record);

    // Filtering rule #2, specific to hidden stories
    if (this.fHiddenByFilter) {
      if (levelNum < LEVEL_STR_TO_NUM.WARN) {
        this.hiddenRecords.push(record);
        return;
      }
      emitRevealSeparator(REVEAL_SEPARATOR_BEGIN);
      this.reveal();
      emitRevealSeparator(REVEAL_SEPARATOR_END);
    }

    emit(record);
  };
});

// -----------------------------------------------
// Story helpers
// -----------------------------------------------
Story.prototype.emitAction = function emitAction(action, t) {
  const record = {
    parents: this.parents,
    fRoot: this.fRoot,
    storyId: this.storyId,
    shortId: this.shortId,
    src: this.src,
    title: this.title,
    level: this.level,
    fServer: this.fServer,
    t,
    fOpen: this.fOpen,
    status: this.status,
    fStory: true,
    action,
  };
  completeRecord(record);
  if (this.fHiddenByFilter) {
    this.hiddenRecords.push(record);
    return;
  }
  emit(record);
};

// Reveal parents recursively, and then reveal myself
Story.prototype.reveal = function reveal() {
  this.parents.forEach((parentStoryId) => {
    if (hiddenStories[parentStoryId] != null) {
      hiddenStories[parentStoryId].reveal();
    }
  });
  this.fHiddenByFilter = false;
  hiddenStories[this.storyId] = null;
  const { hiddenRecords } = this;
  for (let j = 0; j < hiddenRecords.length; j++) {
    emit(hiddenRecords[j]);
  }
  this.hiddenRecords = [];
};

// Records can be logs or stories:
// * Common to stories and logs:
//   - `id: string` (a unique record id)
//   - `hubId: string`
//   - `version: integer`
//   - `fStory: boolean`
//   - `fServer: boolean`
//   - `storyId: string`
//   - `t: number` [ms] (for stories, creation time)
//   - `src: string?`
//   - `level: number`
//   - `signalType: string` (undefined for ordinary, non-signalling records)
// * Only for stories:
//   - `fRoot: boolean`
//   - `title: string?`
//   - `action: string`
//   - `parents: Array`
// * Only for logs:
//   - `msg: string`
//   - `obj: object?`
//   - `objExpanded: bool?`
//   - `objLevel: integer?`
//   - `objOptions: object?`
//   - `objIsError: bool?`
/* eslint-disable no-param-reassign */
const completeRecord = (record) => {
  record.id = getRecordId();
  record.hubId = hubId;
  record.version = RECORD_FORMAT_VERSION;
  if (record.t == null) record.t = new Date().getTime();
  record.fServer = !IS_BROWSER;
  if (record.fStory == null) record.fStory = false;
  if (record.fRoot == null) record.fRoot = false;
};

/* eslint-disable no-prototype-builtins */
const processAttachments = (record, options) => {
  if (options.hasOwnProperty('attach')) {
    record.obj = options.attach;
    record.objExpanded = !options.attachInline;
  } else if (options.hasOwnProperty('attachInline')) {
    record.obj = options.attachInline;
    record.objExpanded = false;
  }
  if (record.hasOwnProperty('obj')) {
    let objLevel;
    if (options.attachLevel != null) {
      objLevel = LEVEL_STR_TO_NUM[options.attachLevel.toUpperCase()];
    }
    if (objLevel == null) objLevel = record.level;
    record.objLevel = objLevel;
    record.objOptions = _.pick(options, ['ignoreKeys']);
    record.objIsError = _.isError(record.obj);
    record.obj = serialize(record.obj);
  }
};
/* eslint-enable no-prototype-builtins */
/* eslint-enable no-param-reassign */

const emitRevealSeparator = (msg) => {
  const record = {
    storyId: mainStory.storyId,
    level: LEVEL_STR_TO_NUM.WARN,
    src: 'storyboard',
    msg,
    signalType: 'REVEAL_SEPARATOR',
  };
  completeRecord(record);
  emit(record);
};

const emit = (record) => {
  emitMsgWithFields('STORIES', 'RECORDS', [record]);
};

// -----------------------------------------------
// Create the main story
// -----------------------------------------------
const platformStr = `${platform.description}, SB ${version}`;
const title = `ROOT STORY: ${chalk.italic.blue.bold(platformStr)}`;
const mainStory = new Story({
  parents: [],
  src: 'storyboard',
  title,
  levelNum: LEVEL_STR_TO_NUM.INFO,
  chalk,
});

// -----------------------------------------------
// API
// -----------------------------------------------
export default mainStory;
