timm        = require 'timm'
ifExtension = require './interfaceExtension'
treeLines   = require '../gral/treeLines'
serializeAttachments = require './serializeAttachments'
k           = require '../gral/constants'

DEFAULT_CONFIG = {}

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (baseConfig) ->
  config = timm.addDefaults baseConfig, DEFAULT_CONFIG
  listener =
    type: 'BROWSER_EXTENSION'
    init: -> 
    process: (record) -> 
      ifExtension.tx {type: 'RECORDS', data: [serializeAttachments record]}
    ## config: (newConfig) -> config = timm.merge config, newConfig
  listener

module.exports = {
  create,
}
