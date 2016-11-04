const React = require('react');

module.exports = (name) => (props) => (
  <div dataMockType={name} {...props}>{name}</div>
);
