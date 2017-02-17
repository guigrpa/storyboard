const path = require('path');
const webpack = require('webpack');  /* from the root package */ // eslint-disable-line
const pkg = require('./package.json');

const fProduction = (process.env.NODE_ENV === 'production');

const cssLoader = {
  loader: 'css-loader',
  options: { minimize: fProduction },
};

const sassLoader = {
  loader: 'sass-loader',
  options: { indentedSyntax: true },
};

module.exports = {
  entry: {
    background: ['./src/background'],
    contentScript: ['./src/contentScript'],
    devTools: ['./src/devTools'],
    devPanel: ['./src/devPanel'],
    devToolsApp: ['./src/devToolsApp'],
  },

  output: {
    filename: '[name].js',
    path: path.resolve(process.cwd(), './lib/public'),
    publicPath: '/',
  },

  plugins: [
    new webpack.DefinePlugin({
      'process.env.TEST_BROWSER': JSON.stringify(false),
      'process.env.STORYBOARD_VERSION': JSON.stringify(pkg.version),
    }),
  ],

  module: {
    rules: [{
      test: /\.js$/,
      exclude: path.resolve(process.cwd(), 'node_modules'),
      loader: 'babel-loader',
    },
    {
      test: /\.(otf|eot|svg|ttf|woff|woff2)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
      loader: 'file-loader',
    },
    {
      test: /\.css$/,
      loaders: ['style-loader', cssLoader],
    },
    {
      test: /\.sass$/,
      loaders: ['style-loader', cssLoader, sassLoader],
    }],
  },
};
