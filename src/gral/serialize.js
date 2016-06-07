import { isObject, cloneDeep } from '../vendor/lodash';

const CIRCULAR_REF = '[[CIRCULAR]]';

const removeCycles = (obj, stack, visited) => {
  if (!isObject(obj)) return obj;
  if (stack.indexOf(obj) >= 0) return CIRCULAR_REF
  if (visited.indexOf(obj) >= 0) return obj;
  stack.push(obj);
  visited.push(obj);
  Object.keys(obj).forEach(key => {
    obj[key] = removeCycles(obj[key], stack, visited);
  });
  stack.pop();
  return obj;
}

const serialize = obj => {
  if (!isObject(obj)) return obj;
  let out = cloneDeep(obj);
  out = removeCycles(out, [], []);
  return out;
}

export {
  serialize,
  CIRCULAR_REF,
};
