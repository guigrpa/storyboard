/* eslint-disable react/prop-types */

const React = require('react');

module.exports = (name) => (props) => (
  <div dataMockType={name} {...props}>
    <div style={{ fontWeight: 'bold', color: 'blue' }}>{name}</div>
    {props.children}
  </div>
);
