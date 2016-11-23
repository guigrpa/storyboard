/* eslint-env browser */

/* eslint-disable react/no-string-refs */

import React from 'react';
import * as ReactRedux from 'react-redux';
import {
  Floats, Notifications,
  LargeMessage,
  Spinner,
  isDark,
} from 'giu';
import tinycolor from 'tinycolor2';
import { pick } from '../../vendor/lodash';
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
    };
  }

  componentDidMount() {
    this.timerFullRefresh = setInterval(this.fullRefresh, 30e3);
    window.addEventListener('scroll', this.onScroll);
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
