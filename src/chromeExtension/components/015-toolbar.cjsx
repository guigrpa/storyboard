_                 = require '../../vendor/lodash'
React             = require 'react'
ReactRedux        = require 'react-redux'
actions           = require '../actions/actions'

mapStateToProps = (state) -> 
  settings:       state.settings
mapDispatchToProps = (dispatch) ->
  onExpandAllStories:   -> dispatch actions.expandAllStories()
  onCollapseAllStories: -> dispatch actions.collapseAllStories()

Toolbar = React.createClass
  displayName: 'Toolbar'

  #-----------------------------------------------------
  propTypes:
    # From Redux.connect
    settings:               React.PropTypes.object.isRequired
    onExpandAllStories:     React.PropTypes.func.isRequired
    onCollapseAllStories:   React.PropTypes.func.isRequired

  #-----------------------------------------------------
  render: -> 
    <div style={_style.outer}>
      <button onClick={@props.onExpandAllStories}>Expand all</button>
      {' '}
      <button onClick={@props.onCollapseAllStories}>Collapse all</button>
    </div>

#-----------------------------------------------------
_style = 
  outer:
    marginBottom: 10

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, mapDispatchToProps
module.exports = connect Toolbar
