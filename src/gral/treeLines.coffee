chalk = require 'chalk'
_ = require '../vendor/lodash'

_tree = (node, options, prefix, stack) ->
  out = []
  options.ignoreKeys ?= []
  stack.push node
  postponedArrayAttrs = []
  postponedObjectAttrs = []
  for key, val of node
    continue if key in options.ignoreKeys
    if _.isObject(val) and _.includes(stack, val)  # Avoid circular dependencies
      out.push "#{prefix}#{key}: #{chalk.green.bold '[CIRCULAR]'}"
    else if _.isArray(val) and val.length is 0
      out.push "#{prefix}#{key}: #{chalk.bold '[]'}"
    else if _.isArray(val) and val.length and _.isString(val[0])
      strVal = _.map(val, (o) -> "'#{o}'").join ', '
      strVal = chalk.yellow.bold "[#{strVal}]"
      out.push "#{prefix}#{key}: #{strVal}"
    else if _.isDate(val)
      out.push "#{prefix}#{key}: #{chalk.magenta.bold val.toISOString()}"
    else if _.isObject(val) and Object.keys(val).length is 0
      out.push "#{prefix}#{key}: #{chalk.bold '{}'}"
    else if _.isArray val
      postponedArrayAttrs.push key
    else if _.isObject val
      postponedObjectAttrs.push key
    else if _.isString val
      out.push "#{prefix}#{key}: " + chalk.yellow.bold("'#{val}'")
    else if _.isNull val
      out.push "#{prefix}#{key}: #{chalk.red.bold 'null'}"
    else if _.isUndefined val
      out.push "#{prefix}#{key}: #{chalk.bgRed.bold 'undefined'}"
    else if _.isBoolean val
      out.push "#{prefix}#{key}: #{chalk.cyan.bold val}"
    else if _.isNumber val
      out.push "#{prefix}#{key}: #{chalk.blue.bold val}"
    else
      ### !pragma coverage-skip-block ###
      out.push "#{prefix}#{key}: #{chalk.bold val}"
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

module.exports = (obj, options = {}) ->
  options.indenter ?= '  '
  prefix = options.prefix ? ''
  return _tree obj, options, prefix, []
