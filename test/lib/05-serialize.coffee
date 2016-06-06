_ = require 'lodash'
chalk = require 'chalk'
{expect} = require './imports'
{serialize, CIRCULAR_PLACEHOLDER} = require '../../lib/gral/serialize'

describe.only 'serialize', ->

  it 'should return the same object for null', ->
    expect(serialize(null)).to.be.null

  it 'should return the same object for undefined', ->
    expect(serialize(undefined)).to.be.undefined

  it 'should return the same object for scalars', ->
    expect(serialize(3)).to.equal(3)
    expect(serialize('a')).to.equal('a')

  describe 'with objects', ->
    it 'should clone the object', ->
      obj = {a: 3, b: {b1: 3}}
      obj2 = serialize obj
      obj.b.b1 = 2
      obj.b.b2 = 5
      expect(obj2.b.b1).to.equal(3)
      expect(obj2.b.b2).to.be.undefined
