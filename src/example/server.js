// Here you'd write 'storyboard' or 'storyboard/lib/listeners/xxx':
import storyboard from '../storyboard';
const { mainStory } = storyboard;
import consoleListener from '../listeners/console';
import fileListener from '../listeners/file';
import wsServerListener from '../listeners/wsServer';

import createHttpServer from './httpServer';
import db from './db';
import writeSomeLogs from './writeSomeLogs';

storyboard.addListener(consoleListener);
storyboard.addListener(fileListener);
storyboard.config({ filter: '*:*' });

// Initialise our server
mainStory.info('server', 'Initialising server...');
const httpServer = createHttpServer();

// Allow remote access to server logs via WebSockets
// (asking for credentials)
storyboard.addListener(wsServerListener, {
  httpServer,
  authenticate: ({ login }) => login !== 'unicorn',
});

// Initialise our fake database
db.init();

writeSomeLogs();

process.on('SIGINT', () => process.exit());
