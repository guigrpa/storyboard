const fs = require('fs');
const path = require('path');
const shell = require('shelljs');
const globby = require('globby');
const babel = require('babel-core');

// Based on http://asiniy.github.io/Convert-Coffeescript-With-ES5-To-JSX-With-ES6/
// npm install -g babel-plugin-transform-react-createelement-to-jsx coffee-react lebab babel-cli

const exec = (cmd) => new Promise((resolve, reject) => {
  console.log(`> ${cmd}`);
  shell.exec(cmd, (code) => {
    if (code !== 0) {
      reject(new Error('Failed!'));
      return;
    }
    resolve();
  });
});

const files = globby.sync('src/chromeExtension/components/*.cjsx');
let promise = Promise.resolve();
files.forEach((filePath) => {
  promise = promise.then(() => {
    console.log(`Processing ${filePath}...`);
    const { dir, name } = path.parse(filePath);
    const outPath = path.join(dir, `${name}.js`);
    return exec(`cjsx --no-header --bare -c ${filePath}`)
    .then(() => exec(`lebab ${outPath} -o ${outPath} --transform arrow`))
    .then(() => exec(`lebab ${outPath} -o ${outPath} --transform commonjs`))
    .then(() => exec(`lebab ${outPath} -o ${outPath} --transform obj-shorthand`))
    .then(() => exec(`lebab ${outPath} -o ${outPath} --transform for-each`))
    .then(() => exec(`lebab ${outPath} -o ${outPath} --transform multi-var`))
    .then(() => {
      console.log('React.createElement() -> JSX...');
      const code0 = fs.readFileSync(outPath);
      const { code } = babel.transform(code0, {
        plugins: ['transform-react-createelement-to-jsx'],
      });
      fs.writeFileSync(outPath, `${code}\n`, 'utf8');
    });
  });
});
