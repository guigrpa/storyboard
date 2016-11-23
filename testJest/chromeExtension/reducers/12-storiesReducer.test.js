/* eslint-env jest */
/* eslint-disable max-len, no-extend-native, no-plusplus */
import timm from 'timm';
import reducer from '../../../lib/chromeExtension/reducers/storiesReducer';
import treeLines from '../../../lib/gral/treeLines';

Date.prototype.getTime = jest.genMockFunction().mockReturnValue(0);

// ---------------------------------------
// Helpers
// ---------------------------------------
const settings = (settings0 = {}) => timm.addDefaults(settings0, {
  maxRecords: 50,
  forgetHysteresis: 0.25,
});

const recordsReceived = (records, fPastRecords = false) => ({
  type: 'RECORDS_RECEIVED',
  records,
  fPastRecords,
});

const forget = (action = {}) => timm.addDefaults(action, {
  type: 'FORGET',
  pathStr: 'records/0',
});

let _seqId = 0;

const log = (record) => timm.addDefaults(record, {
  fStory: false,
  fServer: false,
  src: 'main',
  level: 30,
  storyId: '*',
  id: `llll${_seqId++}`,
});

const actionRecord = (record) => timm.addDefaults(record, {
  fStory: true,
  fServer: false,
  fOpen: true,
  src: 'main',
  level: 30,
});

let _seqStoryId = 0;

const openStory = (record) => actionRecord(timm.addDefaults(record, {
  action: 'CREATED',
  storyId: `ssss${_seqStoryId++}`,
  parents: [],
}));

const closeStory = (storyId) => actionRecord({
  storyId,
  action: 'CLOSED',
  fOpen: false,
});

// const storyAction = (storyId, action) => actionRecord({
//   storyId,
// });

// ---------------------------------------
// Tests
// ---------------------------------------
describe('storyReducer', () => {
  let state;
  beforeEach(() => {
    state = reducer(undefined, { type: '' });
  });

  it('should have correct initial state', () => {
    expect(state).toMatchSnapshot();
  });

  describe('forgetting', () => {
    it('normal logs should be forgotten', () => {
      const records = [0, 1, 2, 3, 4, 5, 6, 7].map((idx) => log({ msg: `msg${idx}` }));
      state = reducer(state, recordsReceived(records));
      expect(state.mainStory.records[0].numRecords).toEqual(8);
      state = reducer(state, forget(), settings({ maxRecords: 4 }));
      const topStory = state.mainStory.records[0];
      expect(topStory.records.length).toEqual(3);
      expect(topStory.records[0].msg).toEqual('msg5');
      expect(topStory.records[1].msg).toEqual('msg6');
      expect(topStory.records[2].msg).toEqual('msg7');
      expect(topStory.numRecords).toEqual(3);
    });

    it('closed stories should be forgotten', () => {
      const openStoryRecord0 = openStory({ title: 'story0' });
      const openStoryRecord1 = openStory({ title: 'story1', parents: [openStoryRecord0.storyId] });
      state = reducer(state, recordsReceived([
        log({ msg: 'msg0' }),
        openStoryRecord0,
        log({ msg: 'story log', storyId: openStoryRecord0.storyId }),
        openStoryRecord1,
        closeStory(openStoryRecord1.storyId),
        closeStory(openStoryRecord0.storyId),
        log({ msg: 'msg1' }),
      ]));
      expect(state.mainStory.records[0].numRecords).toEqual(7);
      state = reducer(state, forget(), settings({ maxRecords: 4 }));
      const topStory = state.mainStory.records[0];
      expect(topStory.records.length).toEqual(1);
      expect(topStory.records[0].msg).toEqual('msg1');
      expect(topStory.numRecords).toEqual(1);
      expect(state.closedStories[openStoryRecord0.storyId]).toEqual(undefined);
      expect(state.closedStories[openStoryRecord1.storyId]).toEqual(undefined);
    });

    it('the pathStr of open stories should be updated if necessary', () => {
      const openStoryRecord0 = openStory({ title: 'story0' });
      const openStoryRecord1 = openStory({ title: 'story1', parents: [openStoryRecord0.storyId] });
      const openStoryRecord2 = openStory({ title: 'story2', parents: [openStoryRecord1.storyId] });
      state = reducer(state, recordsReceived([
        log({ msg: 'msg0' }),
        log({ msg: 'msg1' }),
        openStoryRecord0,
        openStoryRecord1,
        openStoryRecord2,
      ]));
      expect(state.mainStory.records[0].numRecords).toEqual(5);
      state = reducer(state, forget(), settings({ maxRecords: 1 }));
      const topStory = state.mainStory.records[0];
      expect(topStory.records.length).toEqual(1);
      expect(topStory.records[0].title).toEqual('story0');
      expect(topStory.records[0].pathStr).toEqual('records/0/records/0');
      expect(topStory.records[0].records.length).toEqual(2);
      expect(topStory.records[0].records[0].action).toEqual('CREATED');
      expect(topStory.records[0].records[1].title).toEqual('story1');
      expect(topStory.records[0].records[1].pathStr).toEqual('records/0/records/0/records/1');
      expect(topStory.records[0].records[1].records.length).toEqual(2);
      expect(topStory.records[0].records[1].records[0].action).toEqual('CREATED');
      expect(topStory.records[0].records[1].records[1].title).toEqual('story2');
      expect(topStory.records[0].records[1].records[1].pathStr).toEqual('records/0/records/0/records/1/records/1');
      expect(topStory.numRecords).toEqual(3);
      expect(state.openStories[openStoryRecord0.storyId]).toEqual('records/0/records/0');
      expect(state.openStories[openStoryRecord1.storyId]).toEqual('records/0/records/0/records/1');
      expect(state.openStories[openStoryRecord2.storyId]).toEqual('records/0/records/0/records/1/records/1');
    });
  });

  describe('multiple actions', () => {
    beforeEach(() => {
      const openStoryRecord0 = openStory({ title: 'story0' });
      const openStoryRecord1 = openStory({ title: 'story1', parents: [openStoryRecord0.storyId] });
      const attachment = { a: 1, b: 2, c: 3 };
      const logRecord = log({
        id: 'logWithAttachment',
        storyId: openStoryRecord1.storyId,
        msg: 'log with attachment',
        obj: treeLines(attachment),
        objExpanded: false,
      });
      const logRecordWithError = log({
        id: 'logWithError',
        storyId: openStoryRecord1.storyId,
        level: 50,
        msg: 'an error has occurred',
      });
      const logRecordWithWarning = log({
        id: 'logWithWarning',
        storyId: openStoryRecord1.storyId,
        level: 40,
        msg: 'warning, warning',
      });
      state = reducer(state, recordsReceived([
        openStoryRecord0,
        openStoryRecord1,
        logRecord,
        logRecordWithWarning,
        logRecordWithError,
      ]));
      expect(state.mainStory.records[0].records[0].fExpanded).toEqual(true);
      expect(state.mainStory.records[0].records[0].records[1].fExpanded).toEqual(true);
    });

    it('should correctly mark all stories containing (at any depth level) errors/warnings', () => {
      expect(state.mainStory.records[0].records[0].fHasWarning).toEqual(true);
      expect(state.mainStory.records[0].records[0].fHasError).toEqual(true);
      expect(state.mainStory.records[0].records[0].records[1].fHasWarning).toEqual(true);
      expect(state.mainStory.records[0].records[0].records[1].fHasError).toEqual(true);
    });

    it('should allow expanding/collapsing all stories', () => {
      state = reducer(state, { type: 'COLLAPSE_ALL_STORIES' });
      expect(state.mainStory.records[0].records[0].fExpanded).toEqual(false);
      expect(state.mainStory.records[0].records[0].records[1].fExpanded).toEqual(false);
      state = reducer(state, { type: 'EXPAND_ALL_STORIES' });
      expect(state.mainStory.records[0].records[0].fExpanded).toEqual(true);
      expect(state.mainStory.records[0].records[0].records[1].fExpanded).toEqual(true);
    });

    it('should allow expanding/collapsing an individual story', () => {
      state = reducer(state, { type: 'TOGGLE_EXPANDED', pathStr: 'records/0/records/0' });
      expect(state.mainStory.records[0].records[0].fExpanded).toEqual(false);
      state = reducer(state, { type: 'TOGGLE_EXPANDED', pathStr: 'records/0/records/0' });
      expect(state.mainStory.records[0].records[0].fExpanded).toEqual(true);
      const state2 = reducer(state, { type: 'TOGGLE_EXPANDED' });
      expect(state2).toEqual(state);
    });

    it('should allow showing stories in a flat/hierarchical way', () => {
      state = reducer(state, { type: 'TOGGLE_HIERARCHICAL', pathStr: 'records/0/records/0' });
      expect(state.mainStory.records[0].records[0].fHierarchical).toEqual(false);
      state = reducer(state, { type: 'TOGGLE_HIERARCHICAL', pathStr: 'records/0/records/0' });
      expect(state.mainStory.records[0].records[0].fHierarchical).toEqual(true);
      const state2 = reducer(state, { type: 'TOGGLE_HIERARCHICAL' });
      expect(state2).toEqual(state);
    });

    it('should store quick-find info', () => {
      state = reducer(state, { type: 'QUICK_FIND', txt: 'hello' });
      expect(state.quickFind).toEqual('(hello)');
      state = reducer(state, { type: 'QUICK_FIND', txt: '' });
      expect(state.quickFind).toEqual('');
      state = reducer(state, { type: 'QUICK_FIND', txt: '.+*' });
      expect(state.quickFind).toEqual('(\\.\\+\\*)');
    });

    it('should clear the state when receiving a CX_CONNECTED action', () => {
      state = reducer(state, { type: 'CX_CONNECTED' });
      expect(state.mainStory.records[0].records.length).toEqual(0);
      expect(state.mainStory.records[1].records.length).toEqual(0);
    });

    it('should clear the state when receiving a CLEAR_LOGS action', () => {
      state = reducer(state, { type: 'CLEAR_LOGS' });
      expect(state.mainStory.records[0].records.length).toEqual(0);
      expect(state.mainStory.records[1].records.length).toEqual(0);
    });

    describe('expanding attachments', () => {
      it('in a hierarchical story', () => {
        expect(state.mainStory.records[0].records[0].records[1].records[1].msg).toContain('with attachment');
        expect(state.mainStory.records[0].records[0].records[1].records[1].objExpanded).toEqual(false);
        const pathStr = 'records/0/records/0/records/1';
        state = reducer(state, { type: 'TOGGLE_ATTACHMENT', pathStr, recordId: 'logWithAttachment' });
        expect(state.mainStory.records[0].records[0].records[1].records[1].objExpanded).toEqual(true);
        state = reducer(state, { type: 'TOGGLE_ATTACHMENT', pathStr, recordId: 'logWithAttachment' });
        expect(state.mainStory.records[0].records[0].records[1].records[1].objExpanded).toEqual(false);
      });

      it('in a flat story', () => {
        const pathStr = 'records/0';
        state = reducer(state, { type: 'TOGGLE_HIERARCHICAL', pathStr });
        expect(state.mainStory.records[0].fHierarchical).toEqual(false);
        state = reducer(state, { type: 'TOGGLE_ATTACHMENT', pathStr, recordId: 'logWithAttachment' });
        expect(state.mainStory.records[0].records[0].records[1].records[1].objExpanded).toEqual(true);
        state = reducer(state, { type: 'TOGGLE_ATTACHMENT', pathStr, recordId: 'logWithAttachment' });
        expect(state.mainStory.records[0].records[0].records[1].records[1].objExpanded).toEqual(false);
      });

      it('with incorrect arguments', () => {
        const pathStr = 'records/0';
        let state2 = reducer(state, { type: 'TOGGLE_ATTACHMENT', pathStr, recordId: 'xxx' });
        expect(state2).toEqual(state);
        state2 = reducer(state, { type: 'TOGGLE_ATTACHMENT', pathStr: null, recordId: 'xxx' });
        expect(state2).toEqual(state);
        state2 = reducer(state, { type: 'TOGGLE_ATTACHMENT', pathStr: 'unknown/path', recordId: 'xxx' });
        expect(state2).toEqual(state);
      });
    });
  });

  describe('adding a new story to a closed story', () => {
    let _storyId;
    beforeEach(() => {
      const openStoryRecord = openStory({ title: 'story0' });
      _storyId = openStoryRecord.storyId;
      state = reducer(state, recordsReceived([openStoryRecord, closeStory(_storyId)]));
    });

    it('with fPastRecords = false (should NOT include it in the closed story)', () => {
      state = reducer(state, recordsReceived([openStory({ title: 'child', parents: [_storyId] })], false));
      expect(state.mainStory.records[0].records[0].records.length).toEqual(2);
      expect(state.mainStory.records[0].records[1].title).toEqual('child');
    });
    it('with fPastRecords = true (should include it in the closed story)', () => {
      state = reducer(state, recordsReceived([openStory({ title: 'child', parents: [_storyId] })], true));
      expect(state.mainStory.records[0].records[0].records.length).toEqual(3);
      expect(state.mainStory.records[0].records[0].records[2].title).toEqual('child');
    });
  });

  it('adding a root story should be ignored', () => {
    const state2 = reducer(state, recordsReceived([openStory({ title: 'rootStory23', storyId: '*' })]));
    expect(state2).toEqual(state);
  });

  describe('showing identical consecutive logs', () => {
    it('by default, should use shorthand notation', () => {
      state = reducer(state, recordsReceived([
        log({ msg: 'msg23' }),
        log({ msg: 'msg23' }),
        log({ msg: 'msg23' }),
      ]));
      expect(state.mainStory.records[0].records.length).toEqual(1);
      const record = state.mainStory.records[0].records[0];
      expect(record.repetitions).toEqual(2);
      expect(record.tLastRepetition).not.toBeNull();
    });

    it('with fShorthandForDuplicates=false, should include all logs', () => {
      state = reducer(state, recordsReceived([
        log({ msg: 'msg23' }),
        log({ msg: 'msg23' }),
        log({ msg: 'msg23' }),
      ]), { fShorthandForDuplicates: false });
      expect(state.mainStory.records[0].records.length).toEqual(3);
    });

    it('should detect when attachments are equal', () => {
      state = reducer(state, recordsReceived([
        log({ msg: 'msg45', obj: ['line1', 'line2'] }),
        log({ msg: 'msg45', obj: ['line1', 'line2'] }),
      ]));
      expect(state.mainStory.records[0].records.length).toEqual(1);
    });

    it('should detect when attachments are different', () => {
      state = reducer(state, recordsReceived([
        log({ msg: 'msg45', obj: ['line1', 'line2'] }),
        log({ msg: 'msg45', obj: ['line1', 'DIFFERENT'] }),
      ]));
      expect(state.mainStory.records[0].records.length).toEqual(2);
    });
  });

  it('should remove duplicates when using fPastRecords', () => {
    state = reducer(state, recordsReceived([
      log({ msg: 'msg0', id: 'id0' }),
      log({ msg: 'msg1', id: 'id1' }),
    ]));
    state = reducer(state, recordsReceived([
      log({ msg: 'msg0', id: 'id0' }),
    ], true));
    expect(state.mainStory.records[0].records.length).toEqual(2);
    expect(state.mainStory.records[0].records[0].id).toEqual('id0');
    expect(state.mainStory.records[0].records[1].id).toEqual('id1');
  });
});
