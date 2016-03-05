module.exports = 
  IS_BROWSER: window?
  LEVEL_NUM_TO_STR:
    10: 'TRACE'
    20: 'DEBUG'
    30: 'INFO'
    40: 'WARN'
    50: 'ERROR'
    60: 'FATAL'
  LEVEL_STR_TO_NUM:
    TRACE: 10
    DEBUG: 20
    INFO: 30
    WARN: 40
    ERROR: 50
    FATAL: 60

  # Filters
  FILTER_KEY: 'STORYBOARD'
  DEFAULT_FILTER: '*:DEBUG'
