/* eslint-disable indent, max-len, quote-props */

// ===============================================
// Basic config
// ===============================================
const NAME = 'storyboard';
const VERSION = '2.2.0';
const DESCRIPTION = 'End-to-end, hierarchical, real-time, colorful logs and stories';
const KEYWORDS = ['log', 'logging', 'websockets', 'console', 'isomorphic'];

// ===============================================
// Helpers
// ===============================================
const runMultiple = (arr) => arr.join(' && ');
const runTestCov = (env, name) => {
  const envStr = env != null ? `${env} ` : '';
  return runMultiple([
    `cross-env ${envStr}nyc node_modules/mocha/bin/_mocha`,
    'mv .nyc_output/* .nyc_tmp/',
    'rm -rf .nyc_output',
    `cross-env ${envStr}jest --coverage`,
    `mv .nyc_output/coverage-final.json .nyc_tmp/coverage-${name}.json`,
    'rm -rf .nyc_output',
  ]);
};

const WEBPACK_OPTS = [
  '--color',
  '--progress',
  // '--display-modules',
  '--display-chunks',
].join(' ');
// const WEBPACK_OPTS            = '--colors --progress'
const WEBPACK_EXTENSION = `webpack --config src/chromeExtension/webpackConfig ${WEBPACK_OPTS}`;
const WEBPACK_SERVER_LOGS_APP = `webpack --config src/serverLogsApp/webpackConfig ${WEBPACK_OPTS}`;
const WEBPACK_EXAMPLE = `webpack --config src/example/webpackConfig ${WEBPACK_OPTS}`;

const HEROKU_ROOT = 'example/heroku';
const HEROKU_CLIENT = `${HEROKU_ROOT}/client`;
// const HEROKU_SERVER = `${HEROKU_ROOT}/server`;

// ===============================================
// Specs
// ===============================================
const specs = {
  name: NAME,
  version: VERSION,
  description: DESCRIPTION,
  main: 'lib/storyboard.js',
  bin: { sb: 'lib/cli.js' },
  author: 'Guillermo Grau Panea',
  license: 'MIT',
  keywords: KEYWORDS,
  homepage: `https://github.com/guigrpa/${NAME}#readme`,
  bugs: { url: `https://github.com/guigrpa/${NAME}/issues` },
  repository: { type: 'git', url: `git+https://github.com/guigrpa/${NAME}.git` },

  // -----------------------------------------------
  // Scripts
  // -----------------------------------------------
  scripts: {

    // Top-level
    compile:                    runMultiple([
                                  'node package',
                                  'rm -rf ./lib',
                                  'coffee --no-header -o lib -c src',
                                  'babel -d lib src',
                                  'cp src/storyboard.js.flow lib/storyboard.js.flow',
                                  'cp src/storyboard.js.flow lib/withConsoleListener.js.flow',
                                ]),
    build:                      runMultiple([
                                  'npm run lint',
                                  'npm run compile',
                                  'npm run buildServerLogsApp',
                                  'npm run buildExtension',
                                  'npm run test',
                                  'npm run zipExtension',
                                  'npm run buildExampleHeroku',
                                  'npm run xxl',
                                  // 'echo "Remember to update Heroku package.json with the latest SB version!"',
                                ]),
    'now-build':                'echo NOTHING_TO_BE_DONE_NOW',
    travis:                     runMultiple([
                                  'npm run compile',
                                  'npm run test',
                                ]),
    start:                      runMultiple([
                                  'npm run buildExample',
                                  'npm run example',
                                ]),
    'now-start':                'node lib/example/server',

    // Server logs app
    buildServerLogsApp:         `cross-env NODE_ENV=production ${WEBPACK_SERVER_LOGS_APP} -p`,
    buildServerLogsAppWatch:    `${WEBPACK_SERVER_LOGS_APP} --watch`,

    // Chrome extension
    buildExtension:             `cross-env NODE_ENV=production ${WEBPACK_EXTENSION} -p`,
    buildExtensionWatch:        `${WEBPACK_EXTENSION} --watch`,
    zipExtension:               runMultiple([
                                  'rm -f chromeExtension/chromeExtension_*.zip',
                                  `bestzip chromeExtension_v${VERSION}.zip chromeExtension/*`,
                                  `mv chromeExtension_v${VERSION}.zip chromeExtension/`,
                                ]),

    // Example
    buildExample:               `cross-env NODE_ENV=production ${WEBPACK_EXAMPLE} -p`,
    buildExampleWatch:          `${WEBPACK_EXAMPLE} --watch`,
    buildExampleHeroku:         runMultiple([
                                  `rm -f ${HEROKU_CLIENT}/*.eot ${HEROKU_CLIENT}/*.ttf ${HEROKU_CLIENT}/*.woff* ${HEROKU_CLIENT}/*.svg ${HEROKU_CLIENT}/*.js`,
                                  `cross-env NODE_ENV=production ${WEBPACK_EXAMPLE} -p`,
                                  `cp example/*.eot example/*.ttf example/*.woff* example/*.svg example/*.js ${HEROKU_CLIENT}/`,
                                ]),
    example:                    runMultiple([
                                  'npm run compile',
                                  'node lib/example/server',
                                ]),
    exampleWithDb:              runMultiple([
                                  'npm run compile',
                                  'node lib/example/serverWithDb',
                                ]),

    // Static analysis
    lint:                       'eslint src',
    xxl:                        "xxl --src \"[\\\"src\\\"]\"",  // eslint-disable-line quotes

    // Testing - general
    jest:                       'jest --watch --coverage',
    'jest-html':                'jest-html --snapshot-patterns "testJest/**/*.snap"',
    test:                       'npm run testCovFull',
    testFast:                   runMultiple(['mocha', 'jest']),
    testCovFull:                runMultiple([
                                  'npm run testCovPrepare',
                                  'npm run testDev',
                                  'npm run testProd',
                                  'npm run testBrowser',
                                  'npm run testCovReport',
                                ]),
    testCovFast:                runMultiple([
                                  'npm run testCovPrepare',
                                  'npm run testDev',
                                  'npm run testCovReport',
                                ]),
    testCovBrowser:             runMultiple([
                                  'npm run testCovPrepare',
                                  'npm run testBrowser',
                                  'npm run testCovReport',
                                ]),

    // Testing - steps
    testCovPrepare:             runMultiple([
                                  'rm -rf ./coverage .nyc_output .nyc_tmp',
                                  'mkdir .nyc_tmp',
                                ]),
    testDev:                    runTestCov('NODE_ENV=development', 'dev'),
    testProd:                   runTestCov('NODE_ENV=production', 'prod'),
    testBrowser:                runTestCov('NODE_ENV=development TEST_BROWSER=true', 'browser'),
    testCovReport:              runMultiple([
                                  'cp -r .nyc_tmp .nyc_output',
                                  'nyc report --reporter=html --reporter=lcov --reporter=text',
                                ]),
  },

  // ===============================================
  // Storyboard library dependencies
  // ===============================================
  dependencies: {
    'timm': '1.2.1',
    'clocksy': '1.1.0',
    'chalk': '1.x',
    'bluebird': '3.4.6',
    'express': '4.14.0',
    'socket.io': '1.6.0',
    'socket.io-client': '1.6.0',
    'node-uuid': '1.4.7',
    'lodash': '4.17.2',
    'platform': '1.3.1',
    'split': '1.0.0',
    'pg': '6.0.2',
    'ms': '0.7.2',
    'commander': '2.9.0',
  },

  // ===============================================
  // Other dependencies
  // ===============================================
  devDependencies: {

    // -----------------------------------------------
    // Packaged in the Chrome extension
    // -----------------------------------------------
    'babel-polyfill': '6.16.0',
    'giu': '0.8.1',

    // React
    'react':                          '15.4.1',
    'react-dom':                      '15.4.1',
    'react-addons-perf':              '15.4.1',

    // Redux
    'redux': '3.6.0',
    'react-redux': '4.4.6',
    'redux-saga': '0.9.4',
    'redux-thunk': '2.1.0',

    // Redux devtools
    // 'redux-devtools': '3.3.1',
    // 'redux-devtools-dock-monitor': '1.1.1',
    // 'redux-devtools-log-monitor': '1.0.11',
    // 'redux-devtools-inspector': '0.8.0',
    'redux-logger': '2.6.1',

    // Miscellaneous
    'font-awesome': '4.5.0',
    'moment': '2.14.1',
    'tinycolor2': '1.4.1',

    // -----------------------------------------------
    // Extra deps used in the example
    // -----------------------------------------------
    'body-parser': '1.15.2',
    'isomorphic-fetch': '2.2.1',

    // -----------------------------------------------
    // Pure dev dependencies
    // -----------------------------------------------
    'coffee-script': '1.10.0',

    // Babel + plugins
    'babel-cli': '6.18.0',
    'babel-core': '6.18.2',
    'babel-preset-es2015': '6.18.0',
    'babel-preset-react': '6.16.0',
    'babel-preset-stage-2': '6.18.0',

    // Webpack + loaders (+ related stuff)
    'webpack': '1.13.3',
    'babel-loader': '6.2.5',
    'coffee-loader': '0.7.2',
    'file-loader': '0.8.5',
    'json-loader': '0.5.4',
    'css-loader': '0.26.0',
    'style-loader': '0.13.1',
    'sass-loader': '3.1.2',
    'node-sass': '3.7.0',

    // Linting
    eslint: '3.8.1',
    'eslint-config-airbnb': '12.0.0',
    'eslint-plugin-flowtype': '2.20.0',
    'eslint-plugin-import': '1.16.0',
    'eslint-plugin-jsx-a11y': '2.2.3',
    'eslint-plugin-react': '6.4.1',
    'babel-eslint': '7.0.0',

    // Testing with Jest
    'jest': '17.0.3',
    'jest-html': '^1.2.0',
    'react-test-renderer': '15.4.1',
    'babel-jest': '17.0.2',

    // Testing with Mocha
    'mocha': '2.4.5',
    'chai': '3.5.0',
    'sinon': '1.17.6',
    'sinon-chai': '2.8.0',
    'ignore-styles': '4.0.0',

    // Coverage testing
    'nyc': '8.4.0',
    'coveralls': '2.11.15',
    // 'diveSync': '0.3.0',

    // Building tools
    // 'envify': '3.4.0',
    // 'uglifyjs': '2.4.10',
    'cross-env': '1.0.7',
    'bestzip': '1.1.3',
    'xxl': '0.1.1',

    // CJSX conversion
    // 'globby': '6.0.0',
    // 'coffee-react': '5.0.1',  // the cjsx binary
    // 'lebab': '2.6.1',
    // 'babel-plugin-transform-react-createelement-to-jsx': '1.0.1',

    // yarn bug #629
    // chokidar: '1.6.0',
  },

  // -----------------------------------------------
  // Other configs
  // -----------------------------------------------
  nyc: {
    exclude: [
      'lib/vendor/**',
      'node_modules/**/*',
      'test/**',
    ],
  },
  jest: {
    // Default test path:
    // testRegex: '(/__tests__/.*|\\.(test|spec))\\.(js|jsx)$',
    testRegex: 'testJest/.*\\.(test|spec)\\.(js|jsx)$',
    moduleNameMapper: {
      '^.+\\.(css|less|sass)$': '<rootDir>/test/emptyObject.js',
      '^.+\\.(gif|ttf|eot|svg)$': '<rootDir>/test/emptyString.js',
      'node-uuid': '<rootDir>/test/mockUuid.js',
    },
    coverageDirectory: '.nyc_output',
    coverageReporters: ['json', 'text', 'html'],
    snapshotSerializers: ['<rootDir>/node_modules/jest-html'],
    collectCoverageFrom: [
      'lib/**/*.js',
      '!lib/cli.js',
      '!lib/noPlugins.js',
      '!lib/stdinLogger.js',
      '!lib/withConsoleListener.js',
      '!lib/chromeExtension/*.js',  // at the base of the extension folder
      '!lib/chromeExtension/store/**',
      '!lib/example/**',
      '!lib/serverLogsApp/**',
      '!lib/vendor/**',
      '!test/**',
      '!testJest/**',
      '!**/webpack*',
      '!**/node_modules/**',
      '!**/__tests__/**',
      '!**/__mocks__/**',
    ],
    // setupTestFrameworkScriptFile: './testJest/setup.js',
  },
};

// ===============================================
// Build package.json
// ===============================================
const sortDeps = (deps) => {
  const newDeps = {};
  Object.keys(deps).sort().forEach((key) => {
    newDeps[key] = deps[key];
  });
  return newDeps;
};
specs.dependencies = sortDeps(specs.dependencies);
specs.devDependencies = sortDeps(specs.devDependencies);
const packageJson = `${JSON.stringify(specs, null, '  ')}\n`;
require('fs').writeFileSync('package.json', packageJson);

// ===============================================
// Build manifest.json
// ===============================================
const manifest = {
  manifest_version: 2,

  name: 'Storyboard DevTools',
  short_name: 'Storyboard DevTools',
  description: 'Gives you access to end-to-end stories (logs) for Storyboard-equipped applications',
  author: 'Guillermo Grau Panea',
  version: VERSION.split('-')[0],

  content_scripts: [
    {
      matches: ['<all_urls>'],
      js: ['contentScript.js'],
      run_at: 'document_start',
    },
  ],

  background: {
    scripts: ['background.js'],
    persistent: false,
  },

  devtools_page: 'devTools.html',

  icons: {
    '16': 'Logo16.png',
    '32': 'Logo32.png',
    '48': 'Logo48.png',
    '128': 'Logo128.png',
  },
};

const manifestJson = `${JSON.stringify(manifest, null, '  ')}\n`;
require('fs').writeFileSync('chromeExtension/manifest.json', manifestJson);
/* eslint-enable indent, max-len, quote-props */
