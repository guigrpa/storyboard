(function() {
  var WRAPPER_KEY, _, _tree, chalk,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  chalk = require('chalk');

  _ = require('../vendor/lodash');

  WRAPPER_KEY = '__wrapper__';

  _tree = function(node, options, prefix, stack) {
    var finalPrefix, i, j, k, key, len, len1, len2, line, lines, out, postponedArrayAttrs, postponedObjectAttrs, strVal, val;
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
        lines = val.split('\n');
        if (lines.length === 1) {
          out.push(("" + finalPrefix) + chalk.yellow.bold("'" + val + "'"));
        } else {
          for (i = 0, len = lines.length; i < len; i++) {
            line = lines[i];
            out.push(("" + finalPrefix) + chalk.yellow.bold(line));
          }
        }
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
    for (j = 0, len1 = postponedObjectAttrs.length; j < len1; j++) {
      key = postponedObjectAttrs[j];
      val = node[key];
      out.push("" + prefix + key + ":");
      out = out.concat(_tree(val, options, "" + options.indenter + prefix, stack));
    }
    for (k = 0, len2 = postponedArrayAttrs.length; k < len2; k++) {
      key = postponedArrayAttrs[k];
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
    if (_.isError(obj)) {
      obj = _.pick(obj, ['name', 'message', 'stack']);
    } else if (!_.isObject(obj)) {
      obj = (
        obj1 = {},
        obj1["" + WRAPPER_KEY] = obj,
        obj1
      );
    }
    return _tree(obj, options, prefix, []);
  };

}).call(this);
