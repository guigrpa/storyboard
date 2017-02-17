/* eslint-env jest */
/* eslint-disable no-extend-native */
import reducer from '../appReducer';

describe('appReducer', () => {
  it('01 should have correct initial state', () => {
    Date.prototype.getTime = jest.genMockFunction().mockReturnValue(0);
    const state = reducer(undefined, { type: '' });
    expect(state).toMatchSnapshot();
  });

  it('02 should process a simple action', () => {
    let state = reducer(undefined, { type: '' });
    state = reducer(state, { type: 'CX_CONNECTED' });
    expect(state.cx.cxState).toBe('CONNECTED');
  });
});
