import fs from 'fs';
import { addDefaults } from 'timm';
import chalk from 'chalk';
import _ from '../vendor/lodash';
import ansiColors from '../gral/ansiColors';
import k from '../gral/constants';
import filters from '../gral/filters';
import treeLines from '../gral/treeLines';


const DEFAULT_CONFIG = {
  filePath: 'storyboard.log',
  ansiColors: false,
  moduleNameLength: 20,
};

function FileListener(config) {
  this.type = 'FILE';
  this.config = config;
  this.fd = null;
};

FileListener.prototype.init = function() {
  const { filePath } = this.config;
  this.fd = fs.openSync(filePath, 'a');
};

FileListener.prototype.tearDown = function() {
  if (this.fd != null) fs.closeSync(this.fd);
  this.fd = null;
};

FileListener.prototype.process = function(record) {
  if (this.fd == null) return;
  const { format, ansiColors } = this.config;
  
};

const create = config => new FileListener(addDefaults(config, DEFAULT_CONFIG));

module.exports = {
  create,
};
