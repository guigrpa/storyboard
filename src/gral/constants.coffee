timm  = require 'timm'
k     = require 'storyboard-core/lib/constants'

module.exports = timm.merge k,
  # WebSockets
  WS_NAMESPACE: '/STORYBOARD'
