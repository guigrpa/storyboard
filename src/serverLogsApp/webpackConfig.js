const path = require('path');
const { merge } = require('timm');
const webpackConfig = require('../webpackConfigBase');

module.exports = merge(webpackConfig, {
  entry: {
    app: ['./src/serverLogsApp/app.js'],
  },
  output: {
    filename: '[name].js',
    path: path.resolve(process.cwd(), 'serverLogsApp'),
    publicPath: '/',
  },
});
