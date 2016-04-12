_                 = require '../../vendor/lodash'
React             = require 'react'
ReactRedux        = require 'react-redux'
Login             = require './010-login'
Icon              = require './910-icon'
actions           = require '../actions/actions'

mapStateToProps = (state) -> 
  settings:       state.settings
mapDispatchToProps = (dispatch) ->
  updateSettings: (settings) -> dispatch actions.updateSettings settings

Settings = React.createClass
  displayName: 'Settings'

  #-----------------------------------------------------
  propTypes:
    onClose:                    React.PropTypes.func.isRequired
    # From Redux.connect
    settings:                   React.PropTypes.object.isRequired
    updateSettings:             React.PropTypes.func.isRequired
  getInitialState: ->
    _fCanSave: true

  componentWillMount: -> @setState @props.settings
  componentDidMount: -> @checkLocalStorage()

  componentWillUnmount: -> 
    settings = {}
    for key, val of @state
      continue if key[0] is '_'
      settings[key] = switch key
        when 'maxRecords', 'forgetHysteresis' then Number(val)
        else val
    @props.updateSettings settings

  #-----------------------------------------------------
  render: -> 
    <div className="settings" style={_style.outer}>
      {@renderLocalStorageWarning()}
      <Icon 
        icon="close" 
        size="lg"
        title="Save settings and close"
        onClick={@props.onClose}
        style={_style.closeIcon}
      />
      <div>
        <input 
          id="fShowClosedActions"
          type="checkbox"
          checked={@state.fShowClosedActions}
          onChange={@onClickShowClosedActions}
        />
        <label htmlFor="fShowClosedActions">
          Show <i>CLOSED</i> actions
        </label>
      </div>
      <div>
        <input 
          id="fShorthandForDuplicates"
          type="checkbox"
          checked={@state.fShorthandForDuplicates}
          onChange={@onClickShorthandForDuplicates}
        />
        <label htmlFor="fShorthandForDuplicates">
          Use shorthand notation for identical consecutive logs
        </label>
      </div>
      <div>
        <input 
          id="fCollapseAllNewStories"
          type="checkbox"
          checked={@state.fCollapseAllNewStories}
          onChange={@onClickCollapseAllNewStories}
        />
        <label htmlFor="fCollapseAllNewStories">
          Collapse all new stories (even if they are still open)
        </label>
      </div>
      <div>
        <input 
          id="fExpandAllNewAttachments"
          type="checkbox"
          checked={@state.fExpandAllNewAttachments}
          onChange={@onClickExpandAllNewAttachments}
        />
        <label htmlFor="fExpandAllNewAttachments">
          Expand all attachments upon receipt
        </label>
      </div>
      <div>
        <input 
          id="fDiscardRemoteClientLogs"
          type="checkbox"
          checked={@state.fDiscardRemoteClientLogs}
          onChange={@onClickDiscardRemoteClientLogs}
        />
        <label htmlFor="fDiscardRemoteClientLogs">
          Discard stories from remote clients upon receipt
        </label>
      </div>
      <div>
        <label htmlFor="maxRecords">
          Number of logs and stories to remember:
        </label>
        {' '}
        <input 
          id="maxRecords"
          type="number"
          step={1}
          value={@state.maxRecords}
          onChange={@onChangeMaxRecords}
          style={{display: 'inline-block', width: 50}}
        />
        {' '}
        <label htmlFor="forgetHysteresis">
          with hysteresis:
        </label>
        {' '}
        <input 
          id="forgetHysteresis"
          type="number"
          step={.05}
          value={@state.forgetHysteresis}
          onChange={@onChangeForgetHysteresis}
          style={{display: 'inline-block', width: 50}}
        />
        {' '}
        <Icon 
          icon="info-circle"
          title={@maxLogsDesc()}
          style={_style.maxLogsDesc}
        />
      </div>
    </div>

  renderLocalStorageWarning: ->
    return if @state._fCanSave
    <div className="allowUserSelect" style={_style.localStorageWarning}>
      Changes to these settings can't be saved (beyond your current session)
      due to your current Chrome configuration. Please visit 
      <b>chrome://settings/content</b> and
      uncheck the option "Block third-party cookies and site 
      data". Then close the Chrome DevTools and open them again.
    </div>

  maxLogsDesc: ->
    hyst = Number @state.forgetHysteresis
    hi = Number @state.maxRecords
    lo = hi - hi * hyst
    return "When the backlog reaches #{hi}, Storyboard will " +
      "start forgetting old stuff until it goes below #{lo}"

  #-----------------------------------------------------
  onClickShowClosedActions: (ev) -> 
    @setState {fShowClosedActions: ev.target.checked}
  onClickShorthandForDuplicates: (ev) -> 
    @setState {fShorthandForDuplicates: ev.target.checked}
  onClickCollapseAllNewStories: (ev) -> 
    @setState {fCollapseAllNewStories: ev.target.checked}
  onClickExpandAllNewAttachments: (ev) -> 
    @setState {fExpandAllNewAttachments: ev.target.checked}
  onClickDiscardRemoteClientLogs: (ev) ->
    @setState {fDiscardRemoteClientLogs: ev.target.checked}
  onChangeMaxRecords: (ev) -> 
    @setState {maxRecords: ev.target.value}
  onChangeForgetHysteresis: (ev) -> 
    @setState {forgetHysteresis: ev.target.value}

  #-----------------------------------------------------
  checkLocalStorage: ->
    try
      ls = localStorage.foo
      @setState _fCanSave: true
    catch e
      @setState _fCanSave: false

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
  maxLogsDesc:
    cursor: 'pointer'

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, mapDispatchToProps
module.exports = connect Settings
