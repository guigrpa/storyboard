'use strict';

require('coffee-script/register');
const storyboard = require('../src/storyboard');
const mainStory = storyboard.mainStory;

mainStory.info('Launched');

let cnt = 0;

process.on('SIGINT', function (){
  cnt++;
  console.log('Cnt: ' + cnt);
  if (cnt >= 3) process.exit();
  return true;
});

setInterval(function (){
  mainStory.debug('Interval ellapsed');
}, 5000);
