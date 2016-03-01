React = require 'react'
{createDevTools} = require 'redux-devtools'
DiffMonitor = require('redux-devtools-diff-monitor').default
## LogMonitor = require('redux-devtools-log-monitor').default
DockMonitor = require('redux-devtools-dock-monitor').default

module.exports = createDevTools(
  <DockMonitor 
    toggleVisibilityKey="ctrl-h"
    changePositionKey="ctrl-shift-h"
    defaultIsVisible={true}
    defaultPosition="right"
  >
    <DiffMonitor theme='tomorrow' />
  </DockMonitor>
)

###
    <LogMonitor 
      theme="chalk"
      expandStateRoot={true}
    />
###