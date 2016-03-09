istanbul = require 'istanbul'
diveSync = require 'diveSync'
fs       = require 'fs'
path     = require 'path'
chalk    = require 'chalk'

collector = new istanbul.Collector()
reporter = new istanbul.Reporter()
SYNC = false

console.log "Merging coverage results:"

options = filter: (filePath, fDir) ->
  return true if fDir
  return /^coverage.*\.json$/.test path.basename(filePath)
diveSync './coverage', options, (err, filePath) ->
  console.log "- #{chalk.yellow.bold path.basename filePath}"
  try
    collector.add JSON.parse fs.readFileSync path.resolve filePath
reporter.add 'text'
reporter.add 'lcov'
reporter.write collector, SYNC, ->
  console.log "All reports generated"
