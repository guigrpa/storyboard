/* eslint-env jest */
/* eslint-disable global-require, import/newline-after-import */
import React from 'react';
import renderer from 'react-test-renderer';
import { _Story as Story } from '../../../lib/chromeExtension/components/020-story';
import { BASE_COLORS, EMPTY_MAIN_STORY } from './fixtures';
import $ from './jestQuery';

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
});
