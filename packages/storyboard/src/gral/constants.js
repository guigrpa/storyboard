/* eslint-disable no-undef */
export const IS_BROWSER = (typeof window !== 'undefined' && window !== null) ||
  (process.env.TEST_BROWSER != null);
  /* eslint-enable no-undef */
export const LEVEL_NUM_TO_STR = {
  10: 'TRACE',
  20: 'DEBUG',
  30: 'INFO',
  40: 'WARN',
  50: 'ERROR',
  60: 'FATAL',
};
export const LEVEL_STR_TO_NUM = {
  TRACE: 10,
  DEBUG: 20,
  INFO: 30,
  WARN: 40,
  ERROR: 50,
  FATAL: 60,
};

// WebSockets
export const WS_NAMESPACE = '/STORYBOARD';

// Filters
export const FILTER_KEY = 'STORYBOARD';
export const DEFAULT_FILTER = '*:DEBUG';
