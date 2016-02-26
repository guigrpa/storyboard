ANSI_REGEX = /(?:(?:\u001b\[)|\u009b)(?:(?:[0-9]{1,3})?(?:(?:;[0-9]{0,3})*)?[A-M|f-m])|\u001b[A-M]/g
MAP_ADD_STYLE = 
  30: 'color: black'
  31: 'color: red'
  32: 'color: green'
  33: 'color: orange'
  34: 'color: blue'
  94: 'color: blue'
  35: 'color: magenta'
  36: 'color: cyan'
  37: 'color: lightgrey'
  90: 'color: grey'
  40: 'color: white;background-color: black'
  41: 'color: white;background-color: red'
  42: 'color: white;background-color: green'
  43: 'color: white;background-color: orange'
  44: 'color: white;background-color: blue'
  45: 'color: white;background-color: magenta'
  46: 'color: white;background-color: cyan'
  47: 'color: white;background-color: lightgrey'
  1: 'font-weight: bold'
  2: 'opacity: 0.8'
  3: 'font-style: italic'
  4: 'text-decoration: underline'
  8: 'display: none'
  9: 'text-decoration: line-through'
MAP_ADD_STYLE_REACT = 
  30: {color: 'black'}
  31: {color: 'red'}
  32: {color: 'green'}
  33: {color: 'orange'}
  34: {color: 'blue'}
  94: {color: 'blue'}
  35: {color: 'magenta'}
  36: {color: 'cyan'}
  37: {color: 'lightgrey'}
  90: {color: 'grey'}
  40: {color: 'white', backgroundColor: 'black'}
  41: {color: 'white', backgroundColor: 'red'}
  42: {color: 'white', backgroundColor: 'green'}
  43: {color: 'white', backgroundColor: 'orange'}
  44: {color: 'white', backgroundColor: 'blue'}
  45: {color: 'white', backgroundColor: 'magenta'}
  46: {color: 'white', backgroundColor: 'cyan'}
  47: {color: 'white', backgroundColor: 'lightgrey'}
  1: {fontWeight: 'bold'}
  2: {opacity: 0.8}
  3: {fontStyle: 'italic'}
  4: {textDecoration: 'underline'}
  8: {display: 'none'}
  9: {textDecoration: 'line-through'}
REMOVE_STYLE_LIST = [0, 21, 22, 23, 24, 27, 28, 29, 39, 49]

argsForBrowserConsole = (str) ->
  outStr = str.replace ANSI_REGEX, '%c'
  argArray = [outStr]
  curStyles = []
  regex = /\u001b\[(\d+)*m/gi
  while (res = regex.exec str)
    code = Number res[1]
    if code in REMOVE_STYLE_LIST
      curStyles.pop()
    else
      curStyles.push(MAP_ADD_STYLE[code] ? '')
    argArray.push curStyles.join(';')
  argArray

getStructured = (str) ->
  return null if not str?
  regex = /\u001b\[(\d+)*m/gi
  tokens = str.split regex
  return [str] if tokens.length <= 1
  lev = 0
  tmp = [{lev, style: '', txt: tokens[0]}]
  for idx in [1...tokens.length] by 2
    code = Number tokens[idx]
    txt = tokens[idx+1]
    if code in REMOVE_STYLE_LIST
      style = {}
      lev--
    else
      style = MAP_ADD_STYLE_REACT[code]
      if not style?
        console.warn "Unknown ANSI code #{code} in string #{str}"
        style = {}
      lev++
    tmp.push {lev, style, txt}
  out = [
    style: {}
    children: []
  ]
  if tmp[0].txt.length then out[0].children.push tmp[0].txt
  ptr = []
  ptr[0] = out[0].children
  prevLev = 0
  for idx in [1...tmp.length] by 1
    {lev, style, txt} = tmp[idx]
    if lev > prevLev  
      newChild = {style, children: []}
      ptr[prevLev].push newChild
      ptr[lev] = newChild.children
      if txt.length then ptr[lev].push txt
    else
      if txt.length then ptr[lev].push txt
    prevLev = lev
  out

module.exports = {
  argsForBrowserConsole,
  getStructured,
}