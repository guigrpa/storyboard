// Re-export default export
import storyboard from './storyboard';
export default storyboard;

// Re-export named exports
export * from './storyboard';

// Show deprecation notice
const { chalk } = storyboard;
/* eslint-disable no-console */
console.log(chalk.yellow.bold(
  "Use of 'storyboard/lib/noPlugins' is deprecated in Storyboard 2.0.0"));
console.log(chalk.yellow.bold(
  "Import 'storyboard' directly (it no longer enables any plugin by default)"));
/* eslint-enable no-console */
