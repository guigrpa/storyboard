target = process.env.TEST_COV?.toUpperCase()
return if not target?

chalk = require 'chalk'
path = require 'path'
coffeeCoverage = require 'coffee-coverage'

console.log "Configuring coffee-coverage for #{chalk.yellow.bold target}..."

projectRoot = path.resolve __dirname, ".."
coverageVar = coffeeCoverage.findIstanbulVariable()
# Only write a coverage report if we're not running inside of Istanbul.
covFileName = "coverage-coffee-#{target}.json"
writeOnExit = if not coverageVar? then "#{projectRoot}/coverage/#{covFileName}" else null

coffeeCoverage.register
  instrumentor: 'istanbul'
  basePath: projectRoot
  exclude: [
    '/node_modules'
    '**/src/chromeExtension'
    '**/src/serverLogsApp'
    '**/src/example'
    '/test'
    '/tools'
    '**/package.coffee'
    '**/webpackConfig*'
    '/.git'
    '/.package.coffee'
  ]
  coverageVar: coverageVar
  writeOnExit: writeOnExit
  initAll: true
