/* eslint-env jest */
import reducer from '../../../lib/chromeExtension/reducers/cxReducer';

describe('cxReducer', () => {
  let state;
  beforeEach(() => {
    state = reducer(undefined, { type: '' });
  });

  it('01 should have correct initial state', () => {
    expect(state).toMatchSnapshot();
  });

  describe('02 DevTools <-> WsClient cx state', () => {
    it('01 should process CX_CONNECTED', () => {
      state = reducer(state, { type: 'CX_CONNECTED' });
      expect(state).toMatchSnapshot();
    });

    it('02 should process CX_DISCONNECTED', () => {
      state = reducer(state, { type: 'CX_CONNECTED' });
      state = reducer(state, { type: 'CX_DISCONNECTED' });
      expect(state).toMatchSnapshot();
    });
  });

  describe('03 WsClient <-> WsServer cx state', () => {
    it('01 should process WS_CONNECTED', () => {
      state = reducer(state, { type: 'WS_CONNECTED' });
      expect(state).toMatchSnapshot();
    });

    it('02 should process CX_DISCONNECTED', () => {
      state = reducer(state, { type: 'WS_CONNECTED' });
      state = reducer(state, { type: 'WS_DISCONNECTED' });
      expect(state).toMatchSnapshot();
    });
  });

  describe('04 login state', () => {
    it('01 should process LOGIN_REQUIRED (false)', () => {
      state = reducer(state, { type: 'LOGIN_REQUIRED', fLoginRequired: false });
      expect(state).toMatchSnapshot();
    });

    it('02 should process LOGIN_REQUIRED (true)', () => {
      state = reducer(state, { type: 'LOGIN_REQUIRED', fLoginRequired: true });
      expect(state).toMatchSnapshot();
    });

    it('03 should process LOGIN_STARTED', () => {
      state = reducer(state, { type: 'LOGIN_STARTED' });
      expect(state).toMatchSnapshot();
    });

    it('04 should process LOGIN_SUCCEEDED', () => {
      state = reducer(state, { type: 'LOGIN_SUCCEEDED', login: 'John' });
      expect(state).toMatchSnapshot();
    });

    it('05 should process LOGGED_OUT', () => {
      state = reducer(state, { type: 'LOGIN_SUCCEEDED', login: 'John' });
      state = reducer(state, { type: 'LOGGED_OUT' });
      expect(state).toMatchSnapshot();
    });
  });

  describe('05 filters', () => {
    it('01 should process SERVER_FILTER', () => {
      state = reducer(state, { type: 'SERVER_FILTER', filter: 'abcd:*' });
      expect(state).toMatchSnapshot();
    });

    it('02 should process LOCAL_CLIENT_FILTER', () => {
      state = reducer(state, { type: 'LOCAL_CLIENT_FILTER', filter: 'dcba:*' });
      expect(state).toMatchSnapshot();
    });
  });
});
