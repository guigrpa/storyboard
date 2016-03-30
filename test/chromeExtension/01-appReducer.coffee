_         = require 'lodash'
timm      = require 'timm'
{expect}  = require './imports'
reducer   = require '../../lib/chromeExtension/reducers/appReducer'

#-------------------------------------------------
# ## Tests
#-------------------------------------------------
describe 'appReducer', ->
  
  state = null
  beforeEach -> state = reducer undefined, {type: ''}

  it 'should have correct initial state', ->
    expect(state.cx.cxState).to.equal 'DISCONNECTED'
    expect(state.settings.fShorthandForDuplicates).to.be.true
    expect(state.stories.mainStory.records).to.have.length 2

  it 'should process a simple action', ->
    state = reducer state, {type: 'CX_CONNECTED'}
    expect(state.cx.cxState).to.equal 'CONNECTED'
