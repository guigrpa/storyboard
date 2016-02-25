path = require 'path'
timm = require 'timm'
webpackConfig = require '../webpackConfigBase'
module.exports = timm.merge webpackConfig,
  entry: 
    background: ['./src/chromeExtension/background.coffee']
    contentScript: ['./src/chromeExtension/contentScript.coffee']
    devTools: ['./src/chromeExtension/devTools.coffee']
    devPanel: ['./src/chromeExtension/devPanel.coffee']
    devToolsApp: ['./src/chromeExtension/devToolsApp.coffee']
  output:
    filename: '[name].js'
    path: path.resolve(process.cwd(), 'chromeExtension')
    publicPath: '/'
