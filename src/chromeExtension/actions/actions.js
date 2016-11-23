import { _cxInit } from './cxActions';

const init = ({ sendMsg }) => {
  if (!sendMsg) throw new Error('MISSING_DEPS');
  _cxInit({ sendMsg });
};

export default init;
export * from './cxActions';
export * from './settingsActions';
export * from './storyActions';
