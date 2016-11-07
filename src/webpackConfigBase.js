/* eslint-disable no-useless-escape */

const path = require('path');
const webpack = require('webpack');
const pkg = require('../package.json');

const LANGS = ['en_gb'];

module.exports = {
  resolve: {
    // Add automatically the following extensions to required modules
    extensions: ['', '.coffee', '.js'],
  },

  plugins: [
    new webpack.ContextReplacementPlugin(
      /moment[\\\/]locale$/,
      new RegExp(`.[\\\/](${LANGS.join('|')})`)
    ),
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV),
      'process.env.TEST_BROWSER': JSON.stringify(false),
      'process.env.STORYBOARD_VERSION': JSON.stringify(pkg.version),
    }),
  ],

  // devtool: if process.env.NODE_ENV isnt 'production' then 'eval'

  module: {
    loaders: [
      {
        test: /\.coffee$/,
        loader: 'babel!coffee',
      },
      {
        test: /\.js$/,
        exclude: path.resolve(process.cwd(), 'node_modules'),
        loader: 'babel',
      },
      {
        test: /\.(otf|eot|svg|ttf|woff|woff2)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'file',
      },
      {
        test: /\.css$/,
        loader: 'style!css',
      },
      {
        test: /\.sass$/,
        loader: 'style!css!sass?indentedSyntax',
      },
      {
        test: /\.json$/,
        loader: 'json',
      },
    ],
  },
};
