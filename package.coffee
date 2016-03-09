WEBPACK_OPTS            = "--colors --progress --display-modules --display-chunks"
WEBPACK_EXTENSION       = "webpack --config src/chromeExtension/webpackConfig.coffee #{WEBPACK_OPTS}"
WEBPACK_SERVER_LOGS_APP = "webpack --config src/serverLogsApp/webpackConfig.coffee #{WEBPACK_OPTS}"
WEBPACK_EXAMPLE         = "webpack --config src/example/webpackConfig.coffee #{WEBPACK_OPTS}"

ISTANBUL_OPTS = "--report json"

_runMultiple = (arr) -> arr.join ' && '

_runMocha = (basePath, env) -> 
  prefix = if env? then "cross-env #{env} " else ''
  return "#{prefix}mocha #{basePath} --opts #{basePath}/mocha.opts"

_runMochaCov = (basePath, nodeEnv) ->
  return _runMultiple [
    "cross-env NODE_ENV=#{nodeEnv} istanbul cover node_modules/mocha/bin/_mocha #{ISTANBUL_OPTS} -- --opts #{basePath}/mocha.opts"
    "mv coverage/coverage-final.json coverage/coverage-#{nodeEnv.toUpperCase()}.json"
    "rm coverage/coverage.json"
  ]

#-================================================================
# ## General
#-================================================================
specs =
  name: "storyboard"
  version: "0.0.3"
  description: "End-to-end, hierarchical, real-time, colorful logs & stories"
  main: "lib/storyboard.js"
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
    compile: _runMultiple [
      "rm -rf lib"
      "coffee --no-header -o lib -c src/storyboard.coffee"
      "coffee --no-header -o lib/gral -c src/gral"
      "coffee --no-header -o lib/listeners -c src/listeners"
      "coffee --no-header -o lib/vendor -c src/vendor"
    ]
    ## testLib:                  _runMocha    'test/lib'
    testLibDev:               _runMochaCov 'test/lib', 'development'
    testLibProd:              _runMochaCov 'test/lib', 'production'

    # Server logs app
    buildServerLogsApp:       "cross-env NODE_ENV=production #{WEBPACK_SERVER_LOGS_APP} -p"
    buildServerLogsAppWatch:  "#{WEBPACK_SERVER_LOGS_APP} --watch"

    # Chrome extension
    buildExtension:           "cross-env NODE_ENV=production #{WEBPACK_EXTENSION} -p"
    buildExtensionWatch:      "#{WEBPACK_EXTENSION} --watch"

    # Example
    buildExample:             "#{WEBPACK_EXAMPLE} --watch"
    example:                  "coffee src/example/server.coffee"

    # General
    build: _runMultiple [
      "coffee package.coffee"
      "npm run compile"
      "npm run buildServerLogsApp"
      "npm run buildExtension"
      "npm run test"
    ]
    test:                     "npm run testCov"
    testCov: _runMultiple [
      "rm -rf coverage"
      "npm run testLibCovDev"
      "npm run testLibCovProd"
      "npm run testCovMerge"
    ]
    testCovMerge:             "coffee tools/mergeCoverage.coffee"

  #-================================================================
  # ## Storyboard library dependencies
  #-================================================================
  dependencies:
    "timm": "0.4.3"
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
    "babel-polyfill":       "6.6.1"     # es6

    # React
    "react":                          "15.0.0-rc.1" # 0.14.7
    "react-dom":                      "15.0.0-rc.1"
    "react-addons-pure-render-mixin": "15.0.0-rc.1"
    "react-addons-perf":              "15.0.0-rc.1"

    # Redux
    "redux": "3.3.1"
    "react-redux": "4.4.0"
    "redux-saga": "0.9.2"
    "redux-thunk": "1.0.3"

    # Redux devtools
    "redux-devtools": "3.1.1"
    "redux-devtools-dock-monitor": "1.1.0"
    "redux-devtools-log-monitor": "1.0.5"
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

    # Babel + plugins
    "babel-core":           "6.6.5"     # es6
    "babel-preset-es2015":  "6.6.0"     # for ES2015 (a.k.a. ES6)
    "babel-preset-react":   "6.5.0"     # for React
    "babel-preset-stage-2": "6.5.0"     # to replace the "stage" of support option in a Webpack config    

    # Webpack + loaders (+ related stuff)
    "webpack": "1.12.13"
    "babel-loader": "6.2.4"
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
