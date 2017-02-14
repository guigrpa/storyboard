// A convenience initialiser for the most common case of all: just a console!

/* eslint-disable no-console, global-require */

const consoleListener = require('storyboard-listener-console').default;

let storyboard;
try {
  storyboard = require('storyboard');
  storyboard.addListener(consoleListener);
} catch (err) {
  console.error('Please add storyboard to your project: `npm install storyboard --save`');
}
