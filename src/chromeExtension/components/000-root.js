import { Provider } from 'react-redux';
import React from 'react';
import App from './005-app';

const Root = ({ store }) =>
  <Provider store={store}>
    <App />
  </Provider>;

Root.propTypes = {
  store: React.PropTypes.object.isRequired,
};

export default Root;
