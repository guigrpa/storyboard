_ = require 'lodash'
chalk = require 'chalk'
ansiColors = require '../lib/gral/ansiColors'

RED = "#cc0000"

describe 'ansiColors', ->

  it 'should provide unique colors for different sources', ->
    fn = ansiColors.getSrcChalkColor 'src1'
    expect(_.isFunction fn).to.be.true
    fn2 = ansiColors.getSrcChalkColor 'src1'
    expect(fn2).to.equal fn
    fn3 = ansiColors.getSrcChalkColor 'src2'
    expect(fn3).not.to.equal fn

  describe 'ANSI color conversion', ->

    describe 'converting ANSI to console arguments', ->

      it 'should handle a simple case', ->
        text = "A #{chalk.red 'simple'} test"
        args = ansiColors.getBrowserConsoleArgs text
        expect(args).to.deep.equal [
          "A %csimple%c test"
          "color: #{RED}"
          ''
        ]

      it 'should support ANSI background colors', ->
        text = chalk.bgRed 'inverted'
        args = ansiColors.getBrowserConsoleArgs text
        expect(args).to.deep.equal [
          '%cinverted%c'
          "color: white; background-color: #{RED}"
          ''
        ]

    describe 'converting ANSI to styled segments', ->

      it 'should handle a simple case', ->
        text = "A #{chalk.red 'simple'} test"
        segments = ansiColors.getStyledSegments text
        expect(segments).to.deep.equal [
          text: 'A '
          style: {}
        ,
          text: 'simple'
          style: color: RED
        ,
          text: ' test'
          style: {}
        ]

      it 'should support ANSI background colors', ->
        text = chalk.bgRed 'inverted'
        args = ansiColors.getStyledSegments text
        expect(args).to.deep.equal [
          text: 'inverted'
          style: {color: 'white', backgroundColor: RED}
        ]

      it 'should not include extra, empty segments', ->
        text = "#{chalk.red.bold 'Three'} babies"
        segments = ansiColors.getStyledSegments text
        expect(segments).to.deep.equal [
          text: 'Three'
          style: {color: RED, fontWeight: 'bold'}
        ,
          text: ' babies'
          style: {}
        ]

      it 'should return [] for non-strings', ->
        expect(ansiColors.getStyledSegments null).to.have.length 0

    it 'should support ANSI reset', ->
      text = chalk.red "Red #{chalk.reset 'tomatoes'}"
      args = ansiColors.getBrowserConsoleArgs text
      expect(args).to.deep.equal [
        "%cRed %ctomatoes%c%c"
        "color: #{RED}"
        ''
        ''
        ''
      ]

    it 'should support ANSI modifiers', ->
      text = "An #{chalk.bold 'important'} remark"
      args = ansiColors.getBrowserConsoleArgs text
      expect(args).to.deep.equal [
        "An %cimportant%c remark"
        'font-weight: bold'
        ''
      ]
