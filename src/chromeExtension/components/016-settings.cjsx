_                 = require '../../vendor/lodash'
timm              = require 'timm'
React             = require 'react'
ReactRedux        = require 'react-redux'
{
  Icon,
  Modal,
  Checkbox, TextInput, NumberInput,
}                 = require 'giu'
Promise           = require 'bluebird'
Login             = require './010-login'
actions           = require '../actions/actions'

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
  getInitialState: ->
    _fCanSave: true
    maxRecords: @props.settings.maxRecords
    forgetHysteresis: @props.settings.forgetHysteresis

  componentDidMount: -> @checkLocalStorage()
  componentWillReceiveProps: (nextProps) ->
    { maxRecords, forgetHysteresis } = nextProps.settings;
    @setState({ maxRecords, forgetHysteresis })

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
      <Checkbox ref="fShowClosedActions"
        label={<span>Show <i>CLOSED</i> actions</span>}
        value={@props.settings.fShowClosedActions}
      /><br />
      <Checkbox ref="fShorthandForDuplicates"
        label={
          <span>
            Use shorthand notation for identical consecutive logs ( <Icon icon="copy" style={_style.icon} disabled /> )
          </span>
        }
        value={@props.settings.fShorthandForDuplicates}
      /><br />
      <Checkbox ref="fCollapseAllNewStories"
        label="Collapse all new stories (even if they are still open)"
        value={@props.settings.fCollapseAllNewStories}
      /><br />
      <Checkbox ref="fExpandAllNewAttachments"
        label="Expand all attachments upon receipt"
        value={@props.settings.fExpandAllNewAttachments}
      /><br />
      <Checkbox ref="fDiscardRemoteClientLogs"
        label="Discard stories from remote clients upon receipt"
        value={@props.settings.fDiscardRemoteClientLogs}
      />
      <br />
      <br />
      <div>
        <label htmlFor="maxRecords">
          Number of logs and stories to remember:
        </label>{' '}
        <NumberInput ref="maxRecords"
          id="maxRecords"
          step={1} min={0}
          value={@props.settings.maxRecords}
          onChange={(ev, maxRecords) => @setState({ maxRecords })}
          style={{width: 50}}
          required errorZ={52}
        />{' '}
        <label htmlFor="forgetHysteresis">
          with hysteresis:
        </label>{' '}
        <NumberInput ref="forgetHysteresis"
          id="forgetHysteresis"
          step={.05} min={0} max={1}
          value={@props.settings.forgetHysteresis}
          onChange={(ev, forgetHysteresis) => @setState({ forgetHysteresis })}
          style={{width: 50}}
          required errorZ={52}
        />{' '}
        <Icon 
          icon="info-circle"
          title={@maxLogsDesc()}
          style={_style.maxLogsDesc}
        />
      </div>
      <br />
      <div style={{marginBottom: 5}}>
        Log filters, e.g. <b>foo, ba*:INFO, -test, *:WARN</b>{' '}
        <a href="https://github.com/guigrpa/storyboard#log-filtering" target="_blank" style={_style.link}>
          (more examples here)
        </a>:
      </div>
      <ul style={_style.filters.list}>
        <li>
          <label htmlFor="serverFilter" style={_style.filters.itemLabel}>
            Server:
          </label>{' '}
          <TextInput ref="serverFilter"
            id="serverFilter"
            value={@props.serverFilter}
            required errorZ={52}
            style={{width: 300}}
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
          />
        </li>
      </ul>
      {@renderVersion()}
    </Modal>

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
    console.log @state
    hyst = @state.forgetHysteresis
    hi = @state.maxRecords
    lo = hi - hi * hyst
    return "When the backlog reaches #{hi}, Storyboard will " +
      "start forgetting old stuff until it goes below #{lo}"

  #-----------------------------------------------------
  onSubmit: ->
    settings = {}
    keys = [
      'fShowClosedActions',
      'fShorthandForDuplicates',
      'fCollapseAllNewStories',
      'fExpandAllNewAttachments',
      'fDiscardRemoteClientLogs',
      'maxRecords', 'forgetHysteresis',
      'serverFilter', 'localClientFilter',
    ]
    Promise.map keys, (key) =>
      ref = this.refs[key]
      if not(ref) then throw new Error('Could not read form')
      this.refs[key].validateAndGetValue()
      .then (val) -> settings[key] = val
    .then =>
      @props.updateSettings timm.omit(settings, ['serverFilter', 'localClientFilter'])
      if settings.serverFilter isnt @props.serverFilter
        @props.setServerFilter settings.serverFilter
      if settings.localClientFilter isnt @props.localClientFilter
        @props.setLocalClientFilter settings.localClientFilter
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
