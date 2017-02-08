import listPaths from './listPaths';
import { exec } from './helpers';

const forAllPackages = async (cmd) => {
  const pkgPaths = await listPaths();
  for (let i = 0; i < pkgPaths.length; i += 1) {
    await exec(cmd, { cwd: pkgPaths[i] });
  }
};

export default forAllPackages;
