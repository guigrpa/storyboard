path = require 'path'
timm = require 'timm'
webpackConfig = require '../webpackConfigBase'
module.exports = timm.merge webpackConfig,
  entry: 
    app: ['./src/example/client.coffee']
    exampleUpload: ['./src/example/clientWithUpload.coffee']
  output:
    filename: '[name].js'
    path: path.resolve(process.cwd(), 'example')
    publicPath: '/'
