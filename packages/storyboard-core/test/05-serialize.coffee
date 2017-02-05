_ = require 'lodash'
chalk = require 'chalk'
{serialize, deserialize, CIRCULAR_REF, STORYBOARD_TYPE_ATTR} = require '../lib/gral/serialize'

describe 'serialize', ->

  it 'should return a wrapper object for undefined', ->
    expect(serialize(undefined)).to.deep.equal "#{STORYBOARD_TYPE_ATTR}": 'UNDEFINED'

  it 'should return the same object for other scalars, including null', ->
    expect(serialize(null)).to.be.null
    expect(serialize(3)).to.equal 3
    expect(serialize('a')).to.equal 'a'
    expect(serialize(true)).to.equal true
    expect(serialize(false)).to.equal false

  it 'should return a trimmed-down object for errors', ->
    s = serialize(new Error('MY_ERROR'))
    expect(s[STORYBOARD_TYPE_ATTR]).to.equal 'ERROR'
    expect(s.name).not.to.be.null
    expect(s.message).not.to.be.null
    expect(s.stack).not.to.be.null

  it 'should clone dates', ->
    a = new Date()
    expect(serialize(a)).not.to.equal a

  it 'should clone arrays', ->
    a = [1, 2, 3]
    expect(serialize(a)).not.to.equal a

  it 'should return a wrapped buffer that can be transmitted', ->
    s = serialize(Buffer.from [1, 2, 3, 4])
    expect(s[STORYBOARD_TYPE_ATTR]).to.equal 'BUFFER'
    expect(s.data).to.deep.equal [1, 2, 3, 4]

  describe 'with objects', ->
    it 'should clone the object deeply', ->
      obj = {a: 3, b: {b1: 3}}
      obj2 = serialize obj
      expect(obj2.a).to.equal obj.a
      expect(obj2.b).not.to.equal obj.b
      expect(obj2.b.b1).to.equal obj.b.b1

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

describe 'deserialize', ->

  it 'should return the same object for scalars, including null', ->
    expect(deserialize(null)).to.be.null
    expect(deserialize(3)).to.equal 3
    expect(deserialize('a')).to.equal 'a'
    expect(deserialize(true)).to.equal true
    expect(deserialize(false)).to.equal false

  it 'should clone dates', ->
    a = new Date()
    expect(deserialize(a)).not.to.equal a

  it 'should clone arrays', ->
    a = [1, 2, 3]
    expect(deserialize(a)).not.to.equal a

  it 'should unwrap a top-level undefined value', ->
    obj = {"#{STORYBOARD_TYPE_ATTR}": 'UNDEFINED'}
    expect(deserialize(obj)).to.be.undefined

  it 'should unwrap a nested undefined value', ->
    obj = {a: 3, b: {"#{STORYBOARD_TYPE_ATTR}": 'UNDEFINED'}}
    ds = deserialize obj
    expect(ds.a).to.equal 3
    expect(ds.b).to.equal undefined

  it 'should deserialize errors', ->
    obj = {"#{STORYBOARD_TYPE_ATTR}": 'ERROR', name: 'a', message: 'b', stack: 'c'}
    expect(deserialize obj).to.deep.equal {name: 'a', message: 'b', stack: 'c'}

  it 'should deserialize buffers', ->
    obj = {"#{STORYBOARD_TYPE_ATTR}": 'BUFFER', data: [1, 2, 3]}
    ds = deserialize obj
    expect(ds instanceof Buffer).to.be.true
    expect(ds.length).to.equal 3
