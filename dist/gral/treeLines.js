(function() {
  var WRAPPER_KEY, _, _tree, chalk,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  chalk = require('chalk');

  _ = require('../vendor/lodash');

  WRAPPER_KEY = '__wrapper__';

  _tree = function(node, options, prefix, stack) {
    var finalPrefix, i, j, key, len, len1, out, postponedArrayAttrs, postponedObjectAttrs, strVal, val;
    out = [];
    if (options.ignoreKeys == null) {
      options.ignoreKeys = [];
    }
    stack.push(node);
    postponedArrayAttrs = [];
    postponedObjectAttrs = [];
    for (key in node) {
      val = node[key];
      if (indexOf.call(options.ignoreKeys, key) >= 0) {
        continue;
      }
      finalPrefix = key === WRAPPER_KEY ? prefix : "" + prefix + key + ": ";
      if (_.isObject(val) && _.includes(stack, val)) {
        out.push("" + finalPrefix + (chalk.green.bold('[CIRCULAR]')));
      } else if (_.isArray(val) && val.length === 0) {
        out.push("" + finalPrefix + (chalk.bold('[]')));
      } else if (_.isArray(val) && val.length && _.isString(val[0])) {
        strVal = _.map(val, function(o) {
          return "'" + o + "'";
        }).join(', ');
        strVal = chalk.yellow.bold("[" + strVal + "]");
        out.push("" + finalPrefix + strVal);
      } else if (_.isDate(val)) {
        out.push("" + finalPrefix + (chalk.magenta.bold(val.toISOString())));
      } else if (_.isObject(val) && Object.keys(val).length === 0) {
        out.push("" + finalPrefix + (chalk.bold('{}')));
      } else if (_.isArray(val)) {
        postponedArrayAttrs.push(key);
      } else if (_.isObject(val)) {
        postponedObjectAttrs.push(key);
      } else if (_.isString(val)) {
        out.push(("" + finalPrefix) + chalk.yellow.bold("'" + val + "'"));
      } else if (_.isNull(val)) {
        out.push("" + finalPrefix + (chalk.red.bold('null')));
      } else if (_.isUndefined(val)) {
        out.push("" + finalPrefix + (chalk.bgRed.bold('undefined')));
      } else if (_.isBoolean(val)) {
        out.push("" + finalPrefix + (chalk.cyan.bold(val)));
      } else if (_.isNumber(val)) {
        out.push("" + finalPrefix + (chalk.blue.bold(val)));
      } else {

        /* !pragma coverage-skip-block */
        out.push("" + finalPrefix + (chalk.bold(val)));
      }
    }
    for (i = 0, len = postponedObjectAttrs.length; i < len; i++) {
      key = postponedObjectAttrs[i];
      val = node[key];
      out.push("" + prefix + key + ":");
      out = out.concat(_tree(val, options, "" + options.indenter + prefix, stack));
    }
    for (j = 0, len1 = postponedArrayAttrs.length; j < len1; j++) {
      key = postponedArrayAttrs[j];
      val = node[key];
      out.push("" + prefix + key + ":");
      out = out.concat(_tree(val, options, "" + options.indenter + prefix, stack));
    }
    stack.pop();
    return out;
  };

  module.exports = function(obj, options) {
    var obj1, prefix, ref;
    if (options == null) {
      options = {};
    }
    if (options.indenter == null) {
      options.indenter = '  ';
    }
    prefix = (ref = options.prefix) != null ? ref : '';
    if (!_.isObject(obj)) {
      obj = (
        obj1 = {},
        obj1["" + WRAPPER_KEY] = obj,
        obj1
      );
    }
    return _tree(obj, options, prefix, []);
  };

}).call(this);
