module.exports =
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
      test: /\.(otf|eot|svg|ttf|woff|woff2)(\?v=[0-9]\.[0-9]\.[0-9])?$/
      loader: 'file'
    ,
      test: /\.css$/
      loader: 'style!css'
    ,
      test: /\.sass$/
      loader: 'style!css!sass?indentedSyntax'
    ]
