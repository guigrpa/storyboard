// Re-export default export
import storyboard, { mainStory } from './storyboard';

export default storyboard;

// Re-export named exports
export * from './storyboard';

// Show deprecation notice
/* eslint-disable no-console */
mainStory.warn('storyboard', "Use of 'storyboard/lib/noPlugins' is deprecated in Storyboard 2.0.0");
mainStory.warn('storyboard',
  "Import 'storyboard' directly (it no longer enables any plugin by default)");
/* eslint-enable no-console */
