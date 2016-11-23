/* eslint-disable no-console */
const fs = require('fs');
const path = require('path');
const globby = require('globby');
const cjsx = require('coffee-react');
const lebab = require('lebab');
const babel = require('babel-core');

const files = globby.sync('src/chromeExtension/components/*.cjsx');
let promise = Promise.resolve();
files.forEach((filePath) => {
  promise = promise.then(() => {
    console.log(`Processing ${filePath}...`);
    const { dir, name } = path.parse(filePath);
    const outPath = path.join(dir, `${name}.js`);
    const cjsxCode = fs.readFileSync(filePath, 'utf8');
    let code = cjsx.compile(cjsxCode, {
      header: false,
      bare: true,
    });
    const tmp = lebab.transform(code, [
      'arrow',
      'commonjs',
      'obj-shorthand',
      'for-each',
      'multi-var',
    ]);
    code = tmp.code;
    if (tmp.warnings.length) console.log(tmp.warnings);
    code = babel.transform(code, {
      plugins: ['transform-react-createelement-to-jsx'],
    }).code;
    fs.writeFileSync(outPath, `${code}\n`, 'utf8');
  });
});
