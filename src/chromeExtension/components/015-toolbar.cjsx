_                 = require '../../vendor/lodash'
React             = require 'react'
ReactRedux        = require 'react-redux'
actions           = require '../actions/actions'

mapStateToProps = (state) -> 
  settings:       state.settings
mapDispatchToProps = (dispatch) ->
  expandAllStories:   -> dispatch actions.expandAllStories()
  collapseAllStories: -> dispatch actions.collapseAllStories()
  setShowClosedActions: (fEnabled) -> dispatch actions.setShowClosedActions fEnabled

Toolbar = React.createClass
  displayName: 'Toolbar'

  #-----------------------------------------------------
  propTypes:
    # From Redux.connect
    settings:             React.PropTypes.object.isRequired
    expandAllStories:     React.PropTypes.func.isRequired
    collapseAllStories:   React.PropTypes.func.isRequired
    setShowClosedActions: React.PropTypes.func.isRequired

  #-----------------------------------------------------
  render: -> 
    <div style={_style.outer}>
      <button onClick={@props.expandAllStories}>Expand all</button>
      {' '}
      <button onClick={@props.collapseAllStories}>Collapse all</button>
      {' '}
      <input 
        id="closedActions"
        type="checkbox"
        checked={@props.settings.fShowClosedActions}
        onChange={@onClickShowClosedActions}
      />
      <label htmlFor="closedActions">
        Show <i>CLOSED</i> actions
      </label>
    </div>

  onClickShowClosedActions: (ev) -> 
    @props.setShowClosedActions ev.target.checked

#-----------------------------------------------------
_style = 
  outer:
    marginBottom: 10

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, mapDispatchToProps
module.exports = connect Toolbar
