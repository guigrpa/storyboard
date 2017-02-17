/*!
 * Storyboard Chrome DevTools Extension
 * (c) Guillermo Grau Panea 2016
 * License: MIT
 */

/* eslint-env browser */
/* eslint-disable global-require, no-console */

import React from 'react';
import ReactDOM from 'react-dom';
import { chalk } from 'storyboard-core';
import initActions, * as actions from './actions/actions';
import createStore from './store/createStore';
import RootComponent from './components/000-root';

require('babel-polyfill');  /* from root packages */ // eslint-disable-line

if (process.env.NODE_ENV !== 'production') {
  window.ReactPerf = require('react-addons-perf');  // eslint-disable-line import/newline-after-import
  window.chalk = chalk;
}

// =======================================
// Internal
// =======================================
let store = null;

// =======================================
// Initialisation
// =======================================
const init = ({ sendMsg }) => {
  if (sendMsg == null) throw new Error('MISSING_DEPS');
  console.log('[DT] Starting up...');

  initActions({ sendMsg });

  store = createStore();
  store.dispatch(actions.loadSettings());

  // Render the app
  const RootElement = React.createElement(RootComponent, { store });
  ReactDOM.render(RootElement, document.getElementById('devToolsApp'));
};

// =======================================
// Message processing
// =======================================
const processMsg = (msg) => {
  if (store == null) return;
  store.dispatch({ type: 'MSG_RECEIVED', msg });
};

export {
  init,
  processMsg,
};
