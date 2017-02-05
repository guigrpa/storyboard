import { merge, set as timmSet } from 'timm';
import tinycolor from 'tinycolor2';
import { isDark } from 'giu';

const calcFgColorForBgColor = (bg) => (isDark(bg) ? 'white' : 'black');
const calcFgColorForUiBgColor = (bg) => (
  isDark(bg)
  ? tinycolor('white').darken(25).toRgbString()
  : tinycolor('black').lighten(25).toRgbString()
);

// in-place
/* eslint-disable no-param-reassign */
const addDerivedColorState = (state) => {
  state.colorClientFg = calcFgColorForBgColor(state.colorClientBg);
  state.colorServerFg = calcFgColorForBgColor(state.colorServerBg);
  state.colorUiFg = calcFgColorForUiBgColor(state.colorUiBg);
  state.colorClientBgIsDark = isDark(state.colorClientBg);
  state.colorServerBgIsDark = isDark(state.colorServerBg);
  state.colorUiBgIsDark = isDark(state.colorUiBg);
  return state;
};
/* eslint-enable no-param-reassign */

const INITIAL_STATE = {
  timeType: 'LOCAL',
  fShowClosedActions: false,
  fShorthandForDuplicates: true,
  fCollapseAllNewStories: false,
  fExpandAllNewAttachments: false,
  fDiscardRemoteClientLogs: false,
  maxRecords: 800,
  forgetHysteresis: 0.25,
  colorClientBg: 'aliceblue',  // lemonchiffon is also nice
  colorServerBg: tinycolor('aliceblue').darken(5).toRgbString(),
  colorUiBg: 'white',
};
addDerivedColorState(INITIAL_STATE);

const reducer = (state = INITIAL_STATE, action) => {
  let nextState = state;
  switch (action.type) {
    case 'UPDATE_SETTINGS':
      nextState = merge(nextState, action.settings);
      if (nextState !== state) addDerivedColorState(nextState);
      if (!(nextState.maxRecords > 0)) {
        nextState = timmSet(nextState, 'maxRecords', INITIAL_STATE.maxRecords);
      }
      return nextState;
    default:
      return nextState;
  }
};

export default reducer;
export { INITIAL_STATE as DEFAULT_SETTINGS };
