_                 = require '../../vendor/lodash'
React             = require 'react'
ReactRedux        = require 'react-redux'
{ Icon }          = require 'giu'
Login             = require './010-login'
Settings          = require './016-settings'
actions           = require '../actions/actions'

mapStateToProps = (state) -> 
  settings:       state.settings
  wsState:        state.cx.wsState
mapDispatchToProps = (dispatch) ->
  expandAllStories:   -> dispatch actions.expandAllStories()
  collapseAllStories: -> dispatch actions.collapseAllStories()
  clearLogs:          -> dispatch actions.clearLogs()
  quickFind: (txt) -> dispatch actions.quickFind txt

Toolbar = React.createClass
  displayName: 'Toolbar'

  #-----------------------------------------------------
  propTypes:
    # From Redux.connect
    settings:             React.PropTypes.object.isRequired
    wsState:              React.PropTypes.string.isRequired
    expandAllStories:     React.PropTypes.func.isRequired
    collapseAllStories:   React.PropTypes.func.isRequired
  getInitialState: ->
    fSettingsShown:       false


  #-----------------------------------------------------
  render: -> 
    <div>
      {@renderSettings()}
      <div style={_style.outer}>
        <div style={_style.left}>
          <Icon 
            icon="cog" 
            size="lg"
            title="Show settings..."
            onClick={@toggleSettings}
            style={_style.icon}
          />
          <Icon 
            icon="chevron-circle-down" 
            size="lg" 
            title="Expand all stories"
            onClick={@props.expandAllStories}
            style={_style.icon}
          />
          <Icon 
            icon="chevron-circle-right" 
            size="lg" 
            title="Collapse all stories"
            onClick={@props.collapseAllStories}
            style={_style.icon}
          />
          <Icon 
            icon="remove"
            size="lg" 
            title="Clear logs"
            onClick={@props.clearLogs}
            style={_style.icon}
          />
          {' '}
          <input
            id="quickFind"
            type="search"
            results=0
            placeholder="Quick find..."
            onChange={@onChangeQuickFind}
          />
          {@renderWsStatus()}
        </div>
        <div style={_style.spacer}/>
        <Login/>
      </div>
      <div style={_style.placeholder}/>
    </div>

  renderSettings: ->
    return if not @state.fSettingsShown
    <Settings onClose={@toggleSettings}/>

  renderWsStatus: ->
    fConnected = @props.wsState is 'CONNECTED'
    if fConnected
      icon = 'chain'
      title = 'Connection with the server is UP'
    else
      icon = 'chain-broken'
      title = 'Connection with the server is DOWN'
    <Icon 
      icon={icon}
      size="lg" 
      title={title}
      style={_style.wsStatus fConnected}
    />

  #-----------------------------------------------------
  toggleSettings: -> @setState {fSettingsShown: not @state.fSettingsShown}
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
    whiteSpace: 'nowrap'
    zIndex: 10
  icon:
    cursor: 'pointer'
    color: '#666'
    marginRight: 10
  wsStatus: (fConnected) ->
    marginRight: 5
    marginLeft: 10
    color: if fConnected then 'green' else 'red'
    cursor: 'default'
  placeholder:
    height: 30
  left:
    padding: "4px 4px 4px 8px"
  right:
    padding: "4px 8px 4px 4px"
  spacer:
    flex: '1 1 0px'

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, mapDispatchToProps
module.exports = connect Toolbar
