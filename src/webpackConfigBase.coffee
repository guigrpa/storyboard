webpack = require 'webpack'

LANGS = ['en_gb']

module.exports =
  resolve:
    # Add automatically the following extensions to required modules
    extensions: ['', '.coffee', '.cjsx', '.js']

  plugins: [
    new webpack.ContextReplacementPlugin /moment[\\\/]locale$/, new RegExp ".[\\\/](#{LANGS.join '|'})"
  ]

  ## devtool: if process.env.NODE_ENV isnt 'production' then 'eval'

  module:
    loaders: [
      test: /\.cjsx$/
      loader: 'coffee!cjsx'
    ,
      test: /\.coffee$/
      loader: 'coffee'
    ,
      test: /\.(otf|eot|svg|ttf|woff|woff2)(\?v=[0-9]\.[0-9]\.[0-9])?$/
      loader: 'file'
    ,
      test: /\.css$/
      loader: 'style!css'
    ,
      test: /\.sass$/
      loader: 'style!css!sass?indentedSyntax'
    ]
