/* eslint-env browser */

/* eslint-disable react/no-string-refs */

import React from 'react';
import * as ReactRedux from 'react-redux';
import {
  Floats, Notifications,
  Hints, hintDefine, hintShow,
  LargeMessage,
  Spinner,
  isDark,
} from 'giu';
import tinycolor from 'tinycolor2';
import pick from 'lodash/pick';
import Toolbar from './015-toolbar';
import Story from './020-story';
// let ReduxDevTools;
// if process.env.NODE_ENV isnt 'production' {
//   ReduxDevTools = require('../components/990-reduxDevTools')
// }

require('./app.sass');

const mapStateToProps = (state) => ({
  fRelativeTime: state.settings.timeType === 'RELATIVE',
  cxState: state.cx.cxState,
  mainStory: state.stories.mainStory,
  colors: pick(state.settings, [
    'colorClientBg', 'colorServerBg', 'colorUiBg',
    'colorClientFg', 'colorServerFg', 'colorUiFg',
    'colorClientBgIsDark', 'colorServerBgIsDark', 'colorUiBgIsDark',
  ]),
});

class App extends React.PureComponent {
  static propTypes = {
    // From Redux.connect
    fRelativeTime: React.PropTypes.bool.isRequired,
    cxState: React.PropTypes.string.isRequired,
    mainStory: React.PropTypes.object.isRequired,
    colors: React.PropTypes.object.isRequired,
  };

  constructor(props) {
    super(props);
    this.state = {
      seqFullRefresh: 0,
      timeRef: null,
    };
  }

  componentDidMount() {
    this.timerFullRefresh = setInterval(this.fullRefresh, 30e3);
    window.addEventListener('scroll', this.onScroll);
    this.showHint();
  }

  componentWillUnmount() {
    clearInterval(this.timerFullRefresh);
    this.timerFullRefresh = null;
    window.removeEventListener('scroll', this.onScroll);
  }

  componentDidUpdate() {
    if (this.fAnchoredToBottom) {
      window.scrollTo(0, document.body.scrollHeight);
    }
    this.showHint();
  }

  // -----------------------------------------------------
  fullRefresh = () => {
    if (!this.props.fRelativeTime) return;
    this.setState({
      seqFullRefresh: this.state.seqFullRefresh + 1,
    });
  }

  onScroll = () => {
    const bcr = this.refs.outer.getBoundingClientRect();
    this.fAnchoredToBottom = bcr.bottom - window.innerHeight < 30;
  }

  // -----------------------------------------------------
  render() {
    let reduxDevTools;
    const { cxState, colors } = this.props;
    // if (process.env.NODE_ENV isnt 'production') {
    //   reduxDevTools = <ReduxDevTools />
    // }
    const fConnected = cxState === 'CONNECTED';
    return (
      <div ref="outer" id="appRoot" style={style.outer(colors)}>
        <Floats />
        <Notifications />
        <Hints />
        {!fConnected && this.renderConnecting()}
        {fConnected && <Toolbar colors={colors} />}
        {fConnected && this.renderStories()}
        {reduxDevTools}
      </div>
    );
  }

  renderStories() {
    return (
      <div style={style.stories}>
        <Story
          story={this.props.mainStory}
          level={0}
          seqFullRefresh={this.state.seqFullRefresh}
          timeRef={this.state.timeRef}
          setTimeRef={this.setTimeRef}
          colors={this.props.colors}
        />
      </div>
    );
  }

  renderConnecting() {
    return (
      <LargeMessage style={style.largeMessage(this.props.colors)}>
        <div><Spinner /> Connecting to Storyboard...</div>{' '}
        <div>Navigate to your Storyboard-equipped app (and log in if required)</div>
      </LargeMessage>
    );
  }

  // -----------------------------------------------------
  setTimeRef = (timeRef) => { this.setState({ timeRef }); }

  showHint() {
    if (this.props.cxState !== 'CONNECTED') return;
    if (this.fAttempted) return;
    this.fAttempted = true;
    const elements = () => {
      const out = [];
      const nodeToolbar = document.getElementById('sbToolbar');
      if (nodeToolbar) {
        const wWin = window.innerWidth;
        const bcr = nodeToolbar.getBoundingClientRect();
        let x;
        x = 50;
        const y = 80;
        if (wWin > 500) {
          out.push({
            type: 'LABEL', x, y, align: 'left',
            children: <span>Settings, collapse/expand…<br />that sort of stuff</span>,
            style: { width: 150 },
          });
          out.push({
            type: 'ARROW', from: { x: x - 5, y },
            to: { x: 20, y: bcr.bottom - 2 },
          });
        }
        // ----------
        x = wWin - 80;
        out.push({
          type: 'LABEL', x, y, align: 'right',
          children: <span>Maybe you need to log in to see <span style={{ color: 'yellow' }}>server logs</span></span>,
          style: { width: 150 },
        });
        out.push({
          type: 'ARROW', from: { x: x + 5, y },
          to: { x: wWin - 50, y: bcr.bottom - 2 },
          counterclockwise: true,
        });
      }
      // ----------
      {
        const x = 50;
        const y = 230;
        out.push({
          type: 'LABEL', x, y, align: 'left',
          children: (
            <span>
              <span style={{ color: '#4df950' }}>Click</span> on timestamps to toggle: local, UTC, relative to now
              <br />
              <span style={{ color: '#4df950' }}>Right-click</span> to set a reference timestamp
            </span>
          ),
          style: { width: 2000 },
        });
        out.push({
          type: 'ARROW', from: { x: x - 5, y },
          to: { x: 20, y: y + 40 },
          counterclockwise: true,
        });
      }
      return out;
    };
    hintDefine('main', { elements, closeLabel: 'Enjoy!' });
    hintShow('main');
  }
}

// -----------------------------------------------------
const style = {
  outer: (colors) => ({
    height: '100%',
    backgroundColor: colors.colorUiBg,
    color: colors.colorUiFg,
  }),
  largeMessage: (colors) => {
    let color = tinycolor(colors.colorUiFg);
    color = isDark(colors.colorUiFg) ? color.lighten(20) : color.darken(20);
    return { color: color.toRgbString() };
  },
  stories: { padding: 4 },
};

// -----------------------------------------------------
const connect = ReactRedux.connect(mapStateToProps);
export default connect(App);
export { App as _App };
