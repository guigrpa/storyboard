timm        = require 'timm'
treeLines   = require '../gral/treeLines'

module.exports = (record) ->
  return record if not record.hasOwnProperty 'obj'
  ### istanbul ignore next ###
  return record if record.fSerialized
  return timm.set record, 'obj', treeLines(record.obj, record.objOptions)
