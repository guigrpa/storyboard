path = require 'path'
webpack = require 'webpack'

module.exports = 

  entry: 
    app: ['./src/serverLogsApp/app.coffee']

  output:
    filename: 'app.js'

    # Where PRODUCTION bundles will be stored
    path: path.resolve(process.cwd(), 'serverLogsApp')

    # 
    publicPath: '/'

  resolve:
    # Add automatically the following extensions to required modules
    extensions: ['', '.coffee', '.js']

  module:
    loaders: [
      test: /\.coffee$/
      loader: 'coffee'
    ]
