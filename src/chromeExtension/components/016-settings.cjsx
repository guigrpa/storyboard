_                 = require '../../vendor/lodash'
timm              = require 'timm'
React             = require 'react'
ReactRedux        = require 'react-redux'
{
  Icon,
  Modal,
  Checkbox, TextInput, NumberInput,
}                 = require 'giu'
Login             = require './010-login'
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

  #-----------------------------------------------------
  render: -> 
    buttons = [
      {label: 'Cancel', onClick: @props.onClose, left: true}
      {label: 'Save', onClick: @onSubmit, defaultButton: true}
    ]
    <Modal
      buttons={buttons}
      onEsc={@props.onClose}
    >
      {@renderLocalStorageWarning()}
      <Checkbox 
        id="fShowClosedActions"
        label={<span>Show <i>CLOSED</i> actions</span>}
        value={@state.fShowClosedActions}
        onChange={@onChangeCheckbox}
      /><br />
      <Checkbox 
        id="fShorthandForDuplicates"
        label="Use shorthand notation for identical consecutive logs"
        checked={@state.fShorthandForDuplicates}
        onChange={@onChangeCheckbox}
      /><br />
      <Checkbox 
        id="fCollapseAllNewStories"
        label="Collapse all new stories (even if they are still open)"
        checked={@state.fCollapseAllNewStories}
        onChange={@onChangeCheckbox}
      /><br />
      <Checkbox 
        id="fExpandAllNewAttachments"
        label="Expand all attachments upon receipt"
        checked={@state.fExpandAllNewAttachments}
        onChange={@onChangeCheckbox}
      /><br />
      <Checkbox 
        id="fDiscardRemoteClientLogs"
        label="Discard stories from remote clients upon receipt"
        checked={@state.fDiscardRemoteClientLogs}
        onChange={@onChangeCheckbox}
      />
      <br />
      <br />
      <div>
        <label htmlFor="maxRecords">
          Number of logs and stories to remember:
        </label>
        {' '}
        <NumberInput 
          id="maxRecords"
          step={1}
          value={@state.maxRecords}
          onChange={@onChangeInput}
          style={{width: 50}}
        />
        {' '}
        <label htmlFor="forgetHysteresis">
          with hysteresis:
        </label>
        {' '}
        <NumberInput 
          id="forgetHysteresis"
          step={.05}
          value={@state.forgetHysteresis}
          onChange={@onChangeInput}
          style={{width: 50}}
        />
        {' '}
        <Icon 
          icon="info-circle"
          title={@maxLogsDesc()}
          style={_style.maxLogsDesc}
        />
      </div>
      <br />
      <div style={{marginBottom: 5}}>
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
          <TextInput 
            id="serverFilter"
            value={@state.serverFilter}
            onChange={@onChangeInput}
            style={{width: 300}}
          />
        </li>
        <li>
          <label htmlFor="localClientFilter" style={_style.filters.itemLabel}>
            Local client:
          </label>
          {' '}
          <TextInput 
            id="localClientFilter"
            value={@state.localClientFilter}
            onChange={@onChangeInput}
            style={{width: 300}}
          />
        </li>
      </ul>
    </Modal>

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

  onSubmit: ->
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
    @props.onClose()
    return

  #-----------------------------------------------------
  checkLocalStorage: ->
    try
      ls = localStorage.foo
      @setState _fCanSave: true
    catch e
      @setState _fCanSave: false

#-----------------------------------------------------
_style = 
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
