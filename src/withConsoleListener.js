// A convenience initialiser for the most common case of all: just a console!

import storyboard, { addListener } from './storyboard';
import consoleListener from './listeners/console';

// Re-export default export
export default storyboard;

// Re-export named exports
export * from './storyboard';

// Add console listener
addListener(consoleListener);
