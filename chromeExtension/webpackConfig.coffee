path = require 'path'
webpack = require 'webpack'

module.exports = 

  entry: 
    background: ['./chromeExtension/app/background.coffee']
    contentScript: ['./chromeExtension/app/contentScript.coffee']
    devTools: ['./chromeExtension/app/devTools.coffee']
    devPanel: ['./chromeExtension/app/devPanel.coffee']

  output:
    filename: '[name].js'

    # Where PRODUCTION bundles will be stored
    path: path.resolve(process.cwd(), 'chromeExtension/dist')

    # 
    publicPath: '/'

  resolve:
    # Add automatically the following extensions to required modules
    extensions: ['', '.coffee', '.js']

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
