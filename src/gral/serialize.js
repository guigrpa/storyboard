import {
  isObject,
  cloneDeep,
} from '../vendor/lodash';

const CIRCULAR_PLACEHOLDER = '__CIRCULAR__';

const removeCycles = (obj) => {
  return obj;
}

const serialize = (obj) => {
  if (!isObject(obj)) return obj;
  let out = cloneDeep(obj);
  out = removeCycles(out);
  return out;
}

export {
  serialize,
  CIRCULAR_PLACEHOLDER,
};
