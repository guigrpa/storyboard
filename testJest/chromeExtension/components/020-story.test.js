/* eslint-env jest */
/* eslint-disable global-require, import/newline-after-import */
import React from 'react';
import renderer from 'react-test-renderer';
import chalk from 'chalk';
import { setIn } from 'timm';
import { _Story as Story } from '../../../lib/chromeExtension/components/020-story';
import { BASE_COLORS, EMPTY_MAIN_STORY, buildLogRecord } from './fixtures';

jest.mock('react-dom');

describe('Story', () => {
  it('01 renders correctly an empty main story', () => {
    const tree = renderer.create(
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
      />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('02 renders correctly server and client records (root level)', () => {
    const mainStory = setIn(EMPTY_MAIN_STORY, ['records', 0, 'records'], [
      buildLogRecord({ id: 'id1', msg: 'msg 1' }),
      buildLogRecord({ id: 'id2', msg: chalk.yellow('msg 2') }),
    ]);
    const tree = renderer.create(
      <Story
        story={mainStory}
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
      />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });
});
