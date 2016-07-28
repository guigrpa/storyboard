_                 = require '../../vendor/lodash'
timm              = require 'timm'
React             = require 'react'
ReactRedux        = require 'react-redux'
{
  Icon,
  Modal,
  Checkbox, TextInput, NumberInput, ColorInput,
}                 = require 'giu'
Promise           = require 'bluebird'
Login             = require './010-login'
actions           = require '../actions/actions'
DEFAULT_SETTINGS  = require('../reducers/settingsReducer').DEFAULT_SETTINGS

FORM_KEYS = [
  'fShowClosedActions',
  'fShorthandForDuplicates',
  'fCollapseAllNewStories',
  'fExpandAllNewAttachments',
  'fDiscardRemoteClientLogs',
  'serverFilter', 'localClientFilter',
  'maxRecords', 'forgetHysteresis',
  'mainColor',
]

mapStateToProps = (state) ->
  settings:       state.settings
  serverFilter:   state.cx.serverFilter
  localClientFilter: state.cx.localClientFilter

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
  getInitialState: -> timm.merge {}, @props.settings,
    _fCanSave: true
    # maxRecords: @props.settings.maxRecords
    # forgetHysteresis: @props.settings.forgetHysteresis
    cmdsToInputs: null

  componentDidMount: -> @checkLocalStorage()
  componentWillReceiveProps: (nextProps) ->
    { maxRecords, forgetHysteresis } = nextProps.settings;
    @setState({ maxRecords, forgetHysteresis })

  #-----------------------------------------------------
  render: ->
    buttons = [
      {label: 'Cancel', onClick: @props.onClose, left: true}
      {label: 'Reset defaults', onClick: @onReset, left: true}
      {label: 'Save', onClick: @onSubmit, defaultButton: true}
    ]
    {cmdsToInputs} = @state
    <Modal
      buttons={buttons}
      onEsc={@props.onClose}
    >
      {@renderLocalStorageWarning()}
      <Checkbox ref="fShowClosedActions"
        label={<span>Show <i>CLOSED</i> actions</span>}
        value={@state.fShowClosedActions}
        cmds={cmdsToInputs}
      /><br />
      <Checkbox ref="fShorthandForDuplicates"
        label={
          <span>
            Use shorthand notation for identical consecutive logs ( <Icon icon="copy" style={_style.icon} disabled /> )
          </span>
        }
        value={@state.fShorthandForDuplicates}
        cmds={cmdsToInputs}
      /><br />
      <Checkbox ref="fCollapseAllNewStories"
        label="Collapse all new stories (even if they are still open)"
        value={@state.fCollapseAllNewStories}
        cmds={cmdsToInputs}
      /><br />
      <Checkbox ref="fExpandAllNewAttachments"
        label="Expand all attachments upon receipt"
        value={@state.fExpandAllNewAttachments}
        cmds={cmdsToInputs}
      /><br />
      <Checkbox ref="fDiscardRemoteClientLogs"
        label="Discard stories from remote clients upon receipt"
        value={@state.fDiscardRemoteClientLogs}
        cmds={cmdsToInputs}
      /><br />
      <br />
      {@renderLogFilters()}
      {@renderForgetSettings()}
      {@renderColor()}
      {@renderVersion()}
    </Modal>

  renderLogFilters: ->
    {cmdsToInputs} = @state
    return [
      <div key="filterTitle" style={{marginBottom: 5}}>
        Log filters, e.g. <b>foo, ba*:INFO, -test, *:WARN</b>{' '}
        <a href="https://github.com/guigrpa/storyboard#log-filtering" target="_blank" style={_style.link}>
          (more examples here)
        </a>:
      </div>
    ,
      <ul key="filterList" style={_style.filters.list}>
        <li>
          <label htmlFor="serverFilter" style={_style.filters.itemLabel}>
            Server:
          </label>{' '}
          <TextInput ref="serverFilter"
            id="serverFilter"
            value={@props.serverFilter}
            required errorZ={52}
            style={{width: 300}}
            cmds={cmdsToInputs}
          />
        </li>
        <li>
          <label htmlFor="localClientFilter" style={_style.filters.itemLabel}>
            Local client:
          </label>{' '}
          <TextInput ref="localClientFilter"
            id="localClientFilter"
            value={@props.localClientFilter}
            required errorZ={52}
            style={{width: 300}}
            cmds={cmdsToInputs}
          />
        </li>
      </ul>
    ]

  # For maxRecords and forgetHysteresis, we keep track of their current values
  # to update the tooltip accordingly
  renderForgetSettings: ->
    {cmdsToInputs} = @state
    <div>
      <label htmlFor="maxRecords">
        Number of logs and stories to remember:
      </label>{' '}
      <NumberInput ref="maxRecords"
        id="maxRecords"
        step={1} min={0}
        value={@state.maxRecords}
        onChange={(ev, maxRecords) => @setState({ maxRecords })}
        style={{width: 50}}
        required errorZ={52}
        cmds={cmdsToInputs}
      />{' '}
      <label htmlFor="forgetHysteresis">
        with hysteresis:
      </label>{' '}
      <NumberInput ref="forgetHysteresis"
        id="forgetHysteresis"
        step={.05} min={0} max={1}
        value={@state.forgetHysteresis}
        onChange={(ev, forgetHysteresis) => @setState({ forgetHysteresis })}
        style={{width: 50}}
        required errorZ={52}
        cmds={cmdsToInputs}
      />{' '}
      <Icon
        icon="info-circle"
        title={@maxLogsDesc()}
        style={_style.maxLogsDesc}
      />
    </div>

  renderColor: ->
    {cmdsToInputs} = @state
    <div>
      UI color:{' '}
      <ColorInput ref="mainColor"
        id="mainColor"
        value={@state.mainColor}
        floatZ={52}
        styleOuter={{position: 'relative', top: 5}}
        cmds={cmdsToInputs}
      />{' '}
      (choose light colors for best results)
    </div>

  renderVersion: ->
    return if not process.env.STORYBOARD_VERSION
    <div style={_style.version}>
      Storyboard DevTools v{process.env.STORYBOARD_VERSION}<br/>
      (c) <a href="https://github.com/guigrpa" target="_blank" style={_style.link}>Guillermo Grau</a> 2016
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
    hyst = @state.forgetHysteresis
    hi = @state.maxRecords
    lo = hi - hi * hyst
    return "When the backlog reaches #{hi}, Storyboard will " +
      "start forgetting old stuff until it goes below #{lo}"

  #-----------------------------------------------------
  onSubmit: ->
    settings = {}
    Promise.map FORM_KEYS, (key) =>
      ref = this.refs[key]
      if not(ref) then throw new Error('Could not read form')
      this.refs[key].validateAndGetValue()
      .then (val) -> settings[key] = val
    .then =>
      persistedSettings = timm.omit(settings, ['serverFilter', 'localClientFilter'])
      @props.updateSettings persistedSettings
      if settings.serverFilter isnt @props.serverFilter
        @props.setServerFilter settings.serverFilter
      if settings.localClientFilter isnt @props.localClientFilter
        @props.setLocalClientFilter settings.localClientFilter
      @props.onClose()
    return

  # Reset to factory settings, and send a `REVERT` command to all inputs
  onReset: ->
    @setState DEFAULT_SETTINGS
    # setTimeout due to a potential bug in Giu
    setTimeout => @setState cmdsToInputs: [{ type: 'REVERT' }]
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
  version:
    textAlign: 'right'
    color: '#888'
    marginTop: 8
    marginBottom: 8
  link:
    color: 'currentColor'
  icon:
    color: 'currentColor'
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
connect = ReactRedux.connect mapStateToProps, actions
module.exports = connect Settings
