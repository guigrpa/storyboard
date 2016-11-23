// Here you'd write 'storyboard' or 'storyboard/lib/listeners/xxx':
import { mainStory, config, addListener } from '../storyboard';
import consoleListener from '../listeners/console';
import wsServerListener from '../listeners/wsServer';
import dbPostgresListener from '../listeners/dbPostgres';

import createHttpServer from './httpServer';
import db from './db';
import writeSomeLogs from './writeSomeLogs';

addListener(consoleListener);
addListener(dbPostgresListener, {
  user: 'postgres',
  password: 's3cret',
  database: 'storyboard',
});
config({ filter: '*:*' });

// Initialise our server
mainStory.info('server', 'Initialising server...');
const httpServer = createHttpServer();

// Allow remote access to server logs via WebSockets
// (asking for credentials)
addListener(wsServerListener, {
  httpServer,
  authenticate: ({ login }) => login !== 'unicorn',
});

// Initialise our fake database
db.init();

writeSomeLogs();

process.on('SIGINT', () => process.exit());
