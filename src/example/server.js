import http from 'http';
import path from 'path';
import bodyParser from 'body-parser';
import express from 'express';

import { mainStory, chalk } from '../storyboard'; // you'd write: `storyboard`
import * as storyboard from '../storyboard'; // you'd write: `storyboard`
import consoleListener from '../listeners/console';  // you'd write: `storyboard/lib/listeners/console`
import wsServer from '../listeners/wsServer'; // you'd write: `storyboard/lib/listeners/wsServer`

import db from './db';

storyboard.addListener(consoleListener);
storyboard.config({ filter: '*:*' });

const PORT = process.env.PORT || 3000;

// Initialise our server
mainStory.info('server', 'Initialising server...');
const app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(process.cwd(), 'example')));
app.post('/animals', (req, res, next) => {
  const { storyId } = req.body;
  let extraParents;
  if (storyId != null) extraParents = [storyId];
  const story = mainStory.child({
    src: 'httpServer',
    title: `HTTP request ${chalk.green(req.url)}`,
    extraParents,
  });
  db.getItems({ story })
  .then(result => {
    story.debug('httpServer', `HTTP response: ${result.length} animals`,
      { attachInline: result });
    res.json(result);
  })
  .finally(() => story.close());
});
const httpServer = http.createServer(app);
httpServer.listen(PORT);
mainStory.info('httpServer', "Listening on port ${chalk.cyan(PORT)}...");

// Allow remote access to server logs via WebSockets 
// (asking for credentials)
storyboard.addListener(wsServer, {
  httpServer: httpServer,
  authenticate: ({login, password}) => login !== 'unicorn',
});

// Initialise our fake database
db.init();

// Some example logs (including a circular reference)
const longArray = [];
for (let i = 0; i < 1000; i++) {
  longArray.push(i);
}
const someInfo = {
  appName: 'Storyboard example',
  upSince: new Date(),
  dontShow: 'hidden',
  loginRequiredForLogs: true,
  nested: {
    configOptions: {
      foo: undefined,
      bar: null,
      values: [1, 2],
    },
  },
  shortBuffer: Buffer.from([0, 1, 2, 3]),
  longBuffer: Buffer.from(longArray),
};
someInfo.nested.configOptions.mainInfo = someInfo;
mainStory.debug('server', 'Example info:', {
  attach: someInfo,
  attachLevel: 'TRACE',
  ignoreKeys: ['dontShow'],
});
mainStory.warn('server', 'Example warning');
mainStory.error('server', 'Example error', { attach: new Error('EXAMPLE error message') });
setInterval(() => { 
  mainStory.debug('server', `t: ${chalk.blue(new Date().toISOString())}`);
}, 60000);

const story = mainStory.child({ title: 'Example child story' });
story.info('Info');
story.warn('Warn');
story.error('Error!');
story.close();

process.on('SIGINT', () => process.exit());
