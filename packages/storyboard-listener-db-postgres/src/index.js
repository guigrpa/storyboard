import pg from 'pg';
import { addDefaults } from 'timm';
import { chalk, _ } from 'storyboard-core';

const DEFAULT_CONFIG = {
  host: 'localhost',
  port: process.env.PGPORT || 5432,
  database: process.env.PGDATABASE,
  table: 'logEntries',
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  throttle: 200,
  colors: true,
};

const LOG_SRC = 'storyboard';
const BUF_LENGTH = 2000;

// -----------------------------------------
// Listener
// -----------------------------------------
class DbPostgresListener {
  constructor(config, { hub, mainStory }) {
    this.type = 'DB_POSTGRES';
    this.config = config;
    this.hub = hub;
    this.hubId = hub.getHubId();
    this.mainStory = mainStory;
    this.client = new pg.Client(config);
    this.fConnected = false;
    // Short buffer for records to be saved
    // (accumulated during the throttle period)
    this.bufRecords = [];
    const { throttle: throttlePeriod } = config;
    if (throttlePeriod) {
      this.saveRecords = _.throttle(this.saveRecords, throttlePeriod).bind(this);
    }
    // pg.on('error', err => console.log(err));
    this.client.on('error', () => {});
    this.insertQuery = `INSERT INTO "${this.config.table}" (
        "hubId", version, "fStory", "fServer",
        "storyId", t, src, level,
        "fRoot", title, action, parents,
        msg, obj, "objExpanded", "objLevel", "objOptions", "objIsError"
      )
      VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8,
        $9, $10, $11, $12,
        $13, $14, $15, $16, $17, $18
      )
    `;
  }

  init() {
    const { config, mainStory } = this;
    mainStory.info(LOG_SRC, 'Connecting to PG database...', { attach: config });
    this.client.on('error', (err) => {
      this.fConnected = false;
      mainStory.error(LOG_SRC, 'Connection to PG database is down (will stop saving logs)',
        { attach: err });
    });
    this.client.on('connect', () => {
      this.fConnected = true;
      mainStory.info(LOG_SRC, 'Connected to PG database');
      this.saveRecords();
    });
    this.client.connect((err) => {
      if (err) {
        mainStory.error(LOG_SRC, 'Could not connect to PG database (will not save logs)',
          { attach: err });
        return;
      }
    });
  }

  tearDown() {
    if (!this.fConnected) return;
    this.fConnected = false;
    this.client.end(() => {});
  }

  getConfig() {
    return this.config;
  }

  addToRecordBuffer(records) {
    const finalRecords = records.filter((r) => !r.signalType);
    this.bufRecords = this.bufRecords.concat(finalRecords);
    if (this.bufRecords.length > BUF_LENGTH) {
      this.bufRecords = this.bufRecords.slice(-BUF_LENGTH);
    }
  }

  saveRecords() {
    if (!this.fConnected) return;
    const { insertQuery, config } = this;
    this.bufRecords.forEach((r) => {
      const jsonObj = r.obj != null ? JSON.stringify(r.obj) : undefined;
      const msg = config.colors ? r.msg : chalk.stripColor(r.msg);
      let title = r.title;
      if (!config.colors && title) title = chalk.stripColor(title);
      this.client.query(insertQuery, [
        // Common to stories and logs
        r.hubId, r.version, r.fStory, r.fServer,
        r.storyId, new Date(r.t), r.src, r.level,
        // Stories-only
        r.fRoot, title, r.action, JSON.stringify(r.parents),
        // Logs-only
        msg, jsonObj, r.objExpanded, r.objLevel, r.objOptions, r.objIsError,
      ])
      /* eslint-disable no-console */
      .on('error', (err) => console.log(err));
      /* eslint-enable no-console */
    });
    this.bufRecords.length = 0;
  }

  // -----------------------------------------
  // Main processing function
  // -----------------------------------------
  process(msg) {
    if (msg.type !== 'RECORDS') return;
    const { data: records } = msg;
    this.addToRecordBuffer(records);
    this.saveRecords(); // may be throttled
  }
}

// -----------------------------------------
// API
// -----------------------------------------
const create = (userConfig, context) =>
  new DbPostgresListener(addDefaults(userConfig, DEFAULT_CONFIG), context);

export default create;
