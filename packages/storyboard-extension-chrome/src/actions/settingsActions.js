import { merge } from 'timm';
import {
  setLocalStorageNamespace,
  localGet,
  localSet,
} from 'giu';

setLocalStorageNamespace('storyboard');

// =============================================
// Actions
// =============================================
const loadSettings = () => (dispatch) => {
  const settings = localGet('settings');
  if (settings != null) dispatch(updateSettings(settings));
};

const updateSettings = (settings) => {
  const prevSettings = localGet('settings') || {};
  const nextSettings = merge(prevSettings, settings);
  localSet('settings', nextSettings);
  return { type: 'UPDATE_SETTINGS', settings };
};

const setTimeType = (timeType) => ({ type: 'UPDATE_SETTINGS', settings: { timeType } });

export {
  loadSettings,
  updateSettings,
  setTimeType,
};
