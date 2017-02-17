/* eslint-env jest */
/* eslint-disable no-extend-native, global-require */
import React from 'react';
import renderer from 'react-test-renderer';
import { _App as App } from '../005-app';
import { BASE_COLORS } from './fixtures';

jest.mock('react-dom');
jest.mock('../015-toolbar', () => require('./mockComponent')('Toolbar'));
jest.mock('../020-story', () => require('./mockComponent')('Story'));

describe('App', () => {
  it('renders correctly when disconnected', () => {
    const tree = renderer.create(
      <App
        fRelativeTime={false}
        cxState="DISCONNECTED"
        mainStory={{ placeholderFor: 'mainStory' }}
        colors={BASE_COLORS}
      />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('renders correctly when connected', () => {
    const tree = renderer.create(
      <App
        fRelativeTime={false}
        cxState="CONNECTED"
        mainStory={{ placeholderFor: 'mainStory' }}
        colors={BASE_COLORS}
      />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });
});
