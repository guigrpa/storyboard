React = require 'react'
{createDevTools} = require 'redux-devtools'
LogMonitor = require('redux-devtools-log-monitor').default
DockMonitor = require('redux-devtools-dock-monitor').default
Inspector = require('redux-devtools-inspector').default

module.exports = createDevTools(
  <DockMonitor 
    toggleVisibilityKey="ctrl-h"
    changePositionKey="ctrl-shift-h"
    changeMonitorKey="ctrl-m"
    defaultIsVisible={true}
    defaultPosition="right"
  >
    <Inspector/>
  </DockMonitor>
)

###
    <LogMonitor 
      theme="chalk"
      expandStateRoot={true}
    />
###