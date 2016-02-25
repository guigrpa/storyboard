path = require 'path'
timm = require 'timm'
webpackConfig = require '../webpackConfigBase'
module.exports = timm.merge webpackConfig,
  entry: 
    app: ['./src/example/app.coffee']
  output:
    filename: 'app.js'
    path: path.resolve(process.cwd(), 'example')
    publicPath: '/'
