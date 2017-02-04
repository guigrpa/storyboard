// A convenience initialiser for the most common case of all: just a console!

import storyboard from 'storyboard';
import consoleListener from 'storyboard-listener-console';

// Re-export default export
export default storyboard;

// Re-export named exports
export * from 'storyboard';

// Add console listener
storyboard.addListener(consoleListener);
