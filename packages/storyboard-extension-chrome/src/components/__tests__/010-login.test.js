/* eslint-env jest */
/* eslint-disable no-extend-native, react/jsx-no-duplicate-props */
import React from 'react';
import renderer from 'react-test-renderer';
import { Floats } from 'giu';
import { _Login as Login } from '../010-login';
import { BASE_COLORS } from './fixtures';

jest.mock('react-dom');

describe('Login', () => {
  it('renders correctly when login needs are still unknown', () => {
    const tree = renderer.create(
      <Login
        colors={BASE_COLORS}
        loginState="LOGGED_OUT"
        logIn={() => {}}
        logOut={() => {}}
      />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('renders correctly when no login is required', () => {
    const tree = renderer.create(
      <Login
        colors={BASE_COLORS}
        fLoginRequired={false}
        loginState="LOGGED_OUT"
        logIn={() => {}}
        logOut={() => {}}
      />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('renders correctly when LOGGED_IN', () => {
    const tree = renderer.create(
      <Login
        colors={BASE_COLORS}
        fLoginRequired
        loginState="LOGGED_IN"
        login="Guille"
        logIn={() => {}}
        logOut={() => {}}
      />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('renders correctly when LOGGED_OUT', () => {
    const tree = renderer.create(
      <div>
        <Floats />
        <Login
          colors={BASE_COLORS}
          fLoginRequired
          loginState="LOGGED_OUT"
          logIn={() => {}}
          logOut={() => {}}
        />
      </div>
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('renders correctly when LOGGING_IN', () => {
    const tree = renderer.create(
      <div>
        <Floats />
        <Login
          colors={BASE_COLORS}
          fLoginRequired
          loginState="LOGGING_IN"
          logIn={() => {}}
          logOut={() => {}}
        />
      </div>
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });
});
