chalk = require 'chalk'
{merge} = require 'timm'
filters = require '../lib/gral/filters'
recordToLines = require('../lib/gral/recordToLines').default

RECORD =
  t: new Date()
  src: 'main'
  msg: "this is an #{chalk.green.bold('important')} message"
  storyId: 'xx33'
  level: 50
  fStory: false
  fServer: true
  obj: { a: 3 }
  objLevel: 50
  objExpanded: true

#-====================================================
# ## Tests
#-====================================================
describe 'recordToLines', ->
  beforeEach ->
    filters.config '*:*'

  it 'should include colors by default', ->
    lines = recordToLines RECORD,
      moduleNameLength: 25
    expect(lines).to.have.length 2
    expect(lines[0].text).to.contain '\u001b[32m'

  it 'should allow removing colors', ->
    lines = recordToLines RECORD,
      moduleNameLength: 25
      colors: false
    expect(lines).to.have.length 2
    expect(lines[0].text).to.contain 'an important message' # no colors!
    expect(lines[1].text).to.contain 'a: 3' # no colors!
