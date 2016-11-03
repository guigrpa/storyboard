/* eslint-env jest */
/* eslint-disable no-extend-native */
import reducer from '../../../lib/chromeExtension/reducers/appReducer';

describe('appReducer', () => {
  it('should have correct initial state', () => {
    Date.prototype.getTime = jest.genMockFunction().mockReturnValue(0);
    const state = reducer(undefined, { type: '' });
    expect(state).toMatchSnapshot();
  });

  it('should process a simple action', () => {
    let state = reducer(undefined, { type: '' });
    state = reducer(state, { type: 'CX_CONNECTED' });
    expect(state.cx.cxState).toBe('CONNECTED');
  });
});
