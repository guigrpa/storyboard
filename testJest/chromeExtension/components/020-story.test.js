/* eslint-env jest */
/* eslint-disable global-require, import/newline-after-import, max-len, no-plusplus */
import React from 'react';
import renderer from 'react-test-renderer';
import chalk from 'chalk';
import { merge, setIn } from 'timm';
import { serialize } from '../../../lib/gral/serialize';
import { _Story as Story } from '../../../lib/chromeExtension/components/020-story';
import { BASE_COLORS, DARK_COLORS, EMPTY_MAIN_STORY, buildLogRecord, buildStory } from './fixtures';

jest.mock('react-dom');

const renderMainStory = (props) =>
  <Story
    story={EMPTY_MAIN_STORY}
    level={0}
    seqFullRefresh={0}
    colors={BASE_COLORS}
    timeType="LOCAL"
    fShowClosedActions={false}
    quickFind=""
    setTimeType={() => {}}
    onToggleExpanded={() => {}}
    onToggleHierarchical={() => {}}
    onToggleAttachment={() => {}}
    {...props}
  />;

describe('Story', () => {
  it('01 renders correctly an empty main story', () => {
    const el = renderMainStory();
    const tree = renderer.create(el).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('01-b renders correctly the record counter', () => {
    let mainStory = EMPTY_MAIN_STORY;
    mainStory = setIn(mainStory, ['records', 0, 'numRecords'], 34);
    mainStory = setIn(mainStory, ['records', 1, 'numRecords'], 23);
    const el = renderMainStory({ story: mainStory });
    expect(renderer.create(el).toJSON()).toMatchSnapshot();
  });

  it('02 renders correctly server and client records (root level)', () => {
    let mainStory = EMPTY_MAIN_STORY;
    mainStory = setIn(mainStory, ['records', 0, 'records'], [
      buildLogRecord({ id: 'id1', msg: 'Client message 1' }),
      buildLogRecord({ id: 'id2', msg: `${chalk.yellow('Client')} message 2` }),
      buildLogRecord({ id: 'id3', msg: `${chalk.red('Server')} message`, fServer: true }),
    ]);
    mainStory = setIn(mainStory, ['records', 1, 'records'], [
      buildLogRecord({ id: 'id1', msg: 'Server message 1', fServer: true }),
    ]);
    const el = renderMainStory({ story: mainStory });
    expect(renderer.create(el).toJSON()).toMatchSnapshot();
  });

  it('03 renders correctly different time types', () => {
    const mainStory = setIn(EMPTY_MAIN_STORY, ['records', 0, 'records'], [
      buildLogRecord({ id: 'id1', msg: 'msg 1' }),
      buildLogRecord({ id: 'id2', msg: chalk.yellow('msg 2') }),
    ]);
    let el;
    el = renderMainStory({ story: mainStory, timeType: 'UTC' });
    expect(renderer.create(el).toJSON()).toMatchSnapshot();
    el = renderMainStory({ story: mainStory, timeType: 'RELATIVE' });
    expect(renderer.create(el).toJSON()).toMatchSnapshot();
  });

  it('04 renders messages with different sources', () => {
    const mainStory = setIn(EMPTY_MAIN_STORY, ['records', 0, 'records'], [
      buildLogRecord({ id: 'id1', src: 'one', msg: `message ${chalk.cyan('1')}` }),
      buildLogRecord({ id: 'id2', src: 'two', msg: `message ${chalk.cyan('2')}` }),
      buildLogRecord({ id: 'id3', src: 'three', msg: `message ${chalk.cyan('3')}` }),
    ]);
    const el = renderMainStory({ story: mainStory });
    expect(renderer.create(el).toJSON()).toMatchSnapshot();
  });

  it('05 renders messages with different levels', () => {
    const mainStory = setIn(EMPTY_MAIN_STORY, ['records', 0, 'records'], [
      buildLogRecord({ id: 'id1', level: 10, msg: `message ${chalk.cyan('1')}` }),
      buildLogRecord({ id: 'id2', level: 20, msg: `message ${chalk.cyan('2')}` }),
      buildLogRecord({ id: 'id3', level: 30, msg: `message ${chalk.cyan('3')}` }),
      buildLogRecord({ id: 'id4', level: 40, msg: `message ${chalk.cyan('4')}` }),
      buildLogRecord({ id: 'id5', level: 50, msg: `message ${chalk.cyan('5')}` }),
      buildLogRecord({ id: 'id6', level: 60, msg: `message ${chalk.cyan('6')}` }),
    ]);
    const el = renderMainStory({ story: mainStory });
    expect(renderer.create(el).toJSON()).toMatchSnapshot();
  });

  it('06 renders attachments correctly', () => {
    const attachment = serialize({ a: 3, b: false, c: true, d: undefined, e: 'foo', f: Buffer.from([1, 2, 3]), g: { g1: { g2: 4 } }, h: null, i: new Date(0) });
    const errorMsg = {
      __SB_TYPE__: 'ERROR',
      name: 'CustomError',
      message: 'An error occurred!',
      stack: 'This should be the error stack',
    };
    let cnt = 1;
    const log = (props) => buildLogRecord(merge({
      id: `id${cnt++}`,
      msg: 'Placeholder',
      level: 30,
      obj: null,
      objExpanded: false,
      objLevel: 30,
      objIsError: false,
    }, props));
    const mainStory = setIn(EMPTY_MAIN_STORY, ['records', 0, 'records'], [
      log({ msg: 'Collapsed attachment', obj: attachment }),
      log({ msg: 'Expanded attachment', obj: attachment, objExpanded: true }),
      log({ msg: 'Collapsed error message', obj: errorMsg, objLevel: 50, objIsError: true }),
      log({ msg: 'Expanded error message', obj: errorMsg, objExpanded: true, objLevel: 50, objIsError: true }),
    ]);
    const el = renderMainStory({ story: mainStory });
    expect(renderer.create(el).toJSON()).toMatchSnapshot();
  });

  it('07 renders repetitions correctly', () => {
    const mainStory = setIn(EMPTY_MAIN_STORY, ['records', 0, 'records'], [
      buildLogRecord({ id: 'id1', msg: 'msg 1', repetitions: 52, tLastRepetition: 3000 }),
    ]);
    let el;
    el = renderMainStory({ story: mainStory });
    expect(renderer.create(el).toJSON()).toMatchSnapshot();
    el = renderMainStory({ story: mainStory, timeType: 'UTC' });
    expect(renderer.create(el).toJSON()).toMatchSnapshot();
  });

  describe('08 hierarchical stories', () => {
    let mainStory;
    beforeEach(() => {
      const storyA11 = buildStory({
        id: 'a11',
        storyId: 'a11',
        title: `Story ${chalk.cyan.bold('A11')}`,
        t: 1700,
        src: 'one',
        records: [
          buildLogRecord({ id: 'id1a', msg: 'foo1', t: 1801 }),
          buildLogRecord({ id: 'id2a', msg: 'Message at the END in flat mode', t: 3500 }),
        ],
      });
      const storyA1 = buildStory({
        id: 'a1',
        storyId: 'a1',
        title: `Story ${chalk.cyan.bold('A1')}`,
        t: 1500,
        src: 'one',
        fHasWarning: true,
        records: [
          buildLogRecord({ id: 'id1b', level: 40, msg: 'Warning, warning!!', t: 1510 }),
          storyA11,
          buildLogRecord({ id: 'id2b', level: 20, msg: 'A debug message', t: 1910 }),
        ],
      });
      const storyA = buildStory({
        id: 'a',
        storyId: 'a',
        title: `Story ${chalk.cyan.bold('A')} is still open`,
        t: 1000,
        fOpen: true,
        src: 'one',
        level: 30,
        fHasWarning: true,
        fHasError: true,
        records: [
          buildLogRecord({ id: 'id1c', msg: 'message1', t: 1005 }),
          buildLogRecord({ id: 'id2c', level: 50, msg: 'Error, error!!', t: 1010 }),
          storyA1,
          buildLogRecord({ id: 'id3c', msg: 'message2', t: 1800 }),
        ],
      });
      mainStory = setIn(EMPTY_MAIN_STORY, ['records', 0, 'records'], [
        buildLogRecord({ id: 'id1d', msg: 'Top-level message 1', t: 0 }),
        storyA,
        buildLogRecord({ id: 'id2d', msg: 'Top-level message 2', t: 2000 }),
        buildLogRecord({ id: 'id3d', msg: 'Top-level message 3', t: 3000 }),
      ]);
    });

    it('01 renders collapse/expand correctly', () => {
      let el;
      el = renderMainStory({ story: mainStory });
      expect(renderer.create(el).toJSON()).toMatchSnapshot();
      mainStory.records[0].records[1].records[3].records[2].fExpanded = false;
      el = renderMainStory({ story: mainStory });
      expect(renderer.create(el).toJSON()).toMatchSnapshot();
      mainStory.records[0].records[1].records[3].fExpanded = false;
      el = renderMainStory({ story: mainStory });
      expect(renderer.create(el).toJSON()).toMatchSnapshot();
      mainStory.records[0].records[1].fExpanded = false;
      el = renderMainStory({ story: mainStory });
      expect(renderer.create(el).toJSON()).toMatchSnapshot();
    });

    it('02 renders flat/hierarchical correctly', () => {
      let el;
      el = renderMainStory({ story: mainStory });
      expect(renderer.create(el).toJSON()).toMatchSnapshot();
      mainStory.records[0].records[1].records[3].records[2].fHierarchical = false;
      el = renderMainStory({ story: mainStory });
      expect(renderer.create(el).toJSON()).toMatchSnapshot();
      mainStory.records[0].records[1].records[3].fHierarchical = false;
      el = renderMainStory({ story: mainStory });
      expect(renderer.create(el).toJSON()).toMatchSnapshot();
      mainStory.records[0].records[1].fHierarchical = false;
      el = renderMainStory({ story: mainStory });
      expect(renderer.create(el).toJSON()).toMatchSnapshot();
      mainStory.records[0].fHierarchical = false;
      el = renderMainStory({ story: mainStory });
      expect(renderer.create(el).toJSON()).toMatchSnapshot();
    });

    it('03 renders quick-find correctly', () => {
      const el = renderMainStory({ story: mainStory, quickFind: '(message)' });
      expect(renderer.create(el).toJSON()).toMatchSnapshot();
    });

    it('04 renders closed actions correctly', () => {
      const el = renderMainStory({ story: mainStory, fShowClosedActions: true });
      expect(renderer.create(el).toJSON()).toMatchSnapshot();
    });

    it('05 renders with dark backgrounds correctly', () => {
      const el = renderMainStory({ story: mainStory, colors: DARK_COLORS });
      expect(renderer.create(el).toJSON()).toMatchSnapshot();
    });
  });
});
