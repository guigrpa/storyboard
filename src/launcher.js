// import { spawn } from 'child_process';
import { exec } from 'child_process';

import split from 'split';
import { mainStory, addListener } from './storyboard';
import consoleListener from './listeners/console';

// Setting `useStderr` to `false` aims to reduce out-of-order
// logs (Storyboard will output everything through `stdout`),
// but only solves part of the problem: the launched process
// will still use `stdout` and `stderr`, and they will typically
// be flushed asynchronously:
// https://nodejs.org/api/console.html#console_asynchronous_vs_synchronous_consoles
addListener(consoleListener, { useStderr: false });

/*
process.stdin.pipe(split())
.on('data', line => mainStory.info(line))
.on('end', () => process.exit());
*/

const argv = process.argv;
// const cmd = argv[2];
// const args = argv.slice(3);
// spawn(cmd, args);
const child = exec(argv.slice(2).join(' '));

child.stdout.pipe(split())
.on('data', line => mainStory.info(line));

child.stderr.pipe(split())
.on('data', line => mainStory.error(line));
