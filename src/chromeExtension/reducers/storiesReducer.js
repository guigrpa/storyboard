/* eslint-disable no-useless-escape */

import timm from 'timm';
import * as _ from '../../vendor/lodash';
import * as k from '../../gral/constants';

const mainStoryPathStr = (fServer) => (fServer ? 'records/1' : 'records/0');

const buildMainStory = (fServer) => {
  const idx = fServer ? 1 : 0;
  const id = `main_${idx}`;
  const story = {
    id,
    storyId: id,
    pathStr: mainStoryPathStr(fServer),
    fStoryObject: true,
    t: new Date().getTime(),
    src: 'main',
    title: fServer ? 'Server' : 'Client',
    fServer,
    lastAction: 'CREATED',
    fOpen: true,
    fMain: true,
    status: undefined,
    fExpanded: true,
    fHierarchical: true,
    records: [],
    numRecords: 0,
  };
  return story;
};

const buildInitialState = (localHubId) => ({
  localHubId,
  mainStory: {
    fWrapper: true,
    fOpen: true,
    fExpanded: true,
    fHierarchical: true,
    records: [buildMainStory(false), buildMainStory(true)],
  },
  openStories: {},
  closedStories: {},
  quickFind: '',
});

// ---------------------------------------------
// Reducer
// ---------------------------------------------
const reducer = (state0, action, settings = {}) => {
  const state = state0 != null ? state0 : buildInitialState();

  // Clean up the main story after connecting
  // (we don't want to carry over logs from a previous page)
  if (action.type === 'CX_CONNECTED') return buildInitialState(action.hubId);
  if (action.type === 'CLEAR_LOGS') return buildInitialState();

  if (action.type === 'RECORDS_RECEIVED') return rxRecords(state, action, settings);

  if (action.type === 'FORGET') return forgetRecords(state, action, settings);

  if (action.type === 'TOGGLE_EXPANDED') {
    if (action.pathStr == null) return state;
    const path = (`mainStory/${action.pathStr}/fExpanded`).split('/');
    return timm.updateIn(state, path, (fExpanded) => !fExpanded);
  }

  if (action.type === 'TOGGLE_HIERARCHICAL') {
    if (action.pathStr == null) return state;
    const path = (`mainStory/${action.pathStr}/fHierarchical`).split('/');
    return timm.updateIn(state, path, (fHierarchical) => !fHierarchical);
  }

  if (action.type === 'TOGGLE_ATTACHMENT') {
    let { pathStr } = action;
    const { recordId } = action;
    if (pathStr == null || recordId == null) return state;
    pathStr = `mainStory/${pathStr}`;
    const story = timm.getIn(state, pathStr.split('/'));
    if (story == null) return state;
    const recordPathStr = findRecord(story, recordId, !story.fHierarchical, pathStr);
    if (recordPathStr == null) return state;
    const recordPath = recordPathStr.split('/');
    const record = timm.getIn(state, recordPath);
    recordPath.push('objExpanded');
    return timm.setIn(state, recordPath, !record.objExpanded);
  }

  if (action.type === 'EXPAND_ALL_STORIES') return expandCollapseAll(state, true);
  if (action.type === 'COLLAPSE_ALL_STORIES') return expandCollapseAll(state, false);

  if (action.type === 'QUICK_FIND') {
    const { txt } = action;
    let quickFind;
    if (txt.length) {
      quickFind = txt.replace(/([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, '\\$1');
      quickFind = `(${quickFind})`;
    } else {
      quickFind = '';
    }
    return timm.set(state, 'quickFind', quickFind);
  }

  return state;
};

// ---------------------------------------------
// Adding records
// ---------------------------------------------
const rxRecords = (state0, action, settings) => {
  let state = state0;
  const { records, fPastRecords, fShorthandForDuplicates } = action;
  const options = timm.merge(settings, { fPastRecords, fShorthandForDuplicates });
  const newStories = [];
  for (let i = 0, len = records.length; i < len; i++) {
    const record = records[i];
    if (record.signalType) continue;
    if (record.fStory) {
      const [tempState, pathStr] = rxStory(state, record, options);
      state = tempState;
      if (pathStr) newStories.push(pathStr);
    } else {
      state = rxLog(state, record, options);
    }
  }

  // Don't expand stories that are already closed upon reception
  for (let j = 0, len1 = newStories.length; j < len1; j++) {
    const pathStr = newStories[j];
    const fOpen = timm.getIn(state, (`mainStory/${pathStr}/fOpen`).split('/'));
    if (fOpen) continue;
    state = timm.setIn(state, (`mainStory/${pathStr}/fExpanded`).split('/'), false);
  }
  return state;
};

const rxStory = (state0, record0, options) => {
  let state = state0;
  let record = record0;
  const { fPastRecords, fDiscardRemoteClientLogs } = options;
  const { storyId, fServer, hubId } = record;
  const { localHubId } = state;
  let newStoryPathStr = null;

  // We ignore root stories (beginning by '*') when they are server-side
  // OR they belong to our local hub
  if (storyId[0] === '*') {
    if (fServer || hubId === localHubId) return [state, newStoryPathStr];
    const title = record.title.replace('ROOT STORY', 'REMOTE CLIENT');
    record = timm.set(record, 'title', title);
  }

  // We also ignore stories (not only root ones) when they belong to a remote
  // client and the user doesn't want to see them
  if (fDiscardRemoteClientLogs && (!fServer) && (hubId !== localHubId)) {
    return [state, newStoryPathStr];
  }

  // Check whether we already have a story object for this `storyId`
  // and update it with this record. Normally we only
  // check in our list of open stories, except if we know
  // that we're receiving past records
  const { openStories } = state;
  let pathStr = openStories[storyId];
  if (pathStr == null && fPastRecords) pathStr = state.closedStories[storyId];
  let rootStoryIdx;
  if (pathStr != null) {
    state = updateStory(state, pathStr, record);
    state = addLog(state, pathStr, record, options).state;
    rootStoryIdx = pathStr.split('/')[1];

  // It's a new story. Look for the *most suitable parent* and create
  // a new child story object. The *most suitable parent* is
  // obtained as the first client-side parent, or otherwise the first
  // server-side parent
  } else {
    const { parents } = record;
    if (parents != null && parents.length) {
      let parentStoryId = _.find(parents, (o) => o[0] === 'c');
      if (parentStoryId == null) parentStoryId = parents[0];
      pathStr = openStories[parentStoryId];
      if (pathStr == null && fPastRecords) pathStr = state.closedStories[parentStoryId];
    }
    if (pathStr == null) pathStr = mainStoryPathStr(fServer);
    [state, newStoryPathStr] = addStory(state, pathStr, record, options);
    state = addLog(state, newStoryPathStr, record, options).state;
    rootStoryIdx = newStoryPathStr.split('/')[1];
  }

  // Increment counter
  state = timm.updateIn(state, ['mainStory', 'records', rootStoryIdx, 'numRecords'],
    (o) => o + 1);

  // We return the new state, as well as the path of the new story (if any)
  return [state, newStoryPathStr];
};

const updateStory = (state0, pathStr, record) => {
  let state = state0;
  const { fOpen, title, status, action, storyId } = record;
  const path = `mainStory/${pathStr}`.split('/');
  const prevStory = timm.getIn(state, path);
  const nextStory = timm.merge(prevStory, { fOpen, title, status, lastAction: action });
  state = timm.setIn(state, path, nextStory);
  if (!nextStory.fOpen) {
    state = timm.setIn(state, ['openStories', storyId], undefined);
    state = timm.setIn(state, ['closedStories', storyId], pathStr);
  }
  return state;
};

const addStory = (state0, parentStoryPathStr, record, options) => {
  let state = state0;
  const { fCollapseAllNewStories } = options;
  const parentRecordsPath = `mainStory/${parentStoryPathStr}/records`.split('/');
  const parentRecords = timm.getIn(state, parentRecordsPath);
  const pathStr = `${parentStoryPathStr}/records/${parentRecords.length}`;
  const story = timm.merge(record, {
    pathStr,
    records: [],
    fStoryObject: true,
    lastAction: record.action,
    fExpanded: !fCollapseAllNewStories,
    fHierarchical: true,
  });
  delete story.fStory;
  delete story.action;
  state = timm.setIn(state, `mainStory/${pathStr}`.split('/'), story);
  const pathSeg = story.fOpen ? 'openStories' : 'closedStories';
  state = timm.setIn(state, [pathSeg, story.storyId], pathStr);
  return [state, pathStr];
};

const rxLog = (state0, record, options) => {
  let state = state0;
  const { localHubId } = state;
  const { storyId, fServer, hubId } = record;
  const { fDiscardRemoteClientLogs } = options;
  if (fDiscardRemoteClientLogs && (!fServer) && hubId !== localHubId) return state;
  const pathStr = state.openStories[storyId] != null
    ? state.openStories[storyId]
    : mainStoryPathStr(fServer);
  const { state: tmpState, fDuplicate } = addLog(state, pathStr, record, options);
  state = tmpState;
  if (!fDuplicate) {
    const rootStoryIdx = pathStr.split('/')[1];
    state = timm.updateIn(state, ['mainStory', 'records', rootStoryIdx, 'numRecords'],
      (o) => o + 1);
  }
  return state;
};

const addLog = (state0, pathStr, record0, options) => {
  let state = state0;
  let record = record0;
  const { fPastRecords, fExpandAllNewAttachments, fShorthandForDuplicates = true } = options;
  const path = `mainStory/${pathStr}/records`.split('/');
  record = timm.set(record, 'objExpanded', !!fExpandAllNewAttachments);
  let fDuplicate = false;
  let nextRecords;
  state = timm.updateIn(state, path, (prevRecords) => {
    // Handle duplicates when including past records
    if (fPastRecords) {
      const { storyId, id } = record;
      if (_.find(prevRecords, (o) => o.storyId === storyId && o.id === id)) {
        return prevRecords;
      }
    }

    // Handle consecutive repetitions
    if (fShorthandForDuplicates && !record.fStory) {
      const idx = prevRecords.length - 1;
      const prevLastRecord = prevRecords[idx];
      if (prevLastRecord != null &&
        prevLastRecord.msg === record.msg &&
        prevLastRecord.src === record.src &&
        _.isEqual(prevLastRecord.obj, record.obj)
      ) {
        fDuplicate = true;
        const repetitions = prevLastRecord.repetitions || 0;
        const nextLastRecord = timm.merge(prevLastRecord, {
          repetitions: repetitions + 1,
          tLastRepetition: record.t,
        });
        nextRecords = timm.replaceAt(prevRecords, idx, nextLastRecord);
      }
    }

    // Normal case
    if (nextRecords == null) nextRecords = timm.addLast(prevRecords, record);
    return nextRecords;
  });

  // Flag stories containing warnings and errors
  const fWarn = record.level === k.LEVEL_STR_TO_NUM.WARN;
  const fError = record.level >= k.LEVEL_STR_TO_NUM.ERROR;
  if (fWarn || fError) {
    const recurPath = [].concat(path);
    while (true) {  // eslint-disable-line no-constant-condition
      recurPath.pop();  // recurPath is now the story path
      const story = timm.getIn(state, recurPath);
      if (story.fMain) break;
      if (fWarn && !story.fHasWarning) {
        state = timm.setIn(state, recurPath.concat(['fHasWarning']), true);
      }
      if (fError && !story.fHasError) {
        state = timm.setIn(state, recurPath.concat(['fHasError']), true);
      }
      recurPath.pop();
    }
  }

  return { state, fDuplicate };
};

// ---------------------------------------------
// Forgetting records
// ---------------------------------------------
const forgetRecords = (state0, action, settings) => {
  let state = state0;
  const { pathStr } = action;
  const { maxRecords, forgetHysteresis } = settings;
  const path = `mainStory/${pathStr}`.split('/');
  const prevStory = timm.getIn(state, path);
  const { numRecords } = prevStory;
  const targetForget = Math.ceil((numRecords - maxRecords) + (maxRecords * forgetHysteresis));
  const { nextStory, numForgotten, updatedStoryPaths } =
    forgetRecursively(prevStory, targetForget, {}, prevStory.pathStr);
  nextStory.numRecords = numRecords - numForgotten;
  state = timm.setIn(state, path, nextStory);
  const openStories = updateStoryPaths(state.openStories, updatedStoryPaths);
  const closedStories = updateStoryPaths(state.closedStories, updatedStoryPaths);
  state = timm.merge(state, { openStories, closedStories });
  return state;
};

/* eslint-disable no-param-reassign */
const forgetRecursively = (prevStory, targetForget, updatedStoryPaths, storyPathStr) => {
  let numForgotten = 0;
  const nextRecords = [];
  const prevRecords = prevStory.records;
  const prevRecordsLen = prevRecords.length;

  // Forget records
  let idx = 0;
  while (idx < prevRecordsLen) {
    const prevRecord = prevRecords[idx];
    const fEnoughForgotten = numForgotten >= targetForget;

    // Action records are never forgotten
    if (prevRecord.fStory) {
      nextRecords.push(prevRecord);

    // Stories
    } else if (prevRecord.fStoryObject) {
      // Closed story objects are forgotten as a whole
      if (!fEnoughForgotten && !prevRecord.fOpen) {
        numForgotten += numStoryRecords(prevRecord);
        const storyIds = collectChildStoryIds(prevRecord);
        for (let i = 0; i < storyIds.length; i++) {
          updatedStoryPaths[storyIds[i]] = null;
        }
        updatedStoryPaths[prevRecord.storyId] = null;

      // Other cases: open stories, or enough forgotten. Copy at least some records
      } else {
        const childPathStr = `${storyPathStr}/records/${nextRecords.length}`;
        const targetChildForget = fEnoughForgotten ? 0 : targetForget - numForgotten;
        const result = forgetRecursively(prevRecord, targetChildForget,
          updatedStoryPaths, childPathStr);
        const nextChildStory = timm.set(result.nextStory, 'pathStr', childPathStr);
        nextRecords.push(nextChildStory);
        numForgotten += result.numForgotten;
        updatedStoryPaths[prevRecord.storyId] = childPathStr;
      }

    // Normal logs
    } else if (fEnoughForgotten) {
      nextRecords.push(prevRecord);
    } else {
      numForgotten += 1;
    }

    idx += 1;
  }

  const nextStory = timm.set(prevStory, 'records', nextRecords);
  return { nextStory, numForgotten, updatedStoryPaths };
};
/* eslint-enable no-param-reassign */

const numStoryRecords = (story) => {
  const { records } = story;
  let num = 0;
  for (let i = 0; i < records.length; i++) {
    const record = records[i];
    if (record.fStoryObject) num += numStoryRecords(record);
    else num += 1;
  }
  return num;
};

const collectChildStoryIds = (story, storyIds = []) => {
  const { records } = story;
  for (let i = 0; i < records.length; i++) {
    const record = records[i];
    if (!record.fStoryObject) continue;
    storyIds.push(record.storyId);
    collectChildStoryIds(record, storyIds);
  }
  return storyIds;
};

const updateStoryPaths = (storyHash0, updatedStoryPaths) => {
  let storyHash = storyHash0;
  const storyIds = Object.keys(updatedStoryPaths);
  for (let i = 0; i < storyIds.length; i++) {
    const storyId = storyIds[i];
    let pathStr = updatedStoryPaths[storyId];
    if (storyHash[storyId] != null) {
      if (pathStr === null) pathStr = undefined;
      storyHash = timm.set(storyHash, storyId, pathStr);
    }
  }
  return storyHash;
};

// ---------------------------------------------
// Expand/collapse all
// ---------------------------------------------
const expandCollapseAll = (state, fExpanded) => {
  // Returns a new subtree, expanding/collapsing child stories
  const expandCollapse = (prevStory) => {
    const nextRecords = prevStory.records.map(expandCollapseRecord);
    const nextStory = timm.set(prevStory, 'records', nextRecords);
    if (!(nextStory.fWrapper || nextStory.fMain)) {
      nextStory.fExpanded = fExpanded;  // in-place since it is always a new object
    }
    return nextStory;
  };

  // Returns:
  // - For normal records (logs): the same record
  // - For story objects: the expanded/collapsed record
  const expandCollapseRecord = (prevRecord) => {
    if (!prevRecord.fStoryObject) return prevRecord;
    return expandCollapse(prevRecord);
  };

  // Run recursive algorithm
  return timm.set(state, 'mainStory', expandCollapse(state.mainStory));
};

// ---------------------------------------------
// Helpers
// ---------------------------------------------
const findRecord = (story, recordId, fRecurse, pathStr) => {
  const { records } = story;
  for (let idx = 0; idx < records.length; idx++) {
    const record = records[idx];
    if (record.id === recordId) return `${pathStr}/records/${idx}`;
    if (record.fStoryObject && fRecurse) {
      const res = findRecord(record, recordId, fRecurse, `${pathStr}/records/${idx}`);
      if (res != null) return res;
    }
  }
  return null;
};

// ---------------------------------------------
// API
// ---------------------------------------------
export default reducer;
