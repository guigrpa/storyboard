import React from 'react';
import * as ReactRedux from 'react-redux';
import {
  TextInput, PasswordInput,
  Icon, Spinner,
} from 'giu';
import Promise from 'bluebird';
import actions from '../actions/actions';

const RETURN_KEY = 13;

const mapStateToProps = ({ cx: { fLoginRequired, loginState, login } }) => ({
  fLoginRequired,
  loginState,
  login,
});

class Login extends React.PureComponent {
  static propTypes = {
    colors: React.PropTypes.object.isRequired,
    fLoginRequired: React.PropTypes.bool,
    loginState: React.PropTypes.string.isRequired,
    login: React.PropTypes.string,
    logIn: React.PropTypes.func.isRequired,
    logOut: React.PropTypes.func.isRequired,
  };

  // -----------------------------------------------------
  render() {
    const { fLoginRequired, loginState, colors } = this.props;
    if (fLoginRequired == null) {
      return (
        <div style={style.outer(colors)}>
          <Spinner size="lg" fixedWidth />
        </div>
      );
    }
    if (!fLoginRequired) {
      return <div style={style.outer(colors)}><i>No login required to see server logs</i></div>;
    }
    return loginState === 'LOGGED_IN'
      ? this.renderLogOut()
      : this.renderLogIn();
  }

  renderLogOut() {
    const { login, colors } = this.props;
    const msg = login ? `Logged in as ${login}` : 'Logged in';
    return (
      <div style={style.outer(colors)}>
        {msg}
        {' '}
        <Icon
          icon="sign-out"
          title="Log out"
          size="lg"
          fixedWidth
          onClick={this.logOut}
        />
      </div>
    );
  }

  renderLogIn() {
    const { loginState, colors } = this.props;
    let btn;
    switch (loginState) {
      case 'LOGGED_OUT':
        btn = (
          <Icon
            icon="sign-in"
            title="Log in"
            size="lg"
            fixedWidth
            onClick={this.logIn}
          />
        );
        break;
      case 'LOGGING_IN':
        btn = <Spinner title="Logging in" size="lg" fixedWidth />;
        break;
      default:
        btn = '';
        break;
    }
    return (
      <div style={style.outer(colors, true)}>
        <b>Server logs:</b>
        {' '}
        <TextInput
          ref="login"
          id="login"
          placeholder="Login"
          onKeyUp={this.onKeyUpCredentials}
          style={style.field}
          required errorZ={12}
        />
        <PasswordInput
          ref="password"
          id="password"
          placeholder="Password"
          onKeyUp={this.onKeyUpCredentials}
          style={style.field}
          required errorZ={12}
        />
        {btn}
      </div>
    );
  }

  // -----------------------------------------------------
  logIn = () => {
    const credentials = {};
    Promise.map(['login', 'password'], (key) =>
      this.refs[key].validateAndGetValue()
      .then((val) => { credentials[key] = val; })
    )
    .then(() => this.props.logIn(credentials));
  }

  logOut = () => { this.props.logOut(); }

  onKeyUpCredentials = (ev) => {
    if (ev.which !== RETURN_KEY) return;
    this.logIn();
  }
}

// -----------------------------------------------------
const style = {
  outer: (colors, fHighlight) => ({
    padding: '4px 10px',
    backgroundColor: fHighlight ? colors.colorServerBg : colors.colorUiBg,
    color: fHighlight ? colors.colorServerFg : colors.colorUiFg,
  }),
  field: {
    marginRight: 4,
    width: 70,
    backgroundColor: 'transparent',
  },
};

// -----------------------------------------------------
const connect = ReactRedux.connect(mapStateToProps, actions);
export default connect(Login);
export { Login as _Login };
