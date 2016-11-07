import split from 'split';
import { mainStory, addListener } from './storyboard';
import consoleListener from './listeners/console';

addListener(consoleListener);

mainStory.warn('storyboard', 'stdinLogger.js is deprecated. Use the `storyboard` command instead.');

process.stdin.pipe(split())
.on('data', (line) => mainStory.info(line))
.on('end', () => process.exit());
