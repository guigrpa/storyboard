k = require './constants'

_included = null
_excluded = null
_cachedThreshold = null

_init = ->
  _included = []
  _excluded = []
  _cachedThreshold = {}
  filter = getConfig()
  specs = filter.split /[\s,]+/
  for spec in specs
    continue if not spec.length
    [src, level] = spec.split ':'
    src = src.replace /\*/g, '.*?'
    if src[0] is '-'
      _excluded.push {re: new RegExp("^#{src.substr 1}$")}
    else
      if level is '*' then level = 'TRACE'
      level = k.LEVEL_STR_TO_NUM[level] ? k.LEVEL_STR_TO_NUM.DEBUG
      _included.push {re: new RegExp("^#{src}$"), threshold: level}

getConfig = ->
  store = window?.localStorage ? process.env
  _filter = store[k.FILTER_KEY]
  if (not _filter?) or (not _filter.length)
    _filter = k.DEFAULT_FILTER
  _filter

config = (filter) ->
  store = window?.localStorage ? process.env
  store[k.FILTER_KEY] = filter || ''
  _cachedThreshold = null
  _init()

_calcThreshold = (src) ->
  for excluded in _excluded
    return null if excluded.re.test src
  for included in _included
    return included.threshold if included.re.test src
  return null

passesFilter = (src, level) ->
  thresh = _cachedThreshold[src] ?= _calcThreshold src
  return thresh? and (level >= thresh)

_init()

module.exports = {
  config,
  getConfig,
  passesFilter,
}
