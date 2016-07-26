// A convenience initialiser for the most common case of all: just a console!

// Re-export default export
import storyboard from './storyboard';
export default storyboard;

// Re-export named exports
export * from './storyboard';

// Add console listener
import consoleListener from './listeners/console';
storyboard.addListener(consoleListener);
