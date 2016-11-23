import { addDefaults } from 'timm';
import isObject from 'lodash/isObject';
import isFunction from 'lodash/isFunction';
import isString from 'lodash/isString';

const $ = (root, options0, fnMatch0) => {
  let options = options0;
  let fnMatch = fnMatch0;
  if (isFunction(options0) || isString(options0)) {
    options = {};
    fnMatch = options0;
  }
  options = addDefaults(options, {
    fIncludeTextElements: false,
    fLog: false,
  });
  if (isString(fnMatch)) fnMatch = getMatcher(fnMatch);
  return visitElement(root, options, fnMatch);
};

const getMatcher = (selector0) => {
  const selector = selector0.trim();
  let out;
  if (selector[0] === '.') {
    const className = selector.slice(1);
    out = (el) => el.props.className && el.props.className.indexOf(className) >= 0;
  } else if (selector[0] === '#') {
    const id = selector.slice(1);
    out = (el) => el.props.id && String(el.props.id) === id;
  } else {
    out = (el) => el.type === selector;
  }
  return out;
};

const visitElement = (tree, options, fnMatch) => {
  if (isObject(tree) || options.fIncludeTextElements) {
    // eslint-disable-next-line
    if (options.fLog) console.log(tree);
    if (fnMatch(tree)) return tree;
  }
  const { children } = tree;
  if (!children) return null;
  for (let i = 0; i < children.length; i++) {
    const foundDescendant = visitElement(children[i], options, fnMatch);
    if (foundDescendant) return foundDescendant;
  }
  return null;
};

export default $;
