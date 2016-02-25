path = require 'path'
webpack = require 'webpack'

module.exports = 

  entry: 
    app: ['./src/example/app.coffee']

  output:
    filename: 'app.js'

    # Where PRODUCTION bundles will be stored
    path: path.resolve(process.cwd(), 'example/public')

    # 
    publicPath: '/'

  resolve:
    # Add automatically the following extensions to required modules
    extensions: ['', '.coffee', '.cjsx', '.js']

  module:
    loaders: [
      test: /\.cjsx$/
      loader: 'coffee!cjsx'
    ,
      test: /\.coffee$/
      loader: 'coffee'
    ,
      test: /\.css$/
      loader: 'style!css'
    ,
      test: /\.sass$/
      loader: 'style!css!sass?indentedSyntax'
    ]
