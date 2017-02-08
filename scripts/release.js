import { exec } from './utils/helpers';
import { mainStory, chalk } from './utils/storyboard';

const run = async () => {
  // TODO: Ask the user whether he has run `yarn run build`

  // Check current branch
  let { stdout: branch } = await exec('git symbolic-ref --short HEAD', { logLevel: 'trace' });
  branch = branch.trim();
  if (branch !== 'master') {
    mainStory.error(`Can't publish from current branch: ${chalk.bold(branch)}`);
    process.exit(1);
  }
  mainStory.info(`Current branch: ${chalk.yellow.bold(branch)}`);

  // Check that the branch is clean
  let { stdout: pending } = await exec('git status --porcelain', { logLevel: 'trace' });
  pending = pending.trim();
  if (pending !== '') {
    mainStory.error(`Can't publish with uncommitted changes (stash/commit them): \n${chalk.bold(pending)}`);
    process.exit(1);
  }
  mainStory.info('No uncommitted changes');

  // Check remote history
  // Ripped off from: https://github.com/sindresorhus/np/blob/master/lib/git.js
  let { stdout: pulls } = await exec('git rev-list --count --left-only @{u}...HEAD', { logLevel: 'trace' });
  pulls = pulls.trim();
  if (pulls !== '0') {
    mainStory.error('Remote history differs. Please pull changes');
    process.exit(1);
  }
  mainStory.info('Remote history matches local history');

  // TODO: Package by package, check whether it needs publishing and do it
};

run();
