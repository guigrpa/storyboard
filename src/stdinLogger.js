import split from 'split';
import { mainStory, addListener } from './storyboard';
import consoleListener from './listeners/console';

addListener(consoleListener);

process.stdin.pipe(split())
.on('data', line => mainStory.info(line))
.on('end', () => process.exit());
