import { set as timmSet } from 'timm';
import settings from './settingsReducer';
import cx from './cxReducer';
import stories from './storiesReducer';

const reducer = (state0 = {}, action) => {
  let state = state0;
  state = timmSet(state, 'settings', settings(state.settings, action));
  state = timmSet(state, 'cx', cx(state.cx, action));
  state = timmSet(state, 'stories', stories(state.stories, action, state.settings));
  return state;
};

export default reducer;
