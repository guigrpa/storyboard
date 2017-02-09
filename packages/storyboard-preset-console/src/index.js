// A convenience initialiser for the most common case of all: just a console!

import { addListener } from 'storyboard';
import consoleListener from 'storyboard-listener-console';

export * from 'storyboard';

addListener(consoleListener);
