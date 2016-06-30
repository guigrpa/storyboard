path = require 'path'
timm = require 'timm'
webpackConfig = require '../webpackConfigBase'
module.exports = timm.merge webpackConfig,
  entry: 
    app: ['./src/serverLogsApp/app.js']
  output:
    filename: 'app.js'
    path: path.resolve(process.cwd(), 'serverLogsApp')
    publicPath: '/'
