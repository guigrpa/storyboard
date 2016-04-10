timm        = require 'timm'
treeLines   = require 'storyboard-core/lib/treeLines'
ifExtension = require './interfaceExtension'
k           = require '../gral/constants'

DEFAULT_CONFIG = {}

#-------------------------------------------------
# ## Helpers
#-------------------------------------------------
# Process client-side attachments, exactly the same
# way as in the WS Server listener
_preprocessAttachments = (record) -> 
  return record if not record.obj?
  return timm.set record, 'obj', treeLines(record.obj)

#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (baseConfig) ->
  config = timm.addDefaults baseConfig, DEFAULT_CONFIG
  listener =
    type: 'BROWSER_EXTENSION'
    init: -> 
    process: (record) -> 
      ifExtension.tx {type: 'RECORDS', data: [_preprocessAttachments record]}
    ## config: (newConfig) -> config = timm.merge config, newConfig
  listener

module.exports = {
  create,
}
