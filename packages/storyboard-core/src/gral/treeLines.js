import chalk from 'chalk';
import * as _ from '../vendor/lodash';
import { CIRCULAR_REF } from './serialize';

const WRAPPER_KEY = '__SB_WRAPPER__';
const BUFFER_EXPLICIT_LIMIT = 40;

const isBuffer = (val) => val instanceof Buffer;

const tree = (node, options, prefix, stack) =>  {
  let out = [];
  const { ignoreKeys = [] } = options;
  stack.push(node);
  const postponedArrayAttrs = [];
  const postponedObjectAttrs = [];
  const keys = Object.keys(node);
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    const val = node[key];
    if (ignoreKeys.indexOf(key) >= 0) {
      continue;
    }
    const finalPrefix = key === WRAPPER_KEY ? prefix : `${prefix}${key}: `;
    if (
      (_.isObject(val) && stack.indexOf(val) >= 0) ||  // Avoid circular dependencies
      val === CIRCULAR_REF
    ) {
      out.push(finalPrefix + chalk.green.bold('[CIRCULAR]'));
    } else if (Array.isArray(val) && val.length === 0) {
      out.push(finalPrefix + chalk.bold('[]'));
    } else if (Array.isArray(val) && val.length && _.isString(val[0])) {
      let strVal = _.map(val, (o) => `'${o}'`).join(', ');
      strVal = chalk.yellow.bold(`[${strVal}]`);
      out.push(finalPrefix + strVal);
    } else if (_.isDate(val)) {
      out.push(finalPrefix + chalk.magenta.bold(val.toISOString()));
    } else if (isBuffer(val)) {
      let str = val.slice(0, BUFFER_EXPLICIT_LIMIT)
        .toString('hex')
        .toUpperCase()
        .match(/(..)/g)
        .join(' ');
      if (val.length > BUFFER_EXPLICIT_LIMIT) str += '...';
      str = `Buffer [${val.length}]: ${str}`;
      out.push(finalPrefix + chalk.magenta.bold(str));
    } else if (_.isObject(val) && Object.keys(val).length === 0) {
      out.push(finalPrefix + chalk.bold('{}'));
    } else if (Array.isArray(val)) {
      postponedArrayAttrs.push(key);
    } else if (_.isObject(val)) {
      postponedObjectAttrs.push(key);
    } else if (_.isString(val)) {
      const lines = val.split('\n');
      if (lines.length === 1) {
        out.push(finalPrefix + chalk.yellow.bold(`'${val}'`));
      } else {
        for (let m = 0, len = lines.length; m < len; m++) {
          const line = lines[m];
          out.push(finalPrefix + chalk.yellow.bold(line));
        }
      }
    } else if (val === null) {
      out.push(finalPrefix + chalk.red.bold('null'));
    } else if (val === undefined) {
      out.push(finalPrefix + chalk.bgRed.bold('undefined'));
    } else if ((val === true) || (val === false)) {
      out.push(finalPrefix + chalk.cyan.bold(val));
    } else if (_.isNumber(val)) {
      out.push(finalPrefix + chalk.blue.bold(val));
    } else {
      /* istanbul ignore next */
      out.push(finalPrefix + chalk.bold(val));
    }
  }
  for (let j = 0; j < postponedObjectAttrs.length; j++) {
    const key = postponedObjectAttrs[j];
    const val = node[key];
    out.push(`${prefix}${key}:`);
    out = out.concat(tree(val, options, options.indenter + prefix, stack));
  }
  for (let k = 0; k < postponedArrayAttrs.length; k++) {
    const key = postponedArrayAttrs[k];
    const val = node[key];
    out.push(`${prefix}${key}:`);
    out = out.concat(tree(val, options, options.indenter + prefix, stack));
  }
  stack.pop();
  return out;
};

const treeLines = (obj0, options0 = {}) => {
  const options = options0;
  if (options.indenter == null) options.indenter = '  ';
  const prefix = options.prefix || '';
  let obj = obj0;
  if (_.isError(obj)) {
    obj = _.pick(obj, ['name', 'message', 'stack']);
  } else if ((!_.isObject(obj)) || isBuffer(obj)) {
    obj = { [WRAPPER_KEY]: obj };
  }
  return tree(obj, options, prefix, []);
};

/* eslint-disable no-console */
treeLines.log = (...args) => {
  const lines = treeLines(...args);
  for (let i = 0, len = lines.length; i < len; i++) {
    const line = lines[i];
    console.log(line);
  }
};
/* eslint-enable no-console */

export default treeLines;
