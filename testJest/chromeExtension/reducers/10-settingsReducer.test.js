/* eslint-env jest */
import reducer from '../../../lib/chromeExtension/reducers/settingsReducer';

describe('settingsReducer', () => {
  it('01 should update settings with new values', () => {
    let state = reducer(undefined, { type: '' });
    expect(state).toMatchSnapshot();
    state = reducer(state, {
      type: 'UPDATE_SETTINGS',
      settings: {
        maxRecords: 2e3,
        forgetHysteresis: 0.5,
      },
    });
    expect(state).toMatchSnapshot();
  });

  it('02 should not allow invalid maxRecords', () => {
    let state = reducer(undefined, { type: '' });
    state = reducer(state, {
      type: 'UPDATE_SETTINGS',
      settings: {
        maxRecords: -25,
      },
    });
    expect(state.maxRecords >= 0).toBeTruthy();
  });
});
