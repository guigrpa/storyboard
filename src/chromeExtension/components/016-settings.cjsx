_                 = require '../../vendor/lodash'
timm              = require 'timm'
React             = require 'react'
ReactRedux        = require 'react-redux'
Login             = require './010-login'
Icon              = require './910-icon'
actions           = require '../actions/actions'

mapStateToProps = (state) -> 
  settings:       state.settings
  serverFilter:   state.cx.serverFilter
  localClientFilter: state.cx.localClientFilter
mapDispatchToProps = (dispatch) ->
  updateSettings: (settings) -> dispatch actions.updateSettings settings
  setServerFilter: (filter) -> dispatch actions.setServerFilter filter
  setLocalClientFilter: (filter) -> dispatch actions.setLocalClientFilter filter

Settings = React.createClass
  displayName: 'Settings'

  #-----------------------------------------------------
  propTypes:
    onClose:                    React.PropTypes.func.isRequired
    # From Redux.connect
    settings:                   React.PropTypes.object.isRequired
    serverFilter:               React.PropTypes.string
    localClientFilter:          React.PropTypes.string
    updateSettings:             React.PropTypes.func.isRequired
    setServerFilter:            React.PropTypes.func.isRequired
    setLocalClientFilter:       React.PropTypes.func.isRequired
  getInitialState: ->
    _fCanSave: true

  componentWillMount: -> 
    @setState timm.merge @props.settings,
      serverFilter: @props.serverFilter
      localClientFilter: @props.localClientFilter
  componentDidMount: -> @checkLocalStorage()

  componentWillUnmount: -> 
    settings = {}
    for key, val of @state
      continue if key[0] is '_'
      continue if key in ['serverFilter', 'localClientFilter']
      settings[key] = switch key
        when 'maxRecords', 'forgetHysteresis' then Number(val)
        else val
    @props.updateSettings settings
    if @state.serverFilter isnt @props.serverFilter
      @props.setServerFilter @state.serverFilter
    if @state.localClientFilter isnt @props.localClientFilter
      @props.setLocalClientFilter @state.localClientFilter
    return

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
          onChange={@onChangeCheckbox}
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
          onChange={@onChangeCheckbox}
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
          onChange={@onChangeCheckbox}
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
          onChange={@onChangeCheckbox}
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
          onChange={@onChangeCheckbox}
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
          onChange={@onChangeInput}
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
          onChange={@onChangeInput}
          style={{display: 'inline-block', width: 50}}
        />
        {' '}
        <Icon 
          icon="info-circle"
          title={@maxLogsDesc()}
          style={_style.maxLogsDesc}
        />
      </div>
      <div>
        Log filters, e.g. <b>foo, ba*:INFO, -test, *:WARN</b>{' '}
        <a href="https://github.com/guigrpa/storyboard#log-filtering" target="_blank">
          (more examples here)
        </a>:
      </div>
      <ul style={_style.filters.list}>
        <li>
          <label htmlFor="serverFilter" style={_style.filters.itemLabel}>
            Server:
          </label>
          {' '}
          <input 
            id="serverFilter"
            type="text"
            value={@state.serverFilter}
            onChange={@onChangeInput}
            style={{display: 'inline-block', width: 300}}
          />
        </li>
        <li>
          <label htmlFor="localClientFilter" style={_style.filters.itemLabel}>
            Local client:
          </label>
          {' '}
          <input 
            id="localClientFilter"
            type="text"
            value={@state.localClientFilter}
            onChange={@onChangeInput}
            style={{display: 'inline-block', width: 300}}
          />
        </li>
      </ul>
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
  onChangeCheckbox: (ev) -> @setState {"#{ev.target.id}": ev.target.checked}
  onChangeInput:    (ev) -> @setState {"#{ev.target.id}": ev.target.value}

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
  filters:
    list:
      marginTop: 0
    itemLabel:
      display: 'inline-block'
      width: 80

#-----------------------------------------------------
connect = ReactRedux.connect mapStateToProps, mapDispatchToProps
module.exports = connect Settings
