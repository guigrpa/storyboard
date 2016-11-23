/* eslint-env jest */
/* eslint-disable global-require, import/newline-after-import */
import React from 'react';
import renderer from 'react-test-renderer';
import { Floats } from 'giu';
import { _Settings as Settings } from '../../../lib/chromeExtension/components/016-settings';
import { BASE_COLORS } from './fixtures';

jest.mock('react-dom');

describe('Settings', () => {
  it('renders correctly', () => {
    const settings = {
      colorClientBg: 'aliceblue',
      colorClientBgIsDark: false,
      colorClientFg: 'black',
      colorServerBg: 'rgb(214, 236, 255)',
      colorServerBgIsDark: false,
      colorServerFg: 'black',
      colorUiBg: 'white',
      colorUiBgIsDark: false,
      colorUiFg: 'rgb(64, 64, 64)',
      fCollapseAllNewStories: false,
      fDiscardRemoteClientLogs: false,
      fExpandAllNewAttachments: false,
      fShorthandForDuplicates: true,
      fShowClosedActions: false,
      forgetHysteresis: 0.25,
      maxRecords: 800,
      timeType: 'LOCAL',
    };
    const tree = renderer.create(
      <div>
        <Floats />
        <Settings
          onClose={() => {}}
          colors={BASE_COLORS}
          settings={settings}
          serverFilter="*:INFO"
          localClientFilter="*:DEBUG"
          updateSettings={() => {}}
          setServerFilter={() => {}}
          setLocalClientFilter={() => {}}
        />
      </div>
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });
});
