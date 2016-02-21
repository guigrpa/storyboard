IS_BROWSER = typeof window isnt 'undefined'
LEVEL_NUM_TO_STR = 
  5:  'STORY'
  10: 'TRACE'
  20: 'DEBUG'
  30: 'INFO'
  40: 'WARN'
  50: 'ERROR'
  60: 'FATAL'
LEVEL_STR_TO_NUM =
  STORY: 5
  TRACE: 10
  DEBUG: 20
  INFO: 30
  WARN: 40
  ERROR: 50
  FATAL: 60

module.exports = {
  IS_BROWSER,
  LEVEL_NUM_TO_STR,
  LEVEL_STR_TO_NUM,
}