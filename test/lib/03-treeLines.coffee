chalk = require 'chalk'
{expect} = require './imports'
treeLines = require '../../lib/gral/treeLines'

describe 'treeLines', ->

  it 'should correctly detect circular references', ->
    a = {b: 3}
    a.c = a
    lines = treeLines a
    expect(lines[1]).to.contain 'CIRCULAR'
  
  it 'should show empty arrays as []', ->
    lines = treeLines {b: []}
    expect(lines[0]).to.contain '[]'

  it 'should show empty objects as {}', ->
    lines = treeLines {b: {}}
    expect(lines[0]).to.contain '{}'

  it 'should show arrays of strings as [\'a\', \'b\'...]', ->
    lines = treeLines {b: ['a', 'b', 'c']}
    expect(lines[0]).to.contain "['a', 'b', 'c']"

  it 'should format dates', ->
    now = new Date()
    lines = treeLines {b: now}
    expect(lines[0]).to.contain now.toISOString()

  it 'should format strings', ->
    lines = treeLines {b: 'a'}
    expect(lines[0]).to.contain "'a'"

  it 'should format booleans', ->
    lines = treeLines {b: false}
    expect(lines[0]).to.contain "false"

  it 'should format undefined and null', ->
    lines = treeLines {b: undefined, c: null}
    expect(lines[0]).to.contain "undefined"
    expect(lines[1]).to.contain "null"

  it 'should use colors', ->
    lines = treeLines {b: 4}
    expect(lines[0]).to.contain chalk.blue.bold 4

  it 'should format nested objects (and include them at the end)', ->
    lines = treeLines {nested: {nested1: 2, nested2: 3}, attr: 5}
    expect(lines).to.have.length 4
    expect(lines[0]).to.contain 'attr:'
    expect(lines[1]).to.contain 'nested:'
    expect(lines[2]).to.contain 'nested1:'
    expect(lines[3]).to.contain 'nested2:'

  it 'should format nested arrays (and include them at the end)', ->
    lines = treeLines {nested: [{nested1: 2}, {nested2: 3}], attr: 5}
    expect(lines).to.have.length 6
    expect(lines[0]).to.contain 'attr:'
    expect(lines[1]).to.contain 'nested:'
    expect(lines[2]).to.contain '0:'
    expect(lines[3]).to.contain 'nested1:'
    expect(lines[4]).to.contain '1:'
    expect(lines[5]).to.contain 'nested2:'

  it 'should allow ignoring keys', ->
    lines = treeLines {a: 1, b: 2}, {ignoreKeys: ['a']}
    expect(lines).to.have.length 1
    expect(lines[0]).to.contain 'b:'

  it 'should handle non-object types: string', ->
    lines = treeLines "Ratatouille"
    expect(lines).to.have.length 1
    expect(lines[0]).to.contain 'Ratatouille'

  it 'should handle multiline strings', ->
    lines = treeLines "En un lugar de La Mancha\nde cuyo nombre no quiero acordarme"
    expect(lines).to.have.length 2
    expect(lines[0]).to.contain 'Mancha'
    expect(lines[1]).to.contain 'nombre'

  it 'should handle Errors', ->
    lines = treeLines new Error('ExampleError')
    expect(lines.length).to.be.at.least 3
    expect(lines[0]).to.contain 'name'
    expect(lines[1]).to.contain 'message'
    expect(lines[2]).to.contain 'stack'

