_                 = require '../../vendor/lodash'
React             = require 'react'
ReactRedux        = require 'react-redux'
Login             = require './010-login'
Icon              = require './910-icon'
actions           = require '../actions/actions'

mapStateToProps = (state) -> 
  settings:       state.settings
mapDispatchToProps = (dispatch) ->
  setShowClosedActions: (fEnabled) -> dispatch actions.setShowClosedActions fEnabled

Settings = React.createClass
  displayName: 'Settings'

  #-----------------------------------------------------
  propTypes:
    onClose:              React.PropTypes.func.isRequired
    # From Redux.connect
    settings:             React.PropTypes.object.isRequired
    setShowClosedActions: React.PropTypes.func.isRequired
  getInitialState: ->
    fCanSave: true

  componentDidMount: -> @checkLocalStorage()

  #-----------------------------------------------------
  render: -> 
    <div className="settings" style={_style.outer}>
      {@renderLocalStorageWarning()}
      <Icon 
        icon="close" 
        size="lg" 
        onClick={@props.onClose}
        style={_style.closeIcon}
      />
      <div>
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
    </div>

  renderLocalStorageWarning: ->
    return if @state.fCanSave
    <div className="allowUserSelect" style={_style.localStorageWarning}>
      Changes to these settings can't be saved (beyond your current session)
      due to your current Chrome configuration. Please visit 
      <b>chrome://settings/content</b> and
      uncheck the option "Block third-party cookies and site 
      data". Then close the Chrome DevTools and open them again.
    </div>

  #-----------------------------------------------------
  onClickShowClosedActions: (ev) -> 
    @props.setShowClosedActions ev.target.checked

  #-----------------------------------------------------
  checkLocalStorage: ->
    try
      ls = localStorage.foo
      @setState fCanSave: true
    catch e
      @setState fCanSave: false

#-----------------------------------------------------
_style = 
  outer:
    position: 'fixed'
    top: 0
    left: 0
    right: 0
    margin: 10
    zIndex: 1000
    backgroundColor: 'white'
    padding: 20
    boxShadow: "0 3px 6px rgba(0,0,0,0.16), 0 3px 6px rgba(0,0,0,0.23)"
    borderRadius: 2
  closeIcon:
    position: 'absolute'
    right: 5
    top: 5
    cursor: 'pointer'
  localStorageWarning:
    color: 'red'
    border: "1px solid red"
    padding: 15
    marginBottom: 10
    borderRadius: 2

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, mapDispatchToProps
module.exports = connect Settings
