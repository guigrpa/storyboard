timm        = require 'timm'
ifExtension = require './helpers/interfaceExtension'
filters     = require '../gral/filters'
k           = require '../gral/constants'

DEFAULT_CONFIG = {}

#-------------------------------------------------
# ## Extension I/O
#-------------------------------------------------
_extensionRxMsg = (msg) ->
  {type, data} = msg
  switch type
    when 'GET_LOCAL_CLIENT_FILTER', 'SET_LOCAL_CLIENT_FILTER'
      if type is 'SET_LOCAL_CLIENT_FILTER' then filters.config msg.data
      ifExtension.tx
        type: 'LOCAL_CLIENT_FILTER'
        result: 'SUCCESS'
        data: filter: filters.getConfig()
    else
      return
  return


#-------------------------------------------------
# ## API
#-------------------------------------------------
create = (baseConfig) ->
  config = timm.addDefaults baseConfig, DEFAULT_CONFIG
  listener =
    type: 'BROWSER_EXTENSION'
    init: ->
      ifExtension.rx _extensionRxMsg
    process: (record) -> 
      ifExtension.tx {type: 'RECORDS', data: [record]}
    ## config: (newConfig) -> config = timm.merge config, newConfig
  listener

module.exports = {
  create,
}
