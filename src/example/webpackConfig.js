const path = require('path');
const { merge } = require('timm');
const webpackConfig = require('../webpackConfigBase');

module.exports = merge(webpackConfig, {
  entry: {
    app: ['./src/example/clientOld.coffee'],
    exampleUpload: ['./src/example/clientWithUpload'],
  },
  output: {
    filename: '[name].js',
    path: path.resolve(process.cwd(), 'example'),
    publicPath: '/',
  },
});
