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
function FileListener(config) {
  this.type = 'FILE';
  this.config = config;
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

FileListener.prototype.process = function(record) {
  // Don't save client logs uploaded to the server
  if (!k.IS_BROWSER && record.uploadedBy != null) return;
  const { fd } = this;
  if (fd == null) return;
  const lines = recordToLines(record, this.config);
  lines.forEach(({ text }) => fs.write(fd, `${text}\n`, null, 'utf8'));
};

// -----------------------------------------
// API
// -----------------------------------------
const create = config => new FileListener(addDefaults(config, DEFAULT_CONFIG));

export default create;