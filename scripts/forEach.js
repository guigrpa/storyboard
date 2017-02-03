import 'storyboard/lib/withConsoleListener';
import forAllPackages from './utils/forAllPackages';

if (process.argv.length < 3) {
  console.error('Please specify a command to run');  // eslint-disable-line
  process.exit(1);
}
forAllPackages(process.argv[2]);
