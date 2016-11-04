import React from 'react';
import * as ReactRedux from 'react-redux';
import { merge, omit } from 'timm';
import {
  Icon, Modal, Button,
  Checkbox, TextInput, NumberInput, ColorInput,
} from 'giu';
import Promise from 'bluebird';
import actions from '../actions/actions';
import { DEFAULT_SETTINGS } from '../reducers/settingsReducer';

const FORM_KEYS = [
  'fShowClosedActions',
  'fShorthandForDuplicates',
  'fCollapseAllNewStories',
  'fExpandAllNewAttachments',
  'fDiscardRemoteClientLogs',
  'serverFilter', 'localClientFilter',
  'maxRecords', 'forgetHysteresis',
  'colorClientBg', 'colorServerBg', 'colorUiBg',
];

let idxPresetColors = 2;  // next one will be dark!
const PRESET_COLORS = [
  { colorClientBg: 'aliceblue', colorServerBg: 'rgb(214, 236, 255)', colorUiBg: 'white' },
  { colorClientBg: 'rgb(255, 240, 240)', colorServerBg: 'rgb(255, 214, 215)', colorUiBg: 'white' },
  { colorClientBg: 'rgb(250, 240, 255)', colorServerBg: 'rgb(238, 214, 255)', colorUiBg: 'white' },
  { colorClientBg: 'rgb(17, 22, 54)', colorServerBg: 'rgb(14, 11, 33)', colorUiBg: 'black' },
];

const mapStateToProps = (state) => ({
  settings: state.settings,
  serverFilter: state.cx.serverFilter,
  localClientFilter: state.cx.localClientFilter,
});

class Settings extends React.Component {
  static propTypes = {
    onClose: React.PropTypes.func.isRequired,
    colors: React.PropTypes.object.isRequired,
    // From Redux.connect
    settings: React.PropTypes.object.isRequired,
    serverFilter: React.PropTypes.string,
    localClientFilter: React.PropTypes.string,
    updateSettings: React.PropTypes.func.isRequired,
    setServerFilter: React.PropTypes.func.isRequired,
    setLocalClientFilter: React.PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);
    this.state = merge({}, this.props.settings, {
      _fCanSave: true,
      cmdsToInputs: null,
    });
  }

  componentDidMount() {
    this.checkLocalStorage();
  }

  componentWillReceiveProps(nextProps) {
    const { maxRecords, forgetHysteresis } = nextProps.settings;
    return this.setState({ maxRecords, forgetHysteresis });
  }

  // -----------------------------------------------------
  render() {
    const { colors } = this.props;
    const buttons = [
      { label: 'Cancel', onClick: this.props.onClose, left: true },
      { label: 'Reset defaults', onClick: this.onReset, left: true },
      {
        label: 'Save',
        onClick: this.onSubmit,
        defaultButton: true,
        style: style.modalDefaultButton(colors),
      },
    ];
    const { cmdsToInputs } = this.state;
    return (
      <Modal
        buttons={buttons}
        onEsc={this.props.onClose}
        style={style.modal(colors)}
      >
        {this.renderLocalStorageWarning()}
        <Checkbox
          ref="fShowClosedActions"
          label={<span>Show <i>CLOSED</i> actions</span>}
          value={this.state.fShowClosedActions}
          cmds={cmdsToInputs}
        /><br />
        <Checkbox
          ref="fShorthandForDuplicates"
          label={
            <span>
              Use shorthand notation for identical consecutive
              logs ( <Icon icon="copy" style={style.icon} disabled /> )
            </span>
          }
          value={this.state.fShorthandForDuplicates}
          cmds={cmdsToInputs}
        /><br />
        <Checkbox
          ref="fCollapseAllNewStories"
          label="Collapse all new stories (even if they are still open)"
          value={this.state.fCollapseAllNewStories}
          cmds={cmdsToInputs}
        /><br />
        <Checkbox
          ref="fExpandAllNewAttachments"
          label="Expand all attachments upon receipt"
          value={this.state.fExpandAllNewAttachments}
          cmds={cmdsToInputs}
        /><br />
        <Checkbox
          ref="fDiscardRemoteClientLogs"
          label="Discard stories from remote clients upon receipt"
          value={this.state.fDiscardRemoteClientLogs}
          cmds={cmdsToInputs}
        /><br />
        <br />
        {this.renderLogFilters()}
        {this.renderForgetSettings()}
        {this.renderColors()}
        {this.renderVersion()}
      </Modal>
    );
  }

  renderLogFilters() {
    const { cmdsToInputs } = this.state;
    return [
      <div key="filterTitle" style={{ marginBottom: 5 }}>
        Log filters, e.g. <b>foo, ba*:INFO, -test, *:WARN</b>{' '}
        <a
          href="https://github.com/guigrpa/storyboard#log-filtering"
          target="_blank"
          style={style.link}
        >
          (more examples here)
        </a>:
      </div>,
      // ------------------------------------------------
      <ul key="filterList" style={style.filters.list}>
        <li>
          <label htmlFor="serverFilter" style={style.filters.itemLabel}>
            Server:
          </label>{' '}
          <TextInput
            ref="serverFilter"
            id="serverFilter"
            value={this.props.serverFilter}
            required errorZ={52}
            style={style.textNumberInput(300)}
            cmds={cmdsToInputs}
          />
        </li>
        <li>
          <label htmlFor="localClientFilter" style={style.filters.itemLabel}>
            Local client:
          </label>{' '}
          <TextInput
            ref="localClientFilter"
            id="localClientFilter"
            value={this.props.localClientFilter}
            required errorZ={52}
            style={style.textNumberInput(300)}
            cmds={cmdsToInputs}
          />
        </li>
      </ul>,
    ];
  }

  renderForgetSettings() {
    const { cmdsToInputs } = this.state;
    return (
      <div>
        <label htmlFor="maxRecords">
          Number of logs and stories to remember:
        </label>{' '}
        <NumberInput
          ref="maxRecords"
          id="maxRecords"
          step={1} min={0}
          value={this.state.maxRecords}
          onChange={(ev, maxRecords) => this.setState({ maxRecords })}
          style={style.textNumberInput(50)}
          required errorZ={52}
          cmds={cmdsToInputs}
        />{' '}
        <label htmlFor="forgetHysteresis">
          with hysteresis:
        </label>{' '}
        <NumberInput
          ref="forgetHysteresis"
          id="forgetHysteresis"
          step={0.05} min={0} max={1}
          value={this.state.forgetHysteresis}
          onChange={(ev, forgetHysteresis) => this.setState({ forgetHysteresis })}
          style={style.textNumberInput(50)}
          required errorZ={52}
          cmds={cmdsToInputs}
        />{' '}
        <Icon
          icon="info-circle"
          title={this.maxLogsDesc()}
          style={style.maxLogsDesc}
        />
      </div>
    );
  }

  renderColors() {
    const { cmdsToInputs } = this.state;
    return (
      <div>
        Colors:
        client stories:
        {' '}
        <ColorInput
          ref="colorClientBg"
          id="colorClientBg"
          value={this.state.colorClientBg}
          floatZ={52}
          styleOuter={style.colorInput}
          cmds={cmdsToInputs}
        />
        {' '}
        server stories:
        {' '}
        <ColorInput
          ref="colorServerBg"
          id="colorServerBg"
          value={this.state.colorServerBg}
          floatZ={52}
          styleOuter={style.colorInput}
          cmds={cmdsToInputs}
        />
        {' '}
        background:
        {' '}
        <ColorInput
          ref="colorUiBg"
          id="colorUiBg"
          value={this.state.colorUiBg}
          floatZ={52}
          styleOuter={style.colorInput}
          cmds={cmdsToInputs}
        />
        <div style={{ marginTop: 3 }}>
          (Use very light or very dark colors for best results, or choose a
          {' '}
          <Button onClick={this.onClickPresetColors}>preset</Button>)
        </div>
      </div>
    );
  }

  renderVersion() {
    if (!process.env.STORYBOARD_VERSION) return null;
    return (
      <div style={style.version}>
        Storyboard DevTools v{process.env.STORYBOARD_VERSION}<br />
        (c) <a
          href="https://github.com/guigrpa"
          target="_blank"
          style={style.link}
        >
          Guillermo Grau
        </a> 2016
      </div>
    );
  }

  renderLocalStorageWarning() {
    if (this.state._fCanSave) return null;
    const txt1 = "Changes to these settings can't be saved (beyond your current session) " +
      'due to your current Chrome configuration. Please visit ';
    const url = 'chrome://settings/content';
    const txt2 = ' and uncheck the option "Block third-party cookies and site' +
      ' data". Then close the Chrome DevTools and open them again.';
    return (
      <div className="allowUserSelect" style={style.localStorageWarning}>
        {txt1}<b>{url}</b>{txt2}
      </div>
    );
  }

  maxLogsDesc() {
    const hyst = this.state.forgetHysteresis;
    const hi = this.state.maxRecords;
    const lo = hi - hi * hyst;
    return `When the backlog reaches ${hi}, Storyboard will ` +
      `start forgetting old stuff until it goes below ${lo}`;
  }

  // -----------------------------------------------------
  onSubmit = () => {
    const settings = {};
    Promise.map(FORM_KEYS, (key) => {
      const ref = this.refs[key];
      if (!ref) throw new Error('Could not read form');
      return this.refs[key].validateAndGetValue()
      .then((val) => { settings[key] = val; });
    })
    .then(() => {
      const persistedSettings = omit(settings, ['serverFilter', 'localClientFilter']);
      this.props.updateSettings(persistedSettings);
      if (settings.serverFilter !== this.props.serverFilter) {
        this.props.setServerFilter(settings.serverFilter);
      }
      if (settings.localClientFilter !== this.props.localClientFilter) {
        this.props.setLocalClientFilter(settings.localClientFilter);
      }
      this.props.onClose();
    });
  }

  onReset = () => {
    this.setState(DEFAULT_SETTINGS);
    this.setState({
      cmdsToInputs: [{ type: 'REVERT' }],
    });
  }

  onClickPresetColors = () => {
    idxPresetColors = (idxPresetColors + 1) % PRESET_COLORS.length;
    const presetColors = PRESET_COLORS[idxPresetColors];
    this.setState(presetColors);
  }

  checkLocalStorage() {
    try {
      /* eslint-disable no-unused-vars */
      const ls = localStorage.foo;
      /* eslint-enable no-unused-vars */
      this.setState({ _fCanSave: true });
    } catch (error) {
      this.setState({ _fCanSave: false });
    }
  }
}

// -----------------------------------------------------
const style = {
  modal: (colors) => ({
    backgroundColor: colors.colorUiBgIsDark ? 'black' : 'white',
    color: colors.colorUiBgIsDark ? 'white' : 'black',
  }),
  modalDefaultButton: (colors) => ({
    border: colors.colorUiBgIsDark ? '1px solid white' : undefined,
  }),
  version: {
    textAlign: 'right',
    color: '#888',
    marginTop: 8,
    marginBottom: 8,
  },
  link: { color: 'currentColor' },
  icon: { color: 'currentColor' },
  localStorageWarning: {
    color: 'red',
    border: '1px solid red',
    padding: 15,
    marginBottom: 10,
    borderRadius: 2,
  },
  maxLogsDesc: { cursor: 'pointer' },
  filters: {
    list: { marginTop: 0 },
    itemLabel: {
      display: 'inline-block',
      width: 80,
    },
  },
  colorInput: {
    position: 'relative',
    top: 1,
  },
  textNumberInput: (width) => ({
    backgroundColor: 'transparent',
    width,
  }),
};

// -----------------------------------------------------
const connect = ReactRedux.connect(mapStateToProps, actions);
export default connect(Settings);
export { Settings as _Settings };
