WEBPACK_OPTS            = "--colors --progress --display-modules --display-chunks"
WEBPACK_EXTENSION       = "webpack --config src/chromeExtension/webpackConfig.coffee #{WEBPACK_OPTS}"
WEBPACK_SERVER_LOGS_APP = "webpack --config src/serverLogsApp/webpackConfig.coffee #{WEBPACK_OPTS}"
WEBPACK_EXAMPLE         = "webpack --config src/example/webpackConfig.coffee #{WEBPACK_OPTS}"
_runMocha = (basePath, env) -> 
  prefix = if env? then "cross-env #{env} " else ''
  return "#{prefix}mocha #{basePath} --opts #{basePath}/mocha.opts"
_runMultiple = (arr) -> arr.join ' && '

#-================================================================
# ## General
#-================================================================
specs =
  name: "storyboard"
  version: "0.0.1"
  description: "End-to-end, hierarchical, real-time, colorful logs & stories"
  main: "index.js"
  author: "Guillermo Grau Panea"
  license: "MIT"
  keywords: ["log", "logging", "websockets", "console", "isomorphic"]
  homepage: "https://github.com/guigrpa/storyboard#readme"
  bugs: url: "https://github.com/guigrpa/storyboard/issues"
  repository:
    type: "git"
    url: "git+https://github.com/guigrpa/storyboard.git"

  #-================================================================
  # ## Scripts
  #-================================================================
  scripts: 

    # Library
    compileLib: _runMultiple [
      "rm -rf dist"
      "coffee -o dist -c src"
    ]
    testLib:                  _runMocha 'test/lib'
    testLibCovDev:            _runMocha 'test/lib', 'TEST_COV=lib_development NODE_ENV=development'
    testLibCovProd:           _runMocha 'test/lib', 'TEST_COV=lib_production NODE_ENV=production'
    testCovMerge:             "coffee tools/coffeeCoverageMerge.coffee"
    testCov: _runMultiple [
      "npm run testLibCovDev"
      "npm run testLibCovProd"
      "npm run testCovMerge"
    ]

    # Server logs app
    buildServerLogsApp:       "#{WEBPACK_SERVER_LOGS_APP}"
    buildServerLogsAppWatch:  "#{WEBPACK_SERVER_LOGS_APP} --watch"

    # Chrome extension
    buildExtension:           "#{WEBPACK_EXTENSION}"
    buildExtensionWatch:      "#{WEBPACK_EXTENSION} --watch"

    # Example
    buildExample:             "#{WEBPACK_EXAMPLE} --watch"
    example:                  "coffee src/example/server.coffee"

    # General
    build: _runMultiple [
      "npm run compileLib"
      "npm run buildExtension"
      "npm run buildServerLogsApp"
    ]


  #-================================================================
  # ## Storyboard library dependencies
  #-================================================================
  dependencies:
    "timm": "0.4.2"
    "chalk": "1.1.1"
    "bluebird": "3.3.1"
    "express": "4.13.4"
    "socket.io": "1.4.5"
    "node-uuid": "1.4.7"
    "lodash": "4.5.0"

  #-================================================================
  # ## Other dependencies
  #-================================================================
  devDependencies:

    #-----------------------------------------------------------------
    # ### Packaged in the Chrome extension
    #-----------------------------------------------------------------
    # React
    "react": "0.14.7"
    "react-dom": "0.14.7"
    "react-addons-pure-render-mixin": "0.14.7"
    "react-addons-perf": "0.14.7"

    # Redux
    "redux": "3.3.1"
    "react-redux": "4.4.0"
    "redux-saga": "0.9.2"
    "redux-thunk": "1.0.3"

    # Redux devtools
    "redux-devtools": "3.1.1"
    "redux-devtools-dock-monitor": "1.1.0"
    "redux-devtools-log-monitor": "1.0.4"
    "redux-devtools-inspector": "0.3.1"
    "redux-logger": "2.6.1"

    # Miscellaneous
    "font-awesome": "4.5.0"
    "moment": "^2.11.2"
    "socket.io-client": "1.4.5"
    "tinycolor2": "1.3.0"

    #-----------------------------------------------------------------
    # ### Extra deps used in the example
    #-----------------------------------------------------------------
    "body-parser": "1.15.0"

    #-----------------------------------------------------------------
    # ### Pure dev dependencies
    #-----------------------------------------------------------------
    "coffee-script": "1.10.0"

    # Webpack + loaders (+ related stuff)
    "webpack": "1.12.13"
    "coffee-loader": "0.7.2"
    "cjsx-loader": "2.1.0"
    "file-loader": "0.8.5"
    "css-loader": "0.23.1"
    "style-loader": "0.13.0"
    "sass-loader": "3.1.2"
    "node-sass": "3.4.2"

    # Testing
    "chai": "3.5.0"
    "sinon": "1.17.3"
    "sinon-chai": "2.8.0"
    "mocha": "2.4.5"
    "istanbul": "0.4.2"
    "coffee-coverage": "1.0.1"
    "coveralls": "2.11.6"
    "diveSync": "0.3.0"

    # Building tools
    "envify": "3.4.0"
    "cross-env": "1.0.7"
    "uglifyjs": "2.4.10"


#-================================================================
# ## Build package.json
#-================================================================
_sortDeps = (deps) -> 
  newDeps = {}
  newDeps[key] = deps[key] for key in Object.keys(deps).sort()
  newDeps
specs.dependencies = _sortDeps specs.dependencies
specs.devDependencies = _sortDeps specs.devDependencies
packageJson = JSON.stringify(specs, null, '  ') + '\n'
require('fs').writeFileSync "package.json", packageJson
