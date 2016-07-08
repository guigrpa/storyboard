import fs from 'fs';
import { addDefaults } from 'timm';
import k from '../gral/constants';
import recordToLines from './helpers/recordToLines';


const DEFAULT_CONFIG = {
  filePath: 'storyboard.log',
  colors: false,
  moduleNameLength: 20,
};

// -----------------------------------------
// Listener
// -----------------------------------------
function FileListener(config, { hub }) {
  this.type = 'FILE';
  this.config = config;
  this.hub = hub;
  this.hubId = hub.getHubId();
  this.fd = null;
}

FileListener.prototype.init = function() {
  const { filePath } = this.config;
  this.fd = fs.openSync(filePath, 'a');
};

FileListener.prototype.tearDown = function() {
  if (this.fd != null) fs.closeSync(this.fd);
  this.fd = null;
};

// -----------------------------------------
// Main processing function
// -----------------------------------------
FileListener.prototype.process = function(msg) {
  if (msg.type !== 'RECORDS') return;
  if (msg.hubId !== this.hubId) return; // only save local records
  msg.data.forEach(record => this.processRecord(record));
};

FileListener.prototype.processRecord = function(record) {
  const { fd } = this;
  if (fd == null) return;
  const lines = recordToLines(record, this.config);
  lines.forEach(({ text }) => fs.write(fd, `${text}\n`, null, 'utf8'));
};

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new FileListener(addDefaults(userConfig, DEFAULT_CONFIG), context);

export default create;