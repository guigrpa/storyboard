import { omit } from 'timm';
import { isObject, isError } from '../vendor/lodash';

const CIRCULAR_REF = '__SB_CIRCULAR__';
const STORYBOARD_TYPE_ATTR = '__SB_TYPE__';

// -------------------------------------
// Main
// -------------------------------------
const serialize = (obj) => doSerialize(obj, []);
const deserialize = (obj) => doDeserialize(obj);

// -------------------------------------
// Helpers
// -------------------------------------
const doSerialize = (obj, stack) => {
  if (obj === undefined) return { [STORYBOARD_TYPE_ATTR]: 'UNDEFINED' };
  if (!isObject(obj)) return obj;

  // Handle circular references (using `stack`)
  if (stack.indexOf(obj) >= 0) return CIRCULAR_REF;
  stack.push(obj);
  let out;

  // Handle special cases
  if (isError(obj)) {
    const { name, message, stack: errorStack } = obj;
    out = {
      [STORYBOARD_TYPE_ATTR]: 'ERROR',
      name, message, stack: errorStack,
    };
  } else if (obj instanceof Date) {
    out = new Date(obj);
  } else if (obj instanceof Buffer) {
    out = {
      [STORYBOARD_TYPE_ATTR]: 'BUFFER',
      data: Array.from(obj),
    };

  // Handle arrays
  } else if (Array.isArray(obj)) {
    out = obj.map((el) => doSerialize(el, stack));

  // Handle objects
  } else {
    out = {};
    Object.keys(obj).forEach((key) => {
      out[key] = doSerialize(obj[key], stack);
    });
  }
  stack.pop();
  return out;
};

const doDeserialize = (obj) => {
  if (!isObject(obj)) return obj;
  let out;
  if (Array.isArray(obj)) {
    out = obj.map((el) => doDeserialize(el));
  } else if (obj instanceof Date) {
    out = new Date(obj);
  } else {
    switch (obj[STORYBOARD_TYPE_ATTR]) {
      case 'UNDEFINED':
        out = undefined;
        break;
      case 'ERROR':
        out = omit(obj, STORYBOARD_TYPE_ATTR);
        break;
      case 'BUFFER':
        out = Buffer.from(obj.data);
        break;
      default:
        out = {};
        Object.keys(obj).forEach((key) => {
          out[key] = doDeserialize(obj[key]);
        });
        break;
    }
  }
  return out;
};

// -------------------------------------
// API
// -------------------------------------
export {
  serialize, deserialize,
  CIRCULAR_REF,
  STORYBOARD_TYPE_ATTR,
};
