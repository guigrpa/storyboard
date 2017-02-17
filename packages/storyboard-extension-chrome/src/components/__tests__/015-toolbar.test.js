/* eslint-env jest */
/* eslint-disable global-require, import/newline-after-import */
import React from 'react';
import renderer from 'react-test-renderer';
import { _Toolbar as Toolbar } from '../015-toolbar';
import { BASE_COLORS } from './fixtures';
import $ from './jestQuery';

jest.mock('react-dom');
jest.mock('../010-login', () => require('./mockComponent')('Login'));
jest.mock('../016-settings', () => require('./mockComponent')('Settings'));

describe('Toolbar', () => {
  it('renders correctly when disconnected', () => {
    const tree = renderer.create(
      <Toolbar
        colors={BASE_COLORS}
        wsState="DISCONNECTED"
        expandAllStories={() => {}}
        collapseAllStories={() => {}}
      />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('renders correctly when connected', () => {
    const tree = renderer.create(
      <Toolbar
        colors={BASE_COLORS}
        wsState="CONNECTED"
        expandAllStories={() => {}}
        collapseAllStories={() => {}}
      />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('shows settings when the corresponding icon is clicked', () => {
    const component = renderer.create(
      <Toolbar
        colors={BASE_COLORS}
        wsState="CONNECTED"
        expandAllStories={() => {}}
        collapseAllStories={() => {}}
      />
    );
    let tree = component.toJSON();
    const showSettingsBtn = $(tree, '#sbBtnShowSettings');
    expect(showSettingsBtn).not.toBeNull();
    showSettingsBtn.props.onClick();
    tree = component.toJSON();
    expect(tree).toMatchSnapshot();
  });
});
