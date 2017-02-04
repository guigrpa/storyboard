import path from 'path';
import fs from 'fs';
import { omit, set as timmSet } from 'timm';
import { mainStory, chalk } from './utils/storyboard';
import listPackages from './utils/listPackages';
import { exec } from './utils/helpers';

const DEP_TYPES = ['dependencies', 'devDependencies', 'peerDependencies', 'optionalDependencies'];

const run = async () => {
  const pkgPaths = await listPackages();
  const pkgNames = pkgPaths.map((o) => path.basename(o));

  // Read all package.json files
  const allPackages = {};
  mainStory.info('Reading all package.json files...');
  for (let i = 0; i < pkgPaths.length; i++) {
    const pkgPath = pkgPaths[i];
    const pkgName = pkgNames[i];
    allPackages[pkgName] = { pkgPath };
    const pkg = allPackages[pkgName];
    try {
      pkg.specPath = path.resolve(process.cwd(), pkgPath, 'package.json');
      pkg.specs = JSON.parse(fs.readFileSync(pkg.specPath, 'utf8'));
    } catch (err) {
      mainStory.error(`Could not read package.json for package ${pkgName}`);
      throw err;
    }
    const specs = pkg.specs;
    if (specs.name !== pkgName) throw new Error('Package name does not match directory name');
  }

  // Pass 1: register each package with yarn, and install external deps
  for (let i = 0; i < pkgNames.length; i++) {
    const pkgName = pkgNames[i];
    const { pkgPath, specPath, specs: prevSpecs } = allPackages[pkgName];
    mainStory.info(`${chalk.bold('PASS 1:')} processing ${chalk.cyan.bold(pkgName)}...`);

    // Link
    await exec('yarn link', { cwd: pkgPath });

    // Rewrite package.json without own packages, install, and revert changes
    try {
      let nextSpecs = prevSpecs;
      DEP_TYPES.forEach((type) => {
        const prevDeps = nextSpecs[type];
        if (prevDeps == null) return;
        const nextDeps = omit(prevDeps, pkgNames);
        nextSpecs = timmSet(nextSpecs, type, nextDeps);
      });
      if (nextSpecs !== prevSpecs) {
        fs.writeFileSync(specPath, JSON.stringify(nextSpecs, null, '  '), 'utf8');
      }
      await exec('yarn install', { cwd: pkgPath });
    } finally {
      if (prevSpecs != null) {
        fs.writeFileSync(specPath, JSON.stringify(prevSpecs, null, '  '), 'utf8');
      }
    }
  }

  // Pass 2: link internal deps
  for (let i = 0; i < pkgNames.length; i++) {
    const pkgName = pkgNames[i];
    const { pkgPath, specs } = allPackages[pkgName];
    mainStory.info(
      `${chalk.bold('PASS 2:')} installing internal deps for ${chalk.cyan.bold(pkgName)}...`);
    for (let k = 0; k < pkgNames.length; k++) {
      const depName = pkgNames[k];
      if (depName === pkgName) continue;
      for (let m = 0; m < DEP_TYPES.length; m++) {
        const deps = specs[DEP_TYPES[m]];
        if (deps == null) continue;
        if (deps[depName]) {
          await exec(`yarn link ${depName}`, { cwd: pkgPath });
          break;
        }
      }
    }
  }
};

run();
