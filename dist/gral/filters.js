(function() {
  var _cachedThreshold, _calcThreshold, _excluded, _getFilter, _included, _init, config, k, passesFilter;

  k = require('./constants');

  _included = null;

  _excluded = null;

  _cachedThreshold = null;

  _init = function() {
    var filter, i, len, level, ref, ref1, results, spec, specs, src;
    _included = [];
    _excluded = [];
    _cachedThreshold = {};
    filter = _getFilter();
    if (!filter.length) {
      return;
    }
    specs = filter.split(/[\s,]+/);
    results = [];
    for (i = 0, len = specs.length; i < len; i++) {
      spec = specs[i];
      if (!spec.length) {
        continue;
      }
      ref = spec.split(':'), src = ref[0], level = ref[1];
      src = src.replace(/\*/g, '.*?');
      if (src[0] === '-') {
        results.push(_excluded.push({
          re: new RegExp("^" + (src.substr(1)) + "$")
        }));
      } else {
        if (level === '*') {
          level = 'TRACE';
        }
        level = (ref1 = k.LEVEL_STR_TO_NUM[level]) != null ? ref1 : k.LEVEL_STR_TO_NUM.DEBUG;
        results.push(_included.push({
          re: new RegExp("^" + src + "$"),
          threshold: level
        }));
      }
    }
    return results;
  };

  _getFilter = function() {
    var _filter, store;
    store = k.IS_BROWSER ? localStorage : process.env;
    _filter = store[k.FILTER_KEY];
    if ((_filter == null) || (!_filter.length)) {
      _filter = k.DEFAULT_FILTER;
    }
    return _filter;
  };

  config = function(filter) {
    var store;
    store = k.IS_BROWSER ? localStorage : process.env;
    store[k.FILTER_KEY] = filter;
    return _init();
  };

  _calcThreshold = function(src) {
    var excluded, i, included, j, len, len1;
    for (i = 0, len = _excluded.length; i < len; i++) {
      excluded = _excluded[i];
      if (excluded.re.test(src)) {
        return null;
      }
    }
    for (j = 0, len1 = _included.length; j < len1; j++) {
      included = _included[j];
      if (included.re.test(src)) {
        return included.threshold;
      }
    }
    return null;
  };

  passesFilter = function(src, level) {
    var thresh;
    thresh = _cachedThreshold[src] != null ? _cachedThreshold[src] : _cachedThreshold[src] = _calcThreshold(src);
    return (thresh != null) && (level >= thresh);
  };

  _init();

  module.exports = {
    config: config,
    passesFilter: passesFilter
  };

}).call(this);
