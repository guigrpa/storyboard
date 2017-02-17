/* eslint-disable no-constant-condition */

import Promise from 'bluebird';
import Saga from 'redux-saga/effects';
import debounce from 'lodash/debounce';

const CHECK_FORGET_PERIOD = 3000;
const QUICK_FIND_DEBOUNCE = 250;

// =============================================
// Miscellaneous actions
// =============================================
const toggleExpanded = (pathStr) => ({ type: 'TOGGLE_EXPANDED', pathStr });
const toggleHierarchical = (pathStr) => ({ type: 'TOGGLE_HIERARCHICAL', pathStr });
const toggleAttachment = (pathStr, recordId) => ({ type: 'TOGGLE_ATTACHMENT', pathStr, recordId });
const expandAllStories = () => ({ type: 'EXPAND_ALL_STORIES' });
const collapseAllStories = () => ({ type: 'COLLAPSE_ALL_STORIES' });
const clearLogs = () => ({ type: 'CLEAR_LOGS' });
const quickFind = (txt) => (dispatch) => _quickFind(dispatch, txt);

const _quickFind = debounce((dispatch, txt) =>
  dispatch({ type: 'QUICK_FIND', txt })
, QUICK_FIND_DEBOUNCE);

// =============================================
// Forget saga
// =============================================
function* forgetRecords() {
  while (true) {
    for (let idx = 0; idx <= 1; idx++) {
      const { story, maxRecords } = yield Saga.select((state) => ({
        story: state.stories.mainStory.records[idx],
        maxRecords: state.settings.maxRecords,
      }));
      if (story.numRecords > maxRecords) {
        yield Saga.put({
          type: 'FORGET',
          pathStr: story.pathStr,
        });
      }
    }
    yield Promise.delay(CHECK_FORGET_PERIOD);
  }
}

// =============================================
// API
// =============================================
const sagas = [forgetRecords];
export default sagas;
export {
  toggleExpanded,
  toggleHierarchical,
  toggleAttachment,
  expandAllStories,
  collapseAllStories,
  clearLogs,
  quickFind,
};
