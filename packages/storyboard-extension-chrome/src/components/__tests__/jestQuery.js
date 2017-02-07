import { addDefaults } from 'timm';
import { _ } from 'storyboard-core';

const $ = (root, options0, fnMatch0) => {
  let options = options0;
  let fnMatch = fnMatch0;
  if (_.isFunction(options0) || _.isString(options0)) {
    options = {};
    fnMatch = options0;
  }
  options = addDefaults(options, {
    fIncludeTextElements: false,
    fLog: false,
  });
  if (_.isString(fnMatch)) fnMatch = getMatcher(fnMatch);
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
  if (_.isObject(tree) || options.fIncludeTextElements) {
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
