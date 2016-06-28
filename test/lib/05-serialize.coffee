_ = require 'lodash'
chalk = require 'chalk'
{expect} = require './imports'
{serialize, CIRCULAR_REF} = require '../../lib/gral/serialize'

describe 'serialize', ->

  it 'should return the same object for null', ->
    expect(serialize(null)).to.be.null

  it 'should return the same object for undefined', ->
    expect(serialize(undefined)).to.be.undefined

  it 'should return the same object for scalars', ->
    expect(serialize(3)).to.equal 3
    expect(serialize('a')).to.equal 'a'
    expect(serialize(true)).to.equal true
    expect(serialize(false)).to.equal false

  it 'should return a trimmed-down object for errors', ->
    expect(serialize(new Error('MY_ERROR'))).to.have.all.keys ['name', 'message', 'stack']

  describe 'with objects', ->
    it 'should clone the object', ->
      obj = {a: 3, b: {b1: 3}}
      obj2 = serialize obj
      obj.b.b1 = 2
      obj.b.b2 = 5
      expect(obj2.b.b1).to.equal(3)
      expect(obj2.b.b2).to.be.undefined

    it 'should clean the object of circular references (I)', ->
      obj = {a: 3, b: {b1: 3}}
      obj.b.b2 = obj
      obj2 = serialize obj
      expect(obj2.b.b2).to.equal CIRCULAR_REF
      expect(obj.b.b2).to.equal obj

    it 'should clean the object of circular references (II)', ->
      obj = [{a: 1}, {b: 2}]
      obj[2] = obj
      obj2 = serialize obj
      expect(obj2[2]).to.equal CIRCULAR_REF

    it 'should not detect circular references where there are none', ->
      obj = {a: 3, b: {b1: 3}}
      obj.c = obj.b
      obj2 = serialize obj
      expect(obj2.c.b1).to.equal 3
      expect(obj2.c).to.equal(obj2.b)
