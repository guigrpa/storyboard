const path = require('path');
const { merge } = require('timm');
const webpackConfig = require('../webpackConfigBase');

module.exports = merge(webpackConfig, {
  entry: {
    background: ['./src/chromeExtension/background'],
    contentScript: ['./src/chromeExtension/contentScript'],
    devTools: ['./src/chromeExtension/devTools'],
    devPanel: ['./src/chromeExtension/devPanel'],
    devToolsApp: ['./src/chromeExtension/devToolsApp'],
  },
  output: {
    filename: '[name].js',
    path: path.resolve(process.cwd(), 'chromeExtension'),
    publicPath: '/',
  },
});
