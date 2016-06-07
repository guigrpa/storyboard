chalk = require 'chalk'
_ = require '../vendor/lodash'
{CIRCULAR_REF} = require './serialize'

WRAPPER_KEY = '__wrapper__'

_tree = (node, options, prefix, stack) ->
  out = []
  options.ignoreKeys ?= []
  stack.push node
  postponedArrayAttrs = []
  postponedObjectAttrs = []
  for key, val of node
    continue if options.ignoreKeys.indexOf(key) >= 0
    finalPrefix = if key is WRAPPER_KEY then prefix else "#{prefix}#{key}: "
    if (_.isObject(val) and _.includes(stack, val)) or  # Avoid circular dependencies
       (val is CIRCULAR_REF)
      out.push "#{finalPrefix}#{chalk.green.bold '[CIRCULAR]'}"
    else if _.isArray(val) and val.length is 0
      out.push "#{finalPrefix}#{chalk.bold '[]'}"
    else if _.isArray(val) and val.length and _.isString(val[0])
      strVal = _.map(val, (o) -> "'#{o}'").join ', '
      strVal = chalk.yellow.bold "[#{strVal}]"
      out.push "#{finalPrefix}#{strVal}"
    else if _.isDate(val)
      out.push "#{finalPrefix}#{chalk.magenta.bold val.toISOString()}"
    else if _.isObject(val) and Object.keys(val).length is 0
      out.push "#{finalPrefix}#{chalk.bold '{}'}"
    else if _.isArray val
      postponedArrayAttrs.push key
    else if _.isObject val
      postponedObjectAttrs.push key
    else if _.isString val
      lines = val.split '\n'
      if lines.length is 1
        out.push "#{finalPrefix}" + chalk.yellow.bold("'#{val}'")
      else
        for line in lines
          out.push "#{finalPrefix}" + chalk.yellow.bold(line)
    else if _.isNull val
      out.push "#{finalPrefix}#{chalk.red.bold 'null'}"
    else if _.isUndefined val
      out.push "#{finalPrefix}#{chalk.bgRed.bold 'undefined'}"
    else if _.isBoolean val
      out.push "#{finalPrefix}#{chalk.cyan.bold val}"
    else if _.isNumber val
      out.push "#{finalPrefix}#{chalk.blue.bold val}"
    else
      ### istanbul ignore next ###
      out.push "#{finalPrefix}#{chalk.bold val}"
  for key in postponedObjectAttrs
    val = node[key]
    out.push "#{prefix}#{key}:"
    out = out.concat _tree val, options, "#{options.indenter}#{prefix}", stack
  for key in postponedArrayAttrs
    val = node[key]
    out.push "#{prefix}#{key}:"
    out = out.concat _tree val, options, "#{options.indenter}#{prefix}", stack
  stack.pop()
  out

treeLines = (obj, options = {}) ->
  options.indenter ?= '  '
  prefix = options.prefix ? ''
  if _.isError obj
    obj = _.pick obj, ['name', 'message', 'stack']
  else if not _.isObject obj 
    obj = {"#{WRAPPER_KEY}": obj}
  return _tree obj, options, prefix, []

treeLines.log = ->
  lines = treeLines arguments...
  for line in lines
    console.log line
  return

module.exports = treeLines