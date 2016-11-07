import React from 'react';
import * as ReactRedux from 'react-redux';
import { Icon, isDark } from 'giu';
import Login from './010-login';
import Settings from './016-settings';
import actions from '../actions/actions';  // eslint-disable-line import/no-unresolved, import/extensions

const mapStateToProps = (state) => ({
  wsState: state.cx.wsState,
});
const mapDispatchToProps = {
  expandAllStories: actions.expandAllStories,
  collapseAllStories: actions.collapseAllStories,
  clearLogs: actions.clearLogs,
  quickFind: actions.quickFind,
};

class Toolbar extends React.PureComponent {
  static propTypes = {
    colors: React.PropTypes.object.isRequired,
    // From Redux.connect
    wsState: React.PropTypes.string.isRequired,
    expandAllStories: React.PropTypes.func.isRequired,
    collapseAllStories: React.PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);
    this.state = {
      fSettingsShown: false,
    };
  }

  // -----------------------------------------------------
  render() {
    const { colors } = this.props;
    return (
      <div>
        {this.renderSettings()}
        <div style={style.outer(colors)}>
          <div style={style.left}>
            <Icon
              id="sbBtnShowSettings"
              icon="cog"
              size="lg"
              title="Show settings..."
              onClick={this.toggleSettings}
              style={style.icon(colors)}
            />
            <Icon
              icon="chevron-circle-down"
              size="lg"
              title="Expand all stories"
              onClick={this.props.expandAllStories}
              style={style.icon(colors)}
            />
            <Icon
              icon="chevron-circle-right"
              size="lg"
              title="Collapse all stories"
              onClick={this.props.collapseAllStories}
              style={style.icon(colors)}
            />
            <Icon
              icon="remove"
              size="lg"
              title="Clear logs"
              onClick={this.props.clearLogs}
              style={style.icon(colors)}
            />
            {' '}
            <input
              id="quickFind"
              type="search"
              results={0}
              placeholder="Quick find..."
              onChange={this.onChangeQuickFind}
              style={style.quickFind(colors)}
            />
            {this.renderWsStatus()}
          </div>
          <div style={style.spacer} />
          <Login colors={colors} />
        </div>
        <div style={style.placeholder} />
      </div>
    );
  }

  renderSettings() {
    if (!this.state.fSettingsShown) return null;
    return (
      <Settings
        onClose={this.toggleSettings}
        colors={this.props.colors}
      />
    );
  }

  renderWsStatus() {
    const fConnected = this.props.wsState === 'CONNECTED';
    const icon = fConnected ? 'chain' : 'chain-broken';
    const title = fConnected
      ? 'Connection with the server is UP'
      : 'Connection with the server is DOWN';
    return (
      <Icon
        icon={icon}
        size="lg"
        title={title}
        style={style.wsStatus(fConnected)}
      />
    );
  }

  // -----------------------------------------------------
  toggleSettings = () => {
    this.setState({ fSettingsShown: !this.state.fSettingsShown });
  }

  onChangeQuickFind = (ev) => {
    this.props.quickFind(ev.target.value);
  }
}

// -----------------------------------------------------
const style = {
  outer: (colors) => {
    const rulerColor = isDark(colors.colorUiBg) ? '#ccc' : '#555';
    return {
      position: 'fixed',
      top: 0,
      left: 0,
      height: 30,
      width: '100%',
      backgroundColor: colors.colorUiBg,
      borderBottom: `1px solid ${rulerColor}`,
      display: 'flex',
      flexDirection: 'row',
      whiteSpace: 'nowrap',
      zIndex: 10,
    };
  },
  icon: (colors) => ({
    cursor: 'pointer',
    color: colors.colorUiFg,
    marginRight: 10,
  }),
  wsStatus: (fConnected) => ({
    marginRight: 5,
    marginLeft: 10,
    color: fConnected ? 'green' : 'red',
    cursor: 'default',
  }),
  placeholder: { height: 30 },
  left: { padding: '4px 4px 4px 8px' },
  right: { padding: '4px 8px 4px 4px' },
  spacer: { flex: '1 1 0px' },
  quickFind: (colors) => ({
    backgroundColor: 'transparent',
    color: colors.colorUiFg,
    borderWidth: 1,
  }),
};

// -----------------------------------------------------
const connect = ReactRedux.connect(mapStateToProps, mapDispatchToProps);
export default connect(Toolbar);
export { Toolbar as _Toolbar };
