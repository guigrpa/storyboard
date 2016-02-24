path = require 'path'
webpack = require 'webpack'

module.exports = 

  entry: 
    background: ['./src/chromeExtension/background.coffee']
    contentScript: ['./src/chromeExtension/contentScript.coffee']
    devTools: ['./src/chromeExtension/devTools.coffee']
    devPanel: ['./src/chromeExtension/devPanel.coffee']
    devToolsApp: ['./src/chromeExtension/devToolsApp.coffee']

  output:
    filename: '[name].js'

    # Where PRODUCTION bundles will be stored
    path: path.resolve(process.cwd(), 'chromeExtension')

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
