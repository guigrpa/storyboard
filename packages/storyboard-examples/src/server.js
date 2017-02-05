import { mainStory, config, addListener } from 'storyboard';
import consoleListener from 'storyboard-listener-console';
// import fileListener from 'storyboard-listener-file';
import wsServerListener from 'storyboard-listener-ws-server';

import createHttpServer from './httpServer';
import db from './db';
import writeSomeLogs from './writeSomeLogs';

config({ filter: '*:*' });
addListener(consoleListener);
// addListener(fileListener);

// Initialise our server
mainStory.info('server', 'Initialising server...');
const httpServer = createHttpServer();

// Allow remote access to server logs via WebSockets
// (asking for credentials)
addListener(wsServerListener, {
  httpServer,
  // authenticate: ({ login }) => login !== 'unicorn',
});

// Initialise our fake database
db.init();

writeSomeLogs();

process.on('SIGINT', () => process.exit());
