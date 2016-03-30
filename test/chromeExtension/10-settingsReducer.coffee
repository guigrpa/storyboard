_         = require 'lodash'
timm      = require 'timm'
{expect}  = require './imports'
reducer   = require '../../lib/chromeExtension/reducers/settingsReducer'

#-------------------------------------------------
# ## Tests
#-------------------------------------------------
describe 'settingsReducer', ->
  
  state = null
  beforeEach -> state = reducer undefined, {type: ''}

  it 'should update settings with new values', ->
    state = reducer state,
      type: 'UPDATE_SETTINGS'
      settings:
        maxRecords: 2e3
        forgetHysteresis: 0.5
    expect(state.maxRecords).to.equal 2e3
    expect(state.forgetHysteresis).to.equal 0.5

  it 'should not allow invalid maxRecords', ->
    state = reducer state,
      type: 'UPDATE_SETTINGS'
      settings:
        maxRecords: -25
    expect(state.maxRecords).to.be.above 0
