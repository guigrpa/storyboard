_                 = require '../../vendor/lodash'
React             = require 'react'
ReactRedux        = require 'react-redux'
Login             = require './010-login'
actions           = require '../actions/actions'

mapStateToProps = (state) -> 
  settings:       state.settings
mapDispatchToProps = (dispatch) ->
  expandAllStories:   -> dispatch actions.expandAllStories()
  collapseAllStories: -> dispatch actions.collapseAllStories()
  setShowClosedActions: (fEnabled) -> dispatch actions.setShowClosedActions fEnabled
  quickFind: (txt) -> dispatch actions.quickFind txt

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
    <div style={_style.outmost}>
      <div style={_style.outer}>
        <div style={_style.left}>
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
          {' '}
          <input
            id="quickFind"
            type="search"
            results=0
            placeholder="Quick find..."
            onChange={@onChangeQuickFind}
          />
        </div>
        <div style={_style.spacer}/>
        <Login/>
      </div>
      <div style={_style.placeholder}/>
    </div>

  #-----------------------------------------------------
  onClickShowClosedActions: (ev) -> 
    @props.setShowClosedActions ev.target.checked
  onChangeQuickFind: (ev) -> @props.quickFind ev.target.value

#-----------------------------------------------------
_style = 
  outer:
    position: 'fixed'
    top: 0
    left: 0
    height: 30
    width: '100%'
    backgroundColor: 'white'
    borderBottom: '1px solid #ccc'
    display: 'flex'
    flexDirection: 'row'
  placeholder:
    height: 30
  left:
    padding: 4
  spacer:
    flex: '1 1 0px'

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, mapDispatchToProps
module.exports = connect Toolbar
