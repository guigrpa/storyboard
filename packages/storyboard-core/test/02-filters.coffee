filters = require '../lib/gral/filters'
mainStory = require('../lib/gral/stories').default

{init, config, passesFilter} = filters

describe 'filters', ->
  beforeEach -> init({mainStory})

  it "should correctly apply: 'hello:INFO'", ->
    config 'hello:INFO'
    expect(passesFilter 'hi',    20).to.be.false
    expect(passesFilter 'hello', 20).to.be.false
    expect(passesFilter 'hello', 30).to.be.true
    expect(passesFilter 'hello', 40).to.be.true

  it "should tolerate: 'hello:INFO',", ->
    config 'hello:INFO,'
    expect(passesFilter 'hi',    20).to.be.false
    expect(passesFilter 'hello', 20).to.be.false
    expect(passesFilter 'hello', 30).to.be.true
    expect(passesFilter 'hello', 40).to.be.true

  it "should tolerate: 'hello:info'", ->
    config 'hello:info'
    expect(passesFilter 'hi',    20).to.be.false
    expect(passesFilter 'hello', 20).to.be.false
    expect(passesFilter 'hello', 30).to.be.true
    expect(passesFilter 'hello', 40).to.be.true

  it "should prioritise exclusion: 'hello:INFO, -hello'", ->
    config 'hello:INFO, -hello'
    expect(passesFilter 'hi',    20).to.be.false
    expect(passesFilter 'hello', 20).to.be.false
    expect(passesFilter 'hello', 30).to.be.false
    expect(passesFilter 'hello', 40).to.be.false

  it "should correctly apply: 'hello:INFO, hi:DEBUG'", ->
    config 'hello:INFO, hi:DEBUG'
    expect(passesFilter 'hi',    10).to.be.false
    expect(passesFilter 'hi',    20).to.be.true
    expect(passesFilter 'hi',    30).to.be.true
    expect(passesFilter 'hello', 20).to.be.false
    expect(passesFilter 'hello', 30).to.be.true
    expect(passesFilter 'hello', 40).to.be.true

  describe 'wildcards', ->
    it 'should correctly apply the default configuration (*:DEBUG)', ->
      config ''
      expect(passesFilter 'src3',  10).to.be.false
      expect(passesFilter 'hi',    20).to.be.true
      expect(passesFilter 'hello', 30).to.be.true
      expect(passesFilter 'there', 50).to.be.true

    it "should correctly apply: '*:*'", ->
      config '*:*'
      expect(passesFilter 'src3',  10).to.be.true
      expect(passesFilter 'hi',    20).to.be.true
      expect(passesFilter 'hello', 30).to.be.true
      expect(passesFilter 'there', 50).to.be.true

    it "should correctly apply: '-*'", ->
      config '-*'
      expect(passesFilter 'src3',  10).to.be.false
      expect(passesFilter 'hi',    20).to.be.false
      expect(passesFilter 'hello', 30).to.be.false
      expect(passesFilter 'there', 50).to.be.false

    it "should correctly apply: 'h*:DEBUG'", ->
      config 'h*:DEBUG'
      expect(passesFilter 'rand',  40).to.be.false
      expect(passesFilter 'hi',    10).to.be.false
      expect(passesFilter 'hi',    20).to.be.true
      expect(passesFilter 'hi',    30).to.be.true
      expect(passesFilter 'hello', 10).to.be.false
      expect(passesFilter 'hello', 20).to.be.true
      expect(passesFilter 'hello', 30).to.be.true

    it "should correctly apply: 'h*:DEBUG, -he*'", ->
      config 'h*:DEBUG, -he*'
      expect(passesFilter 'rand',  40).to.be.false
      expect(passesFilter 'hi',    10).to.be.false
      expect(passesFilter 'hi',    20).to.be.true
      expect(passesFilter 'hi',    30).to.be.true
      expect(passesFilter 'hello', 10).to.be.false
      expect(passesFilter 'hello', 20).to.be.false
      expect(passesFilter 'hello', 30).to.be.false
