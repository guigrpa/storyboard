import fs from 'fs';
import path from 'path';
import { addDefaults } from 'timm';

const DEFAULT_CONFIG = {
  filePath: 'storyboard.log',
  colors: false,
  moduleNameLength: 20,
};

// -----------------------------------------
// Listener
// -----------------------------------------
class FileListener {
  constructor(config, { hub, mainStory, recordToLines, chalk }) {
    this.type = 'FILE';
    this.config = config;
    this.hub = hub;
    this.hubId = hub.getHubId();
    this.mainStory = mainStory;
    this.recordToLines = recordToLines;
    this.chalk = chalk;
    this.fd = null;
  }

  init() {
    const { filePath } = this.config;
    this.fd = fs.openSync(filePath, 'a');
    this.mainStory.info('storyboard',
      `Logs available at ${this.chalk.cyan.bold(path.resolve(filePath))}`);
  }

  tearDown() {
    if (this.fd != null) fs.closeSync(this.fd);
    this.fd = null;
  }

  getConfig() {
    return this.config;
  }

  // -----------------------------------------
  // Main processing function
  // -----------------------------------------
  process(msg) {
    if (msg.type !== 'RECORDS') return;
    if (msg.hubId !== this.hubId) return; // only save local records
    msg.data.forEach((record) => this.processRecord(record));
  }

  processRecord(record) {
    const { fd } = this;
    if (fd == null) return;
    const lines = this.recordToLines(record, this.config);
    lines.forEach(({ text }) => fs.write(fd, `${text}\n`, () => {}, 'utf8'));
  }
}

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new FileListener(addDefaults(userConfig, DEFAULT_CONFIG), context);
create.requiredCoreVersion = '^3.0.0-rc.2';

export default create;
